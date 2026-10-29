#!/usr/bin/env bash
# validate.sh — 测试设计产物硬校验（workspace 运行时结构，零依赖，bash 3.2 兼容）
# 用法: bash validate.sh "<会话目录>/test-point.md|test-case.md"   （阶段质检，禁止传 all）
#       all 仅限人工调试: bash validate.sh "<会话目录>" all
# 辅助模式（S1/编排用，摘录一律程序化提取，禁止模型手抄）:
#   scope:    bash validate.sh "<会话目录>/scope.md" scope         # 功能清单+锚点底册+摘录机验（S1 无 test-point 时）
#   state:    bash validate.sh "<会话目录>/state.md" state         # state.md 登记项固定唯一/确认记录格式/CL 编号唯一/指纹格式
#   pull:     bash validate.sh "<会话目录>/scope.md" pull "<锚点>"  # 输出该锚点底册摘录（先自验命中快照）
#   snapshot: bash validate.sh "<需求目录>" snapshot "<docx 文件名>" # 生成 prd.txt（textutil+引号归一）并输出源文件 md5
# 目录推导: 会话目录(session-log)内取 scope.md 锚点底册; 需求目录(上两级)取 functions.md 功能清单与 prd.txt 快照
# 退出码: 0 = 全部通过; 1 = 存在 FAIL, 必须修复后重跑; 2 = 用法错误
# 摘录逐字机验依赖 <prdId>/prd.txt(PRD 文本快照, 生成规则见 prd-quality-check 锚点规则 9)
# 注意: macOS awk length() 按字节计数, 摘录长度校验用 wc -m
set -u

ARG=${1:-}
TARGET=${2:-}
EXTRA=${3:-}
FAILS=0
PASSES=0

fail() { FAILS=$((FAILS+1)); printf '[FAIL] %s\n' "$*"; }
pass() { PASSES=$((PASSES+1)); printf '[PASS] %s\n' "$*"; }

if [ -z "$ARG" ]; then
  printf '用法: bash validate.sh "<会话目录>/test-point.md|test-case.md"（阶段质检禁止传 all；all 仅限人工调试，传会话目录）\n'
  printf '辅助: scope（底册校验）/ state（状态校验）/ pull <锚点>（提取摘录）/ snapshot <docx名>（生成快照）\n'
  exit 2
fi

if [ -f "$ARG" ]; then
  DIR=$(dirname "$ARG")
  case "$(basename "$ARG")" in
    test-point.md) TARGET=test-point.md ;;
    test-case.md)  TARGET=test-case.md ;;
    scope.md)      case "$TARGET" in ""|scope) TARGET=scope ;; pull) : ;; *) printf '用法: scope.md 仅支持 scope / pull\n'; exit 2 ;; esac ;;
    state.md)      case "$TARGET" in ""|state) TARGET=state ;; *) printf '用法: state.md 仅支持 state\n'; exit 2 ;; esac ;;
    *) printf '用法: 阶段校验仅支持 test-point.md / test-case.md / scope.md / state.md\n'; exit 2 ;;
  esac
elif [ -d "$ARG" ]; then
  DIR=${ARG%/}
  if [ "$TARGET" != "all" ] && [ "$TARGET" != "snapshot" ]; then
    printf '用法: 传目录仅限人工调试 all 或快照生成 snapshot\n'
    exit 2
  fi
else
  printf '用法: bash validate.sh "<会话目录>/test-point.md|test-case.md|scope.md|state.md"\n'
  exit 2
fi

S_FILE="$DIR/scope.md"
F_FILE="$DIR/../../functions.md"
P_FILE="$DIR/test-point.md"
C_FILE="$DIR/test-case.md"

TMPD=$(mktemp -d) || exit 2
TPIDS="$TMPD/tp_ids"    # test-point.md 中全部合法 TP 编号（每行一个）
TCTPS="$TMPD/tc_tps"   # test-case.md 中全部合法关联 TP（每行一个）
TPANCH="$TMPD/tp_anchors"  # test-point.md 主表依据列提取的锚点（每行一个）
: > "$TPIDS"; : > "$TCTPS"; : > "$TPANCH"
trap 'rm -rf "$TMPD"' EXIT

# ---- functions.md 功能清单结构校验（名称原文/编号/功能码，全局注册表）----
check_scope() {
  if [ ! -f "$F_FILE" ]; then fail "缺少 $F_FILE(功能清单注册表)"; return; fi
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
      if (f[col["mname"]]=="") { printf "[FAIL] functions 功能清单第%d数据行: 模块名称为空\n", row; bad++ }
      if (f[col["fname"]]=="") { printf "[FAIL] functions 功能清单第%d数据行: 功能名称为空\n", row; bad++ }
      c=f[col["code"]]
      if (c=="") { printf "[FAIL] functions 功能清单第%d数据行: 功能码为空\n", row; bad++ }
      else if (c !~ /^[A-Za-z0-9]{1,6}$/) { printf "[FAIL] functions 功能清单第%d数据行: 功能码格式非法: %s\n", row, c; bad++ }
      else if (seen[c]++) { printf "[FAIL] functions 功能清单第%d数据行: 功能码重复: %s\n", row, c; bad++ }
      if ("mno" in col) {
        m=f[col["mno"]]
        if (m !~ /^M[A-Za-z]{0,5}-?[0-9]{1,3}$/) { printf "[FAIL] functions 功能清单第%d数据行: 模块编号格式非法: %s\n", row, m; bad++ }
      }
      if ("fno" in col) {
        fn=f[col["fno"]]
        if (fn !~ /^[A-Za-z]{1,4}-?[0-9]{1,4}$/) { printf "[FAIL] functions 功能清单第%d数据行: 功能编号格式非法: %s\n", row, fn; bad++ }
      }
      next
    }
    !/^[[:space:]]*\|/ && hdr && !done { done=1 }
    END {
      if (!hdr) { print "[FAIL] functions 缺少功能清单表(需含模块名称/功能名称/功能码列)"; bad++ }
      else if (row==0) { print "[FAIL] functions 功能清单无数据行"; bad++ }
      exit (bad ? 1 : 0)
    }
  ' "$F_FILE"); RC=$?
  printf '%s\n' "$OUT"
  NF_=$(printf '%s\n' "$OUT" | grep -c '^\[FAIL\]')
  FAILS=$((FAILS + NF_))
  [ "$RC" -eq 0 ] && pass "functions 功能清单结构校验通过（功能码全局唯一）"
}

# ---- test-point.md 行内校验（格式/唯一/必填/锚点）----
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
        printf "[FAIL] test-point 第%d数据行: TP编号格式非法: %s\n", row, id; bad++
      } else if (seen[id]++) {
        printf "[FAIL] test-point 第%d数据行: TP编号重复: %s\n", row, id; bad++
      }
      if (f[2]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 验证意图为空\n", row, id; bad++ }
      else if (f[2] !~ /^验证/) { printf "[FAIL] test-point 第%d数据行(%s): 验证意图未以「验证」开头: %s\n", row, id, f[2]; bad++ }
      if (f[3]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 类型为空\n", row, id; bad++ }
      if (f[4]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 分析方法为空\n", row, id; bad++ }
      if (f[5]=="")   { printf "[FAIL] test-point 第%d数据行(%s): 依据为空\n", row, id; bad++ }
      else if (match(f[5], /(M[0-9]+-S[0-9]+-P[0-9]+)|([A-Za-z]{2,5}(-[A-Za-z]{2,5})?-[0-9]{1,5})|([0-9]+(\.[0-9]+)+)/)) {
        print substr(f[5], RSTART, RLENGTH) > tpanch
      } else {
        printf "[FAIL] test-point 第%d数据行(%s): 依据缺锚点(需 M模块-S章节-P段落 或 PRD原文编号)\n", row, id; bad++
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
    pass "快照机验: scope.md 已声明降级, 跳过(规则见 prd-quality-check 锚点规则 9)"
    return
  fi
  SNAP="$DIR/../../prd.txt"
  if [ ! -f "$SNAP" ]; then
    fail "缺少 $SNAP(PRD 文本快照), 无法机验摘录(生成规则见 prd-quality-check 锚点规则 9)"
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
      fail "scope 锚点 $ANC: 摘录未逐字命中 PRD 快照"
      SNAP_OK=0
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
        if (id !~ /^TP-[A-Za-z0-9]{1,6}-[0-9]{3,}$/) next
        if (match(dep, /(M[0-9]+-S[0-9]+-P[0-9]+)|([A-Za-z]{2,5}(-[A-Za-z]{2,5})?-[0-9]{1,5})|([0-9]+(\.[0-9]+)+)/)) {
          anc = substr(dep, RSTART, RLENGTH)
          if (anc in exc) {
            c = dep; gsub(/[[:space:]]/, "", c); gsub(/　/, "", c)
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

# ---- state.md 校验（登记项固定词汇表/key 唯一/确认记录格式/CL 编号唯一/指纹格式）----
check_state() {
  ST="$ARG"
  if [ ! -f "$ST" ]; then fail "缺少 $ST(state.md)"; return; fi
  OUT=$(awk -F'|' '
    function trim(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s);return s}
    /^[[:space:]]*\|/ {
      k=""; val=""; n=0
      for(i=2;i<NF;i++){v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); n++; if(n==1)k=v; else val=val v}
      if(k=="项" && val=="内容") next
      if(k ~ /^[-:]+$/) next
      keys[++c]=k; vals[c]=val
    }
    END{
      nv=split("当前状态|产物条目数|PRD 指纹|派发会话|质检轮次|S6 缺口登记|确认记录|挂起/降级|变更登记", vocab, "|")
      for(i=1;i<=c;i++){
        ok=0
        for(j=1;j<=nv;j++) if(keys[i]==vocab[j]) ok=1
        if(!ok){ printf "[FAIL] state 第%d行: 登记项不在固定词汇表: %s\n", i, keys[i]; bad++ }
        for(j=i+1;j<=c;j++) if(keys[i]==keys[j]){ printf "[FAIL] state: 登记项重复: %s\n", keys[i]; bad++ }
      }
      for(j=1;j<=nv;j++){
        found=0
        for(i=1;i<=c;i++) if(keys[i]==vocab[j]) found=1
        if(!found){ printf "[FAIL] state: 缺少固定登记项: %s\n", vocab[j]; bad++ }
      }
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

  # 澄清登记 CL 编号唯一
  DUPCL=$(grep -o 'CL-[0-9]\+' "$ST" | sort | uniq -d | tr '\n' ' ')
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

# ---- pull：按锚点提取底册摘录（自验命中快照后输出到 stdout，供程序化填充，禁止手抄）----
pull_excerpt() {
  ANC="$EXTRA"
  if [ -z "$ANC" ]; then printf '用法: bash validate.sh "<会话目录>/scope.md" pull "<锚点>"\n' >&2; exit 2; fi
  EXC=$(awk -F'|' -v a="$ANC" '
    /^## /{in_sec=(index($0,"锚点清单")>0)}
    in_sec && /^[[:space:]]*\|/ {
      n=0; id=""; e=""
      for(i=2;i<NF;i++){v=$i; gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); if(v ~ /^[-:]+$/){n=-99;break} n++; if(n==1)id=v; else if(n==3)e=v}
      if(n!=-99 && id==a && id!="锚点"){ print e; exit }
    }' "$S_FILE")
  if [ -z "$EXC" ]; then printf '[FAIL] 底册未找到锚点: %s\n' "$ANC" >&2; exit 1; fi
  SNAP="$DIR/../../prd.txt"
  if [ ! -f "$SNAP" ]; then printf '[FAIL] 缺少快照 %s\n' "$SNAP" >&2; exit 1; fi
  NEXC=$(printf '%s' "$EXC" | awk '{ gsub(/[[:space:]]/, ""); gsub(/　/, ""); printf "%s", $0 }')
  awk '{ gsub(/[[:space:]]/, ""); gsub(/　/, ""); printf "%s", $0 }' "$SNAP" > "$TMPD/snap_norm"
  if ! grep -qF -- "$NEXC" "$TMPD/snap_norm"; then printf '[FAIL] 摘录未逐字命中快照: %s\n' "$ANC" >&2; exit 1; fi
  printf '%s\n' "$EXC"
  exit 0
}

# ---- snapshot：生成 PRD 文本快照（textutil + 引号归一，输出源文件 md5；快照只读，已存在即拒绝）----
make_snapshot() {
  DOCX="$EXTRA"
  if [ -z "$DOCX" ]; then printf '用法: bash validate.sh "<需求目录>" snapshot "<需求文档文件名>"\n' >&2; exit 2; fi
  SRC="$ARG/$DOCX"
  if [ ! -f "$SRC" ]; then printf '找不到源文件: %s\n' "$SRC" >&2; exit 2; fi
  if [ -f "$ARG/prd.txt" ]; then printf 'prd.txt 已存在（快照只读，S1 冻结）；确认重建请先自行移除旧快照\n' >&2; exit 2; fi
  case "$DOCX" in
    *.docx|*.doc)
      if command -v textutil >/dev/null 2>&1; then
        textutil -convert txt -stdout "$SRC" | sed -e 's/“/"/g' -e 's/”/"/g' -e "s/‘/'/g" -e "s/’/'/g" > "$ARG/prd.txt"
      else
        printf 'textutil 不可用（仅 macOS）：请用 pandoc 转文本并自行归一引号后落盘（规则见 prd-quality-check 锚点规则 9）\n' >&2; exit 2
      fi ;;
    *.txt|*.md)
      sed -e 's/“/"/g' -e 's/”/"/g' -e "s/‘/'/g" -e "s/’/'/g" "$SRC" > "$ARG/prd.txt" ;;
    *)
      printf '不支持的快照源格式: %s（支持 docx/doc/txt/md；PDF/图片按锚点规则 9 降级声明）\n' "$DOCX" >&2; exit 2 ;;
  esac
  H=$(md5 -q "$SRC" 2>/dev/null || md5sum "$SRC" 2>/dev/null | cut -d' ' -f1)
  printf 'prd.txt 已生成: %s/prd.txt\n源文件 md5=%s\n' "$ARG" "$H"
  exit 0
}

# ---- 从 test-point.md 提取全部合法且唯一的 TP 编号（供引用校验）----
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

# ---- test-case.md 行内校验（格式/唯一/必填/优先级/引用）----
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
        printf "[FAIL] test-case 第%d数据行: TC编号格式非法: %s\n", row, id; bad++
      } else if (seen[id]++) {
        printf "[FAIL] test-case 第%d数据行: TC编号重复: %s\n", row, id; bad++
      }
      if (f[2]=="") { printf "[FAIL] test-case 第%d数据行(%s): 标题为空\n", row, id; bad++ }
      if (f[3]=="") { printf "[FAIL] test-case 第%d数据行(%s): 关联TP为空\n", row, id; bad++ }
      else if (f[3] ~ /^TP-[A-Za-z0-9]{1,6}-[0-9]{3,}$/) { print f[3] > tctps }
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
    # TP 全覆盖豁免: test-case.md 覆盖对照表显式声明未覆盖原因(非空且非「—」占位)的 TP 不计 FAIL(规则见 self-review-checklist)
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
    fail "TP 清单为空(test-point.md 无合法编号), TC→TP 引用校验跳过"
  fi

  if grep -q "覆盖对照表" "$C_FILE"; then
    pass "test-case 存在覆盖对照表"
  else
    fail "test-case 缺少覆盖对照表章节"
  fi
}

case "$TARGET" in
  test-point.md) check_scope; check_points; check_anchors; check_snapshot ;;
  test-case.md)  extract_tpids; check_cases ;;
  scope)         check_scope; check_snapshot ;;
  state)         check_state ;;
  pull)          pull_excerpt ;;
  snapshot)      make_snapshot ;;
  *)             check_scope; check_points; check_anchors; check_snapshot; extract_tpids; check_cases ;;
esac

printf '\n========== 校验汇总: PASS=%d FAIL=%d ==========\n' "$PASSES" "$FAILS"
if [ "$FAILS" -eq 0 ]; then exit 0; else exit 1; fi
