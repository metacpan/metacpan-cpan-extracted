# SYNOPSIS

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

# DESCRIPTION

A module that uses the ValidSign API to create/upload and sign documents.

# ATTRIBUTES

This module extends [WebService::ValidSign::API::Constructor](https://metacpan.org/pod/WebService%3A%3AValidSign%3A%3AAPI%3A%3AConstructor) and all of its
attributes.

- secret

    Your API key

- endpoint

    The API URI endpoint as described in the Application Integrator's Guide

- lwp

    An [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) object.

- auth

    An [WebService::ValidSign::API::Auth](https://metacpan.org/pod/WebService%3A%3AValidSign%3A%3AAPI%3A%3AAuth) object. Build for you.

- package

    An [WebService::ValidSign::API::DocumentPackage](https://metacpan.org/pod/WebService%3A%3AValidSign%3A%3AAPI%3A%3ADocumentPackage) object. Build for you.

- account

    An [WebService::ValidSign::API::Account](https://metacpan.org/pod/WebService%3A%3AValidSign%3A%3AAPI%3A%3AAccount) object. Build for you.

# BUGS

[JSON::XS](https://metacpan.org/pod/JSON%3A%3AXS) 4.01 has a bug that causes JSON serialization errors. Please
upgrade or downgrade JSON::XS where needed.

# ACKNOWLEDGEMENTS

This module has been made possible by my employer [Mintlab
B.V.](https://mintlab.nl) who uses this module in their open source product
[Zaaksysteem](https://zaaksysteem.nl).
