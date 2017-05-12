#!/usr/bin/env perl

package CmdTest;
use strict;
use warnings;
use Command::Tree;

class CmdTest { is => 'Command::Tree', doc => 'test suite test command tree' };

if ($0 eq __FILE__) {
    require Command::Shell;
    exit Command::Shell->run(__PACKAGE__,@ARGV);
}

1;

