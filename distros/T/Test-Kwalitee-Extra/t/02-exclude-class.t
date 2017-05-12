use strict;
use warnings;
use Test::More;
use Module::CPANTS::Kwalitee;

require Test::Kwalitee::Extra;

my $mck = Module::CPANTS::Kwalitee->new;
my $ref = Test::Kwalitee::Extra::_init();
my $num = scalar grep { !exists $ref->{exclude}{$_} } @{$mck->core_indicator_names};

plan( tests => $num + 1);

Test::Kwalitee::Extra->import(qw(:no_plan !:optional));

ok(Test::Builder->new->current_test == $num);
