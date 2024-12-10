#!/usr/bin/env perl
use strict;
use warnings;
use constant DEBUG_LIB => $ENV{DEBUG_YATT_CLI_LIB};
use FindBin; BEGIN {
  if (-r (my $libFn = "$FindBin::RealBin/libdir.pl")) {
    print STDERR "# using $libFn\n" if DEBUG_LIB;
    do $libFn
  }
  elsif ($FindBin::RealBin =~ m{/local/bin$ }x) {
    print STDERR "# using local/lib/perl5\n" if DEBUG_LIB;
    require lib;
    lib->import($FindBin::RealBin . "/../lib/perl5");
  }
  else {
    print STDERR "# No special libdir\n" if DEBUG_LIB;
  }
}

use YATT::Lite::LanguageServer -as_base;

{
  my MY $self = MY->new(MY->cli_parse_opts(\@ARGV));

  $self->cmd_server(@ARGV);
}
