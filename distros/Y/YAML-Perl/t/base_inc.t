use t::TestYAMLPerl tests => 1;

use YAML::Perl::Events;

ok UNIVERSAL::can('YAML::Perl::Event::CollectionStart', 'new'),
    'Derived class works with -base';
