#!/usr/bin/env bash

if [ -f $HOME/.bashrc ]
  then
    source $HOME/.bashrc
  fi

if [ -f $HOME/.bash_profile ]
  then
    source $HOME/.bash_profile
  fi

$HOME/workspace/categorization-perl/trunk/Text/Corpus/CNN/scripts/update_Text_Corpus_CNN.pl $*
