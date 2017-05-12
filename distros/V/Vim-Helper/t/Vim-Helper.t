#!/usr/bin/env perl
package Test::Vim::Helper;
use strict;
use warnings;

use Fennec;
use File::Temp qw/tempfile/;

our $CLASS = 'Vim::Helper';
require_ok $CLASS;

tests accessors => sub {
    can_ok( $CLASS, qw/cli plugins/ );
    my $one = $CLASS->new;
    isa_ok( $one->cli, 'Declare::CLI' );

    $one->cli(1);
    is( $one->cli, 1, "Can write to accessor" );
};

# Note: we also test 'plugin()' here.
tests meta_and_import => sub {
    my $meta = $CLASS->new;
    local *VH_META = sub { $meta };

    ok( !$meta->plugin('LoadMod'), "Have not loaded plugin 'LoadMod'" );
    ok( !$meta->plugin('Fennec'),  "Have not loaded plugin 'Fennec'" );

    $CLASS->import(qw/LoadMod Fennec/);
    can_ok( __PACKAGE__, qw/LoadMod Fennec/ );

    ok( $meta->plugin('LoadMod'), "Loaded plugin 'LoadMod'" );
    ok( $meta->plugin('Fennec'),  "Loaded plugin 'Fennec'" );

    Fennec( {run_key => 'XXX', less_key => 'YYY'} );

    is( $meta->plugin('Fennec')->run_key,  'XXX', "Configured 'Fennec'" );
    is( $meta->plugin('Fennec')->less_key, 'YYY', "Configured 'Fennec'" );
};

tests command_reconstruction => sub {
    local $0 = 'thescript';
    my $one = $CLASS->new;

    is( $one->command, 'thescript', "Command with no config is just \$0" );
    is(
        $one->command( {config => 'foobar'} ),
        "thescript -c 'foobar'",
        "Command with a config includes config"
    );
};

tests load_plugin => sub {
    my $meta = $CLASS->new;
    local *VH_META = sub { $meta };

    $meta->_load_plugin( 'Fennec', __PACKAGE__ );
    can_ok( __PACKAGE__, qw/Fennec/ );
    $meta->_load_plugin( 'Help', __PACKAGE__ );

    ok( $meta->plugin('Help'),   "Loaded plugin 'Help'" );
    ok( $meta->plugin('Fennec'), "Loaded plugin 'Fennec'" );

    # Check the config function
    Fennec( {run_key => 'XXX', less_key => 'YYY'} );
    is( $meta->plugin('Fennec')->run_key,  'XXX', "Configured 'Fennec'" );
    is( $meta->plugin('Fennec')->less_key, 'YYY', "Configured 'Fennec'" );

    # Check that the args and opts from 'Help' are loaded
    my $args = $meta->plugin('Help')->args;
    my $opts = $meta->plugin('Help')->opts;

    ok( $meta->cli->args->{$_}, "Found arg '$_' from plugin 'Help'" ) for keys %$args;
    ok( $meta->cli->opts->{$_}, "Found opt '$_' from plugin 'Help'" ) for keys %$opts;
};

tests read_config => sub {
    my $one = $CLASS->new;

    my ( $tfh, $tmp ) = tempfile( UNLINK => 1 );
    print $tfh "Line 1\nLine 2\nLine 3\n";
    close($tfh);

    my ( $content, $file ) = $one->read_config( {config => $tmp} );
    is( $file, $tmp, "Got the file back" );
    is( $content, "Line 1\nLine 2\nLine 3\n", "got content" );
};

tests run => sub {
    my $config = <<"    EOT";
        use Vim::Helper qw/
            TidyFilter
            Test
            LoadMod
            Fennec
        /;
    EOT

    my $control = qtakeover $CLASS => (
        read_config => sub { ( $config, 'fakefile' ) },
    );

    lives_ok {
        my $out = $CLASS->run('help');
        is( $out->{code}, 0, "successful return" );
    }
    "config is valid";

    $config .= "die 'xxx';\n";

    ok( !eval { $CLASS->run('help'); 1; }, "died" );
    like(
        $@,
        qr/xxx at fakefile line 7/,
        "Got correct error (shows proper file and line)"
    );
};

1;

