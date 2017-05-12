use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::Google::Contact',
    license             => 'perl',
    dist_author         => 'DAISUKE ABUI <abui@cpan.org>',
    dist_version_from   => 'lib/WebService/Google/Contact.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'Class::Accessor::Fast' => 0,
        'URI' => 0,
        'LWP::UserAgent' => 0,
        'XML::Liberal' => 0,
    },
    add_to_cleanup      => [ 'WebService-Google-Contact-*' ],
);

$builder->create_build_script();
