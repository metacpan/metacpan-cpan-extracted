package Weather::OpenWeatherMap::Request::Current;
$Weather::OpenWeatherMap::Request::Current::VERSION = '0.005004';
use Moo;
extends 'Weather::OpenWeatherMap::Request';

# Empty subclass

1;

=pod

=head1 NAME

Weather::OpenWeatherMap::Request::Current

=head1 SYNOPSIS

  # Usually created by Weather::OpenWeatherMap
  use Weather::OpenWeatherMap::Request;
  my $current = Weather::OpenWeatherMap::Request->new_for(
    Current =>
      tag      => 'foo',
      location => 'Manchester, NH',
  );

=head1 DESCRIPTION

This is an empty subclass of L<Weather::OpenWeatherMap::Request>.

Look there for related documentation.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl

=cut
