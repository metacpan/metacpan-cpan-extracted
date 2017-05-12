use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use Test::Builder::Tester;

{ package TC1; use Moose;       use namespace::autoclean }
{ package TC2; use Moose;                                }
{ package TR1; use Moose::Role; use namespace::autoclean }
{ package TR2; use Moose::Role;                          }

use TAP::SimpleOutput 0.009 'counters';

sub _validate {
    my ($thing, $sugar) = @_;

    my ($_ok, $_nok) = counters();
    my $verb = $sugar ? 'can' : 'cannot';

    test_out $_ok->("$thing $verb $_")
        for Test::Moose::More::known_sugar();
    validate_thing $thing => (sugar => $sugar);
    test_test "validate_thing: $thing, sugar => $sugar";
}

_validate('TC1', 0);
_validate('TC2', 1);
_validate('TR1', 0);
_validate('TR2', 1);

done_testing;
