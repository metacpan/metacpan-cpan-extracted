use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Test::Mock::Cmd',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Test/Mock/Cmd.pm',
    requires          => {
        'Test::More' => 0,    # for testing, I know I know: Test::XT
        'Test::Carp' => 0,    # for testing
                              # 'Test::Output' => 0, # for testing
    },
    add_to_cleanup => ['Test-Mock-Cmd-*'],
);

$builder->create_build_script();
