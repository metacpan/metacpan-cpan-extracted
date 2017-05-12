use strict;
use warnings;

# This little bit of stupidity is due to CPAN::YACSmoke.
eval {require Module::Build};
if ($@)
{
    warn "Module::Build is required for Build.PL\n";
    exit 0;
}


my $builder = Module::Build->new(
    module_name         => 'Time::Normalize',
    license             => 'perl',
    dist_author         => 'Eric J. Roode <roode@cpan.org>',
    dist_version_from   => 'lib/Time/Normalize.pm',
    build_requires =>
    {
     'Test::More'      =>  '0.40',
    },
    sign => 1,
    add_to_cleanup      => [ 'Time-Normalize-*' ],
);

$builder->create_build_script();
