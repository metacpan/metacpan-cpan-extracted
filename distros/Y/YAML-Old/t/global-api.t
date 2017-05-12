use strict;
use lib -e 't' ? 't' : 'test';
use lib 'inc';
use Test::YAML();
BEGIN {
    @Test::YAML::EXPORT =
        grep { not /^(Dump|Load)(File)?$/ } @Test::YAML::EXPORT;
}
use TestYAML tests => 4;
use YAML::Old;

{
    no warnings qw'once redefine';
    require YAML::Old::Dumper;

    local *YAML::Old::Dumper::dump =
        sub { return 'got to dumper' };

    require YAML::Old::Loader;
    local *YAML::Old::Loader::load =
        sub { return 'got to loader' };

    is Dump(\%ENV), 'got to dumper',
        'Dump got to the business end';
    is Load(\%ENV), 'got to loader',
        'Load got to the business end';

    is Dump(\%ENV), 'got to dumper',
        'YAML::Old::Dump got to the business end';
    is Load(\%ENV), 'got to loader',
        'YAML::Old::Load got to the business end';
}
