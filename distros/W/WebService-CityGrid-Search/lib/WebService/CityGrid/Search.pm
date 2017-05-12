package WebService::CityGrid::Search;

use strict;
use warnings;

=head1 NAME

WebService::CityGrid::Search - Interface to the CityGrid Search API

=cut

use Any::Moose;
use Any::URI::Escape;
use XML::LibXML;
use LWP::UserAgent;

has 'api_key'   => ( is => 'ro', isa => 'Str', required => 1 );
has 'publisher' => ( is => 'ro', isa => 'Str', required => 1 );

use constant DEBUG => $ENV{CG_DEBUG} || 0;

our $api_host = 'api2.citysearch.com';
our $api_base = "http://$api_host/search/";
our $VERSION  = 0.04;

our $Ua = LWP::UserAgent->new( agent => join( '_', __PACKAGE__, $VERSION ) );
our $Parser = XML::LibXML->new;

=head1 METHODS

=over 4

=item query

  $res = $cs->query({
      mode => 'locations', 
      where => '90210',
      what  => 'pizza%20and%20burgers', });

Queries the web service.  Dies if the http request fails, so eval it!

=cut

sub query {
    my ( $self, $args ) = @_;

    die "key mode missing, can be locations or events"
      unless ( defined $args->{mode} && ( $args->{mode} eq 'locations' )
        or ( $args->{mode} eq 'events' ) );

    my $url =
        $api_base
      . $args->{mode}
      . '?api_key='
      . $self->api_key
      . '&publisher='
      . $self->publisher . '&';
    delete $args->{mode};

    for (qw( what where )) {
        die "missing required arg $_" unless defined $_;
    }

    foreach my $arg ( keys %{$args} ) {

        die "invalid key $arg" unless grep { $arg eq $_ } qw( type what tag
              chain event first feature where lat lon radius from to page rpp
              sort publisher api_key placement format callback );

        $url .= join( '=', $arg, $args->{$arg} ) . '&';
    }
    $url = substr( $url, 0, length($url) - 1 );

    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get($url);

    die "query for $url failed!" unless $res->is_success;

    my $dom = $Parser->load_xml( string => $res->decoded_content );
    my @locations = $dom->documentElement->getElementsByTagName('location');

    my @results;
    foreach my $loc (@locations) {

        warn("raw location: " . $loc->toString) if DEBUG;
        my $name = $loc->getElementsByTagName('name')->[0]->firstChild->data;
        my $tagline = $loc->getElementsByTagName('tagline')->[0];
        my $img = $loc->getElementsByTagName('image')->[0];
        my $nbh = $loc->getElementsByTagName('neighborhood')->[0];
        my $sc = $loc->getElementsByTagName('samplecategories')->[0];
        my %res_args        = (
            id   => $loc->getAttribute('id'),
            name => $loc->getElementsByTagName('name')->[0]->firstChild->data,
            profile =>
              $loc->getElementsByTagName('profile')->[0]->firstChild->data,

          );

        if ($sc && $sc->firstChild) {
            $res_args{samplecategories} = $sc->firstChild->data;
        }

        if ($nbh && $nbh->firstChild) {
            $res_args{neighborhood} = $nbh->firstChild->data;
        }

        if ($img) {
            $res_args{image} = $img->firstChild->data;
        }

        if ($tagline) {
            $res_args{tagline} = $tagline->firstChild->data;
        }
        my $result = WebService::CityGrid::Search::Result->new(%res_args);

        push @results, $result;
    }

    return \@results;
}

=item javascript_tracker

Under construction

=back

=cut

sub javascript_tracker {
    my $self = shift;

    return <<END;
<script type=”text/javascript”>
    var _csv = {};
        _csv['action_target'] = '***'; 
        _csv['listing_id'] = '***'; 
        _csv['publisher'] = '***'; 
        _csv['reference_id'] = '***'; 
        _csv['placement'] = '***';
        _csv['mobile_type'] = '***';
        _csv['muid'] = '***';
        _csv['ua'] = '***'
</script>
<script type="text/javascript" src="http://images.citysearch.net/assets/pfp/scripts/tracker.js">/script>

<noscript>
<img src='http://api.citysearch.com/tracker/imp?action_target=***&listing_id=***&publisher=***&reference_id=***&placement=***&mobile_type=***&muid=***&ua=***' width='1' height='1' alt='' />
</noscript>
END
}

__PACKAGE__->meta->make_immutable;

package WebService::CityGrid::Search::Result;

use Any::Moose;

has 'id'      => ( is => 'ro', isa => 'Int', required => 1 );
has 'name'    => ( is => 'ro', isa => 'Str', required => 1 );
has 'tagline' => ( is => 'ro', isa => 'Str', required => 0 );
has 'profile' => ( is => 'ro', isa => 'Str', required => 1 );
has 'image'   => ( is => 'ro', isa => 'Str', required => 0 );
has 'top_hit' => ( is => 'rw', isa => 'Int', required => 0 );
has 'neighborhood' => ( is => 'rw', isa => 'Str', required => 0 );
has 'samplecategories' => ( is => 'rw', isa => 'Str', required => 0 );

1;

=head1 SYNOPSIS

  use WebService::CityGrid::Search;
  $cs = WebService::CityGrid::Search->new(
      api_key   => $my_apikey,
      publisher => $my_pubid, );

  $url = $cs->query({ mode => 'locations', 
      where => '90210',
      what  => 'pizza%20and%20burgers', });

=head1 DESCRIPTION

Currently just returns a url that can represents a call to the CityGrid Web Service.

=head1 SEE ALSO

L<http://developer.citysearch.com/docs/search/>

=head1 AUTHOR

Fred Moyer, E<lt>fred@slwifi.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Silver Lining Networks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
