
use 5.010;
use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec::Functions;

# We want to use WWW::EchoNest::Util::codegen to figure out if there is an
# Echo Nest code generator installed on the system.
use lib ( './lib', );
use WWW::EchoNest::Util qw( codegen );

# We need to be able to figure out where the test scripts will be logging
use WWW::EchoNest::Preferences qw( log_filename );

# Our custom Module::Build subclass
use WWW::EchoNest::Build;

my $all       = 0;
my $files     = join( q[ ], qw[
                                  artist
                                  catalog
                                  echonest
                                  playlist
                                  song
                                  track
                                  00-load
                                  boilerplate
                                  manifest
                                  pod-coverage
                                  pod
                            ]
                    );

my $auto;
my $log_file  = WWW::EchoNest::Preferences::log_filename;
my $test_url  = 'http://spoomusic.com/albums/wjoo. joo. - Full Moon Yawn/'
    . '01 - wjoo. joo. - Full Moon Yawn.mp3';
my $test_file = 'test_file.mp3';

my $builder = WWW::EchoNest::Build->new
    (
     module_name           => 'WWW::EchoNest',
     license               => 'perl',
     dist_author           => 'Brian Sorahan <bsorahan@gmail.com>',
     dist_version_from     => 'lib/WWW/EchoNest.pm',
     build_requires        =>
     {
      'Test::More' => 0,
     },
     requires              =>
     {
      'perl' => '5.10.1',
      'JSON' => 0,
     },
     recommends            =>
     {
      'File::Which' => 0,
      'Log::Log4perl' => 0,
     },
     get_options =>
     {
      auto       => { store => \$auto,                     },
      files      => { store => \$files,       type => '=s' },
      test_url   => { store => \$test_url,    type => '=s' },
      test_file  => { store => \$test_file,   type => '=s' },
     },
     add_to_cleanup        => [ qw( blib _build debian WWW-EchoNest-* ) ],
     create_makefile_pl    => 'traditional',
     # script_files          => [ qw( echonest ) ],
    );



########################################################################
#
# When we run the song.t test harness, we only want to run the tests for
# song_identify if the following conditions are met:
#
# - ffmpeg must be installed
# - File::Which must be installed from CPAN
# - echoprint code generator must be installed
#
# --- bps 2011-08-05
#
my %test_args = ();
my $test_file_string = q[];
if ($files) {
    for my $test ( split(' ', $files) ) {
        $test_file_string .= catfile( 't', $test . '.t' ) . q[ ];
    }
}
# print "$test_file_string\n";
$test_args{'test_files'} = $test_file_string;

# Add some features that the test scripts will use. ####################
eval {
    codegen( $test_file );
};
my $CODEGEN_FOUND = $@ ? 0 : 1;
$builder->feature( test_url      => $test_url             );
$builder->feature( test_file     => $test_file       );
$builder->feature( codegen_found => $CODEGEN_FOUND   );

# Automated build? #####################################################
#
if ($auto) {
    $builder->dispatch( 'realclean' );
    $builder->dispatch( 'build' );
    
    print STDERR 'Running tests. This will take a few minutes...' . "\n";
    
    $builder->dispatch( 'test', %test_args );
    # $builder->dispatch( 'install', uninst => 1 );
}
else {
    $builder->create_build_script();
}
