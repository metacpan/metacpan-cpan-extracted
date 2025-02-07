package WebService::Ollama::Response;

use Moo;

use JSON::Lines qw/jsonl/;

has [qw/
	done
	context
	total_duration
	load_duration
	model
	create_at
	eval_count
	eval_duration
	done_reason
	response
	prompt_eval_duration
	prompt_eval_count
	message
	status
	digest
	total
	completed
	version
	embeddings
	models
/] => (
	is => 'ro',
);

sub json_response {
	my ($self) = shift;
	my $aoa = jsonl( parse_headers => 1, decode => 1, data => $self->response ? $self->response : $self->message->{content} );
	return scalar @{$aoa} == 1 ? $aoa->[0] : $aoa;
}

1;

__END__

=head1 NAME

WebService::Ollama::Response - ollama response

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	my $response = WebService::Ollama::Response(%response_attributes);

=cut

=head1 ATTRIBUTES

=head2 done 

=head2 context

=head2 total_duration 

=head2 load_duration 

=head2 model 

=head2 create_at 

=head2 eval_count 

=head2 eval_duration 

=head2 done_reason 

=head2 response 

=head2 prompt_eval_duration 

=head2 prompt_eval_count

=head2 message

=head2 status

=head2 digest
	
=head2 total

=head2 completed

=head2 version

=head2 embeddings

=head2 models

=head1 SUBROUNTINES/METHODS

=head2 json_response

JSON decode the response.

	$response->json_response;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-ollama at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Ollama>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Ollama


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Ollama>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WebService-Ollama>

=item * Search CPAN

L<https://metacpan.org/release/WebService-Ollama>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

