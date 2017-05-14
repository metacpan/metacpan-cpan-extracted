package TestYAML;
use lib 'inc';
use Test::YAML -Base;

$Test::YAML::YAML = 'YAML::Old';

$^W = 1;

package Test::YAML::Filter;

use Test::Base::Filter ();

our @ISA = 'Test::Base::Filter';

sub yaml {
    $self->assert_scalar(@_);
    require YAML::Old;
    return YAML::Old::Load(shift);
}

1;
