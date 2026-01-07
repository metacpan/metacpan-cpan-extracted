package MockUA;
use strict;
use warnings;
use Path::Tiny;
use HTTP::Response;

sub new {
  my ($class, %args) = @_;
  return bless {
    fixtures_dir => $args{fixtures_dir} // 't/fixtures',
  }, $class;
}

sub request {
  my ($self, $http_request) = @_;
  my $uri = $http_request->uri;

  my $fixture_file;
  if ($uri =~ /\/traders/) {
    $fixture_file = 'traders.json';
  } elsif ($uri =~ /\/items/) {
    $fixture_file = 'items.json';
  } elsif ($uri =~ /\/quests/) {
    $fixture_file = 'quests.json';
  } elsif ($uri =~ /\/events-schedule/) {
    $fixture_file = 'event-timers.json';
  } elsif ($uri =~ /\/arcs/) {
    $fixture_file = 'arcs.json';
  } elsif ($uri =~ /game-map-data/) {
    # Extract mapID from query string
    my ($map) = $uri =~ /mapID=([^&]+)/;
    $fixture_file = $map ? "map-data-$map.json" : 'map-data.json';
  } else {
    return HTTP::Response->new(404, 'Not Found');
  }

  my $file = path($self->{fixtures_dir}, $fixture_file);

  unless ($file->is_file) {
    return HTTP::Response->new(404, 'Fixture not found: ' . $fixture_file);
  }

  my $content = $file->slurp_utf8;
  my $response = HTTP::Response->new(200, 'OK');
  $response->content($content);
  $response->header('Content-Type' => 'application/json');

  return $response;
}

1;
