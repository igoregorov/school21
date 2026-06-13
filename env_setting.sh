#!/bin/bash

# ==============================================================================
# Скрипт бескомпромиссной настройки среды (без вопросов и бэкапов)
# Автор: Игорь (scratcal)
# ==============================================================================

echo "🚀 Начинаем настройку среды. Файлы будут перезаписаны без предупреждений."

# 1. создаем нужную директорию
mkdir -p "$HOME/.local/bin"

# 2. Перезаписываем .bashrc
cat << 'EOF' > "$HOME/.bashrc"
# ~/.bashrc: executed by bash(1) for non-login shells.

# Если не интерактивная оболочка, выходим сразу
[ -z "$PS1" ] && return

# --- Настройки истории ---
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "
shopt -s histappend

# --- Проверка размера окна терминала ---
shopt -s checkwinsize

# --- Цвета и алиасы для ls ---
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# --- Полезные алиасы ---
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- Git фишки ---
parse_git_branch() {
    git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/ [\1]/p'
}

get_short_pwd() {
    local p="${PWD/#$HOME/\~}"
    if [[ "$p" == */*/* ]]; then
        local base="${p##*/}"
        local dir="${p%/*}"
        local parent="${dir##*/}"
        echo "${parent}/${base}"
    else
        echo "$p"
    fi
}

PS1='\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;36m\]$(get_short_pwd)\[\033[01;33m\] $(parse_git_branch)\[\033[00m\]\$ '

# --- Функции ---
function findfile() {
    find . -type f -iname "*$1*"
}

function mkcd() {
    mkdir -p "$1" && cd "$1"
}

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# --- Приветствие при входе ---
echo "Добро пожаловать, $USER. Система стабильна, как орбита спутника."
EOF

# 3. Перезаписываем .vimrc
cat << 'EOF' > "$HOME/.vimrc"
syntax on
filetype plugin indent on
set termguicolors

highlight String ctermfg=Green guifg=#98C379
highlight Comment ctermfg=Gray guifg=#5C6370
highlight Number ctermfg=Yellow guifg=#D19A66
highlight Comment ctermfg=Cyan guifg=#61AFEF
highlight Todo ctermfg=Red guifg=#E06C75 cterm=bold gui=bold
highlight Identifier ctermfg=Magenta guifg=#C678DD
EOF

# 4. Создаем и делаем исполняемым crun
cat << 'EOF' > "$HOME/.local/bin/crun"
#!/bin/bash

if [ -z "$1" ]; then
    echo "Использование: crun <имя_файла>"
    exit 1
fi

FILE=$1
[[ "$FILE" != *.c ]] && FILE="${FILE}.c"

if [ -f "$FILE" ]; then
    TARGET_PATH="$FILE"
elif [ -f "src/$FILE" ]; then
    TARGET_PATH="src/$FILE"
else
    echo "Файл $FILE не найден ни в текущей директории, ни в src/"
    exit 1
fi

EXEC_NAME=$(basename "$TARGET_PATH" .c)

echo "Компиляция $TARGET_PATH с флагами -Wall -Wextra -Werror..."
gcc -Wall -Wextra -Werror "$TARGET_PATH" -o "$EXEC_NAME"

if [ $? -eq 0 ]; then
    echo "Компиляция успешна! Запускаем..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ./"$EXEC_NAME"
    EXIT_CODE=$?
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Убираем за собой: удаляем исполняемый файл '$EXEC_NAME'"
    rm -f "$EXEC_NAME"
    exit $EXIT_CODE
else
    echo "Ошибка компиляции. Компилятор нашел то, что не понравится и проверяющему. Исправляй!"
    exit 1
fi
EOF
chmod +x "$HOME/.local/bin/crun"

# 5. Создаем и делаем исполняемым chck_style
cat << 'EOF' > "$HOME/.local/bin/chck_style"
#!/bin/bash

TARGET_PATH=$1

if [ -z "$TARGET_PATH" ]; then
    echo "Использование: $0 <имя_файла>"
    exit 1
fi

echo "Проверяем код-стайл через clang-format..."

CLANG_OUTPUT=$(clang-format -n --Werror "$TARGET_PATH" 2>&1 | grep -v "WARNING: will not expose Kerberos")

if echo "$CLANG_OUTPUT" | grep -q "error:"; then
    echo "Ошибка форматирования! clang-format нашел нарушения:"
    echo "$CLANG_OUTPUT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    diff -u "$TARGET_PATH" <(clang-format "$TARGET_PATH" 2>/dev/null) | grep -v "WARNING: will not expose Kerberos" || true
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Запусти 'clang-format -i $TARGET_PATH', чтобы исправить это в один клик но на свой риск."
    exit 1
fi

echo "Стиль в полном порядке."
EOF
chmod +x "$HOME/.local/bin/chck_style"

echo "Не забудь выполнить: source ~/.bashrc"
