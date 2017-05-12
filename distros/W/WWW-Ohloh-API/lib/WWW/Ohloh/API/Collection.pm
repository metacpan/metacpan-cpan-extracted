package WWW::Ohloh::API::Collection;

use strict;
use warnings;

use Object::InsideOut;
use Carp;

our $VERSION = '0.3.2';

use overload '<>' => \&next;

my @cache_of : Field;
my @total_entries_of : Field : Default(-1);
my @page_of : Field;
my @max_entries_of : Field : Arg(max) : Get(max) : Default(undef);
my @element_of : Field : Arg(element) : Get(element);
my @sort_order_of : Field : Arg(sort);
my @query_of : Field : Arg(query);
my @ohloh_of : Field : Arg( name => 'ohloh', mandatory => 1);
my @read_so_far : Field : Get(get_read_so_far) : Set(set_read_so_far) :
  Default(0);
my @all_read : Field;

sub _init : Init {
    my $self = shift;

    $cache_of[$$self] = [];    # initialize to empty array
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub total_entries {
    my $self = shift;

    # if not initialized, get a first bunch of entries
    if ( $total_entries_of[$$self] == -1 ) {
        $self->_gather_more;
    }

    return $total_entries_of[$$self];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub next {
    my $self = shift;
    my $nbr_requested = shift || 1;

    while ( @{ $cache_of[$$self] } < $nbr_requested
        and not $all_read[$$self] ) {
        $self->_gather_more;
    }

    my @bunch = splice @{ $cache_of[$$self] }, 0, $nbr_requested;

    if (@bunch) {
        return wantarray ? @bunch : $bunch[0];
    }

    # we've nothing else to return

    $page_of[$$self]  = 0;
    $all_read[$$self] = 0;

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _gather_more {
    my $self = shift;

    my ( $url, $xml ) = $ohloh_of[$$self]->_query_server(
        $self->query_path,
        {   ( query => $query_of[$$self] ) x !!$query_of[$$self],
            ( sort => $sort_order_of[$$self] ) x !!$sort_order_of[$$self],
            page => ++$page_of[$$self] } );

    my $class = $self->element;
    my @new_batch =
      map { $class->new( ohloh => $ohloh_of[$$self], xml => $_, ) }
      $xml->findnodes( $self->element_name );

    if ( defined( $self->max )
        and $self->get_read_so_far + @new_batch > $self->max ) {
        @new_batch =
          @new_batch[ 0 .. $self->max - $self->get_read_so_far - 1 ];
        $all_read[$$self] = 1;
    }

    $read_so_far[$$self] += @new_batch;

    if ( @new_batch == 0 ) {
        $all_read[$$self] = 1;
    }

    # get total elements + where we are  (but don't trust it)

    $total_entries_of[$$self] =
      $xml->findvalue('/response/items_available/text()');

    my $first_item = $xml->findvalue('/response/first_item_position/text()');

    push @{ $cache_of[$$self] }, @new_batch;

    $all_read[$$self] = 1 if $self->total_entries == $self->get_read_so_far;

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub all {
    my $self = shift;

    $self->_gather_more until ( $all_read[$$self] );

    my @bunch = @{ $cache_of[$$self] };
    $cache_of[$$self] = [];

    $page_of[$$self]  = 0;
    $all_read[$$self] = 0;

    return @bunch;
}

1;
