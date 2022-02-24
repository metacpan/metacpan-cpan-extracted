#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw< lives dies >;
use Test::MockFile;

sub test_content_with_keywords {
    my ( $dirname, $dir_content ) = @_;

    my $dh;
    my $open;
    ok(
        lives( sub { $open = opendir $dh, $dirname } ),
        "opendir() $dirname successful",
    );

    $open or return;

    my @content;
    ok(
        lives( sub { @content = readdir($dh) } ),
        "readdir() on $dirname successful",
    );

    is(
        \@content,
        $dir_content,
        'Correct directory content through Perl core keywords',
    );

    ok(
        lives( sub { closedir $dh } ),
        "closedir() on $dirname successful",
    );
}

my $count       = 0;
my $get_dirname = sub {
    $count++;
    return "/foo$count";
};

subtest(
    '->dir() checks when going through ->new_dir()' => sub {
        like(
            dies( sub { Test::MockFile->new_dir( '/etc', { 1 => 2 } ) } ),
            qr!^\QYou cannot set stats for nonexistent dir '/etc'\E!xms,
            'Cannot do TMF->dir( "/etc", { 1 => 2 } )',
        );

        like(
            dies( sub { Test::MockFile->new_dir( '/etc', [ 'foo', 'bar' ], { 1 => 2 } ) } ),
            qr!^\QYou cannot set stats for nonexistent dir '/etc'\E!xms,
            'Cannot do TMF->dir( "/etc", [@content], { 1 => 2 }  )',
        );

        like(
            dies( sub { Test::MockFile->new_dir( '/etc', [ 'foo', 'bar' ] ) } ),
            qr!^\QYou cannot set stats for nonexistent dir '/etc'\E!xms,
            'Cannot do TMF->dir( "/etc", [@content] )',
        );
    }
);

subtest(
    'Scenario 1: ->new_dir() can create dir' => sub {
        my $dirname = $get_dirname->();
        my $dir     = Test::MockFile->new_dir($dirname);

        ok( -d $dirname, "Directory $dirname exists" );

        is(
            $dir->contents(),
            [qw< . .. >],
            'Correct contents of directory through ->contents()',
        );

        test_content_with_keywords( $dirname, [qw< . .. >] );
    }
);

subtest(
    'Scenario 2: ->new_dir() with mode sets the mode' => sub {
        my $dirname  = $get_dirname->();
        my $base_dir = Test::MockFile->new_dir("${dirname}-base");
        my $dir      = Test::MockFile->new_dir( $dirname, { 'mode' => 0300 } );

        ok( -d $base_dir->path(), "$dirname exists" );
        ok( -d $dirname,          "$dirname exists" );

        my $def_perms = sprintf '%04o', ( ( stat $base_dir->path() )[2] ^ umask ) & 07777;
        my $new_perms = sprintf '%04o', ( ( stat $dirname )[2] ^ umask ) & 07777;

        # make sure we're not getting fooled by the default permissions
        isnt( $def_perms, $new_perms, "We picked perms ($new_perms) that are not the default ($def_perms)" );

        is(
            $new_perms,
            '0300',
            'Mode was set correctly',
        );

        is(
            $dir->contents(),
            [qw< . .. >],
            "Correct contents to $dirname",
        );

        test_content_with_keywords( $dirname, [qw< . .. >] );
    }
);

subtest(
    'Scenario 3: ->new_dir() after mkdir() has an error' => sub {
        my $dirname = $get_dirname->();
        my $dir     = Test::MockFile->new_dir($dirname);

        ok( -d $dirname,      "$dirname exists" );
        ok( !mkdir($dirname), "mkdir $dirname fails, since dir already exists" );
        isnt( $! + 0, 0, "\$! is set to an error: " . ( $! + 0 ) . " ($!)" );

        is(
            $dir->contents(),
            [qw< . .. >],
            "Correct contents to $dirname",
        );

        test_content_with_keywords( $dirname, [qw< . .. >] );
    }
);

done_testing();
