#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Text::Guess::Language;

my @languages = Text::Guess::Language->languages();

print 'number of languages: ',scalar(@languages),"\n";
print join("\n",@languages),"\n";
