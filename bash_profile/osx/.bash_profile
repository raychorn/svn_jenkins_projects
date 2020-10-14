#export VAGRANT_HOME="$HOME/.vagrant.d/"

# Setting PATH for Python 2.7
# The orginal version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
export PATH
export ANDROID_HOME=/usr/local/opt/android-sdk

# virtualenv
export WORKON_HOME=$HOME/.virtualenvs
source /Library/Frameworks/Python.framework/Versions/2.7/bin/virtualenvwrapper.sh

# virtualenv aliases
# http://blog.doughellmann.com/2010/01/virtualenvwrapper-tips-and-tricks.html
alias v='workon'
alias v.deactivate='deactivate'
alias v.mk='mkvirtualenv --no-site-packages'
alias v.mk_withsitepackages='mkvirtualenv'
alias v.rm='rmvirtualenv'
alias v.switch='workon'
alias v.add2virtualenv='add2virtualenv'
alias v.cdsitepackages='cdsitepackages'
alias v.cd='cdvirtualenv'
alias v.lssitepackages='lssitepackages'


# Setting PATH for Python 2.7
# The orginal version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
export PATH

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
else
    color_prompt=
fi
 
if [ "$color_prompt" = yes ]; then
    export PS1="\n[\t] \[\e[01;33m\]\u@\H\[\e[0m\]:\$PWD\n-->"
    export SUDO_PS1="\n[\t] \[\e[33;01;41m\]\u@\H\[\e[0m\]:\$PWD\n-->"
else
    export PS1="\n[\t] \u@\H:\$PWD\n-->"
fi

export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

