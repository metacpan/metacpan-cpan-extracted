package WebService::Simple::Yahoo::JP::API::Search;
use base qw(WebService::Simple::Yahoo::JP::API);
our $VERSION = '0.01';
__PACKAGE__->config(
		base_url => 'http://search.yahooapis.jp/',
		);

sub websearch { shift->_post('WebSearchService/V2/webSearch', @_); }
sub imagesearch { shift->_post('ImageSearchService/V2/imageSearch', @_); }
sub videosearch { shift->_post('VideoSearchService/V3/videoSearch', @_); }
sub webunitsearch { shift->_post('AssistSearchService/V1/webunitSearch', @_); }
sub blogsearch { shift->_get('BlogSearchService/V1/blogSearch', @_); }
1;
__END__

=head1 NAME

WebService::Simple::Yahoo::JP::API::Search - Search Subclass for WebService::Simple::Yahoo::JP::API.

=head1 SYNOPSIS

  use Data::Dumper;
  use WebService::Simple::Yahoo::JP::API;
  use WebService::Simple::Yahoo::JP::API::Search;
  my $api = WebService::Simple::Yahoo::JP::API->new(appid => "your appid");
  my $res = $api->search->websearch(query => "Perl");
  print Dumper $res;
  print Dumper $res->parse_response;

=head1 DESCRIPTION

WebService::Simple::Yahoo::JP::API::Search module provides
an interface to the Yahoo! JAPAN Search Web API.

=head1 METHODS

=over

=item new()

Create and return a new WebService::Simple::Yahoo::JP::API::Search object.
"new" Method requires an application ID of Yahoo developper network.

=item websearch()

=item imagesearch()

=item videosearch()

=item webunitsearch()

=item blogsearch()

=back

=head1 AUTHOR

AYANOKOUZI, Ryuunosuke E<lt>i38w7i3@yahoo.co.jpE<gt>

=head1 SEE ALSO

L<WebService::Simple::Yahoo::JP::API>

L<WebService::Simple::Yahoo::JP::API::Map>

L<WebService::Simple::Yahoo::JP::API::Jlp>

L<WebService::Simple::Yahoo::JP::API::Auctions>

L<WebService::Simple::Yahoo::JP::API::Shopping>

L<WebService::Simple::Yahoo::JP::API::News>

L<WebService::Simple::Yahoo::JP::API::Chiebukuro>

L<WebService::Simple::Yahoo::JP::API::Dir>

L<WebService::Simple::Yahoo::JP::API::Cert>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
