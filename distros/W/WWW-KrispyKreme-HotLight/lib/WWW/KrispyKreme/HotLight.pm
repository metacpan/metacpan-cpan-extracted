package WWW::KrispyKreme::HotLight;

use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::JSON ();

our $VERSION = '1.1';

has 'where';

has locations => \&_build_locations;

sub _build_locations {
    my ($self) = @_;
    my $geo = $self->where or return [];

    my $search = {
        Where => {
            LocationTypes => ['Store', 'Commissary', 'Franchise'],
            OpeningDate => {ComparisonType => 0}
        },
        # This is important. Otherwise we receive ALL locations.
        Take => {Min => 3, DistanceRadius => 100},
        PropertyFilters =>
          {Attributes => ['FoursquareVenueId', 'OpeningType']},
    };

    my $ua           = Mojo::UserAgent->new;
    my $hotlight_url = 'http://services.krispykreme.com/api/locationsearchresult/';
    my $header       = {'Referer' => 'http://www.krispykreme.com/Locate/Location-Search'};
    my $form = {
        lat          => $geo->[0],
        lng          => $geo->[1],
        responseType => 'Full',
        search => Mojo::JSON::encode_json($search),
    };

    my $json = $ua->get(
        $hotlight_url => $header => form => $form,
    )->res->json;

    [map $_->{Location}, @$json];
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::KrispyKreme::HotLight - Fetch Krispy Kreme locations near a given geolocation!

=head1 SYNOPSIS

  use WWW::KrispyKreme::HotLight;

  my $donuts = WWW::KrispyKreme::HotLight->new(where => [34.170833,-118.25]);

  # get array ref of all the krispy kreme locations near given geo
  my $stores = $donuts->locations;

  foreach my $store (@$stores) {

      # boolean value which shows if the Hot Light is on now!
      my $is_fresh = $store->{Hotlight};

      # Does this store serve coffee?
      my $has_coffee = $store->{OffersCoffee};

      # And WiFi?
      my $has_wifi = $store->{OffersWifi};

      # store name (Burbank, Los Angeles, etc)
      my $store_name = $store->{Name};

      # geolocation of store
      my $lat = $store->{Latitude};
      my $lon = $store->{Longitude};

      # Direct link to store page
      my $url = $store->{DetailUrl};
  }

=head1 DESCRIPTION

WWW::KrispyKreme::HotLight is a Perl wrapper for Krispy Kreme's location search
page.  This module will return an array ref of hash refs which contain info for
all the Krispy Kreme stores near the given geolocation.

=head1 METHODS

=head2 new

Creates a new WWW::KrispyKreme::HotLight object.  Currently the only REQUIRED
option is 'where' and only supports geo

    my $donuts = WWW::KrispyKreme::HotLight->new(where => [34.170833,-118.25]);

=head2 locations

Returns an array ref of hash refs.  Each hash ref represents a store near the
given geolocation.  The structure of one location entry should look like this:

    {
        "Location" => {
            "Id"              => 204,
            "LocationNumber"  => 1020,
            "Name"            => "Mountain View",
            "Slug"            => "mountain-view",
            "DetailUrl"       => "http://krispykreme.com/location/mountain-view",
            "LocationType"    => "Franchise",
            "Address1"        => "2146 Leghorn Street",
            "Address2"        => "",
            "City"            => "Mountain View",
            "Province"        => "CA",
            "PostalCode"      => "94043",
            "Country"         => "US",
            "PhoneNumber"     => "(650) 254-1231",
            "Latitude"        => 37.419002,
            "Longitude"       => -122.094216,
            "FundraisingType" => "Online",
            "Hotlight"        => 0,
            "OffersCoffee"    => 1,
            "OffersWifi"      => 0,
            "ExtendedDetails" => {
                "Description" => "",
                "Message" =>
                  "Hi. Thanks for stopping by your local Krispy Kreme store. Virtually, of course. Now you can see where we are and what we have going on. Oh, and be sure to LIKE us on Facebook and FOLLOW us on Twitter while you're here. It'd really mean a lot."
            },
            "Attributes" => {},
            "LocationHours" => {
                "Store Hours" => [
                    {
                        "DaysOfWeek"      => 31,
                        "DaysOfWeekAlias" => "Sun-Thu",
                        "Times" =>
                          [{"StartTime" => "06:00:00", "EndTime" => "22:00:00"}]
                    },
                    {
                        "DaysOfWeek"      => 96,
                        "DaysOfWeekAlias" => "Fri,Sat",
                        "Times" =>
                          [{"StartTime" => "06:00:00", "EndTime" => "23:00:00"}]
                    }
                ],
                "Drive-Thru Hours" => [
                    {
                        "DaysOfWeek"      => 31,
                        "DaysOfWeekAlias" => "Sun-Thu",
                        "Times" =>
                          [{"StartTime" => "06:00:00", "EndTime" => "23:00:00"}]
                    },
                    {
                        "DaysOfWeek"      => 32,
                        "DaysOfWeekAlias" => "Fri",
                        "Times" =>
                          [{"StartTime" => "06:00:00", "EndTime" => "00:00:00"}]
                    },
                    {
                        "DaysOfWeek"      => 64,
                        "DaysOfWeekAlias" => "Sat",
                        "Times" =>
                          [{"StartTime" => "00:00:00", "EndTime" => "00:00:00"}]
                    }
                ],
                "Hot Light Hours" => [
                    {
                        "DaysOfWeek"      => 31,
                        "DaysOfWeekAlias" => "Sun-Thu",
                        "Times"           => [
                            {"StartTime" => "06:00:00", "EndTime" => "09:00:00"},
                            {"StartTime" => "17:00:00", "EndTime" => "20:00:00"}
                        ]
                    },
                    {
                        "DaysOfWeek"      => 96,
                        "DaysOfWeekAlias" => "Fri,Sat",
                        "Times"           => [
                            {"StartTime" => "06:00:00", "EndTime" => "10:00:00"},
                            {"StartTime" => "17:00:00", "EndTime" => "21:00:00"}
                        ]
                    }
                ]
            },
            "OpeningDate"    => undef,
            "OpeningDateTBD" => 0
        }
    }

=cut

=head1 AUTHOR

Curtis Brandt E<lt>curtis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Curtis Brandt

=head1 LICENSE

MIT license.  See LICENSE file for details.

=head1 SEE ALSO

=cut
