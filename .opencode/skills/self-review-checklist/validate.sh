#!/usr/bin/env bash
# validate.sh — qa-workspace 测试设计产物硬校验（零依赖，bash 3.2 兼容）
# 用法: bash validate.sh <功能目录> [01-scope.md|03-test-points.md|05-test-cases.md|all]
# 退出码: 0 = 全部通过; 1 = 存在 FAIL, 必须修复后重跑; 2 = 用法错误
# 摘录逐字机验依赖 00-input/prd.txt(PRD 文本快照, 生成规则见 prd-quality-check 锚点规则 9)
# 注意: macOS awk length() 按字节计数, 摘录长度校验用 wc -m
set -u

DIR=${1:-}
TARGET=${2:-all}
FAILS=0
PASSES=0

fail() { FAILS=$((FAILS+1)); printf '[FAIL] %s\n' "$*"; }
pass() { PASSES=$((PASSES+1)); printf '[PASS] %s\n' "$*"; }

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  printf '用法: bash validate.sh <功能目录> [03-test-points.md|05-test-cases.md|all]\n'
  exit 2
fi

DIR=${DIR%/}
S_FILE="$DIR/01-scope.md"
P_FILE="$DIR/03-test-points.md"
C_FILE="$DIR/05-test-cases.md"

TMPD=$(mktemp -d) || exit 2
TPIDS="$TMPD/tp_ids"    # 03 中全部合法 TP 编号（每行一个）
TCTPS="$TMPD/tc_tps"   # 05 中全部合法关联 TP（每行一个）
TPANCH="$TMPD/tp_anchors"  # 03 主表依据列提取的锚点（每行一个）
: > "$TPIDS"; : > "$TCTPS"; : > "$TPANCH"
trap 'rm -rf "$TMPD"' EXIT

# ---- 01-scope.md 功能清单结构校验（名称原文/编号/功能码）----
check_scope() {
  if [ ! -f "$S_FILE" ]; then fail "缺少 $S_FILE"; return; fi
  OUT=$(awk -F'|' '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^[[:space:]]*\|/ && !done {
      if (!hdr) {
        if ($0 ~ /模块名称/ && $0 ~ /功能名称/ && $0 ~ /功能码/) {
          n=0; delete col
          for (i=2; i<NF; i++) {
            v=trim($i)
            if (v ~ /^[-:]+$/) continue
            n++
            if (index(v,"模块名称")==1)      col["mname"]=n
            else if (index(v,"功能名称")==1) col["fname"]=n
            else if (index(v,"功能码")==1)   col["code"]=n
            else if (index(v,"模块编号")==1) col["mno"]=n
            else if (index(v,"功能编号")==1) col["fno"]=n
          }
          if (("mname" in col) && ("fname" in col) && ("code" in col)) { hdr=1; next }
        }
        next
      }
      n=0; delete f
      for (i=2; i<NF; i++) {
        v=trim($i)
        if (v ~ /^[-:]+$/) { n=-99; break }
        n++; if (n==1 && v=="模块编号") { n=-99; break }
        f[n]=v
      }
      if (n==-99) next
      row++
      if (f[col["mname"]]=="") { printf "[FAIL] 01 功能清单第%d数据行: 模块名称为空\n", row; bad++ }
      if (f[col["fname"]]=="") { printf "[FAIL] 01 功能清单第%d数据行: 功能名称为空\n", row; bad++ }
      c=f[col["code"]]
      if (c=="") { printf "[FAIL] 01 功能清单第%d数据行: 功能码为空\n", row; bad++ }
      else if (c !~ /^[A-Za-z0-9]{1,6}$/) { printf "[FAIL] 01 功能清单第%d数据行: 功能码格式非法: %s\n", row, c; bad++ }
      else if (seen[c]++) { printf "[FAIL] 01 功能清单第%d数据行: 功能码重复: %s\n", row, c; bad++ }
      if ("mno" in col) {
        m=f[col["mno"]]
        if (m !~ /^M[0-9]{1,3}$/) { printf "[FAIL] 01 功能清单第%d数据行: 模块编号格式非法: %s\n", row, m; bad++ }
      }
      if ("fno" in col) {
        fn=f[col["fno"]]
        if (fn !~ /^[A-Za-z]{1,4}-?[0-9]{1,4}$/) { printf "[FAIL] 01 功能清单第%d数据行: 功能编号格式非法: %s\n", row, fn; bad++ }
      }
      next
    }
    !/^[[:space:]]*\|/ && hdr && !done { done=1 }
    END {
      if (!hdr) { print "[FAIL] 01 缺少功能清单表(需含模块名称/功能名称/功能码列)"; bad++ }
      else if (row==0) { print "[FAIL] 01 功能清单无数据行"; bad++ }
      exit (bad ? 1 : 0)
    }
  ' "$S_FILE"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))
  [ "$RC" -eq 0 ] && pass "01 功能清单结构校验通过"
}

# ---- 03-test-points.md 行内校验（格式/唯一/必填/锚点）----
check_points() {
  if [ ! -f "$P_FILE" ]; then fail "缺少 $P_FILE"; return; fi
  OUT=$(awk -F'|' -v tpanch="$TPANCH" '
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
      if (id !~ /^TP-[A-Za-z0-9]{1,6}-[0-9]{3,}$/) {
        printf "[FAIL] 03 第%d数据行: TP编号格式非法: %s\n", row, id; bad++
      } else if (seen[id]++) {
        printf "[FAIL] 03 第%d数据行: TP编号重复: %s\n", row, id; bad++
      }
      if (f[2]=="")   { printf "[FAIL] 03 第%d数据行(%s): 验证意图为空\n", row, id; bad++ }
      else if (f[2] !~ /^验证/) { printf "[FAIL] 03 第%d数据行(%s): 验证意图未以「验证」开头: %s\n", row, id, f[2]; bad++ }
      if (f[3]=="")   { printf "[FAIL] 03 第%d数据行(%s): 类型为空\n", row, id; bad++ }
      if (f[4]=="")   { printf "[FAIL] 03 第%d数据行(%s): 分析方法为空\n", row, id; bad++ }
      if (f[5]=="")   { printf "[FAIL] 03 第%d数据行(%s): 依据为空\n", row, id; bad++ }
      else if (match(f[5], /(M[0-9]+-S[0-9]+-P[0-9]+)|([A-Za-z]{2,5}(-[A-Za-z]{2,5})?-[0-9]{1,5})|([0-9]+(\.[0-9]+)+)/)) {
        print substr(f[5], RSTART, RLENGTH) > tpanch
      } else {
        printf "[FAIL] 03 第%d数据行(%s): 依据缺锚点(需 M模块-S章节-P段落 或 PRD原文编号)\n", row, id; bad++
      }
    }
    END { if (row==0) { print "[FAIL] 03 无有效数据行"; bad++ }; exit (bad ? 1 : 0) }
  ' "$P_FILE"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))
  [ "$RC" -eq 0 ] && pass "03 编号格式/唯一性/命名/必填字段/锚点校验通过"

  if grep -q "覆盖对照表" "$P_FILE"; then
    pass "03 存在覆盖对照表"
    if grep "未覆盖" "$P_FILE" | grep -qvE "原因|暂不|不测|不可解析|范围外|N/A"; then
      fail "03 覆盖对照表: 存在未覆盖项疑似未声明原因"
    else
      pass "03 未覆盖项原因声明检查通过"
    fi
  else
    fail "03 缺少覆盖对照表章节"
  fi
}

# ---- 锚点底册一致性校验（01-scope.md 锚点清单 ↔ 03 依据/覆盖对照表）----
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
    fail "01-scope.md 缺少锚点清单表(或无有效锚点)"
  else
    pass "01-scope.md 锚点清单底册存在"
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
  fi
}

# ---- 摘录逐字机验（01 底册摘录 ↔ PRD 快照; TP 依据 ↔ 底册摘录）----
# 快照生成与降级规则见 prd-quality-check 锚点规则 9; 比对前做空白规范化(含全角空格)
# 已知坑: macOS awk 在 LC_ALL=UTF-8 下对纯中文串的 == 比较会误判真;
# 故本函数 awk 一律不设 LC_ALL(走 C locale 字节语义), 中文相等判断用正则, 字符计数只用 wc -m
check_snapshot() {
  [ -f "$S_FILE" ] || return
  if grep -q '^> 快照机验：跳过' "$S_FILE"; then
    pass "快照机验: 01 已声明降级, 跳过(规则见 prd-quality-check 锚点规则 9)"
    return
  fi
  SNAP="$DIR/00-input/prd.txt"
  if [ ! -f "$SNAP" ]; then
    fail "缺少 $SNAP(PRD 文本快照), 无法机验摘录(生成规则见 prd-quality-check 锚点规则 9)"
    return
  fi
  awk '{ gsub(/[[:space:]]/, ""); gsub(/　/, ""); printf "%s", $0 }' "$SNAP" > "$TMPD/snap_norm"

  # 提取 01 锚点清单 (锚点, 摘录) 对, 规范化后落临时文件; 锚点重复直接报 FAIL
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
      if (seen[a]++) { printf "[FAIL] 01 锚点清单: 锚点重复: %s\n", a; bad++; next }
      c=e; gsub(/[[:space:]]/, "", c); gsub(/　/, "", c)
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
      fail "01 锚点 $ANC: 摘录超 40 字(${LEN}字)"
      SNAP_OK=0
    fi
    if ! grep -qF -- "$EXC" "$TMPD/snap_norm"; then
      fail "01 锚点 $ANC: 摘录未逐字命中 PRD 快照"
      SNAP_OK=0
    fi
  done < "$TMPD/exc_pairs"
  if [ -s "$TMPD/exc_pairs" ] && [ "$SNAP_OK" -eq 1 ]; then
    pass "01 底册摘录逐字命中快照且长度合规"
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
        if (id !~ /^TP-[A-Za-z0-9]{1,6}-[0-9]{3,}$/) next
        if (match(dep, /(M[0-9]+-S[0-9]+-P[0-9]+)|([A-Za-z]{2,5}(-[A-Za-z]{2,5})?-[0-9]{1,5})|([0-9]+(\.[0-9]+)+)/)) {
          anc = substr(dep, RSTART, RLENGTH)
          if (anc in exc) {
            c = dep; gsub(/[[:space:]]/, "", c); gsub(/　/, "", c)
            if (index(c, exc[anc]) == 0)
              printf "[FAIL] 03 %s: 依据未含底册摘录(锚点 %s)\n", id, anc
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

# ---- 从 03 提取全部合法且唯一的 TP 编号（供引用校验）----
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
      if (id ~ /^TP-[A-Za-z0-9]{1,6}-[0-9]{3,}$/ && !seen[id]++) print id > tpids
    }
  ' "$P_FILE" >/dev/null
}

# ---- 05-test-cases.md 行内校验（格式/唯一/必填/优先级/引用）----
check_cases() {
  if [ ! -f "$C_FILE" ]; then fail "缺少 $C_FILE"; return; fi
  OUT=$(awk -F'|' -v tctps="$TCTPS" '
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
      if (id !~ /^TC-[A-Za-z0-9]{1,6}-[0-9]{3,}$/) {
        printf "[FAIL] 05 第%d数据行: TC编号格式非法: %s\n", row, id; bad++
      } else if (seen[id]++) {
        printf "[FAIL] 05 第%d数据行: TC编号重复: %s\n", row, id; bad++
      }
      if (f[2]=="") { printf "[FAIL] 05 第%d数据行(%s): 标题为空\n", row, id; bad++ }
      if (f[3]=="") { printf "[FAIL] 05 第%d数据行(%s): 关联TP为空\n", row, id; bad++ }
      else if (f[3] ~ /^TP-[A-Za-z0-9]{1,6}-[0-9]{3,}$/) { print f[3] > tctps }
      else { printf "[FAIL] 05 第%d数据行(%s): 关联TP格式非法: %s\n", row, id, f[3]; bad++ }
      if (f[4] !~ /^P[0-3]$/) { printf "[FAIL] 05 第%d数据行(%s): 优先级非法或为空: %s\n", row, id, f[4]; bad++ }
      if (f[5]=="") { printf "[FAIL] 05 第%d数据行(%s): 前置条件为空\n", row, id; bad++ }
      if (f[6]=="") { printf "[FAIL] 05 第%d数据行(%s): 测试数据为空\n", row, id; bad++ }
      if (f[7]=="") { printf "[FAIL] 05 第%d数据行(%s): 操作步骤为空\n", row, id; bad++ }
      if (f[8]=="") { printf "[FAIL] 05 第%d数据行(%s): 预期结果为空\n", row, id; bad++ }
      if (f[9]=="") { printf "[FAIL] 05 第%d数据行(%s): 用例类型为空\n", row, id; bad++ }
    }
    END { if (row==0) { print "[FAIL] 05 无有效数据行"; bad++ }; exit (bad ? 1 : 0) }
  ' "$C_FILE"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))
  [ "$RC" -eq 0 ] && pass "05 编号格式/唯一性/必填字段/优先级校验通过"

  if [ -s "$TPIDS" ]; then
    BADREF=$(comm -23 <(sort -u "$TCTPS") <(sort -u "$TPIDS") | tr '\n' ' ')
    if [ -n "${BADREF//[[:space:]]/}" ]; then
      fail "以下 TC 关联的 TP 不存在于 03-test-points.md: $BADREF"
    else
      pass "TC→TP 引用完整性校验通过"
    fi
    # TP 全覆盖豁免: 05 覆盖对照表显式声明未覆盖原因(非空且非「—」占位)的 TP 不计 FAIL(规则见 self-review-checklist)
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
        if (n!=-99 && tp ~ /^TP-[A-Za-z0-9]{1,6}-[0-9]{3,}$/ && exc!="" && exc !~ /^(—|-)$/) print tp
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
    fail "TP 清单为空(03 无合法编号), TC→TP 引用校验跳过"
  fi

  if grep -q "覆盖对照表" "$C_FILE"; then
    pass "05 存在覆盖对照表"
  else
    fail "05 缺少覆盖对照表章节"
  fi
}

case "$TARGET" in
  01-scope.md)        check_scope; check_snapshot ;;
  03-test-points.md) check_points; check_anchors; check_snapshot ;;
  05-test-cases.md)  extract_tpids; check_cases ;;
  *)                  check_scope; check_points; check_anchors; check_snapshot; extract_tpids; check_cases ;;
esac

printf '\n========== 校验汇总: PASS=%d FAIL=%d ==========\n' "$PASSES" "$FAILS"
if [ "$FAILS" -eq 0 ]; then exit 0; else exit 1; fi
