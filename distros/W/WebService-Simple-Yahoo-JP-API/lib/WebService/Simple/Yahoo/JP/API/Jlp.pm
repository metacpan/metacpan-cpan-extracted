package WebService::Simple::Yahoo::JP::API::Jlp;
our $VERSION = '0.01';
use base qw(WebService::Simple::Yahoo::JP::API);
__PACKAGE__->config(
		base_url => 'http://jlp.yahooapis.jp/',
		);

sub ma { shift->_post('MAService/V1/parse', @_); }
sub jim { shift->_post('JIMService/V1/conversion', @_); }
sub furigana { shift->_post('FuriganaService/V1/furigana', @_); }
sub kousei { shift->_post('KouseiService/V1/kousei', @_); }
sub da { shift->_post('DAService/V1/parse', @_); }
sub keyphrase { shift->_post('KeyphraseService/V1/extract', @_); }
1;
__END__

=head1 NAME

WebService::Simple::Yahoo::JP::API::Jlp - Search Subclass for WebService::Simple::Yahoo::JP::API.

=head1 SYNOPSIS

  use Data::Dumper;
  use WebService::Simple::Yahoo::JP::API;
  use WebService::Simple::Yahoo::JP::API::Jlp;
  my $api = WebService::Simple::Yahoo::JP::API->new(appid => "your appid");
  my $res = $api->jlp->keyphrase(sentence => "Perl");
  print Dumper $res;
  print Dumper $res->parse_response;

=head1 DESCRIPTION

WebService::Simple::Yahoo::JP::API::Search module provides
an interface to the Yahoo! JAPAN Search Web API.

=head1 METHODS

=over

=item new()

Create and return a new WebService::Simple::Yahoo::JP::API::Jlp object.
"new" Method requires an application ID of Yahoo developper network.

=item ma()

=item jim()

=item furigana()

=item kousei()

=item da()

=item keyphrase()

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
