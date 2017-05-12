use strict;
use warnings;

use Test::More tests => 9;

require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'http://www.ohloh.net/projects/1234.xml', 'factoids.xml' );

my @factoids = $ohloh->get_factoids(9);

is scalar(@factoids) => 4, 'get_factoids';

my $f = shift @factoids;

is $f->id,          341293,                                'id()';
is $f->analysis_id, 116201,                                'analysis_id';
is $f->type,        'FactoidTeamSizeVeryLarge',            'type()';
is $f->description, 'Very large, active development team', 'description';
is $f->severity,    3,                                     'severity()';

is $f->license_id, q{}, 'license_id()';

$f = pop @factoids;

is $f->license_id, 5, 'license_id()';

like $f->as_xml, qr#<factoid>.*</factoid>$#, 'as_xml()';
