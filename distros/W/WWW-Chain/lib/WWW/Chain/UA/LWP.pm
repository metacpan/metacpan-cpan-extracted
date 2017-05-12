package WWW::Chain::UA::LWP;
BEGIN {
  $WWW::Chain::UA::LWP::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Chain::UA::LWP::VERSION = '0.003';
}

use Moo;
extends 'LWP::UserAgent';

with qw( WWW::Chain::UA );

use Scalar::Util 'blessed';

sub request_chain {
	my ( $self, $chain ) = @_;
	die __PACKAGE__."->request_chain needs a WWW::Chain object as parameter"
		unless ( blessed($chain) && $chain->isa('WWW::Chain') );
	while (!$chain->done) {
		my @responses;
		for (@{$chain->next_requests}) {
			my $response = $self->request($_);
			push @responses, $response;
		}
		$chain->next_responses(@responses);
	}
	return $chain;
}

1;
__END__
=pod

=head1 NAME

WWW::Chain::UA::LWP

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

