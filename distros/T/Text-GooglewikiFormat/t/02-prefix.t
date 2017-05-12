#!perl -T

use Test::More tests => 1;
use Text::GooglewikiFormat;

my $raw  = 'WikiWordLink';
my %tags = %Text::GooglewikiFormat::tags;
my $html = Text::GooglewikiFormat::format($raw, \%tags, { prefix => 'http://code.google.com/p/fayland/wiki/' } );
is($html, '<p><a href="http://code.google.com/p/fayland/wiki/WikiWordLink">WikiWordLink</a></p>', 'prefix works');