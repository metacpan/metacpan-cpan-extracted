use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
              module_name       => 'WebService::LibraryThing::ThingISBN',
              license           => 'perl',
              dist_author       => q{Anirvan Chatterjee <anirvan@cpan.org>},
              dist_version_from => 'lib/WebService/LibraryThing/ThingISBN.pm',
              build_requires    => { 'Test::More' => 0, },
              requires          => {
                            'Business::ISBN' => 2,
                            'Carp'           => 0,
                            'Exporter'       => 0,
                            'HTTP::Request'  => 0,
                            'LWP::UserAgent' => 0,
              },
              recommends => { 'Time::HiRes' => 0, },
              add_to_cleanup     => ['WebService-LibraryThing-ThingISBN-*'],
              create_makefile_pl => 'traditional',
);

$builder->create_build_script();

# Local Variables:
# mode: perltidy
# End:
