package Weather::NHC::TropicalCyclone;

use strict;
use warnings;
use HTTP::Tiny ();
use HTTP::Status qw/:constants/;
use JSON::XS                             ();
use Weather::NHC::TropicalCyclone::Storm ();

our $DEFAULT_URL     = q{https://www.nhc.noaa.gov/CurrentStorms.json};
our $DEFAULT_TIMEOUT = 10;

# container class for requesting JSON and providing
# iterator access and meta operations for the storms
# contained in the JSON returned by NHC

sub new {
    my $pkg  = shift;
    my $self = {
        _obj => undef,
    };
    bless $self, $pkg;
    return $self;
}

sub fetch {
    my ( $self, $timeout ) = @_;
    my $http = HTTP::Tiny->new();

    local $SIG{ALRM} = sub { die "Request has timed out.\n" };

    alarm( $timeout // $DEFAULT_TIMEOUT );

    # get content via $DEFAULT_URL unless --file option is passed
    local $@;
    my $response = eval { $http->get($DEFAULT_URL) };
    if ( $@ or not $response or $response->{status} ne HTTP_OK ) {
        die qq{request error\n};
    }

    alarm 0;

    my $content = $response->{content};

    my $ref = eval { JSON::XS::decode_json $content };

    if ( $@ or not $ref ) {
        die qq{JSON decode error\n};
    }

    $self->{_obj} = $ref;

    return $self;
}

sub active_storms {
    my $self = shift;

    my @storms = ();

    for my $storm ( @{ $self->{_obj}->{activeStorms} } ) {
        my $s = Weather::NHC::TropicalCyclone::Storm->new($storm);
        push @storms, $s;
    }

    return \@storms;
}

1;

__END__

=head1 NAME

Weather::NHC::TropicalCyclone

=head1 SYNOPSIS

   use strict;
   use warnings;
   use Weather::NHC::TropicalCyclone ();
   
   my $nhc = Weather::NHC::TropicalCyclone->new;
   $nhc->fetch;
   
   my $storms_ref = $nhc->active_storms;
   foreach my $storm (@$storms_ref) {
     print $storm->name . qq{\n};
     my ($text, $advNum, $local_file) = $storm->fetch_publicAdvisory($storm->id.q{.fst});
     print qq{$local_file saved for Advisory $advNum\n};
     print $text;
   } 

=head1 METHODS

=over 3

=item C<new>

Constructor - doesn't do much, but provide a convenient instance for the other
provided methods described below.

=item C<fetch>

Makes an HTTP request to $Weather::NHC::TropicalCyclone::DEFAULT_URL to get
the JSON provided by the NHC describing the current set of active storms.

If the JSON is malformed or otherwise can't be parsed, C<fetch> will throw
an exception.

Fetch will time out after C<$Weather::NHC::TropicalCyclone::DEFAULT_TIMEOUT> by
throwing an exception. In order to disable the alarm, call C<fetch> with a
parameter of 0:

    $nhc->fetch(0); 

=item C<active_storms>

Provides an array reference of C<Weather::NHC::TropicalCyclone::Storm> instances,
one for each active storm. If there are no storms, the array reference returned is
empty (not undef).

Most of the useful functionality related to this JSON data is available through
the methods provided by the C<Weather::NHC::TropicalCyclone::Storm> instances
returned by this method.

=back

=head1 COPYRIGHT and LICENSE

This module is distributed under the same terms as Perl itself.
