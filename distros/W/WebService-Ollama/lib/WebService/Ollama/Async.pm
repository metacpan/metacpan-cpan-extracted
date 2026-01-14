package WebService::Ollama::Async;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.08';

use Moo;
use Exporter 'import';
use Future;
use JSON::Lines;

use WebService::Ollama::UA::Async;

our @EXPORT_OK = qw(ollama);

# Singleton instance for functional API
my $_instance;

sub ollama {
	my ($method, @args) = @_;
	
	# Initialize singleton on first call
	$_instance //= __PACKAGE__->new(
		base_url => $ENV{OLLAMA_URL} // 'http://localhost:11434',
		model    => $ENV{OLLAMA_MODEL} // 'llama3.2',
	);
	
	# If first arg is a hashref, it's options for new instance
	if (ref($method) eq 'HASH') {
		$_instance = __PACKAGE__->new(%$method);
		return $_instance;
	}
	
	# Call method on singleton
	return $_instance->$method(@args);
}

has base_url => (
	is       => 'ro',
	required => 1,
);

has model => (
	is => 'ro',
);

has loop => (
	is        => 'ro',
	predicate => 'has_loop',
);

has ua => (
	is      => 'ro',
	lazy    => 1,
	default => sub {
		my $self = shift;
		return WebService::Ollama::UA::Async->new(
			base_url => $self->base_url,
			($self->has_loop ? (loop => $self->loop) : ()),
		);
	},
);

has tools => (
	is      => 'ro',
	default => sub { {} },
);

sub register_tool {
	my ($self, %args) = @_;

	my $name = $args{name} or die "Tool name required";
	my $description = $args{description} // '';
	my $parameters = $args{parameters} // { type => 'object', properties => {} };
	my $handler = $args{handler} or die "Tool handler required";

	$self->tools->{$name} = {
		name        => $name,
		description => $description,
		parameters  => $parameters,
		handler     => $handler,
	};

	return $self;
}

sub _format_tools_for_api {
	my ($self, $tools) = @_;

	$tools //= $self->tools;
	return [] unless keys %$tools;

	return [
		map {
			{
				type     => 'function',
				function => {
					name        => $_->{name},
					description => $_->{description},
					parameters  => $_->{parameters},
				},
			}
		} values %$tools
	];
}

sub version {
	my ($self) = @_;
	return $self->ua->get(url => '/api/version');
}

sub available_models {
	my ($self) = @_;
	return $self->ua->get(url => '/api/tags');
}

sub running_models {
	my ($self) = @_;
	return $self->ua->get(url => '/api/ps');
}

sub create_model {
	my ($self, %args) = @_;

	if (!$args{model}) {
		return Future->fail("No model defined for create_model");
	}

	return $self->ua->post(
		url  => '/api/create',
		data => \%args,
	);
}

sub copy_model {
	my ($self, %args) = @_;

	if (!$args{source}) {
		return Future->fail("No source defined for copy_model");
	}

	if (!$args{destination}) {
		return Future->fail("No destination defined for copy_model");
	}

	return $self->ua->post(
		url  => '/api/copy',
		data => \%args,
	);
}

sub delete_model {
	my ($self, %args) = @_;

	if (!$args{model}) {
		return Future->fail("No model defined for delete_model");
	}

	return $self->ua->delete(
		url  => '/api/delete',
		data => \%args,
	);
}

sub load_completion_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for load_completion_model");
	}

	return $self->ua->post(
		url  => '/api/generate',
		data => \%args,
	);
}

sub unload_completion_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for unload_completion_model");
	}

	$args{keep_alive} = 0;

	return $self->ua->post(
		url  => '/api/generate',
		data => \%args,
	);
}

sub completion {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for completion");
	}

	if (!$args{prompt}) {
		return Future->fail("No prompt defined for completion");
	}

	$args{stream} = \0;

	if (defined $args{image_files}) {
		$args{images} = [];
		push @{$args{images}}, @{$self->ua->base64_images(delete $args{image_files})};
	}

	return $self->ua->post(
		url  => '/api/generate',
		data => \%args,
	);
}

sub load_chat_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for load_chat_model");
	}

	$args{messages} = [];

	return $self->ua->post(
		url  => '/api/chat',
		data => \%args,
	);
}

sub unload_chat_model {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for unload_chat_model");
	}

	$args{keep_alive} = 0;
	$args{messages} = [];

	return $self->ua->post(
		url  => '/api/generate',
		data => \%args,
	);
}

sub chat {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for chat");
	}

	if (!$args{messages}) {
		return Future->fail("No messages defined for chat");
	}

	$args{stream} = \0;

	# Add tools if registered and not already provided
	if (!$args{tools} && keys %{$self->tools}) {
		$args{tools} = $self->_format_tools_for_api;
	}

	for my $message (@{$args{messages}}) {
		if ($message->{image_files}) {
			$message->{images} = [];
			push @{$message->{images}}, @{$self->ua->base64_images(delete $message->{image_files})};
		}
	}

	return $self->ua->post(
		url  => '/api/chat',
		data => \%args,
	);
}

sub embed {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for embed");
	}

	return $self->ua->post(
		url  => '/api/embed',
		data => \%args,
	);
}

sub chat_with_tools {
	my ($self, %args) = @_;

	$args{model} //= $self->model;

	if (!$args{model}) {
		return Future->fail("No model defined for chat_with_tools");
	}

	if (!$args{messages}) {
		return Future->fail("No messages defined for chat_with_tools");
	}

	my $max_iterations = $args{max_iterations} // 10;
	my @messages = @{$args{messages}};
	my @all_responses;
	my $tools = $args{tools} // $self->_format_tools_for_api;
	my $model = $args{model};

	my $iterate;
	$iterate = sub {
		my ($iteration) = @_;

		if ($iteration > $max_iterations) {
			return Future->done($all_responses[-1]);
		}

		return $self->chat(
			model    => $model,
			messages => \@messages,
			tools    => $tools,
		)->then(sub {
			my ($response) = @_;
			push @all_responses, $response;

			my $tool_calls = $response->extract_tool_calls;

			# Only stop if there are no tool calls to execute
			if (!@$tool_calls) {
				return Future->done($response);
			}

			# Add assistant message
			push @messages, {
				role       => 'assistant',
				content    => $response->message->{content} // '',
				tool_calls => $tool_calls,
			};

			# Execute tools
			for my $tool_call (@$tool_calls) {
				my $function = $tool_call->{function};
				my $tool_name = $function->{name};
				my $tool_args = $function->{arguments};

				if (!ref($tool_args)) {
					my $json = JSON::Lines->new;
					$tool_args = eval { $json->decode($tool_args)->[0] } // {};
				}

				my $result;
				if (my $handler = $self->tools->{$tool_name}{handler}) {
					$result = eval { $handler->($tool_args) };
					if ($@) {
						$result = "Error executing tool: $@";
					}
				} else {
					$result = "Unknown tool: $tool_name";
				}

				push @messages, {
					role         => 'tool',
					content      => ref($result) ? JSON::Lines->new->encode([$result]) : "$result",
					tool_call_id => $tool_call->{id} // $tool_name,
				};
			}

			return $iterate->($iteration + 1);
		});
	};

	return $iterate->(1);
}

1;

__END__

=head1 NAME

WebService::Ollama::Async - Async Ollama client

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

    # Object-oriented interface
    use WebService::Ollama::Async;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;

    my $ollama = WebService::Ollama::Async->new(
        base_url => 'http://localhost:11434',
        model    => 'llama3.2',
        loop     => $loop,
    );

    # Simple chat - returns Future
    my $future = $ollama->chat(
        messages => [
            { role => 'user', content => 'Hello!' }
        ],
    );

    $future->then(sub {
        my ($response) = @_;
        print $response->message->{content}, "\n";
    })->get;

    # Functional interface
    use WebService::Ollama::Async qw(ollama);

    ollama({ base_url => 'http://localhost:11434', model => 'llama3.2' });
    
    my $future = ollama('chat', messages => [{ role => 'user', content => 'Hi' }]);
    my $response = $future->get;

    # With tools
    $ollama->register_tool(
        name        => 'get_weather',
        description => 'Get current weather',
        parameters  => {
            type       => 'object',
            properties => {
                location => { type => 'string' },
            },
            required => ['location'],
        },
        handler => sub {
            my ($args) = @_;
            return { temp => 72, location => $args->{location} };
        },
    );

    $ollama->chat_with_tools(
        messages => [
            { role => 'user', content => 'What is the weather in Seattle?' }
        ],
    )->then(sub {
        my ($response) = @_;
        print $response->message->{content}, "\n";
    })->get;

=head1 DESCRIPTION

Async version of L<WebService::Ollama> using L<IO::Async> and L<Net::Async::HTTP>.
All methods return L<Future> objects instead of blocking.

=head1 METHODS

All methods mirror L<WebService::Ollama> but return Futures:

=head2 version

=head2 available_models

=head2 running_models

=head2 create_model

=head2 copy_model

=head2 delete_model

=head2 load_completion_model

=head2 unload_completion_model

=head2 completion

=head2 load_chat_model

=head2 unload_chat_model

=head2 chat

=head2 embed

=head2 register_tool

Register a tool for function calling.

    $ollama->register_tool(
        name        => 'tool_name',
        description => 'What the tool does',
        parameters  => { ... },  # JSON Schema
        handler     => sub { my ($args) = @_; ... },
    );

=head2 chat_with_tools

Chat with automatic tool execution loop.

    my $future = $ollama->chat_with_tools(
        messages       => \@messages,
        max_iterations => 10,  # optional, default 10
    );

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.
This is free software, licensed under The Artistic License 2.0.

=cut
