package TWMO;

use strict;
use warnings;

my @pies = qw(cherry apple blueberry);

sub new {
  bless {} => shift;
}

sub url_base { 'http://localhost.localdomain' }

sub request {
  my ($self, $request) = @_;
  my $query = { $request->uri->query_form };

  if ($query->{pie} && $query->{pie} eq 'random') {
    my $response = HTTP::Response->new(302);
    my $location = $request->uri->clone;
    $location->query_form(pie => $pies[rand @pies]);
    $response->header( Location => $location );
    return $response;
  } 

  my $response = HTTP::Response->new(200);
  my $uri = $request->uri->canonical;
  $response->content(
    sprintf(
      <<"END",
Your host is %s.
You got to %s.
You asked for a %s pie.
END
      $uri->host,
      ($uri->path eq '/' ? "nowhere" : $uri->path),
      $query->{pie} || "void",
    )
  );
  if (($request->uri->path_segments)[1] and
        ($request->uri->path_segments)[1] eq 'cookie') {
    $response->header(
      'Set-Cookie' => 'cookie=yummy; domain=' . $uri->host . "; path=/"
    );
  }

  return $response;
}

package TWMO::Remote;

our @ISA = qw(TWMO);

sub url_base { $ENV{TWMO_SERVER} || shift->SUPER::url_base }

1;
