package WebService::GoogleAPI::Client::AccessToken;
use strictures;

our $VERSION = '0.27';    # VERSION

# ABSTRACT: A small class for bundling user and scopes with a token
use Moo;

use overload '""' => sub { shift->token };

has [qw/token user scopes/] => is => 'ro',
    required                => 1;


9008

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::AccessToken - A small class for bundling user and scopes with a token

=head1 VERSION

version 0.27

=head1 SYNOPSIS

  my $token = $gapi->get_access_token # returns this class
  # {
  #   token   => '...',
  #   user    => 'the-user-that-it's-for',
  #   scopes  => [ 'the', 'scopes', 'that', 'its', 'for' ]
  # }
  #
  my $res = ... # any api call here
  $res->{_token} # the token the call was made with

This is a simple class which contains the data related to a Google Cloud access token
that bundles the related user and scopes.

It overloads stringification so that interpolating it in, say an auth header,
will return just the token.

This is for introspection purposes, so if something goes wrong, you can check
the response from your request and check the C<_token> hash key on that object.
Note that this is subject to change in future versions (there's probably a saner
way to do this).

=head1 AUTHOR

Veesh Goldman <veesh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2023 by Veesh Goldman and Others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
