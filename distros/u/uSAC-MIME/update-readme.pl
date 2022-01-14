#!/usr/bin/env perl
use strict;
use warnings;

`pod2text lib/uSAC/MIME.pod > README`;
`pod2github lib/uSAC/MIME.pod >README.md`;
