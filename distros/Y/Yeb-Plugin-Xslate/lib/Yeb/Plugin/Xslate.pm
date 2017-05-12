package Yeb::Plugin::Xslate;
BEGIN {
  $Yeb::Plugin::Xslate::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Yeb Plugin for Text::Xslate
$Yeb::Plugin::Xslate::VERSION = '0.100';
use Moo;
use Carp;
use Text::Xslate;

has app => ( is => 'ro', required => 1 );
has class => ( is => 'ro', required => 1 );

has path => ( is => 'ro', lazy => 1, builder => sub {[]} );
has function => ( is => 'ro', lazy => 1, builder => sub {{}} );
has content_type => ( is => 'ro', lazy => 1, builder => sub {
	my ( $self ) = @_;
	my $type = $self->has_type ? $self->type : 'html';
	return 'text/plain' if $type eq 'text';
	return 'text/xml' if $type eq 'xml';
	return 'text/html' if $type eq 'html';
	croak __PACKAGE__." Unknown type ".$type;
} );
has suffix => ( is => 'ro', lazy => 1, builder => sub {'.tx'} );

my @xslate_attributes = qw(
	cache
	cache_dir
	module
	html_builder_module
	input_layer
	verbose
	syntax
	type
	line_start
	tag_start
	tag_end
	header
	footer
	pre_process_handler
);

for (@xslate_attributes) {
	has $_ => ( is => 'ro', predicate => 1 );
}

has xslate => (
	is => 'ro',
	lazy => 1,
	predicate => 1,
	builder => sub {
		my ( $self ) = @_;
		croak __PACKAGE__." Xslate needs at least one path" unless @{$self->path};
		Text::Xslate->new(
			path => $self->path,
			function => $self->all_functions,
			suffix => $self->suffix,
			map {
				my $predicate = 'has_'.$_;
				$self->$predicate ? ( $_ => $self->$_ ) : ()
			} @xslate_attributes,
		);
	},
);

has all_functions => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		my ( $self ) = @_;
		return {
			%{$self->app->yeb_functions},
			%{$self->class->yeb_class_functions},
			%{$self->app->functions},
			%{$self->function}
		}
	},
);

has base_functions => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		my ( $self ) = @_;
		return {
			current_file => sub { $self->xslate->current_file },
			current_line => sub { $self->xslate->current_line },
			call => sub {
				my ( $thing, $func, @args ) = @_;
				$thing->$func(@args);
			},
			call_if => sub {
				my ( $thing, $func, @args ) = @_;
				$thing->$func(@args) if $thing;
			},
			replace => sub {
				my ( $source, $from, $to ) = @_;
				$source =~ s/$from/$to/g;
				return $source;
			},
		}
	},
);

sub get_vars {
	my ( $self, $user_vars ) = @_;
	my %stash = %{$self->app->cc->stash};
	my %user = defined $user_vars ? %{$user_vars} : ();
	return $self->app->merge_hashs(
		$self->app->cc->export,
		$self->app->cc->stash,
		\%user
	);
}

sub BUILD {
	my ( $self ) = @_;
	$self->app->register_function('xslate_path',sub {
		croak __PACKAGE__." Xslate already instantiated, no path can be added" if $self->has_xslate;
		unshift @{$self->path}, "$_" for (@_);
	});
	$self->app->register_function('xslate_function',sub {
		croak __PACKAGE__." Xslate already instantiated, no function can be added" if $self->has_xslate;
		my ( $name, $function ) = @_;
		$self->function->{$name} = $function;
	});
	$self->app->register_function('xslate',sub {
		my ( $file, $user_vars ) = @_;
		my $vars = $self->get_vars($user_vars);
		my $template_file = $file.$self->suffix;
		$self->app->cc->content_type($self->content_type);
		$self->app->cc->body($self->xslate->render($template_file,$vars));
		$self->app->cc->response;
	});
}

1;

__END__

=pod

=head1 NAME

Yeb::Plugin::Xslate - Yeb Plugin for Text::Xslate

=head1 VERSION

version 0.100

=head1 SYNOPSIS

  package MyYeb;

  use Yeb;

  BEGIN {
    plugin 'Xslate';
  }

  xslate_path root('templates');

  r "/" => sub {
    st page => 'root';
    xslate 'index';
  };

  xslate_function myq => sub {
    "The parameter q contains ".pa('q');	
  };

  1;

=encoding utf8

=head1 FRAMEWORK FUNCTIONS

=head2 xslate

=head2 xslate_path

=head2 xslate_function

=head1 SUPPORT

IRC

  Join #web-simple on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-yeb-plugin-static
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-yeb-plugin-static/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
