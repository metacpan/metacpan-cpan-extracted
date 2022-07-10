package WebService::ValidSign::API::Auth;
our $VERSION = '0.004';
use Moo;

# ABSTRACT: Implementation of the Authentication tokens for ValidSign

use Types::Standard qw(Str);
use namespace::autoclean;

has action_endpoint => (
    is      => 'ro',
    default => 'authenticationTokens'
);

has token => (
    is        => 'rw',
    isa       => Str,
    accessor  => '_token',
    predicate => 'has_token',
);

sub token {
    my $self = shift;

    if ($self->has_token) {
        return $self->_token;
    }
    else {
        return $self->_get_user_token;
    }
}

sub _get_user_token {
    my $self = shift;

    my $uri = $self->get_endpoint($self->action_endpoint, 'user');
    my $request = HTTP::Request->new(
        POST => $uri,
        [
            'Content-Type' => 'application/json',
            Accept         => 'application/json',
        ]
    );

    $request->header("Authorization", join(" ", "Basic", $self->secret));

    $self->_token($self->call_api($request)->{value});
    return $self->_token;
}

with "WebService::ValidSign::API";
has '+auth' => (required => 0);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::API::Auth - Implementation of the Authentication tokens for ValidSign

=head1 VERSION

version 0.004

=head1 SYNOPSIS

=head1 ATTRIBUTES

=head1 METHODS

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
