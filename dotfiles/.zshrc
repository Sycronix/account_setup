# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="robbyrussell"
ZSH_THEME="murilasso"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git lxd-completion-zsh)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export HISTSIZE=1000000000
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY

export LXC_TARGET=21sw-e

lxcr () {
	lxc exec ${LXC_TARGET:=21sw-builder} -- bash
	}

lxcj () {
	lxc exec ${LXC_TARGET:=21sw-builder} -- sudo --login --user jenkins
	}

lxcu () {
	lxc exec ${LXC_TARGET:=21sw-builder} -- sudo --login --user ubuntu
	}

alias lil="lxc image list"

if [[ -z $TMUX ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then; tmux attach -t TMUX || tmux new -s TMUX; fi


[ -n "$XRDP_SESSION" ] && export DESKTOP_SESSION=startxfce4


export BB_ENV_PASSTHROUGH_ADDITIONS="DL_DIR SSTATE_DIR"
export DL_DIR="${HOME}/data/bitbake.downloads"
export SSTATE_DIR="${HOME}/data/bitbake.sstate"

export EDITOR=vi

alias tpass='cat ${BUILDDIR}/conf/passwd.log'
setopt +o nomatch
#export PYENV_ROOT="$HOME/.pyenv"
#[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
#eval "$(pyenv init -)"

alias asdf='GITPATH=${BUILDDIR:=~/git/tsel/build}; echo "Repo: tsel - $(git -C ${GITPATH}/.. branch --show-current)"; git -C ${GITPATH}/.. ls-files -m; echo "---------"; echo "Repo: meta-21sw $(git -C ${GITPATH}/../meta-21sw branch --show-current)"; git -C ${GITPATH}/../meta-21sw ls-files -m; echo; cd ${GITPATH}/..'

if [ "$VSCODE_INJECTION" = "1" ]; then
    export EDITOR="code --wait" # or 'code-insiders' if you're using VS Code Insiders
fi

export COMMAND_SERVER=purple.tang.inafish.net

# Function to log commands and send them to the UDP listener
log_command() {
  local username=$(whoami)
  local hostname=$(hostname)
  local timestamp=$(date +%s)
  local command=$(fc -ln -1)
  local command_server="${COMMAND_SERVER:-<your-express-app-host>}"
  local command_server_port="${COMMAND_SERVER_PORT:-41234}"

  # Debug: Write the timestamp and command to a temp file for inspection
  echo "$timestamp $command" >> /tmp/${username}-${hostname}

  # Send the command log to the UDP listener, encrypted with the server's public key
  printf '{"username":"%s","hostname":"%s","timestamp":%s,"command":"%s"}' "$username" "$hostname" "$timestamp" "$command" | \
    openssl pkeyutl -encrypt -pubin -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha1 -inkey ~/.config/history.pem | base64 | \
    nc -u -w0 $command_server $command_server_port
}

# Hook the log_command function to the Zsh preexec function
#preexec_functions+=(log_command)

copy_from_21swb() {
    if [ -z "$1" ]; then
        echo "Usage: copy_from_21swb <remote_file_path>"
        return 1
    fi

    scp 21swb:"$1" ~/images/
}

alias binkeeper="etckeeper -d ${HOME}/git/bin"
unset RPS1

#PROMPT=$'%{$terminfo[bold]$fg[green]%}%n@%m%{$reset_color%} ${MACHINE}:%{$terminfo[bold]$fg[blue]%}%~%{$reset_color%} %{$fg[red]%}$(ruby_prompt_info)%{$reset_color%}' $'\n''%{$fg[blue]%}$(git_prompt_info)%{$reset_color%} %B$%b '
#PROMPT=$'%{$terminfo[bold]$fg[green]%}%n@%m%{$reset_color%} ${MACHINE}:%{$terminfo[bold]$fg[blue]%}%~%{$reset_color%} %{$fg[red]%}$(ruby_prompt_info)%{$reset_color%}\n%{$fg[blue]%}$(git_prompt_info)%{$reset_color%} %B$%b '
PROMPT=$'%{$terminfo[bold]$fg[green]%}%n@%m%{$reset_color%}${MACHINE:+ MACHINE=${MACHINE}}:%{$terminfo[bold]$fg[blue]%}%~%{$reset_color%} %{$fg[red]%}$(ruby_prompt_info)%{$reset_color%}\n%{$fg[blue]%}$(git_prompt_info)%{$reset_color%} %B$%b '
#
export PATH=${PATH}:~/bin:~/workspace/TSEL-pipeline-runner
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
