#!/usr/bin/perl
###########################################################################

use Test;
use Text::Scan;

BEGIN { plan tests => 2 + 1 }

$ref = new Text::Scan;
$ref->usewild();

# Combine with wildcards
$ref->insert('gorillas * * mist', 'gorillas * * mist');

my @answer = $ref->scan('what if gorillas hate the mist');
ok($answer[0], 'gorillas hate the mist');
ok($answer[1], 'gorillas * * mist');

my $sneakystring = "what if gorillas hate the  mist in the morning";
$sneakystring = "what if gorillas hate the";
@answer = $ref->scan($sneakystring); 
ok($answer[0], undef);

exit 0;






