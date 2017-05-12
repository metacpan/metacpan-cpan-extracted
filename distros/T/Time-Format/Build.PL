use strict;
use warnings;

eval {require Module::Build};
if ($@)
{
    warn "Module::Build is required for Build.PL\n";
    exit 0;
}


my $builder = Module::Build->new(
    module_name        => 'Time::Format',
    license            => 'unrestricted',
    dist_author        => 'Eric J. Roode <roode@cpan.org>',
    dist_version_from  => 'lib/Time/Format.pm',
    configure_requires => {
                           'Module::Build'    => '0.4',
                          },
    build_requires     => {
                          'Test::Simple'      => '0.40',
                         },
    requires           => {
                          'Time::Local'       => '1.07',
                         },
    recommends         => {
                          'I18N::Langinfo'    => 0,
                          'POSIX'             => 0,
                          'Time::HiRes'       => 0,
                          'DateTime'          => 0,
                          'Date::Manip'       => 0,
                          'Module::Signature' => 0,
                         },
    sign               => 1,
    add_to_cleanup     => [ 'Time-Format-*' ],
);

$builder->create_build_script();
