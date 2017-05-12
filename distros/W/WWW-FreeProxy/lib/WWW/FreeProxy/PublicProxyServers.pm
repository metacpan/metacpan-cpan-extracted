package WWW::FreeProxy::PublicProxyServers;

use LWP::Simple;

=head1 FUNCTIONS

=head2 fetch

Fetches proxy list

=cut

sub fetch {
	my ($self, $callback) = @_;
	for (1..6) {	       
		my $content = get("http://www.publicproxyservers.com/page$_.html") or return [];
		&$callback("$1:$2") while $content =~ m~<td[^>]*?>(\d+\.\d+\.\d+\.\d+)</td>.*?<td[^>]*?>(\d+)</td>~igs;
	}
}

1;

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alexey Alexandrov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
