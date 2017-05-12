use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::Atom::App',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/XML/Atom/App.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'XML::Atom'  => 0,
        'XML::Atom::Feed'  => 0,        
        'XML::Atom::Entry' => 0,
        'XML::Simple' => 0,
    },
    add_to_cleanup      => [ 'XML-Atom-App-*' ],
);

$builder->create_build_script();
