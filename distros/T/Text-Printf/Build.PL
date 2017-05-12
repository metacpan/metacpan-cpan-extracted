use strict;
use warnings;

eval {require Module::Build};
if ($@)
{
    warn "Module::Build is required for Build.PL\n";
    exit 0;
}

my $builder = Module::Build->new(
    module_name         => 'Text::Printf',
    license             => 'unrestricted',
    dist_author         => 'Eric J. Roode <roode@cpan.org>',
    dist_version_from   => 'lib/Text/Printf.pm',
    build_requires =>
    {
        'Test::More'         => '0.40',
    },
    requires       =>
    {
        'Readonly'           => '1.00',
        'Exception::Class'   => '1.21',
    },
    add_to_cleanup      => [ 'Text-Printf-*' ],
    sign => 1,
);

$builder->create_build_script();
