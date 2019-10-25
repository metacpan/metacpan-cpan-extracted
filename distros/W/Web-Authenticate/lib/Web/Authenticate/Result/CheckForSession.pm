use strict;
package Web::Authenticate::Result::CheckForSession;
$Web::Authenticate::Result::CheckForSession::VERSION = '0.013';
use Mouse;
#ABSTRACT: The result of calling Web::Authenticate::check_for_session.


has success => (
    isa => 'Bool',
    is => 'ro',
    required => 1,
    default => undef,
);


has user => (
    does => 'Web::Authenticate::User::Role',
    is => 'ro',
);


has auth_redir => (
    does => 'Web::Authenticate::Authenticator::Redirect::Role',
    is => 'ro',
);

# remove undef arguments before constructed
around 'BUILDARGS' => sub {
  my($orig, $self, @params) = @_;
  my $params;

  if(@params == 1 ) {
    ($params) = @params;
  } else {
    $params = { @params };
  }

  for my $key (keys %$params){
    delete $params->{$key} unless defined $params->{$key};
  }

  $self->$orig($params);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Authenticate::Result::CheckForSession - The result of calling Web::Authenticate::check_for_session.

=head1 VERSION

version 0.013

=head1 METHODS

=head2 success

Returns 1 if the call to L<Web::Authenticate/check_for_session> was successful in finding a valid session, undef otherwise.

=head2 user

Returns the user that has a valid session.

=head2 auth_redir

Returns the L<Web::Authenticate::Authenticator::Redirect::Role> object that check_for_session used to redirect.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
