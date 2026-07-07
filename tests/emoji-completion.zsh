#!/usr/bin/env zsh
# emoji-completion.zsh — proves tab completion works on emoji-bearing paths.
#
# Drives a REAL interactive Blossom zsh through a pty (zsh/zpty): keystrokes
# with literal <TAB> go in, the completed line is EXECUTED, and the resulting
# $PWD (or file contents) is asserted. No mocking of the shell itself — if
# these pass, the exact thing your fingers do works.
#
#   zsh tests/emoji-completion.zsh                 # both modes
#   zsh tests/emoji-completion.zsh . native        # native menuselect only
#   zsh tests/emoji-completion.zsh . fzftab        # fzf-tab pipeline only
#
#   native — `disable-fzf-tab` first: tests the compsys matcher tiers
#            (options.zsh), the zoxide completion wrapper (plugins.zsh), and
#            the wrapper that restores `menu select` for the native menu.
#   fzftab — the real fzf-tab pipeline, with fzf impersonated by a stub that
#            speaks its protocol (--print-query/--expect, candidates on
#            stdin) and picks the first candidate, so it runs headless.
#
# Design note: zsh-syntax-highlighting repaints the edit line char-by-char,
# each glyph wrapped in its own SGR sequence — so asserting on line *echo* is
# hopeless. Instead we rely on the pty input queue being ordered (TAB is
# fully processed before the CR queued behind it) and assert only on
# *executed output*, which prints plain.
zmodload zsh/zpty || { print -u2 "need zsh/zpty"; exit 2 }

APP=${1:-${0:A:h:h}}
[[ $APP == . ]] && APP=${0:A:h:h}
MODE=${2:-both}

if [[ $MODE == both ]]; then
  zsh "$0" "$APP" native && zsh "$0" "$APP" fzftab
  exit
fi

ZSHBIN=${ZSHBIN:-$(command -v zsh)}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/bs-emoji-test-XXXXXX")
FIX=$WORK/fixtures
ZD=$WORK/zdot
BIN=$WORK/bin
mkdir -p $FIX $ZD $BIN
typeset -g PTY=bs$$ PN=0

cleanup() { zpty -d $PTY 2>/dev/null; rm -rf $WORK }
trap cleanup EXIT
trap 'print -u2 "── TIMEOUT — last consumed pty output:"; tail -c 2000 $WORK/session.log 2>/dev/null | cat -v >&2; cleanup; exit 1' TERM INT

# ---------- fixtures: the emoji zoo ----------
mkdir -- $FIX/'📁 Documents' $FIX/'📁 Downloads' $FIX/'🎵 Music' \
         $FIX/'👨‍👩‍👧‍👦 family' $FIX/'🇺🇸 usa' $FIX/'❀ blossom' \
         $FIX/'Projects' $FIX/'photos-backup' $FIX/'🌸 photos'
mkdir -- $FIX/'📁 Documents/reports'
print "EMOJI_FILE_PAYLOAD" > $FIX/'notes 📝.txt'

# ---------- zdot: mirrors what `blossom-shell try` generates ----------
cat > $ZD/.zshrc <<EOF
export BLOSSOM_SHELL_HOME="$APP"
source "$APP/shell/init.zsh"
HISTFILE=$WORK/hist          # never touch the real history
EOF
case $MODE in
  native) print 'disable-fzf-tab' >> $ZD/.zshrc ;;
  fzftab) print "zstyle ':fzf-tab:*' fzf-command $BIN/bs-fzf-stub" >> $ZD/.zshrc ;;
  *) print -u2 "unknown mode: $MODE (native|fzftab|both)"; exit 2 ;;
esac
cp $ZD/.zshrc $ZD/.zprofile

# ---------- fzf stub (fzftab mode): first candidate wins ----------
cat > $BIN/bs-fzf-stub <<'STUB'
#!/usr/bin/env zsh
# impersonates fzf for fzf-tab (see its lib/-ftb-fzf): invoked with
# --print-query and --expect=…, so stdout must be: query \n expect-key \n
# selected candidate line(s); candidates arrive on stdin after
# --header-lines=N header rows and are echoed back verbatim.
query='' headers=0
for a in "$@"; do
  case $a in
    (--query=*)        query=${a#--query=} ;;
    (--header-lines=*) headers=${a#--header-lines=} ;;
  esac
done
lines=("${(@f)$(command cat)}")
print -r -- "$query"
print -r -- ""
print -r -- "${lines[headers+1]}"
STUB
chmod +x $BIN/bs-fzf-stub

# ---------- pty plumbing ----------
send()   { zpty -w -n $PTY "$@" }
expect() {  # expect <glob> — block until the pty prints it (wrap the run in `timeout`)
  local pat=$1
  if ! zpty -r $PTY REPLY "*${pat}*"; then
    print -u2 "✗ pty died while waiting for: $pat"
    tail -c 2000 $WORK/session.log 2>/dev/null | cat -v >&2
    exit 1
  fi
  print -rn -- "$REPLY" >> $WORK/session.log
}
probe() {  # probe <pwd-glob> — ask the pty for $PWD (plain output), assert it
  (( PN++ ))
  send 'print -r -- B'$PN'S"":"$PWD":""KO'$'\r'
  expect "B${PN}S:*:KO"
  local out=${REPLY##*B${PN}S:}; out=${out%%:KO*}
  if [[ $out != ${~1} ]]; then
    print -u2 "✗ pwd is '$out' — wanted glob '$1'"
    print -u2 "── last consumed pty output:"
    tail -c 2500 $WORK/session.log 2>/dev/null | cat -v >&2
    exit 1
  fi
}

pass=0
step() { print "  ✓ $1"; (( pass++ )) }

# ---------- boot ----------
zpty $PTY env -i HOME=$HOME TERM=xterm-256color LANG=en_US.UTF-8 \
  PATH=$BIN:$HOME/.local/bin:/usr/bin:/bin ZDOTDIR=$ZD BLOSSOM_GREETED=1 \
  $ZSHBIN -i
expect '❀'                                     # first prompt petal
send 'stty rows 40 cols 160'$'\r'; probe '*'   # sane winsize for menus
step "interactive Blossom zsh is up ($MODE mode)"

# Each test: one keystroke burst (text + TAB [+ menu-accept CR] + run CR),
# then a $PWD probe. The pty queue guarantees TAB completes before the CRs.

# T1 — substring reaches a unique emoji dir
send "cd $FIX"$'\r'; probe "$FIX"
send $'cd Mus\t\r';  probe '*/🎵 Music'
step "cd Mus<TAB>   →  🎵 Music/          (substring past the emoji)"

# T2 — two candidates: menu opens, first pick lands (📁 Documents)
send "cd $FIX"$'\r'; probe "$FIX"
if [[ $MODE == native ]]; then
  send $'cd Doc\t\r\r'      # TAB → menuselect · CR accept first · CR run
else
  send $'cd Doc\t\r'        # stub already picked the first candidate
fi
probe '*/📁 Documents'
step "cd Doc<TAB>   →  📁 Documents/      (multi-candidate menu)"

# T3 — a plain-ASCII prefix still wins, no menu, no emoji hijack
send "cd $FIX"$'\r'; probe "$FIX"
send $'cd phot\t\r'; probe '*/photos-backup'
step "cd phot<TAB>  →  photos-backup/     (prefix tier beats 🌸 photos)"

# T4 — ZWJ sequence (7 codepoints) survives the whole pipeline
send "cd $FIX"$'\r'; probe "$FIX"
send $'cd fam\t\r';  probe '*/👨‍👩‍👧‍👦 family'
step "cd fam<TAB>   →  👨‍👩‍👧‍👦 family/  (ZWJ sequence)"

# T5 — regional-indicator flag
send "cd $FIX"$'\r'; probe "$FIX"
send $'cd usa\t\r';  probe '*/🇺🇸 usa'
step "cd usa<TAB>   →  🇺🇸 usa/           (flag pair)"

# T6 — descend INSIDE an emoji dir (accept-exact-dirs path)
send "cd $FIX"$'\r'; probe "$FIX"
send $'cd 📁\\ Documents/rep\t\r'; probe '*/📁 Documents/reports'
step "cd 📁\\ Documents/rep<TAB> → reports/ (exact emoji parent accepted)"

# T7 — file argument with trailing emoji completes and is readable
send "cd $FIX"$'\r'; probe "$FIX"
send $'cat notes\t\r'; expect 'EMOJI_FILE_PAYLOAD'
probe "$FIX"
step "cat notes<TAB> → notes 📝.txt        (content read back)"

# T8 — dingbat (the ❀ family itself)
send "cd $FIX"$'\r'; probe "$FIX"
send $'cd blos\t\r'; probe '*/❀ blossom'
step "cd blos<TAB>  →  ❀ blossom/         (non-emoji symbol prefix)"

print "ALL $pass ASSERTIONS PASSED — mode: $MODE"
