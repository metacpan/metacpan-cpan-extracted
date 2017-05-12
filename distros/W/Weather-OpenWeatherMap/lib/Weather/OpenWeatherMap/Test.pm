package Weather::OpenWeatherMap::Test;
$Weather::OpenWeatherMap::Test::VERSION = '0.005004';
=pod

=for Pod::Coverage .*

=cut

use strictures 2;
use Carp;

use Path::Tiny;

use File::ShareDir 'dist_dir', 'dist_file';

use parent 'Exporter::Tiny';
our @EXPORT = our @EXPORT_OK = qw/
  get_test_data
  mock_http_ua
/;


sub get_test_data {
  my $type = lc shift || confess "No type specified";
  my $base = 'Weather-OpenWeatherMap';
  my $path = dist_file( $base,
      $type eq 'current'  ? 'current.json'
    : $type =~ /^3day/    ? '3day.json'
    : $type eq 'forecast' ? '3day.json'
    : $type eq 'hourly'   ? 'hourly.json'
    : $type eq 'failure'  ? 'failure.json'
    : $type eq 'error'    ? 'failure.json'
    : $type eq 'find'     ? 'find.json'
    : $type eq 'search'   ? 'find.json'
    : confess "Unknown type $type"
  );
  path($path)->slurp_utf8
}

{ package
    Weather::OpenWeatherMap::Test::MockUA;
  use strict; use warnings FATAL => 'all';
  require HTTP::Response;
  use parent 'LWP::UserAgent';
  sub requested_count { my ($self) = @_; $self->{'__requested'} }
  sub request {
    my ($self, $http_request) = @_;
    my $url = $http_request->uri;
    $self->{'__requested'}++;
    if ($url =~ /forecast/) {
      return $url =~ /daily/ ?
        HTTP::Response->new( 200 => undef => [] => $self->{forecast_json} )
        : HTTP::Response->new( 200 => undef => [] => $self->{hourly_json} )
    } elsif ($url =~ /find/) {
      return HTTP::Response->new( 200 => undef => [] => $self->{find_json} )
    }
    HTTP::Response->new( 200 => undef => [] => $self->{current_json} )
  }
}

sub mock_http_ua {
  return bless +{
    map {; ($_ . '_json' => get_test_data($_) ) } qw/
      forecast
      hourly
      current
      find
    /
  }, 'Weather::OpenWeatherMap::Test::MockUA'
}

1;
