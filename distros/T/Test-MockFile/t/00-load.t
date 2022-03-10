#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok('Test::MockFile')      || print "Bail out!\n";
    use_ok('Overload::FileCheck') || print "Bail out!\n";
    use_ok('File::Temp')          || print "Bail out!\n";
}

diag("Testing Test::MockFile $Test::MockFile::VERSION with Overload::FileCheck $Overload::FileCheck::VERSION and File::Temp $File::Temp::VERSION");
diag("Perl $], $^X");
