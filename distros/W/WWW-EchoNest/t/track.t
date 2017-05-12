#!/usr/bin/perl -T

use 5.010;
use strict;
use warnings;
use Carp;

use Test::More 'no_plan';

BEGIN {
    use_ok( 'WWW::EchoNest',              qw[ get_track                      ] );
    use_ok( 'WWW::EchoNest::Track',       qw[ :all                           ] );
    use_ok( 'WWW::EchoNest::ConfigData'                                        );
}

my $codegen_found    = WWW::EchoNest::ConfigData->feature('codegen_found');
my $test_filename    = WWW::EchoNest::ConfigData->feature('test_file');
my($ext)             = ($test_filename =~ m[^.*\.(\w+)$]);
my $test_url         = WWW::EchoNest::ConfigData->feature('test_url');

########################################################################
#
# Skippage
# - Each of the tests in this script can take a good bit of time, so I
#   needed a way of programmatically skipping them while I was coding.
#
my $skip_track_from_file               = 0;
my $skip_track_from_url                = 0;
my $skip_track_from_id                 = 0;
my $skip_track_from_md5                = 0;
my $skip_track_from_reanalyzing_id     = 0;
my $skip_track_from_reanalyzing_md5    = 0;



########################################################################
#
# track_from_file
#
# - This subroutine accepts one argument, which can be a path to an audio file,
#   a filehandle, or an instance of IO::File.
#
SKIP : {
    skip 'Because', 2 if $skip_track_from_file;

    # Pass a filename
    my $track_from_filename = track_from_file( $test_filename );
    ok( defined($track_from_filename), '$track_from_filename is defined' );
    isa_ok( $track_from_filename, 'WWW::EchoNest::Track' );
};

SKIP : {
    skip "Because", 2 if $skip_track_from_file;

    # Pass a filehandle
    open ( my $FH, '<', $test_filename )
        or die 'Could not open $test_filename: $!';
    # We have to parse the filetype when we're not passing the filename :(
    my $track_from_fh = track_from_file( $FH, $ext );
    ok( defined($track_from_fh), '$track_from_fh is defined' );
    isa_ok( $track_from_fh, 'WWW::EchoNest::Track' );
    close( $FH );
};

SKIP : {
    skip "Because", 2 if $skip_track_from_file;

    # Pass an instance of IO::File
    use IO::File;
    my $iof= IO::File->new();
    $iof->open( $test_filename, '<' )
        or die qq[Could not open $test_filename: $!];
    # We have to parse the filetype when we're not passing the filename :(
    my $track_from_iof = track_from_file( $iof, $ext );
    ok( defined($track_from_iof), '$track_from_iof is defined' );
    isa_ok( $track_from_iof, 'WWW::EchoNest::Track' );
    $iof->close();
};

########################################################################
#
# track_from_url
#
# - This subroutine accepts one argument: a url that points to an audio file
#   publicly accessible via HTTP.
#
SKIP : {
    skip 'Because', 2 if $skip_track_from_url;

    my $track_from_url = track_from_url( $test_url );
    ok( defined($track_from_url), '$track_from_url is defined' );
    isa_ok( $track_from_url, 'WWW::EchoNest::Track' );
};


########################################################################
#
# track_from_id
#
# - This subroutine accepts one argument: a url that points to an audio file
#   publicly accessible via HTTP.
#

SKIP : {
    skip 'Because', 2 if $skip_track_from_url;

    my $wjoojoo_id       = 'TRWERWS1314D810635';
    my $track_from_id1   = track_from_id( $wjoojoo_id );
    ok( defined($track_from_id1), '$track_from_id1 is defined' );
    isa_ok( $track_from_id1, 'WWW::EchoNest::Track' );
};


########################################################################
#
# track_from_md5
#
# - This subroutine accepts one argument: a url that points to an audio file
#

SKIP : {
    skip 'Because', 2 if $skip_track_from_md5;

    my $wjoojoo_md5       = '68fc61663fe5c833684d72885aad854e';
    my $track_from_md51   = track_from_md5( $wjoojoo_md5 );
    ok( defined($track_from_md51), '$track_from_md51 is defined' );
    isa_ok( $track_from_md51, 'WWW::EchoNest::Track' );
};


########################################################################
#
# track_from_md5
#
# - This subroutine accepts one argument: a url that points to an audio file
#

SKIP : {
    skip 'Because', 2 if $skip_track_from_reanalyzing_id;

    my $wjoojoo_id           = 'TRWERWS1314D810635';
    my $track_from_re_id1    = track_from_reanalyzing_id( $wjoojoo_id );
    ok( defined($track_from_re_id1), '$track_from_re_id1 is defined' );
    isa_ok( $track_from_re_id1, 'WWW::EchoNest::Track' );
};


########################################################################
#
# track_from_md5
#
# - This subroutine accepts one argument: a url that points to an audio file
#

SKIP : {
    skip 'Because', 2 if $skip_track_from_reanalyzing_md5;

    my $wjoojoo_md5       = '68fc61663fe5c833684d72885aad854e';
    my $track_from_re_md51   = track_from_reanalyzing_md5( $wjoojoo_md5 );
    ok( defined($track_from_re_md51), '$track_from_re_md51 is defined' );
    isa_ok( $track_from_re_md51, 'WWW::EchoNest::Track' );
};
