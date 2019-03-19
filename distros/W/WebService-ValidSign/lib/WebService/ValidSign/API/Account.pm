package WebService::ValidSign::API::Account;

our $VERSION = '0.003';
use Moo;
use namespace::autoclean;

# ABSTRACT: A REST API client for ValidSign

use WebService::ValidSign::Object::Sender;

has action_endpoint => (
    is      => 'ro',
    default => 'account'
);

sub details {
    my $self = shift;

    my $uri = $self->get_endpoint($self->action_endpoint);
    my $request = HTTP::Request->new(
        GET => $uri,
        [
            'Content-Type' => 'application/json',
            Accept         => 'application/json',
        ]
    );
    return $self->call_api($request);

}

sub senders {
    my ($self, %params) = @_;

    my $uri = $self->get_endpoint($self->action_endpoint, 'senders');
    $uri->query_form(%params) if %params;

    my $request = HTTP::Request->new(
        GET => $uri,
        [
            'Content-Type' => 'application/json',
            Accept         => 'application/json',
        ]
    );

    my $response = $self->call_api($request);
    my @senders;
    foreach (@{$response->{results}}) {
        push(@senders, WebService::ValidSign::Object::Sender->new(%{$_}));
    }

    return \@senders;
}

with "WebService::ValidSign::API";

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::API::Account - A REST API client for ValidSign

=head1 VERSION

version 0.003

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
