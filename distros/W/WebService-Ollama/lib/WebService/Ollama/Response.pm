package WebService::Ollama::Response;

use Moo;

use JSON::Lines;

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

sub has_tool_calls {
	my ($self) = @_;
	my $calls = $self->extract_tool_calls;
	return scalar @$calls > 0;
}

sub extract_tool_calls {
	my ($self) = @_;
	my @calls;
	
	# Ollama returns tool_calls in the message
	if ($self->message && ref($self->message) eq 'HASH') {
		if (my $tc = $self->message->{tool_calls}) {
			push @calls, @$tc;
		}
		
		# Fallback: some models output tool calls as JSON in content
		if (!@calls && $self->message->{content}) {
			my $content = $self->message->{content};
			
			# Look for JSON tool call patterns - handle both "arguments" and "parameters"
			while ($content =~ /\{\s*"name"\s*:\s*"([^"]+)"\s*,\s*"(?:arguments|parameters)"\s*:\s*(\{[^}]*\})\s*\}/g) {
				my ($name, $args_json) = ($1, $2);
				my $args = eval { 
					JSON::Lines->new->decode($args_json)->[0];
				} // {};
				push @calls, {
					function => {
						name      => $name,
						arguments => $args,
					},
				};
			}
		}
	}
	
	return \@calls;
}

sub json_response {
	my ($self) = shift;
	my $aoa = JSON::Lines->new->decode($self->response ? $self->response : $self->message->{content});
	return scalar @{$aoa} == 1 ? $aoa->[0] : $aoa;
}

1;

__END__

=head1 NAME

WebService::Ollama::Response - ollama response

=head1 VERSION

Version 0.08

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

=head2 has_tool_calls

Returns true if the response contains tool calls.

    if ($response->has_tool_calls) {
        my $calls = $response->extract_tool_calls;
    }

=head2 extract_tool_calls

Extract tool calls from the response. Returns an arrayref of tool call structures.
Handles both native Ollama tool_calls and fallback parsing from content text.

    my $calls = $response->extract_tool_calls;
    for my $call (@$calls) {
        my $name = $call->{function}{name};
        my $args = $call->{function}{arguments};
    }

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

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

