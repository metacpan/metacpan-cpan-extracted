
package WWW::Kickstarter::HttpClient::Lwp;

use strict;
use warnings;
no autovivification;


use HTTP::Headers           qw( );
use HTTP::Request::Common   qw( GET POST );
use LWP::Protocol::https    qw( );
use LWP::UserAgent          qw( );
use WWW::Kickstarter::Error qw( my_croak );


sub new {
   my ($class, %opts) = @_;

   my $agent = delete($opts{agent});

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $http_client = LWP::UserAgent->new(
      default_headers => HTTP::Headers->new(
         Accept => 'application/json; charset=utf-8',
      ),
      env_proxy => 1,
   );
   $http_client->agent($agent) if $agent;

   my $self = bless({}, $class);
   $self->{http_client} = $http_client;
   return $self;
}


sub request {
   my ($self, $method, $url, $req_content) = @_;

   my $http_request;
   if ($method eq 'GET' ) {
      $http_request = GET($url);
   }
   elsif ($method eq 'POST') {
      $http_request = POST($url,
         Content_Length => length($req_content),
         Content_Type   => 'application/x-www-form-urlencoded',
         Content        => $req_content,
      );
   }
   else {
      my_croak(400, "Unexpected argument");
   }

   my $http_response = $self->{http_client}->request($http_request);

   my $status_code      = $http_response->code();
   my $status_line      = $http_response->status_line();
   my $content_type     = $http_response->content_type();  # Lowercase with "parameters" filtered out.
   my $content_encoding = $http_response->content_type_charset();
   my $content          = $http_response->decoded_content( charset => 'none' );

   return ( $status_code, $status_line, $content_type, $content_encoding, $content );
}


1;


__END__

=head1 NAME

WWW::Kickstarter::HttpClient::Lwp - LWP connector for WWW::Kickstarter


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $ks = WWW::Kickstarter->new(
      http_client_class => 'WWW::Kickstarter::HttpClient::Lwp',   # default
      ...
   );


=head1 DESCRIPTION

This is the default HTTP client used by L<WWW::Kickstarter>.
It uses L<LWP::UserAgent> to do the actual requests. WWW::Kickstarter
can be instructed to use a different HTTP client, as long as it follows
the interface documented in L<WWW::Kickstarter::HttpClient>.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
