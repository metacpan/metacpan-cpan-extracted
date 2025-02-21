package WebService::Ollama;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use Moo;

use WebService::Ollama::UA;

has base_url => (
	is => 'ro',
	required => 1,
	lazy => 1,
);

has model => (
	is => 'ro',
);

has ua => (
	is => 'ro',
	default => sub {
		return WebService::Ollama::UA->new(
			base_url => $_[0]->base_url
		);
	}
);

sub version {
	my ($self, %args) = @_;

	return $self->ua->get(url => '/api/version');
}

sub create_model {
	my ($self, %args) = @_;

	if (! $args{model}) {
		die "No model defined for create_model";
	}

	return $self->ua->post(
		url => '/api/create',
		data => \%args
	);
}

sub copy_model {
	my ($self, %args) = @_;

	if (! $args{source}) {
		die "No source defined for copy_model";
	}


	if (! $args{destination}) {
		die "No destination defined for copy_model";
	}

	return $self->ua->post(
		url => '/api/create',
		data => \%args
	);
}

sub delete_model {
	my ($self, %args) = @_;

	if (! $args{model}) {
		die "No model defined for create_model";
	}

	return $self->ua->delete(
		url => '/api/delete',
		data => \%args
	);
}


sub available_models {
	my ($self, %args) = @_;
	
	return $self->ua->get(url => '/api/tags');
}

sub running_models {
	my ($self, %args) = @_;
	
	return $self->ua->get(url => '/api/ps');
}

sub load_completion_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (! $args{model}) {
		die "No model defined for load_completion_model";
	}

	return $self->ua->post(
		url => '/api/generate',
		data => \%args
	);
}

sub unload_completion_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (! $args{model}) {
		die "No model defined for unload_completion_model";
	}

	$args{keep_alive} = 0;

	return $self->ua->post(
		url => '/api/generate',
		data => \%args
	);
}

sub completion {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (! $args{model}) {
		die "No model defined for completion";
	}

	if (! $args{prompt}) {
		die "No prompt defined for completion";
	}

	$args{stream} = $args{stream} ? \1 : \0;

	if ( defined $args{image_files} ) {
		$args{images} = [];
		push @{$args{images}}, @{ $self->ua->base64_images(delete $args{image_files}) };
	}

	return $self->ua->post(
		url => '/api/generate',
		data => \%args
	);
}

sub load_chat_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (! $args{model}) {
		die "No model defined for load_chat_model";
	}

	$args{messages} = [];

	return $self->ua->post(
		url => '/api/chat',
		data => \%args
	);
}

sub unload_chat_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (! $args{model}) {
		die "No model defined for unload_chat_model";
	}

	$args{keep_alive} = 0;
	$args{messages} = [];

	return $self->ua->post(
		url => '/api/generate',
		data => \%args
	);
}

sub chat {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (! $args{model}) {
		die "No model defined for chat";
	}

	if (! $args{messages}) {
		die "No messsages defined for chat";
	}

	$args{stream} = $args{stream} ? \1 : \0;

	for my $message (@{$args{messages}}) {
		if ($message->{image_files}) {
			$message->{images} = [];
			push @{$message->{images}}, @{ $self->ua->base64_images(delete $message->{image_files}) };
		}
	}

	return $self->ua->post(
		url => '/api/chat',
		data => \%args
	);
}

sub embed {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (! $args{model}) {
		die "No model defined for embed";
	}

	return $self->ua->post(
		url => '/api/embed',
		data => \%args
	);
}

1;

__END__

=head1 NAME

WebService::Ollama - ollama client

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

	my $ollama = WebService::Ollama->new(
		base_url => 'http://localhost:11434',
		model => 'llama3.2'
	);

	$ollama->load_completion_model;

	my $string = "";

	my $why = $ollama->completion(
		prompt => 'Why is the sky blue?',
		stream => 1,
		stream_cb => sub {
			my ($res) = @_;
			$string .= $res->response;
		}
	); # returns all chunked responses as an array

	$ollama->unload_completion_model;

=head1 SUBROUTINES/METHODS

=head2 version

Retrieve the Ollama version

	$ollama->version;

=head2 create_model

Create a model from: another model, a safetensors directory or a GGUF file.

=head3 Parameters

=over

=item model

name of the model to create

=item from

(optional) name of an existing model to create the new model from

=item files

(optional) a dictionary of file names to SHA256 digests of blobs to create the model from

=item adapters

(optional) a dictionary of file names to SHA256 digests of blobs for LORA adapters

=item template

(optional) the prompt template for the model

=item license

(optional) a string or list of strings containing the license or licenses for the model

=item system

(optional) a string containing the system prompt for the model

=item parameters

(optional) a dictionary of parameters for the model (see Modelfile for a list of parameters)

=item messages

(optional) a list of message objects used to create a conversation

=item stream

(optional) if false the response will be returned as a single response object, rather than a stream of objects

=item stream_cb

(optional) cb to handle stream data

=item quantize

(optional) quantize a non-quantized (e.g. float16) model

=back

	$ollama->create_model(
		model => 'mario',
		from => 'llama3.2',
		system => 'You are Mario from Super Mario Bros.'
	);


	my $mario_story = $ollama->chat(
		model => 'mario',
		messages => [
			{
				role => 'user',
				content => 'Hello, Tell me a story.',
			}
		],
	);

=head2 copy_model

Copy a model. Creates a model with another name from an existing model.

=head3 Parameters

=over

=item source

source of model to be copied from.

=item destination

destination of model to be copied to.

=back

	$ollama->copy_model(
		source => 'llama3.2',
		destination => 'llama3-backup'
	);


=head2 delete_model

Delete a model and its data.

=head3 Parameters

=over

=item model

model name to delete

=back

	$ollama->delete_model(
		model => 'mario'
	);


=head2 available_models

List models that are available locally.

	$ollama->available_models;

=head2 running_models

List models that are currently loaded into memory.

	$ollama->running_models;

=head2 load_completion_model

Load a model into memory

	$ollama->load_completion_model;

	$ollama->load_completion_model(model => 'llava');

=head2 unload_completion_model

Unload a model from memory

	$ollama->unload_completion_model;

	$ollama->unload_completion_model(model => 'llava');

=head2 completion

Generate a response for a given prompt with a provided model. This is a streaming endpoint, so there will be a series of responses. The final response object will include statistics and additional data from the request.

=head3 Parameters

=over

=item model

(required) the model name

=item prompt

the prompt to generate a response for

=item suffix

the text after the model response

=item images

(optional) a list of base64-encoded images (for multimodal models such as llava)

=item image_files

(optional) a list of image files

=back

=head3 Advanced parameters (optional):

=over

=item format

the format to return a response in. Format can be json or a JSON schema

=item options

additional model parameters listed in the documentation for the Modelfile such as temperature

=item system

system message to (overrides what is defined in the Modelfile)

=item template

the prompt template to use (overrides what is defined in the Modelfile)

=item stream

if false the response will be returned as a single response object, rather than a stream of objects

=item stream_cb

(optional) cb to handle stream data

=item raw

 if true no formatting will be applied to the prompt. You may choose to use the raw parameter if you are specifying a full templated prompt in your request to the API

=item keep_alive

controls how long the model will stay loaded into memory following the request (default: 5m)

=item context (deprecated)

the context parameter returned from a previous request to /generate, this can be used to keep a short conversational memory

=back

	my $image = $ollama->completion(
		model => 'llava',
		prompt => 'What is in this image?',
		image_files => [
			"t/pingu.png"
		]
	); 

	my $json = $ollama->completion(
		prompt => "What color is the sky at different times of the day? Respond using JSON",
		format => "json",
	)->json_response;

	my $json2 = $ollama->completion(
		prompt => "Ollama is 22 years old and is busy saving the world. Respond using JSON",
		format => {
			type => "object",
			properties => {
				age => {
					"type" => "integer"
				},
				available => {
					"type" => "boolean"
				}
			},
			required => [
				"age",
				"available"
			]
		}
	)->json_response;

=head2 load_chat_model

Load a model into memory

	$ollama->load_chat_model;

	$ollama->load_chat_model(model => 'llava');


=head2 unload_chat_model

Unload a model from memory

	$ollama->unload_chat_model;

	$ollama->unload_chat_model(model => 'llava');

=head2 chat

Generate the next message in a chat with a provided model. 

=head3 Parameters

=over

=item model

(required) the model name

=item messages

the messages of the chat, this can be used to keep a chat memory

The message object has the following fields:

=over 

=item role
	
the role of the message, either system, user, assistant, or tool

=item content

the content of the message

=item images

(optional) a list of images to include in the message (for multimodal models such as llava)

=item tool_calls

(optional): a list of tools in JSON that the model wants to use

=back

=item tools

list of tools in JSON for the model to use if supported

=item format

the format to return a response in. Format can be json or a JSON schema.

=item options

additional model parameters listed in the documentation for the Modelfile such as temperature

=item stream

if false the response will be returned as a single response object, rather than a stream of objects

=item keep_alive

controls how long the model will stay loaded into memory following the request (default: 5m)

=back

	my $completion = $ollama->chat(
		messages => [
			{
				role => 'user',
				content => 'Why is the sky blue?',
			}
		],
	);


	my $image = $ollama->chat(
		model => 'llava',
		messages => [
			{
				role => 'user',
				content => 'What is in this image?',
				image_files => [
					"t/pingu.png"
				]
			}
		]
	);

	my $json = $ollama->chat(
		messages => [
			{
				role => "user",
				"content" => "Ollama is 22 years old and is busy saving the world. Respond using JSON",
			}
		],
		format => {
			type => "object",
			properties => {
				age => {
					"type" => "integer"
				},
				available => {
					"type" => "boolean"
				}
			},
			required => [
				"age",
				"available"
			]
		}
	)->json_response;


=head2 embed

Generate embeddings from a model

=head3 Parameters

=over 

=item model

name of model to generate embeddings from

=item input

text or list of text to generate embeddings for

=item truncate

(optional) truncates the end of each input to fit within context length. Returns error if false and context length is exceeded. Defaults to true

=item options

(optional) additional model parameters listed in the documentation for the Modelfile such as temperature

=item keep_alive

(optional) controls how long the model will stay loaded into memory following the request (default: 5m)

=back

	my $embeddings = $ollama->embed(
		model => "nomic-embed-text",
		input => "Why is the sky blue?"
	);

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

1; # End of WebService::Ollama
