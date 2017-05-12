#!/usr/bin/perl
use strict;
use warnings;
use Test::More skip_all => 'tbd';

BEGIN {$XUL::Gui::TESTING = 1}
use XUL::Gui;
$| = 1;

use Cwd 'cwd';

chdir '..' until cwd =~ /XUL-Gui.?$/;

for (<examples/*.pl>) {
    do $_;
    ok !$@ #!(system $^X => $_, 'testing')
    => (/(\w+).pl$/)[0]
}
