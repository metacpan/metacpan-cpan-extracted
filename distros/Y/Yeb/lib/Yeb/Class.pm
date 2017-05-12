package Yeb::Class;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Meta Class for all Yeb application classes
$Yeb::Class::VERSION = '0.104';
use Moo;
use Package::Stash;

has app => (
	is => 'ro',
	required => 1,
);

has class => (
	is => 'ro',
	required => 1,
);

has package_stash => (
	is => 'ro',
	lazy => 1,
	builder => sub { Package::Stash->new(shift->class) },
);
sub add_function {
	my ( $self, $func, $coderef ) = @_;
	$self->package_stash->add_symbol('&'.$func,$coderef);
}

has chain_links => (
	is => 'ro',
	lazy => 1,
	builder => sub {[]},
);
sub chain { @{shift->chain_links} }
sub add_to_chain { push @{shift->chain_links}, @_ }
sub prepend_to_chain { unshift @{shift->chain_links}, @_ }

has yeb_class_functions => (
	is => 'ro',
	lazy => 1,
	builder => sub {
		my ( $self ) = @_;
		{
			plugin => sub { $self->app->add_plugin($self->class,@_) },

			r => sub { $self->add_to_chain(@_); return; },
			route => sub { $self->yeb_class_functions->{'r'}->(@_) },

			nop => sub (&) {
				my ( $code ) = @_;
				return sub {
					$code->(@_);
					return;
				};
			},

			pr => sub {
				my $route = shift;
				my $post_route;
				if (ref $_[0] eq 'CODE') {
					$post_route = "POST";
				} else {
					$post_route = "POST + ".(shift);
				}
				my $post_func = shift;
				my @args = @_;
				$self->add_to_chain($route, sub {
					return $post_route, sub {
						shift; $post_func->(@_); return;
					}, @args;
				});
				return;
			},
			post_route => sub { $self->yeb_class_functions->{'pr'}->(@_) },

			middleware => sub {
				my $middleware = shift;
				$self->prepend_to_chain( "" => sub { $middleware } );
			}
		}
	},
);

sub call {
	my ( $self, $func, @args ) = @_;
	return $self->yeb_class_functions->{$func}->(@_) if defined $self->yeb_class_functions->{$func};
	return $self->app->call($func,@args);
}

sub BUILD {
	my ( $self ) = @_;

	for (keys %{$self->app->yeb_functions}) {
		$self->add_function($_,$self->app->yeb_functions->{$_});
	}

	for (keys %{$self->yeb_class_functions}) {
		$self->add_function($_,$self->yeb_class_functions->{$_});
	}
}

1;

__END__

=pod

=head1 NAME

Yeb::Class - Meta Class for all Yeb application classes

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
