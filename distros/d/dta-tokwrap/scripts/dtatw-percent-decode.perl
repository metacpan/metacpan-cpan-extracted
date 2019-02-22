#!/usr/bin/perl -wp

## dtatw-percent-decode.perl : decode '$%$' -> '%' for use with waste tokenizer

s/\$%\$/%/g;
