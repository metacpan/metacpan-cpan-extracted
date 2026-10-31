#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; my $dist; BEGIN { local @_ = "$FindBin::Bin/.."; ($dist) = do "$FindBin::Bin/../t_lib.pl" }
#----------------------------------------

use Test::More;

use YATT::Lite::Test::TestUtil;
use YATT::Lite::Util qw(dict_sort rootname read_file);
my $func = rootname(basename($0));
my $script = "$dist/scripts/yatt.$func";

unless (-r $script) {
  plan skip_all => "Can't find yatt.$func: $script";
}
unless ($^O =~ /^MSWin/ or -x $script) {
  plan skip_all => "Not executable: yatt.$func: $script";
}

$ENV{LANG} = "C"; # To avoid Wide char in $!
chdir($FindBin::Bin) or die "Can't chdir: $!"; # To avoid reading outer app.psgi.

{
  my $fn = "genperl.ytmpl/1/public/index.yatt";
  my $out = qx($^X $script $fn 2>&1);
  ok((defined $out and not $?), $fn);
  print $out, "\n" if $ENV{DEBUG};
}

done_testing();
