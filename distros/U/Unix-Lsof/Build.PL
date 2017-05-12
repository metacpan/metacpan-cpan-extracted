use strict;
use warnings;
use Module::Build;

if ($^O =~ m/^(?:mswin32|dos|macos|os2|cygwin|v[mo]s|riscos|amigaos|beos|mpeix)$/i) {
    die "NA: OS unsupported , lsof is not available for OS $^O, no point installing this module\n";
}

my $builder = Module::Build->new(
    module_name         => 'Unix::Lsof',
    license             => 'perl',
    dist_author         => 'Marc Beyer <japh@tirwhan.org>',
    dist_version_from   => 'lib/Unix/Lsof.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
        'IPC::Run3'  => 0,
        'perl'       => '5.8.0',
             },
    add_to_cleanup      => [ 'Unix-Lsof-*' ],
);

$builder->create_build_script();
