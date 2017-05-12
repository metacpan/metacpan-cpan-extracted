# In bash, you can do
#   vit Foo::Bar::Baz
# to edit the class
#   cdt Foo::Bar::Baz
# to cd to the class's directory, we use vim tags. Also see completion below.

# In ~/.vimrc:
# set tags+=$PTAGSFILE

# PTAGSFILE is needed by .vimrc as well
export PTAGSFILE=~/.ptags
alias vit='vi -t'

cdt () { cd `ptagdir $1`; }

# vit and cdt (see ~/.bashrc for alias def) complete to vim's perl tags
# UPDATE: or use Bash::Completion::Plugins::VimTag

_ptags()
{
    COMPREPLY=( $(grep -h ^${COMP_WORDS[COMP_CWORD]} $PTAGSFILE | cut -f 1) )
    return 0
}
complete -F _ptags vit cdt ptagdir
