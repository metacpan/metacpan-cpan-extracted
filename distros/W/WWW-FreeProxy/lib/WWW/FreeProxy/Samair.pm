package WWW::FreeProxy::Samair;

use LWP::Simple;

=head1 FUNCTIONS

=head2 fetch

Fetches proxy list

=cut

sub fetch {
	my ($self, $callback) = @_;
	for (1 .. 10) {
		(my $p = $_) =~ s/^\d$/0$&/;
		my $c = get "http://www.samair.ru/proxy/proxy-$p.htm";
		$c =~ s{<script type="text/javascript">}{<script>}g;
		$c =~ m{<script>\s*((\w=\d;)+)</script>}s;
		my ($s, %h) = $1;
		$h{$1} = $2 while $s =~ /(\w)=(\d)/g;
		while ($c =~ m{<td>((?:\d+\.){3}\d+)<script>document\.write\(":"((?:\+\w)+)\)</script>}g) {
			my ($i, $n, $r) = ($1, $2);
			$r .= $h{$1} while $n =~ /\+(\w)/g;
			&$callback("$i:$r");
		}
	}
}

1;

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alexey Alexandrov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
