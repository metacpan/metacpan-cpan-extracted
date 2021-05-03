package WebService::Solr::Tiny 0.002;

use v5.20;
use warnings;
use experimental qw/lexical_subs postderef signatures/;

use Exporter 'import';
use URI::Query::FromHash 0.003;

our @EXPORT_OK = qw/solr_escape solr_query/;

sub new ( $class, %args ) {
    my $self = bless \%args, $class;

    $self->{agent}        //=
        do { require HTTP::Tiny; HTTP::Tiny->new( keep_alive => 1 ) };
    $self->{decoder}      //=
        do { require JSON::PP; \&JSON::PP::decode_json };
    $self->{default_args} //= {};
    $self->{url}          //= 'http://localhost:8983/solr/select';

    $self;
}

sub search ( $self, $q = '', %args ) {
    my $reply = $self->{agent}->get( $self->{url} . '?' .
        hash2query { $self->{default_args}->%*, q => $q, %args } );

    unless ( $reply->{success} ) {
        require Carp;

        Carp::croak("Solr request failed - $reply->{content}");
    }

    $self->{decoder}( $reply->{content} );
}

sub solr_escape ( $q ) { $q =~ s/([\Q+-&|!(){}[]^"~*?:\\\E])/\\$1/gr }

# For solr_query
my ( %struct, %value, %op );
sub solr_query ( $x ) { $struct{ARRAY}->( ref $x eq 'ARRAY' ? $x : [ $x ] ) }

my sub dispatch ( $table, $name, @args ) {
    ( $table->{$name} // die "Cannot dispatch to $name" )->(@args);
}

my sub pair ( $k, $v ) {
    # If it's an array ref, the first element MAY be an operator:
    #   [ -and => { -require => 'X' }, { -require => 'Y' } ]
    if ( ref $v eq 'ARRAY' && ( $v->[0] // '' ) =~ /^-(AND|OR)$/i ) {
        my ( $op, undef, @val ) = ( uc $1, @$v );
        return sprintf '(%s)',
            join " $op ", map '(' . $struct{HASH}->({ $k => $_ }) . ')', @val;
    }

    dispatch( \%value, ref $v || 'SCALAR', $k, $v );
}

$struct{HASH} = sub( $x ) {
    join ' AND ', map {
        /^-(.+)/ ? dispatch( \%op, $1, $x->{$_} ) : pair( $_, $x->{$_} )
    } sort keys %$x;
};

$struct{ARRAY} = sub ( $x ) {
    '(' . join( ' OR ', map dispatch( \%struct, ref $_, $_ ), @$x ) . ')';
};

$value{SCALAR} = sub ( $k, $v ) {
    my $value = ref $v ? $$v : ( '"' . solr_escape($v) . '"' );
    "$k:$value" =~ s/^://r;
};

$value{HASH} = sub ( $k, $v ) {
    join ' AND ',
        map dispatch( \%op, s/^-(.+)/$1/r, $k, $v->{$_} ), sort keys %$v;
};

$value{ARRAY} = sub ( $k, $v ) {
    '(' . join( ' OR ', map $value{SCALAR}->( $k, $_ ), @$v ) . ')';
};

$op{default}   = sub (     $v ) { pair( '', $v ) };
$op{require}   = sub ( $k, $v ) { qq(+$k:") . solr_escape($v) . '"' };
$op{prohibit}  = sub ( $k, $v ) { qq(-$k:") . solr_escape($v) . '"' };
$op{range}     = sub ( $k, $v ) { "$k:[$v->[ 0 ] TO $v->[ 1 ]]" };
$op{range_exc} = sub ( $k, $v ) { "$k:{$v->[ 0 ] TO $v->[ 1 ]}" };
$op{range_inc} = $op{range};

$op{boost} = sub ( $k, $extra ) {
    my ( $v, $boost ) = @$extra;
    sprintf '%s:"%s"^%s', $k, solr_escape($v), $boost;
};

$op{fuzzy} = sub ( $k, $extra ) {
    my ( $v, $dist ) = @$extra;
    sprintf '%s:%s~%s', $k, solr_escape($v), $dist;
};

$op{proximity} = sub ( $k, $extra ) {
    my ( $v, $dist ) = @$extra;
    sprintf '%s:"%s"~%s', $k, solr_escape($v), $dist;
};

no URI::Query::FromHash;

1;
