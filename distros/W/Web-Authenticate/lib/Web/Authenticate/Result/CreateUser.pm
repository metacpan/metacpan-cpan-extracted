use strict;
package Web::Authenticate::Result::CreateUser;
$Web::Authenticate::Result::CreateUser::VERSION = '0.011';
use Mouse;
#ABSTRACT: The result of calling Web::Authenticate::create_user.


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


has failed_username_verifiers => (
    isa => 'ArrayRef',
    is => 'ro',
    default => sub { [] },
);


has failed_password_verifiers => (
    isa => 'ArrayRef',
    is => 'ro',
    default => sub { [] },
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

Web::Authenticate::Result::CreateUser - The result of calling Web::Authenticate::create_user.

=head1 VERSION

version 0.011

=head1 METHODS

=head2 success

Returns 1 if the call to L<Web::Authenticate/create_user> was successful, undef otherwise.

=head2 user

Returns the user that was created.

=head2 failed_username_verifiers

Returns the username verifiers that failed if there were any. Default is an empty arrayref.

=head2 failed_password_verifiers

Returns the password verifiers that failed if there were any. Default is an empty arrayref.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
