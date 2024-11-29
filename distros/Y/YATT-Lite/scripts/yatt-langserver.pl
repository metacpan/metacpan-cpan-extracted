#!/usr/bin/env perl
use strict;
use warnings;
use FindBin; BEGIN {local $_ = "$FindBin::RealBin/libdir.pl"; -r $_ and do $_}

use YATT::Lite::LanguageServer -as_base;

{
  my MY $self = MY->new(MY->cli_parse_opts(\@ARGV));

  $self->cmd_server(@ARGV);
}
