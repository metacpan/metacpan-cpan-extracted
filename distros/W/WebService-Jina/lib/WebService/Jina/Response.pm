package WebService::Jina::Response;

use Moo;

use JSON::Lines qw/jsonl/;

has [qw/
	id
	choices
	model
	object
	usage
	system_fingerprint
	created
	data
	results
	num_tokens
	tokenizer
	num_chunks
	chunk_positions
	tokens
	chunks
/] => (
	is => 'ro',
);

1;

__END__

=head1 NAME

WebService::Jina::Response - jina response

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	my $response = WebService::Jina::Response->new(%response_attributes);

=cut

=head1 ATTRIBUTES

=head2 id

=head2 choices

=head2 model

=head2 object

=head2 usage

=head2 system_fingerprint

=head2 created

=head2 data

=head2 results

=head2 num_tokens

=head2 tokenizer

=head2 num_chunks

=head2 chunk_positions

=head2 tokens

=head2 chunks

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-jina at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Jina>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Jina


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Jina>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-Jina>

=item * Search CPAN

L<https://metacpan.org/release/WebService-Jina>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

