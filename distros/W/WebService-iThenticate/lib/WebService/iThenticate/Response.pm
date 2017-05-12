package WebService::iThenticate::Response;

use strict;
use warnings;

our $VERSION = 0.16;

=head1 NAME

WebService::iThenticate::Response - manipulate response objects for the WebService::iThenticate

=head1 SYNOPSIS

 # make the request
 $response = $ithenticate_api_client->login;

 # check for any errors
 my %errors = %{ $response->errors };
 foreach my $key ( keys %errors ) {
     warn(sprintf('Error %s encountered, message %s', $key, $errors{$key}));
 }

 # grab the numeric api status code
 $api_status_code = $response->api_status;

 # grab the session id
 $sid = $response->sid

=head1 DESCRIPTION

This class encapsulates responses received from the WebService::iThenticate

=cut


=head1 METHODS

=over 4

=cut

# new is a private method in this class so don't perldoc it

sub _new {
    my $class = shift;
    my $response = shift or die 'need a response object';

    my %self = ();
    $self{rpc_response} = $response;
    bless \%self, $class;

    return \%self;
}

=item errors()

 %errors = %{ $response->errors };

Returns a hash reference of error name => error value, or undefined if no
errors present.

=cut

sub errors {
    my $self = shift;

    # return if no errors
    return unless exists $self->{rpc_response}->{errors};

    # if there are errors, they are either in array form or array
    if ( ref( $self->{rpc_response}->{errors} ) eq 'RPC::XML::array' ) {

        # errors returned in an array
        return map { $_->value } @{ $self->{rpc_response}->{errors} };
    }

    # errors returned in a hash
    my %errors = map { $_ => $self->{rpc_response}->{errors}->{$_}->value->[0] } keys %{ $self->{rpc_response}->{errors} };

    return unless keys %errors;

    return \%errors;
} ## end sub errors


=item sid()

 $sid = $response->sid;

Returns the session id for an authenticated client, or undefined if
the client has not authenticated (no session present).

=cut


sub sid {
    my $self = shift;

    return unless $self->{rpc_response}->{sid};

    return $self->{rpc_response}->{sid}->value;
}

=item as_xml()

 $xml_response = $response->as_xml;

Returns the stringified xml response

=cut

sub as_xml {

    my $self = shift;

    die "no rpc_response object\n" unless exists $self->{rpc_response};

    return $self->{rpc_response}->as_string;
}

=item timestamp()

 $timestamp = $response->timestamp;

Returns the timestamp of the api response in the format 
iso8601 XMLRPC field in UTC (with a "Z" appended).

=cut

sub timestamp {

    my $self = shift;

    return unless $self->{rpc_response}->{response_timestamp};

    return $self->{rpc_response}->{response_timestamp};
}


=item api_status()

 $api_status = $response->api_status;

Returns the numeric api status code for the client request.

Values correspond to HTTP status codes, e.g. 200 OK, 404 Not Found, etc.

=cut

sub api_status {
    my $self = shift;

    return unless $self->{rpc_response}->{api_status};

    return $self->{rpc_response}->{api_status}->value;
}


=item id()

 $id = $response->id;

Returns the id of a newly created object

=cut

sub id {
    my $self = shift;

    return unless $self->{rpc_response}->{id};

    return $self->{rpc_response}->{id}->value;
}

=item report()

 $report = $response->report;

 # a url to view the report which requires user authentication
 $report_url = $report->{report_url};

 # a view only report url which expires in a set amount of time
 $view_only_url = $report->{view_only_url};

 # the expiration time in minutes of the $view_only_url
 $view_only_expires = $report->{view_only_expires};

Returns a hash reference containing links to view the report, one link
requires authentication, one does not but expires a set amount of time
after the api request is made.

=cut

sub report {
    my $self = shift;

    my %response = map { $_ => $self->{rpc_response}->{$_}->value }
        qw( report_url view_only_url view_only_expires );

    return \%response;
}



=item document()

 $document = $response->document;

Returns an hash reference of the document data

=cut

sub document {
    my $self = shift;

    return unless $self->{rpc_response}->{document};

    my $document = $self->{rpc_response}->{document};

    my %hash;
    foreach my $key ( keys %{$document} ) {
        $hash{$key} = $document->{$key}->value;
    }

    return \%hash;
}


=item account()

 $account = $response->account;

Returns a hash reference of the account status

=cut

sub account {
    my $self = shift;

    return unless $self->{rpc_response}->{account};

    my $account = $self->{rpc_response}->{account};

    my %status_hash;
    foreach my $key ( keys %{$account} ) {
        $status_hash{$key} = $account->{$key}->value;
    }

    return \%status_hash;
}



=item folder()

 $folder = $response->folder;

Returns a hash reference of the folder data

=cut

sub folder {
    my $self = shift;

    return unless $self->{rpc_response}->{folder};

    my $folder = $self->{rpc_response}->{folder};

    my %folder_hash;
    foreach my $key ( keys %{$folder} ) {
        $folder_hash{$key} = $folder->{$key}->value;
    }

    return \%folder_hash;
}

=item uploaded()

 $uploaded = $response->uploaded;

Returns an array reference of document hash references

=cut

sub uploaded {
    my $self = shift;

    return unless defined $self->{rpc_response}->{uploaded}->[0];

    my @uploaded;
    foreach my $upload ( @{ $self->{rpc_response}->{uploaded} } ) {
        my %hash;

        foreach my $key ( keys %{$upload} ) {

            $hash{$key} = $upload->{$key}->value;
        }
        push @uploaded, \%hash;
    }

    return \@uploaded;
}



=item documents()

 $documents = $response->documents;

Returns an array reference of document hash references

=cut

sub documents {
    my $self = shift;

    return unless defined $self->{rpc_response}->{documents}->[0];

    my @documents;
    foreach my $doc ( @{ $self->{rpc_response}->{documents} } ) {
        my %hash;

        foreach my $key ( keys %{$doc} ) {

            $hash{$key} = $doc->{$key}->value;
        }
        push @documents, \%hash;
    }

    return \@documents;
}


=item groups()

 @groups = @{ $response->groups };

Returns an array reference of group hash references

=cut


sub groups {
    my $self = shift;

    return unless defined $self->{rpc_response}->{groups};

    my @groups;
    foreach my $group ( @{ $self->{rpc_response}->{groups} } ) {
        my %hash;

        foreach my $key ( keys %{$group} ) {

            $hash{$key} = $group->{$key}->value;
        }
        push @groups, \%hash;
    }

    return \@groups;
}


=item folders()

 $folders_array_reference = $response->folders;

where the array reference contains a set of hash references
with the folder data

 [ {
    folder_id => '1',
    name      => 'test_folder',
   },
   {
    ...
   },
 ]

Returns an array reference of folder hash references

=cut

sub folders {
    my $self = shift;

    return unless defined $self->{rpc_response}->{folders};

    my @folders;
    foreach my $folder ( @{ $self->{rpc_response}->{folders} } ) {
        my %hash;

        foreach my $key ( keys %{$folder} ) {

            $hash{$key} = $folder->{$key}->value;
        }
        push @folders, \%hash;
    }

    return \@folders;
}


=item users()

 @users = @{ $response->users };

Returns an array reference of user hash references

=cut

sub users {
    my $self = shift;

    return unless defined $self->{rpc_response}->{users};

    my @users;
    foreach my $user ( @{ $self->{rpc_response}->{users} } ) {
        my %hash;

        foreach my $key ( keys %{$user} ) {

            $hash{$key} = $user->{$key}->value;
        }
        push @users, \%hash;
    }

    return \@users;
}



=item messages()

 if ( $response->messages ) {
     @messages = @{ $response->messages };
 }

Returns an array reference of message scalars

=cut

sub messages {
    my $self = shift;

    my $messages_ref = $self->{rpc_response}->{messages};

    return unless defined $messages_ref->[0];

    my @messages = map { $_->value } @{$messages_ref};

    return \@messages;
}




=back

=head1 SEE ALSO

WebService::iThenticate::Request, WebService::iThenticate::Client, RPC::XML

=head1 AUTHOR

Fred Moyer <fred@turnitin.com>

=head1 COPYRIGHT

Copyright (C) (2011) iParadigms, LLC.  All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.

=cut


1;
