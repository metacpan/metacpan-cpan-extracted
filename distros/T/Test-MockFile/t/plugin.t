#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin;
use lib map { "$FindBin::Bin/$_" } qw{ ./lib ../lib };

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use File::Temp ();
use File::Path ();

use File::Slurper qw{ write_text };
use Test::TMF qw ( tmf_test_code );

my $test_code;

$test_code = <<'EOS';
use Test::MockFile ( plugin => q[Unknown] );
EOS

tmf_test_code(
    name => q[Cannot find a Test::MockFile plugin for Unknown],

    exit => 512,

    test => sub {
        my ($out) = @_;

        #note explain $out;

        like $out->{output}, qr{Cannot find a Test::MockFile plugin for Unknown}, 'Cannot find a Test::MockFile plugin for Unknown';

        return;
    },
    test_code => $test_code,
    debug     => 0,
);

# ------------------------------------------------------------------------------------

my $tmp = File::Temp->newdir();

my $base_dir = "$tmp/Test/MockFile/Plugin";

ok File::Path::make_path($base_dir), "create Test/MockFile/Plugin dir for testing";

my $MyPlugin_filename = "$base_dir/MyPlugin.pm";

File::Slurper::write_text( $MyPlugin_filename, <<"EOS" );
package Test::MockFile::Plugin::MyPlugin;

use base 'Test::MockFile::Plugin';

sub register {
    print qq[MyPlugin is now registered!\n];
}

1
EOS

$test_code = <<'EOS';
use Test::MockFile ( plugin => q[MyPlugin] );
ok 1;
EOS

tmf_test_code(
    name => q[Loading a plugin from default namespace],

    perl_args => ["-I$tmp"],

    exit => 0,

    test => sub {
        my ($out) = @_;

        like $out->{output}, qr{MyPlugin is now registered}, 'load and register plugin';

        return;
    },
    test_code => $test_code,
    debug     => 0,
);

$test_code = <<'EOS';
use Test::MockFile ( plugin => [ 'MyPlugin' ] );
ok 1;
EOS

tmf_test_code(
    name => q[use Test::MockFile ( plugin => [ 'MyPlugin' ] )],

    perl_args => ["-I$tmp"],

    exit => 0,

    test => sub {
        my ($out) = @_;

        like $out->{output}, qr{MyPlugin is now registered}, 'load and register plugin';

        return;
    },
    test_code => $test_code,
    debug     => 0,
);

# ------------------------------------------------------------------------------------

note "Testing a custom namespace";

$base_dir = "$tmp/CustomPluginNamespace";

ok File::Path::make_path($base_dir), "create Test/MockFile/Plugin dir for testing";

my $AnotherPlugin_filename = "$base_dir/Another.pm";

File::Slurper::write_text( $AnotherPlugin_filename, <<"EOS" );
package CustomPluginNamespace::Another;

use base 'Test::MockFile::Plugin';

sub register {
    print qq[AnotherPlugin from a Custom namespace is now registered!\n];
}

1
EOS

$test_code = <<'EOS';
BEGIN {
    require Test::MockFile::Plugins;
    push @Test::MockFile::Plugins::NAMESPACES, 'CustomPluginNamespace';
}
use Test::MockFile ( plugin => q[Another] );
ok 1;
EOS

tmf_test_code(
    name => q[Loading a plugin from default namespace],

    perl_args => ["-I$tmp"],

    exit => 0,

    test => sub {
        my ($out) = @_;

        #note explain $out;

        like $out->{output}, qr{AnotherPlugin from a Custom namespace is now registered!}, 'load and register plugin from a custom namespace';

        return;
    },
    test_code => $test_code,
    debug     => 0,
);

done_testing;
