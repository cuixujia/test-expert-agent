#!/usr/bin/env bash
# validate-prd.sh — 需求与证据侧硬校验（零依赖，bash 3.2 兼容）
# 归属: prd-quality-check（规则唯一权威源见 SKILL.md 锚点规则 1）
# 结构: <功能目录>/prd.txt 快照 + <会话目录>/scope.md 锚点底册
# 用法:
#   snapshot: bash validate-prd.sh "<功能目录>" snapshot "<PRD 文件名>"   # 生成 prd.txt（textutil/pandoc+引号归一）并输出源文件 md5
#   scope:    bash validate-prd.sh "<会话目录>/scope.md" scope            # 锚点底册格式 + 锚点语法 + 摘录逐字机验
#   pull:     bash validate-prd.sh "<会话目录>/scope.md" pull "<锚点>"    # 输出该锚点底册摘录（先自验命中快照）
#   scan:     bash validate-prd.sh "<会话目录>/scope.md" scan             # 漏锚扫描一键候选（章节锚点覆盖+功能名命中聚合）
#   find:     bash validate-prd.sh "<功能目录>" find "<关键词>"            # 输出快照中命中该词的行（行号+原文，供逐字节抄写）
#   line:     bash validate-prd.sh "<功能目录>" line <行号>               # 输出快照该行的完整原文（含 markdown 符号）
# 退出码: 0 = 全部通过; 1 = 存在 FAIL, 必须修复后重跑; 2 = 用法错误
# 锚点语法契约: 唯一定义源为 prd-quality-check 锚点规则 1（编号取自 PRD 原文编号；无编号时 M<模块号>-S<章节号>-P<段落号> 派生；
#               形态为字母/数字/小数点组成 1~4 段、段间连字符、整串至少含一个数字；禁止字母后缀细分与中文语义），
#               本脚本的 awk 正则为其实现，两处必须同步修改
# 摘录逐字机验依赖 <bizFunctionId>/prd.txt（PRD 文本快照，生成规则见 prd-quality-check 快照规则）
# 注意: 摘录必须逐字符复制快照原文（含 markdown 标记/列表符号/表格竖线），长度校验用 wc -m（awk length() 按字节计数）
set -u

ARG=${1:-}
TARGET=${2:-}
EXTRA=${3:-}
EXTRA2=${4:-}
FAILS=0
PASSES=0

fail() { FAILS=$((FAILS+1)); printf '[FAIL] %s\n' "$*"; }
pass() { PASSES=$((PASSES+1)); printf '[PASS] %s\n' "$*"; }

if [ -z "$ARG" ]; then
  printf '用法: bash validate-prd.sh "<会话目录>/scope.md" scope|pull|scan | "<功能目录>" snapshot|find|line\n'
  printf '模式: snapshot（生成快照）/ scope（底册校验）/ pull <锚点>（取摘录）/ scan（漏锚候选）/ find <关键词>（定位原文行）/ line <行号>（取该行原文）\n'
  exit 2
fi

if [ -f "$ARG" ]; then
  DIR=$(dirname "$ARG")
  case "$(basename "$ARG")" in
    scope.md)      case "$TARGET" in ""|scope) TARGET=scope ;; pull) : ;; scan) : ;; *) printf '用法: scope.md 仅支持 scope / pull / scan\n'; exit 2 ;; esac ;;
    *) printf '用法: 本脚本只处理 scope.md（会话目录）或功能目录；产物校验用 self-review-checklist/validate.sh\n'; exit 2 ;;
  esac
elif [ -d "$ARG" ]; then
  DIR=${ARG%/}
  case "$TARGET" in
    snapshot|find|line|cat) : ;;
    *) printf '用法: 传目录须带模式: snapshot（生成快照）/ find <关键词>（定位原文行）/ line <行号>[/<结束>]（取原文行）/ cat（全文带行号）\n'; exit 2 ;;
  esac
else
  printf '[FAIL] 路径不可访问: %s\n' "$ARG"
  printf '提示: 本脚本在 bash(WSL/Git Bash) 下运行，入参必须是 bash 可见的路径——相对仓库根的路径（例：workspace/runtime_<项目>/file/<bizFunctionId>）或 WSL 绝对路径（例：/mnt/host/d/Project/<项目>/...）；不要传 Windows 路径（例：D:\\...）。\n'
  printf '用法: bash validate-prd.sh "<会话目录>/scope.md" scope|pull|scan | "<功能目录>" snapshot|find|line\n'
  exit 2
fi

S_FILE="$DIR/scope.md"
P_FILE="$DIR/../output/test-point/test-point.md"
C_FILE="$DIR/../output/test-case/test-case.md"
FNID=$(basename "$(dirname "$DIR")")   # 功能目录名=平台 bizFunctionId; TP/TC 编号功能码必须与其一致

TMPD=$(mktemp -d) || exit 2
TPIDS="$TMPD/tp_ids"    # test-point.md 中全部合法 TP 编号（每行一个）
TCTPS="$TMPD/tc_tps"   # test-case.md 中全部合法关联 TP（每行一个）
TPANCH="$TMPD/tp_anchors"  # test-point.md 主表依据列提取的锚点（每行一个）
TPPAIRS="$TMPD/tp_pairs"   # (TP编号, 锚点) 对（主表依据列，多锚点逐对，供覆盖双向映射机检）
: > "$TPIDS"; : > "$TCTPS"; : > "$TPANCH"; : > "$TPPAIRS"
trap 'rm -rf "$TMPD"' EXIT

# ---- test-point.md 行内校验（格式/唯一/必填/锚点）----
# ---- 锚点底册一致性校验（scope.md 锚点清单 ↔ test-point 依据/覆盖对照表）----
# 从 <file> 的 "## <section>" 节后表格提取第 <col> 列（过滤表头词与占位符）
extract_col() {
  awk -F'|' -v sec="$2" -v col="$3" '
    /^## / { in_sec = (index($0, sec) > 0) }
    in_sec && /^[[:space:]]*\|/ {
      n=0; val=""
      for (i=2; i<NF; i++) {
        v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (v ~ /^[-:]+$/) { n=-99; break }
        n++; if (n==col) val=v
      }
      if (n!=-99 && val!="") print val
    }
  ' "$1" | grep -vE '^(锚点|PRD 锚点|TP 编号|覆盖的 TP 编号|覆盖的 TC 编号|未覆盖原因|条目摘要|原文摘录|覆盖的TP编号|—|-)$'
}

check_anchors() {
  if [ ! -f "$S_FILE" ]; then fail "缺少 $S_FILE(锚点清单底册)"; return; fi
  ANCH="$TMPD/anchors"; COVA="$TMPD/cov_anchors"
  extract_col "$S_FILE" "锚点清单" 1 | sort -u > "$ANCH"
  if [ ! -s "$ANCH" ]; then
    fail "scope.md 缺少锚点清单表(或无有效锚点)"
  else
    pass "scope.md 锚点清单底册存在"
    # 底册锚点格式校验（建册即拦，不留到生成阶段才暴露；语法契约见 prd-quality-check 锚点规则 1）
    BADANC=$(awk '
      $0 !~ /^[A-Za-z0-9]+(\.[0-9]+)*(-[A-Za-z0-9]+(\.[0-9]+)*){0,3}$/ || $0 !~ /[0-9]/ { printf "%s ", $0; bad++ }
      END { exit (bad ? 1 : 0) }
    ' "$ANCH")
    if [ -n "$BADANC" ]; then
      fail "底册锚点格式不合规(须符合 prd-quality-check 锚点规则 1 的锚点语法：字母/数字/小数点组成 1~4 段、段间连字符、整串含数字；编号取自 PRD 原文编号，无编号时按 M<模块号>-S<章节号>-P<段落号> 派生，禁止字母后缀细分与中文语义): $BADANC"
    else
      pass "底册锚点格式校验通过"
    fi
    [ -f "$P_FILE" ] || return
    extract_col "$P_FILE" "覆盖对照表" 1 | sort -u > "$COVA"
    D1=$(comm -23 <(sort -u "$TPANCH") "$ANCH" | tr '\n' ' ')
    if [ -n "${D1//[[:space:]]/}" ]; then
      fail "TP 依据锚点不在底册: $D1"
    else
      pass "TP 依据锚点底册引用校验通过"
    fi
    D2=$(comm -23 "$ANCH" "$COVA" | tr '\n' ' ')
    if [ -n "${D2//[[:space:]]/}" ]; then
      fail "底册锚点未出现在覆盖对照表: $D2"
    else
      pass "锚点底册全覆盖校验通过"
    fi
    D3=$(comm -13 "$ANCH" "$COVA" | tr '\n' ' ')
    if [ -n "${D3//[[:space:]]/}" ]; then
      fail "覆盖对照表锚点不在底册(疑似幻觉锚点): $D3"
    fi
    # 覆盖双向映射机检（覆盖对照表第2列 TP ↔ TP 依据锚点；此类问题脚本捕获，不再依赖质检轮次发现）
    if [ -s "$TPPAIRS" ]; then
      OUTC=$(awk -F'|' -v pairs="$TPPAIRS" '
        BEGIN {
          while ((getline line < pairs) > 0) {
            split(line, p, "\t")
            key=p[2] SUBSEP p[1]
            tp_anc[key]=1
          }
          close(pairs)
        }
        /^## / { in_sec = (index($0, "覆盖对照表") > 0) }
        in_sec && /^[[:space:]]*\|/ {
          n=0; a=""; tps=""
          for (i=2; i<NF; i++) {
            v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
            if (v ~ /^[-:]+$/) { n=-99; break }
            n++; if (n==1) a=v; else if (n==2) tps=v
          }
          if (n==-99 || a=="" || tps=="") next
          if (a ~ /锚点/ || a ~ /^(—|-)$/) next
          gsub(/[、，,\/；;[:space:]]+/, " ", tps)
          m=split(tps, arr, " ")
          for (j=1; j<=m; j++) {
            x=arr[j]
            if (x !~ /^TP-[A-Za-z0-9_-]{1,20}-[0-9]{3,}$/) continue
            key=a SUBSEP x
            if (!(key in tp_anc))
              { printf "[FAIL] 覆盖对照表: 锚点 %s 声明由 %s 覆盖, 但该 TP 依据未挂锚点 %s\n", a, x, a; bad++ }
            claimed[a]=claimed[a] " " x
          }
        }
        END {
          for (k in tp_anc) {
            split(k, kk, SUBSEP)
            if (index(" " claimed[kk[1]] " ", " " kk[2] " ") == 0)
              { printf "[FAIL] 覆盖对照表: TP %s 依据挂锚点 %s, 但覆盖对照表 %s 行未登记该 TP\n", kk[2], kk[1], kk[1]; bad++ }
          }
          exit (bad ? 1 : 0)
        }
      ' "$P_FILE"); RC=$?
      printf '%s\n' "$OUTC"
      NFC=$(printf '%s\n' "$OUTC" | grep -c '^\[FAIL\]')
      FAILS=$((FAILS + NFC))
      [ "$RC" -eq 0 ] && pass "覆盖对照表与 TP 依据双向映射校验通过"
    fi
  fi
}

# ---- 摘录逐字机验（01 底册摘录 ↔ PRD 快照; TP 依据 ↔ 底册摘录）----
# 快照生成与降级规则见 prd-quality-check 快照规则; 比对前做空白规范化(含全角空格)
# 已知坑: macOS awk 在 LC_ALL=UTF-8 下对纯中文串的 == 比较会误判真;
# 故本函数 awk 一律不设 LC_ALL(走 C locale 字节语义), 中文相等判断用正则, 字符计数只用 wc -m
check_snapshot() {
  [ -f "$S_FILE" ] || return
  if grep -q '^> 快照机验：跳过' "$S_FILE"; then
    pass "快照机验: scope.md 已声明降级, 跳过(规则见 prd-quality-check 快照规则)"
    return
  fi
  SNAP="$DIR/../prd.txt"
  if [ ! -f "$SNAP" ]; then
    fail "缺少 $SNAP(PRD 文本快照), 无法机验摘录(生成规则见 prd-quality-check 快照规则)"
    return
  fi
  awk '{ gsub(/[[:space:]]/, ""); gsub(/　/, ""); printf "%s", $0 }' "$SNAP" > "$TMPD/snap_norm"

  # 提取 scope 锚点清单 (锚点, 摘录) 对, 规范化后落临时文件; 锚点重复直接报 FAIL
  OUT=$(awk -F'|' -v out="$TMPD/exc_pairs" '
    /^## / { in_sec = (index($0, "锚点清单") > 0) }
    in_sec && /^[[:space:]]*\|/ {
      n=0; a=""; e=""
      for (i=2; i<NF; i++) {
        v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (v ~ /^[-:]+$/) { n=-99; break }
        n++
        if (n==1) a=v; else if (n==3) e=v
      }
      if (n==-99 || a=="" || e=="") next
      if (a ~ /^锚点$/ || e ~ /^原文摘录$/) next
      if (seen[a]++) { printf "[FAIL] scope 锚点清单: 锚点重复: %s\n", a; bad++; next }
      c=e; gsub(/[[:space:]]/, "", c); gsub(/　/, "", c)
      # 剥摘录壳：底册按 skill 约定用「」包裹，壳不参与逐字比对与长度计
      sub(/^「/, "", c); sub(/」$/, "", c)
      sub(/^"/, "", c); sub(/"$/, "", c)
      printf "%s\t%s\n", a, c > out
    }
    END { exit (bad ? 1 : 0) }
  ' "$S_FILE"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))

  SNAP_OK=1
  while IFS=$'\t' read -r ANC EXC; do
    [ -n "$ANC" ] || continue
    LEN=$(printf '%s' "$EXC" | LC_ALL=en_US.UTF-8 wc -m | tr -d ' ')
    if [ "$LEN" -gt 40 ]; then
      fail "scope 锚点 $ANC: 摘录超 40 字(${LEN}字)"
      SNAP_OK=0
    fi
    if ! grep -qF -- "$EXC" "$TMPD/snap_norm"; then
      fail "scope 锚点 $ANC: 摘录未逐字命中 PRD 快照（必须逐字符复制原文，含 markdown 标记/列表符号/表格竖线；不可摘要或改写）"
      SNAP_OK=0
      P8=$(printf '%s' "$EXC" | cut -c1-8)
      if [ ${#P8} -ge 4 ]; then
        HINT=$(grep -nF -- "$P8" "$SNAP" | head -3)
        [ -n "$HINT" ] && printf '         候选原文行(逐字复制):\n%s\n' "$HINT"
      fi
    fi
  done < "$TMPD/exc_pairs"
  if [ -s "$TMPD/exc_pairs" ] && [ "$SNAP_OK" -eq 1 ]; then
    pass "scope 底册摘录逐字命中快照且长度合规"
  fi

  # TP 依据必须包含对应锚点的底册摘录
  if [ -f "$P_FILE" ] && [ -s "$TMPD/exc_pairs" ]; then
    OUT2=$(awk -F'|' -v pairs="$TMPD/exc_pairs" '
      BEGIN {
        while ((getline line < pairs) > 0) {
          split(line, p, "\t")
          exc[p[1]] = p[2]
        }
        close(pairs)
      }
      /^## / { stop = 1 }
      stop { next }
      /^[[:space:]]*\|/ {
        n=0; id=""; dep=""
        for (i=2; i<NF; i++) {
          v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
          if (v ~ /^[-:]+$/) { n=-99; break }
          n++
          if (n==1) id=v; else if (n==5) dep=v
        }
        if (n==-99 || n<5) next
        if (id !~ /^TP-[A-Za-z0-9_-]{1,20}-[0-9]{3,}$/) next
        # 注意：此处不剥「」引注——摘录本身就在引注中，是要被校验的对象；只剥非锚点 token（引号内极少出现）
        gsub(/TP-[A-Za-z0-9-]+/, "", dep); gsub(/TC-[A-Za-z0-9-]+/, "", dep); gsub(/CL-[0-9]+/, "", dep); gsub(/(^|[^-A-Za-z0-9])Q[0-9]+/, "\\1", dep)
        if (match(dep, /[A-Za-z0-9]+(-[A-Za-z0-9.]+)+|[A-Za-z][A-Za-z0-9]*[0-9][A-Za-z0-9]*|[0-9]+(\.[0-9]+)+/)) {
          anc = substr(dep, RSTART, RLENGTH)
          if (anc in exc) {
            c = dep; gsub(/[[:space:]]/, "", c); gsub(/　/, "", c)
            gsub(/「/, "", c); gsub(/」/, "", c)
            if (index(c, exc[anc]) == 0)
              printf "[FAIL] test-point %s: 依据未含底册摘录(锚点 %s)\n", id, anc
          }
        }
      }
    ' "$P_FILE")
    printf '%s\n' "$OUT2"
    NF2=$(printf '%s\n' "$OUT2" | grep -c '^\[FAIL\]')
    FAILS=$((FAILS + NF2))
    [ "$NF2" -eq 0 ] && pass "TP 依据含对应底册摘录校验通过"
  fi
}


# ---- 锚点来源校验：锚点编号必须真实存在于 PRD（标题编号），否则只能是 M-S-P 自建编号 ----
# 规则见 prd-quality-check 锚点规则 1：优先取最近的带编号标题的编号；该标题无编号才自建 M-S-P
check_anchor_source() {
  [ -f "$S_FILE" ] || return
  if grep -q '^> 快照机验：跳过' "$S_FILE"; then
    pass "锚点来源校验: scope.md 已声明快照降级, 跳过(规则见 prd-quality-check 锚点规则 1)"
    return
  fi
  SNAP="$DIR/../prd.txt"
  if [ ! -f "$SNAP" ]; then
    fail "缺少 $SNAP(PRD 文本快照), 无法校验锚点来源"
    return
  fi
  ANCH2="$TMPD/anchors2"
  extract_col "$S_FILE" "锚点清单" 1 | sort -u > "$ANCH2"
  [ -s "$ANCH2" ] || return
  OUT=$(awk -v snap="$SNAP" '
    FILENAME == snap {
      if ($0 ~ /^[[:space:]]*#+[[:space:]]/) {
        line = $0
        lvl = 0
        while (substr(line, lvl+1, 1) == "#") lvl++
        rest = substr(line, lvl+1)
        sub(/^[[:space:]]+/, "", rest)
        if (match(rest, /^[0-9]+(\.[0-9]+)*/)) {
          num = substr(rest, RSTART, RLENGTH)
          sub(/\.$/, "", num)
          hnum[num] = 1
          if (lvl >= 3) hnum3[num] = 1
          nh++
          split(num, p, ".")
          if (lvl == 2) { l1num[num] = 1 }
          else if (lvl == 3) { l2num[num] = 1; has_l2[p[1]] = 1 }
          else if (lvl == 4) { l2anc[p[1] "." p[2]] = 1; has_l2[p[1]] = 1 }
        }
      }
      next
    }
    {
      a = $0
      gsub(/[[:space:]]/, "", a)
      if (a == "" || a == "锚点") next
      derived = (a ~ /^M[0-9]+-S[0-9]+-P[0-9]+$/)
      if (nh == 0) {
        # PRD 全文无带编号标题: 只允许自建编号
        if (!derived) { printf "[FAIL] scope 锚点 %s: PRD 快照无任何带编号标题, 锚点只能用 M-S-P 自建编号\n", a; bad++ }
        next
      }
      if (derived) {
        mm = substr(a, 2, index(a, "-") - 2) + 0
        s = substr(a, index(a, "-") + 1); sub(/^S/, "", s); sub(/[^0-9].*$/, "", s); s = s + 0
        if (!(mm in l1num)) {
          printf "[FAIL] scope 锚点 %s: 自建编号的模块号 M%d 在 PRD 快照中无对应一级标题\n", a, mm; bad++
        } else if (s == 0) {
          if (mm in has_l2) { printf "[FAIL] scope 锚点 %s: 自建编号写 S0, 但 PRD 快照中 M%d 下存在二级标题\n", a, mm; bad++ }
        } else {
          key = mm "." s
          if (!((key in l2num) || (key in l2anc))) {
            printf "[FAIL] scope 锚点 %s: 自建编号的章节号 S%d 在 PRD 快照中无对应二级标题(%s)\n", a, s, key; bad++
          }
        }
        next
      }
      # 情形 A: 锚点必须整体等于 PRD 的某个标题编号（不做前缀匹配、不剥后缀——禁止编号拼接）
      if (!(a in hnum)) {
        printf "[FAIL] scope 锚点 %s: 不是 PRD 标题编号（须整体等于某个标题编号，不允许拼接后缀；标题无编号时改用 M-S-P 自建编号）\n", a; bad++
      } else {
        cov[a] = 1
      }
    }
    END {
      # 标题零覆盖检查: 带编号的章节标题(### 及以下, 一级标题只是容器)下没有任何锚点 -> 疑似漏建(规则 3 粒度)
      unc = 0
      for (h in hnum3) {
        if (!(h in cov)) { unc++; if (unc <= 40) printf "  未建锚的标题编号: %s\n", h }
      }
      if (unc > 0) {
        printf "[WARN] scope 标题覆盖: %d 个章节标题下无锚点(逐个判定 漏建/范围外; 范围外的在 scope.md 或 prd-check 报告注明)\n", unc
      }
      exit (bad ? 1 : 0)
    }
  ' "$SNAP" "$ANCH2")
  RC=$?
  printf '%s\n' "$OUT"
  NFC=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NFC))
  if [ "$RC" -eq 0 ]; then
    pass "锚点来源校验通过（编号均为 PRD 标题编号或 M-S-P 自建编号）"
  fi
}


# ---- pull：按锚点提取底册摘录（自验命中快照后输出到 stdout，供程序化填充，禁止手抄）----
pull_excerpt() {
  ANC="$EXTRA"
  if [ -z "$ANC" ]; then printf '用法: bash validate-prd.sh "<会话目录>/scope.md" pull "<锚点>"\n' >&2; exit 2; fi
  EXC=$(awk -F'|' -v a="$ANC" '
    /^## /{in_sec=(index($0,"锚点清单")>0)}
    in_sec && /^[[:space:]]*\|/ {
      n=0; id=""; e=""
      for(i=2;i<NF;i++){v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); if(v ~ /^[-:]+$/){n=-99;break} n++; if(n==1)id=v; else if(n==3)e=v}
      if(n!=-99 && id==a && id!="锚点"){ print e; exit }
    }' "$S_FILE")
  if [ -z "$EXC" ]; then printf '[FAIL] 底册未找到锚点: %s\n' "$ANC" >&2; exit 1; fi
  SNAP="$DIR/../prd.txt"
  if [ ! -f "$SNAP" ]; then printf '[FAIL] 缺少快照 %s\n' "$SNAP" >&2; exit 1; fi
  NEXC=$(printf '%s' "$EXC" | awk '{ gsub(/[[:space:]]/, ""); gsub(/　/, ""); sub(/^「/, ""); sub(/」$/, ""); sub(/^"/, ""); sub(/"$/, ""); printf "%s", $0 }')
  awk '{ gsub(/[[:space:]]/, ""); gsub(/　/, ""); printf "%s", $0 }' "$SNAP" > "$TMPD/snap_norm"
  if ! grep -qF -- "$NEXC" "$TMPD/snap_norm"; then printf '[FAIL] 摘录未逐字命中快照: %s\n' "$ANC" >&2; exit 1; fi
  printf '%s\n' "$EXC"
  exit 0
}

# ---- snapshot：生成 PRD 文本快照（textutil + 引号归一，输出源文件 md5；快照只读，已存在即拒绝）----
make_snapshot() {
  DOCX="$EXTRA"
  if [ -z "$DOCX" ]; then printf '用法: bash validate-prd.sh "<功能目录>" snapshot "<PRD 文件名>"\n' >&2; exit 2; fi
  SRC=""
  for CAND in "$ARG/$DOCX" "$ARG/prd-doc/$DOCX"; do
    [ -f "$CAND" ] && { SRC="$CAND"; break; }
  done
  if [ -z "$SRC" ]; then printf '找不到源文件: %s（在功能目录及其 prd-doc/ 下查找）\n' "$ARG/$DOCX" >&2; exit 2; fi
  if [ -f "$ARG/prd.txt" ]; then printf 'prd.txt 已存在（快照只读，S1 冻结）；确认重建请先自行移除旧快照\n' >&2; exit 2; fi
  case "$DOCX" in
    *.docx|*.doc)
      if command -v textutil >/dev/null 2>&1; then
        textutil -convert txt -stdout "$SRC" | sed -e 's/“/"/g' -e 's/”/"/g' -e "s/‘/'/g" -e "s/’/'/g" > "$ARG/prd.txt"
      elif command -v pandoc >/dev/null 2>&1; then
        pandoc -t plain "$SRC" | sed -e 's/“/"/g' -e 's/”/"/g' -e "s/‘/'/g" -e "s/’/'/g" > "$ARG/prd.txt"
      else
        printf 'textutil(仅 macOS)与 pandoc 均不可用：请安装 pandoc，或用其他工具转文本并自行归一引号后落盘（规则见 prd-quality-check 快照规则）\n' >&2; exit 2
      fi ;;
    *.txt|*.md)
      sed -e 's/“/"/g' -e 's/”/"/g' -e "s/‘/'/g" -e "s/’/'/g" "$SRC" > "$ARG/prd.txt" ;;
    *)
      printf '不支持的快照源格式: %s（支持 docx/doc/txt/md；PDF/图片按 prd-quality-check 快照规则降级声明）\n' "$DOCX" >&2; exit 2 ;;
  esac
  H=$(md5sum "$SRC" 2>/dev/null | awk '{print $1}')
  [ -z "$H" ] && H=$(md5 -q "$SRC" 2>/dev/null)
  printf 'prd.txt 已生成: %s/prd.txt\n源文件 md5=%s\n' "$ARG" "$H"
  exit 0
}

# ---- scan：漏锚扫描一键候选（章节锚点覆盖 + 功能名命中聚合；机器出候选，判定权在人/质检）----
run_scan() {
  if [ ! -f "$S_FILE" ]; then fail "缺少 $S_FILE(锚点底册)"; printf '%s\n' ""; printf '========== 校验汇总: PASS=%d FAIL=%d ==========\n' "$PASSES" "$FAILS"; return 1; fi
  SNAP="$DIR/../prd.txt"
  if [ ! -f "$SNAP" ]; then fail "缺少 $SNAP(PRD 文本快照), 无法扫描"; printf '========== 校验汇总: PASS=%d FAIL=%d ==========\n' "$PASSES" "$FAILS"; return 1; fi
  ANCH="$TMPD/scan_anchors"
  extract_col "$S_FILE" "锚点清单" 1 | sort -u > "$ANCH"
  ANCH_N=$(grep -c . "$ANCH" 2>/dev/null || echo 0)
  FEAT=$(head -n 1 "$S_FILE" | sed -e 's/^#[[:space:]]*//' -e 's/锚点底册.*//' -e 's/[[:space:]]*$//')
  printf '== 章节锚点覆盖（底册 %s 条锚点；状态由机器判定，三判定权在质检/经理）==\n' "$ANCH_N"
  awk -v anch="$ANCH" '
    function sec_status(num,  a, cov, part) {
      cov=0; part=0
      while ((getline a < anch) > 0) {
        if (a==num) cov++
        else if (index(a, num ".")==1 || index(num, a ".")==1) part++
      }
      close(anch)
      if (cov>0) return "已建锚"
      if (part>0) return "部分覆盖(仅子节/父节有锚,人工复核)"
      return "疑似缺锚候选"
    }
    /^[[:space:]]*#{1,6}[[:space:]]/ {
      line=$0; num=""
      if (match(line, /[0-9]+(\.[0-9]+)*/)) num=substr(line, RSTART, RLENGTH)
      sub(/^[[:space:]]*#+[[:space:]]*/, "", line)
      if (num=="") { printf "L%-5d [无编号,人工判定] %s\n", NR, line; next }
      printf "L%-5d [%s] %s\n", NR, sec_status(num), line
    }
  ' "$SNAP"
  printf '\n== 功能名命中行（检索词: %s；按章节聚合判定，最多显示 40 行）==\n' "$FEAT"
  if [ -n "$FEAT" ]; then
    grep -nF -- "$FEAT" "$SNAP" | head -40 || printf '(无命中)\n'
  fi
  printf '\n后续: 仅对「疑似缺锚候选/无编号/部分覆盖」行做三判定(已建锚/疑似缺锚/范围外)，写入报告附录。\n'
  exit 0
}

# ---- find：按关键词在快照中定位原文行（行号 + 原文，供逐字节抄写）----
find_lines() {
  KW="$EXTRA"
  [ -z "$KW" ] && { printf '用法: bash validate-prd.sh "<功能目录>" find "<关键词>"\n' >&2; exit 2; }
  SNAP="$DIR/prd.txt"
  [ -f "$SNAP" ] || { printf '[FAIL] 缺少 %s(PRD 文本快照)\n' "$SNAP" >&2; exit 1; }
  printf '== 快照命中行（行号:原文，逐字符复制到 scope.md 摘录列）==\n'
  OUT=$(grep -nF -- "$KW" "$SNAP" | head -60)
  if [ -z "$OUT" ]; then
    printf '[FAIL] 关键词未命中快照: %s\n' "$KW"
    printf '提示: 关键词必须取自 PRD 快照原文用词（禁止凭印象改写用词）；换用快照里真实出现的词再试，或改用 line <行号> / scan 模式。\n'
    exit 1
  fi
  printf '%s\n' "$OUT"
  exit 0
}

# ---- line：输出快照指定行的完整原文（含 markdown 标记/列表符号/表格竖线）----
line_out() {
  N="$EXTRA"
  M="$EXTRA2"
  SNAP="$DIR/prd.txt"
  [ -f "$SNAP" ] || { printf '[FAIL] 缺少 %s(PRD 文本快照)\n' "$SNAP" >&2; exit 1; }
  # 区间：优先第 4 参数，其次 <起始>-<结束> 形式（先拆区间，再校验纯数字）
  if [ -z "$M" ]; then
    case "$N" in
      *-*)
        S=${N%%-*}; E=${N##*-}
        case "$S$E" in ''|*[!0-9]*) printf '[FAIL] 行区间格式非法: %s（应为 <起始>-<结束>）\n' "$N" >&2; exit 2 ;; esac
        M="$E"; N="$S" ;;
    esac
  fi
  case "$N" in ''|*[!0-9]*) printf '用法: bash validate-prd.sh "<功能目录>" line <行号> | line <起始> <结束> | line <起始>-<结束> | cat\n' >&2; exit 2 ;; esac
  if [ -n "$M" ]; then
    case "$M" in ''|*[!0-9]*) printf '用法: bash validate-prd.sh "<功能目录>" line <起始> <结束>\n' >&2; exit 2 ;; esac
    OUT=$(awk -v s="$N" -v e="$M" 'NR>=s && NR<=e { printf "%d:%s\n", NR, $0 }' "$SNAP")
    if [ -z "$OUT" ]; then printf '[FAIL] 快照无第 %s~%s 行\n' "$N" "$M" >&2; exit 1; fi
    printf '== 快照第 %s~%s 行（行号:原文）==\n' "$N" "$M"
    printf '%s\n' "$OUT"
    exit 0
  fi
  OUT=$(awk -v n="$N" 'NR==n { print; exit }' "$SNAP")
  if [ -z "$OUT" ]; then printf '[FAIL] 快照无第 %s 行\n' "$N" >&2; exit 1; fi
  printf '%s\n' "$OUT"
  exit 0
}

# ---- cat：输出快照全文（带行号），供一次性通读；禁止用 line 逐行翻页代替 ----
cat_out() {
  SNAP="$DIR/prd.txt"
  [ -f "$SNAP" ] || { printf '[FAIL] 缺少 %s(PRD 文本快照)\n' "$SNAP" >&2; exit 1; }
  printf '== 快照全文（行号:原文，共 %s 行）==\n' "$(awk 'END{print NR}' "$SNAP")"
  awk '{ printf "%d:%s\n", NR, $0 }' "$SNAP"
  exit 0
}

case "$TARGET" in
  scope)    check_anchors; check_anchor_source; check_snapshot ;;
  pull)     pull_excerpt ;;
  snapshot) make_snapshot ;;
  scan)     run_scan ;;
  find)     find_lines ;;
  line)     line_out ;;
  cat)      cat_out ;;
  *)        printf '未知模式: %s\n' "$TARGET" >&2; exit 2 ;;
esac

printf '\n========== 校验汇总: PASS=%d FAIL=%d ==========\n' "$PASSES" "$FAILS"
if [ "$FAILS" -eq 0 ]; then exit 0; else exit 1; fi
