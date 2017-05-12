
package WWW::Kickstarter::HttpClient;

die "Place holder for documentation. Not an actual module";

__END__

=head1 NAME

WWW::Kickstarter::HttpClient - HTTP client connector for WWW::Kickstarter


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $ks = WWW::Kickstarter->new(
      http_client_class => 'WWW::Kickstarter::HttpClient::Lwp',   # default
      ...
   );


=head1 DESCRIPTION

This module documents the interface that must be provided by HTTP clients to be used by WWW::Kickstarter.


=head1 CONSTRUCTOR

=head2 new

   my $http_client = $http_client_class->new(%opts);

The constructor. An L<WWW::Kickstarter::Error> object is thrown on error.

Options:

=over

=item * C<< agent => "application_name/version " >>

The string to pass to Kickstarter in the User-Agent HTTP header.
If the string ends with a space, the name and version of this library will be appended,
as will the name of version of the underling HTTP client.

=back


=head1 METHODS

=head2 request

   my ( $status_code, $status_line, $content_type, $content_encoding, $content ) =
      $http_client->request($method, $url, $req_content);

Performs an HTTP request for the URL specified by C<$url> using the method specified by C<$method> (either C<GET> or C<POST>).
For C<POST> requests, C<$req_content> will contain the content (of type C<application/x-www-form-urlencoded>) to send in the request.

An C<Accept> header with value C<< application/json; charset=utf-8 >> must be provided.

The following are returned:
The HTTP status code received from the server (C<$status>),
the status line including the HTTP status code (C<$status_line>),
the type of the content of the response (C<$content_type>),
the character encoding of the content (C<$content_encoding>),
and the content of the response (C<$content>).

If a communication failure occurs, appropriate values for C<$status> and C<$status_line> should be mocked up,
such as C<599> and C<< 599 Can't connect to api.kickstarter.com >>.

The value returned for C<$content_type> must be in lower-case letters and devoid of parameters.
C<undef> can be returned for C<$content_type>, and it need not be lower-case.
For example, C<$content_type> will be C<text/html> and C<$content_encoding> can be C<UTF-8> for C<< Text/HTML; charset=UTF-8 >>.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
