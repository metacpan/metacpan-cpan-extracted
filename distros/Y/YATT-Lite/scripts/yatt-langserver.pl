#!/usr/bin/env perl
use strict;
use warnings;
use FindBin; BEGIN {do "$FindBin::RealBin/libdir.pl"}

use YATT::Lite::LanguageServer -as_base;

{
  my MY $self = MY->new(MY->cli_parse_opts(\@ARGV));

  $self->cmd_server(@ARGV);
}
