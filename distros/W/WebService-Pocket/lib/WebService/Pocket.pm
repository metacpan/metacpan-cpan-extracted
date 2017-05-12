use strict;
use warnings;
package WebService::Pocket;
{
  $WebService::Pocket::VERSION = '0.003';
}
use Data::Dumper;
use Moose;
use HTTP::Tiny;
use JSON;
use Try::Tiny;
use WebService::Pocket::Item;

# ABSTRACT: Client for the Pocket api (http://getpocket.com/api/)

has api_key  => ( is => 'ro', default => '47bT8zN1gyPF2N3f15da822u4bpaE96a' );
has base_url => ( is => 'ro', default => 'https://readitlaterlist.com/v2' );
has username => ( is => 'rw', isa => 'Str' );
has password => ( is => 'rw', isa => 'Str' );
has ua => ( is => 'ro', default => sub { HTTP::Tiny->new } );
has json => ( is => 'ro', default => sub { JSON->new->canonical } );
has items => ( is => 'ro', default => sub { {} } );

has list_since => ( is => 'rw', default => undef );

sub BUILD {
    my ( $self ) = @_;
    # Validate credentials
    try { $self->_auth } catch { die "Bad Credentials! $_"; };
};

sub add {
    my ( $self, $items ) = @_;
    die "Need Items to add!" unless $items;
    $items = [ $items ] if ref $items eq 'HASH';
    die "Need HashRef or ArrayRef for items" unless ref $items eq 'ARRAY';

    my $params = {};
    $params->{$_} = $items->[$_] for ( 0 .. @$items - 1 );
    $params = { new => $self->json->encode( $params ) };

    $self->_send( $params );

    # Get the new items
    my $all_items = $self->list;
    return [ splice @$all_items, 0, @$items ];
}

sub list {
    my ( $self, %args ) = @_;
    $args{since} = $self->list_since if $self->list_since;
    $self->list_since( time );
    my $res = $self->_make_request( GET => '/get', \%args );

    $res = $self->json->decode( $res->{content} );

    # Crappy API, they return a HASHREF if there's data
    # but an empty ARRAYREF if there's no data
    $res->{list} = {} if ref $res->{list} eq 'ARRAY';

    # Only update those that have changed
    while ( my ($key, $val) = each %{$res->{list}} ) {
        $self->items->{ $key } = $val;
    } 

    # Sort by time_updated *grumble grumble* crappy API
    my @list = values %{ $self->items };
    @list = sort { $b->{time_updated} <=> $a->{time_updated} } @list;

    my $reval = [];
    push @$reval, WebService::Pocket::Item->new( pocket => $self, %$_ )
        for @list;
    return $reval;
}

sub stats {
    my ( $self ) = @_;
    my $res = $self->_make_request( GET => '/stats' );
    my $data = $self->json->decode( $res->{content} );
    WebService::Pocket::Stats->new( %$data );
}


sub _auth { $_[0]->_make_request( GET => '/auth' ); }

sub _send {
    my ( $self, $params ) = @_;
    $self->_make_request( GET => '/send', $params );
}

sub _make_request {
    my ( $self, $method, $path, $params ) = @_;
    my $url = $self->base_url . $path;
    $method = lc( $method );
    $params //= {};
    $params->{username} = $self->username;
    $params->{password} = $self->password;
    $params->{apikey}   = $self->api_key;

    $params = $self->ua->www_form_urlencode( $params );

    my $res = $self->ua->$method( "$url?$params" );
    die "Failed on request: $url" unless $res->{success};
    return $res;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Pocket - Client for the Pocket api (http://getpocket.com/api/)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::Pocket;

    my $p = WebService::Pocket->new(
        username => 'throughnothing',
        password => 'secret',
    );

    # Get list of read items as Array of WebService::Pocket::Item objects
    my $items = $p->list( state => 'read' );

    # Add an item
    $p->add({ url => 'http://www.article.com', title => 'My Title' });

    # Add multiple items, returns Array of WebService::Pocket::Item objects
    my $new_items = $p->add([
        { url => 'http://www.article.com' },
        { url => 'http://www.article1.com', title => 'Article1' },
        { url => 'http://www.article2.com', title => 'Best Article' },
    ]);

    # Get Titles and URL's for new items
    for ( @$new_items ) {
        say $_->title . " : " . $_->url;
    }

    # Update read status of an item
    $items->[0]->state( 0 );

    # Update title of an item
    $items->[0]->title( 'New Title' );

    # Update tags of an item ( replaces all tags with these )
    $items->[0]->tags( [ 'tag1', 'tag2', 'tag3' ] );

=head1 DESCRIPTION

This distribution provides an easy interface to the
L<Pocket API|http://getpocket.com/api/>.  It allows you to add, view and modify
your list of items in a very simple way.

=head1 METHODS

=head2 new

The constructor accepts a C<username> and C<password> and validates
your credentials with the L<Pocket API|http://getpocket.com/api/>:

    my $p = WebService::Pocket->new(
        username => 'throughnothing',
        password => 'myS3cr3t',
    );

=head2 add

Allows you to add items to your C<Pocket> list.  You can add a single item
via a simple HashRef:

    my ( $new_item ) = $p->add( { url => 'http://youtube.com/video' } );

Or multiple items via an ArrayRef:

    my $new_items = $p->add([
        { url => 'http://youtube.com/video', title => 'video 1' },
        { url => 'http://youtube.com/video2', title => 'video 2' },
    ]);

Note that only the C<url> field is required for each added item, but you
can set the C<title> as well if you like. The C<add> function will always
return an ArrayRef of L<WebService::Pocket::Item> objects if it succeeded.

=head2 list

Allows you to retrieve the list of items in your C<Pocket> account.  Returns
a list of L<WebService::Pocket::Item> objects.

    my $items = $p->list;

You can pass in any parameters available to the
L<Pocket API Get|http://getpocket.com/api/docs/#get> request.

    # Get only read items, with tags
    $p->list( state = 0, tags => 1 );

    # Get only the first 5 resutls
    $p->list( count => 5, page => 1 );

=head2 stats

Stats will return a L<WebService::Pocket::Stats> object, which contains
a few statistics about your C<Pocket> account.

    # Get the stats object
    my $stats = $p->stats;

    # How long i've been a user
    say $stats->user_since;

    # How many items in my list total
    say $stats->count_list;

    # How many unread items in my list
    say $stats->count_unread;

    # How many read items in my list
    say $stats->count_read;

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=head1 CONTRIBUTORS

=over 4

=item *

Andreas Marienborg <andreas.marienborg@gmail.com>

=item *

Paul Fenwick <pjf@perltraining.com.au>

=item *

ben hengst <notbenh@cpan.org>

=back

=cut
