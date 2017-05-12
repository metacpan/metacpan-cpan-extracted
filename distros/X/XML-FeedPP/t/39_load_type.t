# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 6;
    BEGIN { use_ok('XML::FeedPP') };
# ----------------------------------------------------------------
{
    local $@;
    my $source = '<dummy></dummy>';
    eval { XML::FeedPP->new( $source ); };
    like( $@, qr/Invalid feed source/, 'Invalid XML auto' );
}
{
    local $@;
    my $source = 'dummy string';
    eval { XML::FeedPP->new( $source ); };
    like( $@, qr/Invalid feed source/, 'Invalid string auto' );
}
{
    local $@;
    my $source = '<dummy></dummy>';
    eval { XML::FeedPP->new( $source, -type => 'string' ); };
    like( $@, qr/Invalid feed format/, 'Invalid XML type' );
}
{
    local $@;
    my $source = 'dummy string';
    eval { XML::FeedPP->new( $source, -type => 'string' ); };
    like( $@, qr/Loading failed/, 'Invalid string type' );
}
{
    local $@;
    my $source = 'dummy filename';
    eval { XML::FeedPP->new( $source, -type => 'file' ); };
#   like( $@, qr/No such file or directory/, 'Invalid filename' );
    ok( $@, 'Invalid filename' );
}
# ----------------------------------------------------------------
