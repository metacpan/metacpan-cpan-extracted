use strictures;

package WebService::GoogleAPI::Client::AuthStorage::GapiJSON;

our $VERSION = '0.25';    # VERSION

# ABSTRACT: Auth Storage Backend based on gapi.json

use Moo;
use Config::JSON;
use Carp;

with 'WebService::GoogleAPI::Client::AuthStorage';


has 'path' => (is => 'rw', default => './gapi.json');    # default is gapi.json


has 'tokensfile' => (is => 'rw');    # Config::JSON object pointer

# NOTE- this type of class has getters and setters b/c the implementation of
# getting and setting depends on what's storing

sub BUILD {
  my ($self) = @_;
  $self->tokensfile(Config::JSON->new($self->path));
  my $missing = grep !$_, map $self->get_from_storage($_),
    qw/client_id client_secret/;
  croak <<NOCLIENT if $missing;
Malformed gapi.json detected. We need the client_id and client_secret in order
to refresh expired tokens
NOCLIENT

  return $self;
}


sub get_access_token {
  my ($self) = @_;
  my $value = $self->get_from_storage('access_token');
  return $value;
}


sub refresh_access_token {
  my ($self) = @_;
  my %p = map { ($_ => $self->get_from_storage($_)) }
    qw/client_id client_secret refresh_token/;

  croak <<MISSINGCREDS unless $p{refresh_token};
If your credentials are missing the refresh_token - consider removing the auth at
https://myaccount.google.com/permissions as The oauth2 server will only ever mint one refresh
token at a time, and if you request another access token via the flow it will operate as if
you only asked for an access token.
MISSINGCREDS
  my $user = $self->user;

  my $new_token = $self->refresh_user_token(\%p);

  $self->tokensfile->set("gapi/tokens/$user/access_token", $new_token);
  return $new_token;
}

sub get_token_emails_from_storage {
  my ($self) = @_;
  my $tokens = $self->get_from_storage('tokens');
  return [keys %$tokens];
}


sub get_from_storage {
  my ($self, $key) = @_;
  if ($key =~ /_token/) {
    return $self->tokensfile->get("gapi/tokens/${\$self->user}/$key");
  } else {
    return $self->tokensfile->get("gapi/$key");
  }
}

sub get_scopes_from_storage_as_array {
  carp
'get_scopes_from_storage_as_array is being deprecated, please use the more succint scopes accessor';
  return $_[0]->scopes;
}

# NOTE - the scopes are stored as a space seperated list, and this method
# returns an arrayref
#


sub scopes {
  my ($self) = @_;
  return [split / /, $self->tokensfile->get('gapi/scopes')];
}

9011;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::GoogleAPI::Client::AuthStorage::GapiJSON - Auth Storage Backend based on gapi.json

=head1 VERSION

version 0.25

=head1 SYNOPSIS

This class provides an auth backend for gapi.json files produced with the provided L<goauth>
script. This is used for user credentials. For service accounts, please see L<WebService::GoogleAPI::Client::AuthStorage::ServiceAccount>.

In future versions, I hope to provide the functionality of L<goauth> as a
L<Mojolicious::Plugin>, so you can provide this flow in your app rather than having to run it offline.

This class mixes in L<WebService::GoogleAPI::Client::AuthStorage>, and provides
all attributes and methods from that role. As noted there, the C<ua> is usually managed by 
the L<WebService::GoogleAPI::Client> object this is set on.

=head1 ATTRIBUTES

=head2 path

The location of the gapi.json file. Default to gapi.json in the current directory.

=head2 tokensfile

A Config::JSON object that contains the parsed gapi.json file. Authomatically set
at object instantiation.

=head1 METHODS

=head2 get_access_token

Returns the access token for the current user.

=head2 refresh_access_token

This will refresh the access token for the currently set C<user>. Will write the
new token back into the gapi.json file.

If you don't have a refresh token for that user, it will die with the following message:

If your credentials are missing the refresh_token - consider removing the auth at
https://myaccount.google.com/permissions as The oauth2 server will only ever mint one refresh
token at a time, and if you request another access token via the flow it will operate as if
you only asked for an access token.

=head2 get_from_storage

A method to get stored fields from the gapi.json file. Will retrieve tokens for
the current user, and other fields from the global config.

=head2 scopes

Read-only accessor returning the list of scopes configured in the gapi.json file.

=head1 AUTHORS

=over 4

=item *

Veesh Goldman <veesh@cpan.org>

=item *

Peter Scott <localshop@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2021 by Peter Scott and others.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
