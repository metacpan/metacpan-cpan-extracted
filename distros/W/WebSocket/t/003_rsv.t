#!/usr/bin/env perl
BEGIN
{
    use FindBin qw($Bin);
    use lib "$Bin/../lib";
    use lib "$Bin/../t";
    use vars qw( $DEBUG );
    use strict;
    use warnings;
    use utf8;
    use Test::More;
    use Encode;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use_ok( 'WebSocket::Frame' );

my $f = WebSocket::Frame->new(
    buffer => '☺',
    rsv    => [0, 0, 0],
    debug  => $DEBUG,
);
is( substr( $f->to_bytes, 0, 1 ) => "\x81" );

$f = WebSocket::Frame->new(
    buffer => '☺',
    rsv    => [0, 0, 1],
    debug  => $DEBUG,
);
is( substr( $f->to_bytes, 0, 1 ) => "\x91" );

$f = WebSocket::Frame->new(
    buffer => '☺',
    rsv    => [0, 1, 0],
    debug  => $DEBUG,
);
is( substr( $f->to_bytes, 0, 1 ) => "\xa1" );

$f = WebSocket::Frame->new(
    buffer => '☺',
    rsv    => [1, 0, 0],
    debug  => $DEBUG,
);
is( substr( $f->to_bytes, 0, 1 ) => "\xc1" );

$f = WebSocket::Frame->new(
    buffer => '☺',
    rsv    => [1, 0, 1],
    debug  => $DEBUG,
);
is( substr( $f->to_bytes, 0, 1 ) => "\xd1" );

$f = WebSocket::Frame->new(
    buffer => '☺',
    rsv    => [1, 1, 0],
    debug  => $DEBUG,
);
is( substr( $f->to_bytes, 0, 1 ) => "\xe1" );

$f = WebSocket::Frame->new(
    buffer => '☺',
    rsv    => [1, 1, 1],
    debug  => $DEBUG,
);
is( substr( $f->to_bytes, 0, 1 ) => "\xf1" );

done_testing();

__END__

