use Module::Build;
my $build = Module::Build->new
(
     module_name => 'WebService::MusicBrainz',
     dist_abstract => 'Web service API to MusicBrainz database',
     license  => 'perl',
     requires => {
                  'perl'          => '5.10.1',
                  'Mojolicious'   => '7.13'
                 },
     configure_requires => {
        'Module::Build' => '0.42'
     },
     create_makefile_pl => 'traditional',
     dist_author => 'Bob Faist <bob.faist@gmail.com>',
     dist_version => '1.0.7',
     meta_merge => {
        resources => {
           repository => 'git://github.com/bfaist/webservice-musicbrainz.git'
        },
        keywords => [ qw/musicbrainz webservice/ ]
     },
);
$build->create_build_script;
