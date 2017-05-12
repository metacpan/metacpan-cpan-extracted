package Yeb::Plugin::Session;
BEGIN {
  $Yeb::Plugin::Session::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Yeb Plugin for Plack::Middleware::Session
$Yeb::Plugin::Session::VERSION = '0.100';
use Moo;
use Plack::Middleware::Session;
use Plack::Session::Store::File;

has app => ( is => 'ro', required => 1, weak_ref => 1 );

sub BUILD {
	my ( $self ) = @_;
	$self->app->add_middleware(Plack::Middleware::Session->new(
		store => Plack::Session::Store::File->new
	));
	$self->app->register_function('session',sub {
		$self->app->hash_accessor_empty($self->app->cc->env->{'psgix.session'},@_);
	});
	$self->app->register_function('session_has',sub {
		$self->app->hash_accessor_has($self->app->cc->env->{'psgix.session'},@_);
	});
	$self->app->register_function('clear_session',sub {
		$self->app->cc->env->{'psgix.session'} = {};
	});
}

1;

__END__

=pod

=head1 NAME

Yeb::Plugin::Session - Yeb Plugin for Plack::Middleware::Session

=head1 VERSION

version 0.100

=head1 SYNOPSIS

  package MyYeb;

  use Yeb;

  BEGIN {
    plugin 'Session';
  }

  1;

=encoding utf8

=head1 FRAMEWORK FUNCTIONS

=head2 session

=head2 session_has

=head1 SUPPORT

IRC

  Join #web-simple on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-yeb-plugin-session
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-yeb-plugin-session/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
