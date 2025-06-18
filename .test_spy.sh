#!/usr/bin/env bash
LOGFILE="/tmp/test_spy.log"

{
  echo "=== Shell Launch Trace: $(date) ==="
  echo "Shell type: $0"
  echo "Current options (\$-): $-"
  echo "Is interactive?      : [[ \$- == *i* ]] → $([[ $- == *i* ]] && echo yes || echo no)"
  echo "Is login shell?      : shopt -q login_shell → $(shopt -q login_shell && echo yes || echo no)"
  echo "PS1 set?             : [[ -n \"\$PS1\" ]] → $([[ -n "$PS1" ]] && echo yes || echo no)"
  echo "TERM_PROGRAM         : $TERM_PROGRAM"
  echo "Parent process       : $(ps -o ppid= -p $$ | xargs ps -o comm= -p)"
  echo "TTY                  : $(tty)"
  echo
} >> "$LOGFILE"
