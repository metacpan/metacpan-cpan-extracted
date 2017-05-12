
package WebService::Pinterest::Pager;
$WebService::Pinterest::Pager::VERSION = '0.1';
use Moose;

has api => (
    is       => 'ro',
    isa      => 'WebService::Pinterest',
    required => 1,
);

has call => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has total => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_total => 'inc',
    },
);

# Internal state

has active => ( is => 'rw', default => 1 );

has next_request => ( is => 'rw', );

sub BUILD {
    my $self = shift;

    # First request
    my $req = $self->api->_build_request( @{ $self->call } );    # throws
    $self->next_request($req);
}

sub next {
    my $self = shift;

    return undef unless $self->active;

    my $req = $self->next_request;
    return !1 unless defined $req;

    $self->inc_total;
    my $res = $self->api->_call($req);

    if ( exists $res->{page} ) {
        if ( defined $res->{page}{next} ) {
            my $next_url = $res->{page}{next};
            my $next_req = self->api->_build_next_request($next_url);
            $self->next_request($next_req);
        }
        elsif ( exists $res->{data} && scalar @{ $res->{data} } == 0 )
        {    # It is over
            $self->next_request(undef);
            return !1;
        }
        else {    # That was the last page
            $self->next_request(undef);
        }
        return $res;

    }

    # On error
    $self->active( !1 );
    return undef;

}

1;
