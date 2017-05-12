package Yeb::Application;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Main Meta Class for a Yeb Application
$Yeb::Application::VERSION = '0.104';
use Moo;
use Package::Stash;
use Import::Into;
use Yeb::Context;
use Yeb::Class;
use Module::Runtime qw( use_module );
use Path::Tiny qw( path );
use Plack::Middleware::Debug;
use List::Util qw( reduce );
use Hash::Merge qw( merge );
use URL::Encode qw( url_encode_utf8 );
use List::MoreUtils qw(any);
use Sys::Hostname;

use Carp;

use Web::Simple ();

my $first_yep_application;

has class => (
	is => 'ro',
	required => 1,
);

has app => (
	is => 'rw',
);

has first => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		my ( $self ) = @_;
		$first_yep_application->class eq $self->class ? 1 : 0;
	},
);

has args => (
	is => 'ro',
	predicate => 1,
);

has config => (
	is => 'ro',
	lazy => 1,
	builder => sub {{}},
);

has root => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		defined $ENV{YEB_ROOT}
			? path($ENV{YEB_ROOT})
			: path(".")
	},
);

has current_dir => (
	is => 'ro',
	lazy => 1,
	builder => sub { path(".") },
);

has debug => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		my ( $self ) = @_;
		return 0 unless $self->first;
		return $ENV{YEB_TRACE} || $ENV{YEB_DEBUG} ? 1 : 0;
	},
);

has package_stash => (
	is => 'ro',
	lazy => 1,
	builder => sub { Package::Stash->new(shift->class) },
);

has yebs => (
	is => 'ro',
	lazy => 1,
	builder => sub {{}},
);
sub y {
	my ( $self, $yeb ) = @_;
	$self->yebs->{$yeb};
}
sub y_main {
	my ( $self ) = @_;
	$self->yebs->{$self->class};
}

has functions => (
	is => 'ro',
	lazy => 1,
	builder => sub {{}},
);

has plugins => (
	is => 'ro',
	lazy => 1,
	builder => sub {[]},
);

has yeb_functions => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		my ( $self ) = @_;
		{
			yeb => sub { $self },

			app => sub { $self->app },

			chain => sub {
				my $class = $self->class_loader(shift);
				return $class->yeb->y($class)->chain;
			},
			load => sub {
				my $class = $self->class_loader(shift);
				return;
			},

			cfg => sub { $self->config },
			root => sub { path($self->root,@_) },
			cur => sub { path($self->current_dir,@_) },
			hostname => sub { hostname() },

			cc => sub { $self->cc },
			env => sub { $self->hash_accessor($self->cc->env,@_) },
			req => sub { $self->cc->request },
			uri_for => sub { $self->cc->uri_for(@_) },
			st => sub { $self->hash_accessor_empty($self->cc->stash,@_) },
			st_has => sub { $self->hash_accessor_has($self->cc->stash,@_) },
			ex => sub { $self->hash_accessor_empty($self->cc->export,@_) },
			ex_has => sub { $self->hash_accessor_has($self->cc->export,@_) },
			pa => sub { $self->hash_accessor_empty($self->cc->request->parameters,@_) },
			pa_has => sub { $self->hash_accessor_has($self->cc->request->parameters,@_) },

			url => sub {
				my @parts = $self->flat([@_]);
				my ( @path_parts, @hashs );
				for (@parts) {
					if (ref $_ eq 'HASH') {
						push @hashs, $_;
					} else {
						push @path_parts, $_;
					}
				}
				my $url = $self->cc->uri_base;
				if (@path_parts) {
					$url .= join("/",map { url_encode_utf8($_) } @path_parts);
				}
				if (@hashs) {
					$url .= '?';
					my $gets = $self->merge_hashs(reverse @hashs);
					$url .= join("&",map { $_.'='.url_encode_utf8($gets->{$_}) } keys %{$gets});
				}
				return $url;
			},

			text => sub {
				$self->cc->content_type('text/plain');
				$self->cc->body(join("\n",@_));
				$self->cc->response;
			},

			redirect => sub {
				my ( $target, $code ) = shift;
				$code = 307 unless $code;
				$self->cc->content_type('text/html');
				$self->cc->header->{location} = $target;
				$self->cc->body(<<"__REDIRECT__");
<html><head><title>Moved</title><meta http-equiv="refresh" content="0; url=$target"></head>
<body><h1>Moved</h1><p>This page has moved to <a href="$target">$target</a>.</p></body></html>
__REDIRECT__
				$self->cc->response;
			},

			html_body => sub {
				$self->cc->content_type('text/html');
				$self->cc->body('<html><body>'.join(" ",@_).'</body></html>');
				$self->cc->response;
			},
		}
	},
);

sub call {
	my ( $self, $func, @args ) = @_;
	return $self->functions->{$func}->(@_) if defined $self->functions->{$func};
	return $self->yeb_functions->{$func}->(@_) if defined $self->yeb_functions->{$func};
	croak "Unknown function ".$func." inside ".(ref $self)." application";
}

sub class_loader {
	my ( $self, $class ) = @_;
	if ($class =~ m/^\+/) {
		$class =~ s/^(\+)//;
	} else {
		$class = $self->class.'::'.$class;
	}
	use_module($class);
	return $class;
}

sub hash_accessor_empty {
	my ( $self, @hash_and_args ) = @_;
	my $value = $self->hash_accessor(@hash_and_args);
	return defined $value ? $value : "";
}

sub hash_accessor_has {
	my ( $self, @hash_and_args ) = @_;
	my $value = $self->hash_accessor(@hash_and_args);
	return defined $value ? 1 : "";
}

sub hash_accessor {
	my ( $self, $hash, $key, $value ) = @_;
	return $hash unless defined $key;
	my @args = ref $key eq 'ARRAY' ? @{$key} : ($key);
	my $last_key = shift @args;
	my $last;
	if (@args) {
		$last = reduce { $a->{$b}||={} } ($hash, @args);
	} else {
		$last = $hash;
	}
	if (defined $value) {
		return $last->{$last_key} = $value;
	} else {
		return $last->{$last_key};
	}
}

sub add_plugin {
	my ( $self, $source, $plugin, %args ) = @_;
	my $class;
	if ($plugin =~ m/^\+(.+)/) {
		$class = $1;
	} else {
		$class = 'Yeb::Plugin::'.$plugin;
	}
	use_module($class);
	my $obj = $class->new( app => $self, class => $self->y($source) , %args );
	push @{$self->plugins}, $obj;
}

sub add_middleware {
	my ( $self, $middleware ) = @_;
	$self->y_main->prepend_to_chain( "" => sub { $middleware } );
}

sub BUILD {
	my ( $self ) = @_;

	$first_yep_application = $self unless defined $first_yep_application;

	$self->root;
	$self->current_dir;

	$self->package_stash->add_symbol('$yeb',\$self);
	
	Web::Simple->import::into($self->class);

	$self->package_stash->add_symbol('&register_has',sub {
		my ( $attr, @args ) = @_;
		my @attrs = ref $attr eq 'ARRAY' ? @{$attr} : ($attr);
		$self->register_function($_, $self->class->can($_)) for @attrs;
		$self->class->can('has')->($attr, @args);
	});

	$self->package_stash->add_symbol('&register_function',sub {
		$self->register_function(@_);
	});
	
	$self->package_stash->add_symbol('&dispatch_request',sub {
		my ( $app, $env ) = @_;
		$self->app($app);
		$self->reset_context;
		$self->set_cc(Yeb::Context->new( env => $env ));
		return $self->y_main->chain,
			'/...' => sub {
				$self->cc->status(500);
				$self->cc->response;
			};
	});

	$self->yeb_import($self->class);

	$self->package_stash->add_symbol('&import',sub {
		my ( $class ) = @_;
		my $target = caller;
		$self->yeb_import($target);
	});

	if ($self->debug) {
		$self->add_middleware(Plack::Middleware::Debug->new);
	}

	my @args = $self->has_args ? ( @{$self->args} ) : ();

	while (@args) {
		my $plugin = shift @args;
		my $plugin_args = ref $args[0] eq 'HASH'
			? shift @args : {};
		$self->add_plugin($self->class,$plugin,%{$plugin_args});
	}
}

my $cc;
sub set_cc { shift; $cc = shift; }
sub cc { $cc }
sub reset_context { $cc = undef }
sub current_context { shift->cc }

sub yeb_import {
	my ( $self, $target ) = @_;
	$self->yebs->{$target} = Yeb::Class->new(
		app => $self,
		class => $target,
	);
	for (keys %{$self->functions}) {
		$self->y($target)->add_function($_,$self->functions->{$_});
	}
}

sub register_function {
	my ( $self, $func, $coderef ) = @_;
	die "Function ".$func." already defined" if defined $self->functions->{$func};
	$self->functions->{$func} = $coderef;
	for (keys %{$self->yebs}) {
		$self->y($_)->add_function($func,$coderef);
	}
}

sub flat {
	my ( $self, $list, @seen_lists ) = @_;
	if (ref $list ne 'ARRAY') {
	  return $list;
	} elsif (any { $_ == $list } @seen_lists) {
	  return;
	} else {
	  push @seen_lists, $list;
	  return map { $self->flat($_, @seen_lists) } @{$list};
	}
}

sub merge_hashs {
	my ( $self, @hashs ) = @_;
	my $first = pop @hashs;
	while (@hashs) {
		my $next = pop @hashs;
		$first = merge($first,$next);
	}
	return $first;
}

1;

__END__

=pod

=head1 NAME

Yeb::Application - Main Meta Class for a Yeb Application

=head1 VERSION

version 0.104

=head1 SUPPORT

IRC

  Join #web-simple on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-yeb
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-yeb/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
