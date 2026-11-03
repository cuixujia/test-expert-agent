#!/usr/bin/env bash
# validate.sh — 产出与状态侧硬校验（零依赖，bash 3.2 兼容）
# 归属: self-review-checklist（规则唯一权威源见 SKILL.md）
# 结构: <会话目录>/<uuid>/ + <功能目录>/output/test-point|test-case/
# 用法: bash validate.sh "<会话目录>" test-point|test-case   （阶段质检，禁止传 all）
#       all 仅限人工调试: bash validate.sh "<会话目录>" all
#   state:    bash validate.sh "<会话目录>/state.md" state    # state.md 登记项固定唯一/确认记录格式/澄清登记 CL 编号唯一/指纹格式
#   hash:     bash validate.sh "<会话目录>" hash test-point|test-case   # 输出产物 SHA-256（收回核验用，免单独调 sha256sum）
# 需求与证据侧校验（快照/底册/漏锚扫描）用 prd-quality-check/validate-prd.sh，本脚本不依赖它
# 退出码: 0 = 全部通过; 1 = 存在 FAIL, 必须修复后重跑; 2 = 用法错误
# 功能码: TP/TC 编号功能码直接取平台 bizFunctionId(不注册清单文件), 编号格式为 TP-<功能码>-NNN / TC-<功能码>-NNN
#        逐行校验编号功能码段必须等于所在功能目录名(防跨功能串号)
# 锚点语法契约: 唯一定义源为 prd-quality-check 锚点规则 1，本脚本的 awk 正则为其实现，两处必须同步修改
# 依据列契约: TP 依据列 = 锚点（多个用、连接）；摘录原文 —— 脚本只在分号前提取锚点，摘录段不参与锚点扫描（格式定义见 test-point-spec 字段规范）
set -u

ARG=${1:-}
TARGET=${2:-}
EXTRA=${3:-}
FAILS=0
PASSES=0

fail() { FAILS=$((FAILS+1)); printf '[FAIL] %s\n' "$*"; }
pass() { PASSES=$((PASSES+1)); printf '[PASS] %s\n' "$*"; }

if [ -z "$ARG" ]; then
  printf '用法: bash validate.sh "<会话目录>" test-point|test-case（阶段质检；禁止传 all）\n'
  printf '辅助: state（状态校验，传 state.md）/ hash test-point|test-case（产物 SHA-256）；需求与证据侧校验用 prd-quality-check/validate-prd.sh\n'
  exit 2
fi

if [ -f "$ARG" ]; then
  DIR=$(dirname "$ARG")
  case "$(basename "$ARG")" in
    state.md)      case "$TARGET" in ""|state) TARGET=state ;; *) printf '用法: state.md 仅支持 state\n'; exit 2 ;; esac ;;
    *) printf '用法: 阶段质检请传会话目录+模式: bash validate.sh "<会话目录>" test-point|test-case（产物在功能目录 output/ 下，不再按文件直传）\n'; exit 2 ;;
  esac
elif [ -d "$ARG" ]; then
  DIR=${ARG%/}
  case "$TARGET" in
    test-point|test-case|all|hash) : ;;
    *) printf '用法: 传目录须带模式: test-point / test-case（阶段质检）、hash test-point|test-case（产物 SHA-256）、all（仅人工调试）\n'; exit 2 ;;
  esac
else
  printf '用法: bash validate.sh "<会话目录>" test-point|test-case；辅助模式见脚本头注释\n'
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
check_points() {
  if [ ! -f "$P_FILE" ]; then fail "缺少 $P_FILE"; return; fi
  OUT=$(awk -F'|' -v tpanch="$TPANCH" -v tppairs="$TPPAIRS" -v fid="$FNID" '
    /^## / { stop=1 }
    stop { next }
    /^[[:space:]]*\|/ {
      n=0; delete f
      for (i=2; i<NF; i++) {
        v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (v ~ /^[-:]+$/) { n=-99; break }
        n++; if (n==1 && v=="编号") { n=-99; break }
        f[n]=v
      }
      if (n==-99) next
      id=f[1]; row++
      if (id !~ /^TP-[A-Za-z0-9_-]{1,20}-[0-9]{3,}$/) {
        printf "[FAIL] test-point 第%d数据行: TP编号格式非法: %s\n", row, id; bad++
      } else if (id !~ ("^TP-" fid "-[0-9]{3,}$")) {
        printf "[FAIL] test-point 第%d数据行: TP功能码与功能目录名不符: %s(本功能 %s)\n", row, id, fid; bad++
      } else if (seen[id]++) {
        printf "[FAIL] test-point 第%d数据行: TP编号重复: %s\n", row, id; bad++
      }
      if (f[2]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 验证意图为空\n", row, id; bad++ }
      else if (f[2] !~ /^验证/) { printf "[FAIL] test-point 第%d数据行(%s): 验证意图未以「验证」开头: %s\n", row, id, f[2]; bad++ }
      if (f[3]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 类型为空\n", row, id; bad++ }
      if (f[4]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 分析方法为空\n", row, id; bad++ }
      if (f[5]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 依据为空\n", row, id; bad++ }
      else {
        # 依据列契约: 锚点（多个用、连接）；摘录原文 —— 只在第一个分号前提取锚点，摘录段不扫描（防摘录内编号误判为锚点）
        idx = index(f[5], "；"); if (idx == 0) idx = index(f[5], ";")
        if (idx == 0) {
          printf "[FAIL] test-point 第%d数据行(%s): 依据缺「；摘录」段(格式: 锚点；摘录, 多个锚点用、连接)\n", row, id; bad++
        } else {
          s = substr(f[5], 1, idx - 1)
          gsub(/【[^】]*】/, "", s)
          gsub(/TP-[A-Za-z0-9-]+/, "", s); gsub(/TC-[A-Za-z0-9-]+/, "", s); gsub(/CL-[0-9]+/, "", s); gsub(/(^|[^-A-Za-z0-9])Q[0-9]+/, "\\1", s)   # 去非锚点编号 token，防误提取
          found=0
          while (match(s, /[A-Za-z0-9]+(-[A-Za-z0-9.]+)+|[A-Za-z][A-Za-z0-9]*[0-9][A-Za-z0-9]*|[0-9]+(\.[0-9]+)+/)) {
            a=substr(s, RSTART, RLENGTH)
            print a > tpanch
            print id "\t" a > tppairs
            found=1
            s=substr(s, RSTART+RLENGTH)
          }
          if (!found) { printf "[FAIL] test-point 第%d数据行(%s): 分号前锚点段缺锚点(依据须以锚点开头, 摘录放分号后)\n", row, id; bad++ }
        }
      }
    }
    END { if (row==0) { print "[FAIL] test-point 无有效数据行"; bad++ }; exit (bad ? 1 : 0) }
   ' "$P_FILE"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))
  [ "$RC" -eq 0 ] && pass "test-point 编号格式/唯一性/命名/必填字段/锚点校验通过"

  if grep -q "覆盖对照表" "$P_FILE"; then
    pass "test-point 存在覆盖对照表"
    if grep "未覆盖" "$P_FILE" | grep -qvE "原因|暂不|不测|不可解析|范围外|N/A"; then
      fail "test-point 覆盖对照表: 存在未覆盖项疑似未声明原因"
    else
      pass "test-point 未覆盖项原因声明检查通过"
    fi
  else
    fail "test-point 缺少覆盖对照表章节"
  fi
}

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
      $0 !~ /^[A-Za-z0-9]+(\.[0-9]+)*(-[A-Za-z0-9]+(\.[0-9]+)*)*$/ || $0 !~ /[0-9]/ { printf "%s ", $0; bad++ }
      END { exit (bad ? 1 : 0) }
    ' "$ANCH")
    if [ -n "$BADANC" ]; then
      fail "底册锚点格式不合规(须符合 prd-quality-check 锚点规则 1 的锚点语法：字母/数字/小数点组成 1~4 段、段间连字符、整串含数字): $BADANC"
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


# ---- state.md 校验（登记项固定词汇表/key 唯一/确认记录格式/CL 编号唯一/指纹格式）----
check_state() {
  ST="$ARG"
  if [ ! -f "$ST" ]; then fail "缺少 $ST(state.md)"; return; fi
  OUT=$(awk -F'|' '
    function trim(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s);return s}
    /^##[[:space:]]*流转记录/ { in_flow=1; next }   # 流转记录表不是登记项，整表跳过
    in_flow && /^[[:space:]]*\|/ { next }
    /^[[:space:]]*\|/ {
      k=""; val=""; n=0
      for(i=2;i<NF;i++){v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); n++; if(n==1)k=v; else val=val v}
      if(k=="项" && val=="内容") next
      if(k ~ /^[-:]+$/) next
      keys[++c]=k; vals[c]=val
    }
    END{
      nv=split("产物条目数|PRD 指纹|派发会话|质检轮次|S6 缺口登记|确认记录|澄清登记|挂起/降级|变更登记", vocab, "|")
      for(i=1;i<=c;i++){
        ok=0
        if(keys[i]=="当前阶段" || keys[i]=="当前状态") ok=1
        for(j=1;j<=nv;j++) if(keys[i]==vocab[j]) ok=1
        if(!ok){ printf "[FAIL] state 第%d行: 登记项不在固定词汇表: %s\n", i, keys[i]; bad++ }
        for(j=i+1;j<=c;j++) if(keys[i]==keys[j]){ printf "[FAIL] state: 登记项重复: %s\n", keys[i]; bad++ }
      }
      for(j=1;j<=nv;j++){
        found=0
        for(i=1;i<=c;i++) if(keys[i]==vocab[j]) found=1
        if(!found){ printf "[FAIL] state: 缺少固定登记项: %s\n", vocab[j]; bad++ }
      }
      # 当前阶段/当前状态 二选一（兼容两种命名，不得同时出现）
      n_cur=0
      for(i=1;i<=c;i++) if(keys[i]=="当前阶段" || keys[i]=="当前状态") n_cur++
      if(n_cur==0){ printf "[FAIL] state: 缺少固定登记项: 当前阶段\n"; bad++ }
      else if(n_cur>1){ printf "[FAIL] state: 当前阶段与当前状态只能保留其一\n"; bad++ }
      exit (bad?1:0)
    }' "$ST"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))
  [ "$RC" -eq 0 ] && pass "state 登记表结构校验通过（登记项固定且唯一）"

  # 确认记录格式（「待确认」占位放行；每段须为 S<编号>：<裁决>（<日期>…，以；分隔）
  CONF=$(awk -F'|' '
    function trim(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s);return s}
    /^[[:space:]]*\|/ {
      k=""; val=""; n=0
      for(i=2;i<NF;i++){v=trim($i); n++; if(n==1)k=v; else val=val v}
      if(k=="确认记录"){ print val; exit }
    }' "$ST")
  if [ -z "$CONF" ]; then
    fail "state: 缺少确认记录登记项"
  elif printf '%s' "$CONF" | grep -q "待确认"; then
    pass "state 确认记录: 尚无确认（待确认占位放行）"
  else
    BADCONF=$(printf '%s' "$CONF" | awk '{ gsub(/；/, "\n"); print }' | awk '
      function trim(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s);return s}
      { seg=trim($0)
        if(seg=="") next
        # 每段须为 S<编号>：<裁决>（<日期>…；BSD 正则 [0-9+] 类不匹配字面 + 号，故用 substr/index/match 组合
        if(substr(seg,1,1)!="S" || index(seg,"：")==0 || match(seg, /（[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)==0) print seg }')
    if [ -n "$BADCONF" ]; then
      fail "state 确认记录格式不合规（须为 S<编号>：<裁决>（<日期>…，以；分隔）: $BADCONF"
    else
      pass "state 确认记录格式校验通过"
    fi
  fi

  # 澄清登记 CL 编号唯一（只查「澄清登记」登记项；其他字段引用 CL 编号不参与判重）
  CLV=$(awk -F'|' '
    function trim(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s);return s}
    /^[[:space:]]*\|/ {
      k=""; val=""; n=0
      for(i=2;i<NF;i++){v=trim($i); n++; if(n==1)k=v; else val=val v}
      if(k=="澄清登记"){ print val; exit }
    }' "$ST")
  DUPCL=$(printf '%s' "$CLV" | grep -o 'CL-[0-9]\+' | sort | uniq -d | tr '\n' ' ')
  if [ -n "$DUPCL" ]; then fail "state 澄清登记 CL 编号重复: $DUPCL"; else pass "state 澄清登记 CL 编号唯一性通过"; fi

  # PRD 指纹行格式
  FP=$(awk -F'|' '
    function trim(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s);return s}
    /^[[:space:]]*\|/ {
      k=""; val=""; n=0
      for(i=2;i<NF;i++){v=trim($i); n++; if(n==1)k=v; else val=val v}
      if(k=="PRD 指纹"){ print val; exit }
    }' "$ST")
  if [ -z "$FP" ]; then
    fail "state: 缺少 PRD 指纹登记项"
  elif printf '%s' "$FP" | grep -qE 'md5=[0-9a-f]{32}'; then
    pass "state PRD 指纹格式校验通过"
  else
    fail "state PRD 指纹行须含 md5=<32位十六进制>"
  fi
}
extract_tpids() {
  [ -f "$P_FILE" ] || return 0
  awk -F'|' -v tpids="$TPIDS" '
    /^## / { stop=1 }
    stop { next }
    /^[[:space:]]*\|/ {
      n=0; delete f
      for (i=2; i<NF; i++) {
        v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (v ~ /^[-:]+$/) { n=-99; break }
        n++; if (n==1 && v=="编号") { n=-99; break }
        f[n]=v
      }
      if (n==-99) next
      id=f[1]
      if (id ~ /^TP-[A-Za-z0-9_-]{1,20}-[0-9]{3,}$/ && !seen[id]++) print id > tpids
    }
  ' "$P_FILE" >/dev/null
}

# ---- test-case.md 行内校验（格式/唯一/必填/优先级/引用）----
check_cases() {
  if [ ! -f "$C_FILE" ]; then fail "缺少 $C_FILE"; return; fi
  OUT=$(awk -F'|' -v tctps="$TCTPS" -v fid="$FNID" '
    /^## / { stop=1 }
    stop { next }
    /^[[:space:]]*\|/ {
      n=0; delete f
      for (i=2; i<NF; i++) {
        v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (v ~ /^[-:]+$/) { n=-99; break }
        n++; if (n==1 && v=="编号") { n=-99; break }
        f[n]=v
      }
      if (n==-99) next
      id=f[1]; row++
      if (id !~ /^TC-[A-Za-z0-9_-]{1,20}-[0-9]{3,}$/) {
        printf "[FAIL] test-case 第%d数据行: TC编号格式非法: %s\n", row, id; bad++
      } else if (id !~ ("^TC-" fid "-[0-9]{3,}$")) {
        printf "[FAIL] test-case 第%d数据行: TC功能码与功能目录名不符: %s(本功能 %s)\n", row, id, fid; bad++
      } else if (seen[id]++) {
        printf "[FAIL] test-case 第%d数据行: TC编号重复: %s\n", row, id; bad++
      }
      if (f[2]=="") { printf "[FAIL] test-case 第%d数据行(%s): 标题为空\n", row, id; bad++ }
      if (f[3]=="") { printf "[FAIL] test-case 第%d数据行(%s): 关联TP为空\n", row, id; bad++ }
      else if (f[3] ~ /^TP-[A-Za-z0-9_-]{1,20}-[0-9]{3,}$/) { print f[3] > tctps }
      else { printf "[FAIL] test-case 第%d数据行(%s): 关联TP格式非法: %s\n", row, id, f[3]; bad++ }
      if (f[4] !~ /^P[0-3]$/) { printf "[FAIL] test-case 第%d数据行(%s): 优先级非法或为空: %s\n", row, id, f[4]; bad++ }
      if (f[5]=="") { printf "[FAIL] test-case 第%d数据行(%s): 前置条件为空\n", row, id; bad++ }
      if (f[6]=="") { printf "[FAIL] test-case 第%d数据行(%s): 测试数据为空\n", row, id; bad++ }
      if (f[7]=="") { printf "[FAIL] test-case 第%d数据行(%s): 操作步骤为空\n", row, id; bad++ }
      if (f[8]=="") { printf "[FAIL] test-case 第%d数据行(%s): 预期结果为空\n", row, id; bad++ }
      if (f[9]=="") { printf "[FAIL] test-case 第%d数据行(%s): 用例类型为空\n", row, id; bad++ }
    }
    END { if (row==0) { print "[FAIL] test-case 无有效数据行"; bad++ }; exit (bad ? 1 : 0) }
  ' "$C_FILE"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))
  [ "$RC" -eq 0 ] && pass "test-case 编号格式/唯一性/必填字段/优先级校验通过"

  if [ -s "$TPIDS" ]; then
    BADREF=$(comm -23 <(sort -u "$TCTPS") <(sort -u "$TPIDS") | tr '\n' ' ')
    if [ -n "${BADREF//[[:space:]]/}" ]; then
      fail "以下 TC 关联的 TP 不存在于 test-point.md: $BADREF"
    else
      pass "TC→TP 引用完整性校验通过"
    fi
    # TP 全覆盖豁免: test-case.md 覆盖对照表显式声明未覆盖原因(非空且非「—」占位)的 TP 不计 FAIL(规则见本 skill 核验清单)
    EXEMPT=$(awk -F'|' '
      /^## / { in_sec = (index($0, "覆盖对照表") > 0) }
      in_sec && /^[[:space:]]*\|/ {
        n=0; tp=""; exc=""
        for (i=2; i<NF; i++) {
          v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
          if (v ~ /^[-:]+$/) { n=-99; break }
          n++
          if (n==1) tp=v; else if (n==3) exc=v
        }
        if (n!=-99 && tp ~ /^TP-[A-Za-z0-9_-]{1,20}-[0-9]{3,}$/ && exc!="" && exc !~ /^(—|-)$/) print tp
      }
    ' "$C_FILE" | sort -u)
    UNCOVERED_RAW=$(comm -23 <(sort -u "$TPIDS") <(sort -u "$TCTPS") | tr '\n' ' ')
    UNCOVERED=$(printf '%s\n' $UNCOVERED_RAW | grep -v '^$' | comm -23 - <(printf '%s\n' "$EXEMPT" | grep -v '^$' | sort -u) | tr '\n' ' ')
    EXEMPTED=$(printf '%s\n' $UNCOVERED_RAW | grep -v '^$' | sort -u | comm -12 - <(printf '%s\n' "$EXEMPT" | grep -v '^$' | sort -u) | tr '\n' ' ')
    if [ -n "${UNCOVERED//[[:space:]]/}" ]; then
      fail "以下 TP 未被任何 TC 覆盖且未声明未覆盖原因: $UNCOVERED"
    elif [ -n "${EXEMPTED//[[:space:]]/}" ]; then
      pass "TP 全覆盖校验通过(未覆盖 TP 已显式声明原因: $EXEMPTED)"
    else
      pass "TP 全覆盖校验通过"
    fi
  else
    fail "TP 清单为空(test-point.md 无合法编号), TC→TP 引用校验跳过"
  fi

  if grep -q "覆盖对照表" "$C_FILE"; then
    pass "test-case 存在覆盖对照表"
  else
    fail "test-case 缺少覆盖对照表章节"
  fi
}

# ---- hash：输出产物文件 SHA-256（收回核验统一入口，免单独调 sha256sum）----
hash_files() {
  case "$EXTRA" in
    test-point) F="$P_FILE" ;;
    test-case)  F="$C_FILE" ;;
    *) printf '用法: bash validate.sh "<会话目录>" hash test-point|test-case\n' >&2; exit 2 ;;
  esac
  if [ -f "$F" ]; then sha256sum "$F"; else printf '[FAIL] 文件不存在: %s\n' "$F" >&2; exit 1; fi
}

case "$TARGET" in
  test-point)    check_points; check_anchors ;;
  test-case)     extract_tpids; check_cases ;;
  state)         check_state ;;
  hash)          hash_files ;;
  *)             check_points; check_anchors; extract_tpids; check_cases ;;
esac

printf '\n========== 校验汇总: PASS=%d FAIL=%d ==========\n' "$PASSES" "$FAILS"
if [ "$FAILS" -eq 0 ]; then exit 0; else exit 1; fi

