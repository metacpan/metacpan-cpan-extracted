use t::TestYAMLPerl; # tests => 2;

use YAML::Perl::Serializer;
use YAML::Perl::Composer;

spec_file('t/data/parser_emitter');
filters { yaml => [qw'compose serialize'] };

run_is yaml => 'yaml2';

sub compose {
    YAML::Perl::Composer->new()
        ->open($_)
        ->compose();
}

sub serialize {
    $_ = YAML::Perl::Serializer->new()
        ->open()
        ->serialize(@_);
}
