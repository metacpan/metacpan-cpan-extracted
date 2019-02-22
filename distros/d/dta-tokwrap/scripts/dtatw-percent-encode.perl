#!/usr/bin/perl -wp

## dtatw-precent-encode.perl : encode '%' -> '$%$' for use with waste tokenizer

s/%/\$%\$/g;
