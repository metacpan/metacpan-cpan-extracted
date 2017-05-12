package Yeb::Plugin::Static;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Yeb Plugin for Plack::Middleware::Static
$Yeb::Plugin::Static::VERSION = '0.104';
use Moo;
use Path::Tiny qw( path );
use Plack::Middleware::Static;
use Carp;

has app => ( is => 'ro', required => 1 );
has class => ( is => 'ro', required => 1 );

has middleware_statics => (
	is => 'ro',
	lazy => 1,
	builder => sub {[]},
);

has local_static => (
	is => 'ro',
	lazy => 1,
	builder => sub { 0 },
);

has content_type => (
	is => 'ro',
	predicate => 1,
);

has default_root => (
	is => 'ro',
	predicate => 1,
);

sub add_middleware_static {
	my ( $self, $from, $root, $pass_through, $content_type ) = @_;
	$root = $self->default_root if !defined $root and $self->has_default_root;
	croak "Static needs a root directory for a static directory" unless defined $root;
	unshift @{$self->middleware_statics}, Plack::Middleware::Static->new(
		path => $from,
		root => path($root)->absolute,
		pass_through => $pass_through ? 1 : 0,
		defined $content_type
			? ( content_type => $content_type )
			: $self->has_content_type
				? ( content_type => $self->content_type )
				: (),
	);
}

sub BUILD {
	my ( $self ) = @_;
	$self->app->register_function('static',sub {
		my ( $from, $root, $content_type ) = @_;
		$self->add_middleware_static($from,$root,1,$content_type);
	});
	$self->app->register_function('static_404',sub {
		my ( $from, $root, $content_type ) = @_;
		$self->add_middleware_static($from,$root,0,$content_type);
	});
	my $class = $self->local_static
		? $self->class
		: $self->app->y_main;
	$class->prepend_to_chain("/...",sub {
		map { my $mw = $_; sub () { $mw } } @{$self->middleware_statics}
	});
}

1;

__END__

=pod

=head1 NAME

Yeb::Plugin::Static - Yeb Plugin for Plack::Middleware::Static

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  package MyYeb;

  use Yeb;

  BEGIN {
    plugin 'Static', default_root => root('htdocs');
  }

  static qr{^/};
  static_404 qr{^/images/}, root('htdocs');

  1;

=encoding utf8

=head1 FRAMEWORK FUNCTIONS

=head2 static

=head2 static_404

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
