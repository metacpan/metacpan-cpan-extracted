package WebService::ValidSign;
our $VERSION = '0.003';
use Moo;
use namespace::autoclean;

# ABSTRACT: A REST API client for ValidSign

use Module::Pluggable::Object;
use List::Util qw(first);

has auth => (
    is      => 'ro',
    builder => 1,
    lazy    => 1,
    handles => [qw(token)],
);

has package => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

has account => (
    is      => 'ro',
    lazy    => 1,
    builder => 1,
);

{
    my @API_PLUGINS;
    my $search_path = 'WebService::ValidSign::API';
    sub __build_api_package {
        my ($self, $pkg) = @_;

        if (!@API_PLUGINS) {
            my $finder = Module::Pluggable::Object->new(
                search_path => $search_path,
                require     => 1,
            );
            @API_PLUGINS = $finder->plugins;
        }

        if (my $plugin = first { $pkg eq $_ } @API_PLUGINS) {
            return $pkg->new(
                $self->args_builder,
                $pkg eq 'WebService::ValidSign::API::Auth' ? () : (
                    auth => $self->auth,
                )
            );
        }
        die sprintf("Unable to load '%s', not found in search path: '%s'!\n",
            $pkg, $search_path);
    }
}

sub _build_auth {
    my $self = shift;
    return $self->__build_api_package('WebService::ValidSign::API::Auth');
}

sub _build_package {
    my $self = shift;
    return $self->__build_api_package('WebService::ValidSign::API::DocumentPackage');
}

sub _build_account {
    my $self = shift;
    return $self->__build_api_package('WebService::ValidSign::API::Account');
}

with "WebService::ValidSign::API::Constructor";

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign - A REST API client for ValidSign

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::ValidSign;
    use WebService::ValidSign::Object::DocumentPackage;
    use WebService::ValidSign::Object::Document;

    my $client = WebService::ValidSign->new(
        secret   => 'my very secret API key',
        endpoint => 'https://my.validsign.nl/api'
        lwp      => LWP::UserAgent->new(), # optional
    );

    my $documentpackage = WebService::ValidSign::Object::DocumentPackage->new(
        name => "Document package name"
    );

    my $senders = $client->account->senders(search => $sender);
    if (!@$senders) {
        die "Unable to find sender $opts{senders}\n";
    }
    elsif (@$senders > 1) {
        die "Multiple senders found for $opts{senders}\n";
    }
    $documentpackage->sender($senders->[0]);

    my $signers = $client->account->senders(search => $signer);
    if (!@$signers) {
        die "Unable to find sender $signer\n";
    }
    # at this moment only one signer is supported
    elsif (@$signers > 1) {
        die "Multiple senders found for $signer}\n";
    }
    $documentpackage->add_signer('rolename' => signers->[0]);

    my @documents = qw(
        /path/to/documents/foo.bar
        /path/to/documents/foo.txt
    );
    foreach (@documents) {
        my $document = WebService::ValidSign::Object::Document->new(
            name => "$_",
            path => $_,
        );
        $documentpackage->add_document($document);
    }

    my $id = $client->package->create($documentpackage);
    print "Created package with ID $id", $/;
    my $details = $client->package->details($documentpackage);

=head1 DESCRIPTION

A module that uses the ValidSign API to create/upload and sign documents.
This module is in ALPHA state and is subject to change at any given moment
without notice.

=head1 ATTRIBUTES

This module extends L<WebService::ValidSign::API::Constructor> and all of its
attributes.

=over

=item secret

Your API key

=item endpoint

The API URI endpoint as described in the Application Integrator's Guide

=item lwp

An L<LWP::UserAgent> object.

=item auth

An L<WebService::ValidSign::API::Auth> object. Build for you.

=item package

An L<WebService::ValidSign::API::DocumentPackage> object. Build for you.

=item account

An L<WebService::ValidSign::API::Account> object. Build for you.

=back

=head1 BUGS

L<JSON::XS> 4.01 has a bug that causes JSON serialization errors. Please
upgrade or downgrade JSON::XS where needed.

=head1 ACKNOWLEDGEMENTS

This module has been made possible by my employer L<Mintlab
B.V.|https://mintlab.nl> who uses this module in their open source product
L<Zaaksysteem|https://zaaksysteem.nl>.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
