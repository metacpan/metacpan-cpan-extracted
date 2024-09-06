#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use WebSocket::Request;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'WebSocket::Version' ) || BAIL_OUT( "Unable to load WebSocket::Version" );
    use_ok( 'WebSocket::Request' ) || BAIL_OUT( "Unable to load WebSocket::Request" );
}
use warnings qw( WebSocket::Version );

my $v = WebSocket::Version->new(13, debug => $DEBUG );
# To generate this list:
# egrep -E '^sub ' ./lib/WebSocket/Version.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$s, \x27$m\x27 );"'

subtest 'methods' => sub
{
    can_ok( $v, 'init' );
    can_ok( $v, 'as_string' );
    can_ok( $v, 'draft' );
    can_ok( $v, 'expires' );
    can_ok( $v, 'get_dictionary' );
    can_ok( $v, 'issued' );
    can_ok( $v, 'new_from_request' );
    can_ok( $v, 'next' );
    can_ok( $v, 'numify' );
    can_ok( $v, 'prev' );
    can_ok( $v, 'previous' );
    can_ok( $v, 'revision' );
    can_ok( $v, 'serial' );
    can_ok( $v, 'status' );
    can_ok( $v, 'type' );
    can_ok( $v, 'version' );
};

is( "$v", 13, 'stringify' );
is( $v->as_string, 13, 'as_string' );
is( $v->draft, 'draft-ietf-hybi-17', 'draft' );
isa_ok( $v->draft, 'Module::Generic::Scalar', 'draft returns scalar object' );
is( $v->expires, '2012-04-02', 'expires' );
isa_ok( $v->expires, 'DateTime', 'expires returns a DateTime object' );
is( $v->issued, '2011-09-30', 'issued' );
my $exp = $v->expires;
diag( "expires returns -> ", overload::StrVal( $exp ) ) if( $DEBUG );
isa_ok( $v->issued, 'DateTime', 'issued returns a DateTime object' );
is( $v->next, undef, 'no next' );
my $draft16 = $v->prev;
is( "$draft16", 13, 'previous draft' );
isa_ok( $draft16, 'WebSocket::Version', 'prev returns an WebSocket::Version object' );
isa_ok( $v->numify, 'Module::Generic::Number', 'numify returns a Module::Generic::Number object' );
is( $v->revision, 17, 'revision' );
is( $v->serial, 17, 'serial' );
isa_ok( $v->serial, 'Module::Generic::Number', 'serial returns a Module::Generic::Number object' );
is( $v->status, 'draft', 'status' );
is( $v->type, 'hybi', 'type' );
is( $v->version, 13, 'version' );
isa_ok( $v->version, 'Module::Generic::Number', 'version returns a Module::Generic::Number object' );

subtest 'operations' => sub
{
    TRY:
    {
        # Returns draft version 12, because it is the latest version using the protocol version 8
        my $draft12 = WebSocket::Version->new(8, debug => $DEBUG);
        diag( "Cannot find data for draft version 12: ", WebSocket::Version->error ) if( !defined( $draft12 ) || $DEBUG );
    
        my $d16 = $v - 1;
        isa_ok( $d16, 'WebSocket::Version', 'substraction' );
        if( !defined( $d16 ) )
        {
            skip( 'substraction failed', 1 );
        }
        ok( $d16 == $draft16, 'substraction return value' );
    
        my $d13 = $draft12 + 1;
        isa_ok( $d13, 'WebSocket::Version', 'addition' );
        if( !defined( $d13 ) )
        {
            skip( 'addition failed', 1 );
        }
        is( $d13->version, 13, 'addition return value' );
    
        # Draft 24: no such draft. Will return undef
        my $d14 = $draft12 * 2;
        is( $d14, undef, 'multiply out of bound' );
        my $d5 = WebSocket::Version->new(5, debug => $DEBUG);
        diag( "Cannot find data for draft version 5: ", WebSocket::Version->error ) if( !defined( $d5 ) || $DEBUG );
        isa_ok( $d5, 'WebSocket::Version' );
        my $d15 = $d5 * 3;
        isa_ok( $d15, 'WebSocket::Version', 'muliplication' );
        if( !defined( $d15 ) )
        {
            skip( 'muliplication failed', 1 );
        }
        is( $d15->version, 13, 'muliplication return value' );
    
        my $d8 = $v / 2;
        is( $d8, undef, 'division returns undef' );
        $d8 = $v->prev / 2;
        isa_ok( $d8, 'WebSocket::Version', '/' );
        if( !defined( $d8 ) )
        {
            skip( 'division failed', 1 );
        }
        is( $d8->version, 8, '/' );
    
        is( $v % 2, 1, '%' );
    
        ok( $draft12 < $v, '<' );
        ok( $d15 <= $v, '<=' );
        ok( $v > $d15, '>' );
        ok( $v >= $d16, '>=' );
        is( $d15 <=> $v, -1, '<=>' );
        my $v2 = $v->clone;
        is( $v <=> $v2, 0, '<=>' );
        is( $v <=> $d15, 1, '<=>' );
        ok( $v2 == $v, '==' );
        ok( $v != $d15, '!=' );
        ok( $v eq $v2, 'eq' );
        ok( $v ne $d15, 'ne' );
    };
};

subtest 'new_from_request' => sub
{
    my $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'Sec-WebSocket-Key'         => 'dGhlIHNhbXBsZSBub25jZQ',
        'Sec-WebSocket-Origin'      => 'https://example.com',
        'Sec-WebSocket-Protocol'    => 'chat, superchat',
        'Sec-WebSocket-Version'     => 4,
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    diag( "WebSocket::Request object is -> ", $req->as_string ) if( $DEBUG );
    my $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && $DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, 4, 'new_from_request -> version (4)' );

    # Intentionally missing the 'Sec-WebSocket-Version' header
    $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'Sec-WebSocket-Key'         => 'dGhlIHNhbXBsZSBub25jZQ',
        'Sec-WebSocket-Origin'      => 'https://example.com',
        'Sec-WebSocket-Protocol'    => 'chat, superchat',
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && $DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, 8, 'new_from_request -> version (8)' );
    
    # Intentionally missing the 'Sec-WebSocket-Version' and 'Sec-WebSocket-Origin' header
    $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'Sec-WebSocket-Key'         => 'dGhlIHNhbXBsZSBub25jZQ',
        'Sec-WebSocket-Protocol'    => 'chat, superchat',
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && $DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, 13, 'new_from_request -> version (13)' );

    # Using draft version 2 and 3 header 'Sec-WebSocket-Draft'
    $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'Sec-WebSocket-Key1'        => '4 @1  46546xW%0l 1 5',
        'Sec-WebSocket-Key2'        => '12998 5 Y3 1  .P00',
        'Sec-WebSocket-Protocol'    => 'chat, superchat',
        'Origin'                    => 'https://example.com',
        'Sec-WebSocket-Draft'       => 2,
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && $DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, 2, 'new_from_request -> version (2)' );

    # Using header 'Sec-WebSocket-Key1'
    $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'Sec-WebSocket-Key1'        => '4 @1  46546xW%0l 1 5',
        'Sec-WebSocket-Key2'        => '12998 5 Y3 1  .P00',
        'Sec-WebSocket-Protocol'    => 'chat, superchat',
        'Origin'                    => 'https://example.com',
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && $DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, 2, 'new_from_request -> version (2)' );

    # Another one missing most of those headers
    $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'Sec-WebSocket-Protocol'    => 'chat, superchat',
        'Sec-WebSocket-Origin'      => 'https://example.com',
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && $DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, undef, 'new_from_request -> no version' );
    is( $ver->revision, 76, 'new_from_request -> revision (76)' );
    is( $ver->status, 'obsolete', 'version is obsolete' );

    # Another one missing most of those headers
    $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'WebSocket-Protocol'        => 'chat, superchat',
        'Origin'                    => 'https://example.com',
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && $DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, undef, 'new_from_request -> no version' );
    is( $ver->revision, 75, 'new_from_request -> revision (75)' );

    # Bare bones headers
    $req = WebSocket::Request->new([
        'Upgrade'                   => 'websocket',
        'Connection'                => 'Upgrade',
        'Origin'                    => 'https://example.com',
        ],
        host => 'example.com',
        uri => 'ws://example.com/chat?csrf_token=7a292e44341dc0a052d717980563fa4528dc254bc80f3e735303ed710b764143.1631279571',
        debug => $DEBUG,
    ) || BAIL_OUT( "Failed to get a WebSocket::Request object: " . WebSocket::Request->error );
    $ver = WebSocket::Version->new_from_request( $req, debug => $DEBUG );
    diag( "Error with WebSocket::Version->new_from_request: ", WebSocket::Version->error ) if( !defined( $ver ) && !$DEBUG );
    isa_ok( $ver, 'WebSocket::Version', 'new_from_request' );
    is( $ver->version, undef, 'new_from_request -> no version' );
    is( $ver->revision, 7, 'new_from_request -> revision (7)' );
};

done_testing();

__END__
