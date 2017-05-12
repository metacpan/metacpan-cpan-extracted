use strict;
use warnings;
use File::Copy;
use Module::Build;

use strict;
use warnings;

# check to find the root directory for yote using a list of common candidates
my( $yote_root_parent ) = grep { -e $_ && -r $_ && -w $_ } ( '/opt',
                                                             '/var',
                                                             '/usr/local',
                                                             $ENV{HOME},
                                                             '.'
);

die "Unable to write yote root directory" unless -w $yote_root_parent;
my $yote_root = "$yote_root_parent/yote";

mkdir $yote_root unless -d $yote_root;

die "Unable to create root directory" unless -w $yote_root;

mkdir "$yote_root/html";
mkdir "$yote_root/lib";

# fill the root directory
sub copy_dir {
    my( $dir, $dest, $overwrite ) = @_;
    mkdir "$dest" unless -d "$dest";
    opendir( my $DIN, $dir );
    while( my $fn = readdir $DIN ) {
        next if $fn =~ /^\.+$/;
        if( -d "$dir/$fn" ) {
            copy_dir( "$dir/$fn", "$dest/$fn", $overwrite );
        }
        elsif( ! -e "$dest/$fn" || $overwrite ) {
            copy( "$dir/$fn", "$dest/$fn" );
        }
    }
} #copy_dir
copy_dir( 'html', $yote_root );
copy_dir( 'cgi-bin', $yote_root );


my $builder = Module::Build->new(
    add_to_cleanup      => [ 'Yote-*' ],
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.40,
    },
    create_makefile_pl => 'traditional',
    dist_author        => q{Eric Wolf (coyocanid@gmail.com)},
    dist_version_from  => 'lib/Yote/Server.pm',
    license            => 'perl',
    module_name        => 'Yote::Server',
    release_status     => 'stable',
    test_files         => [ 't/servertest.t', ],
    requires => {
        'perl'                  => 'v5.12',
        'Yote'                  => 1.31,
        'JSON'                  => 0,
        'IO::Socket::SSL'       => 2.024,
        'Lock::Server'          => 1.73,
        'Test::More'            => 0,
        'URI::Escape'           => 0,
        'UUID::Tiny'            => 0,
    },
    );

$builder->config_data( 'yote_root' => $yote_root );

$builder->create_build_script();
