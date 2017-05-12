package WWW::Namecheap::Domain;

use 5.006;
use strict;
use warnings;
use Carp();
use MIME::Base64();

=head1 NAME

WWW::Namecheap::Domain - Namecheap API domain methods

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Namecheap API domain methods.

See L<WWW::Namecheap::API> for main documentation.

    use WWW::Namecheap::Domain;

    my $domain = WWW::Namecheap::Domain->new(API => $api);
    $domain->check(...);
    $domain->create(...);
    ...

=head1 SUBROUTINES/METHODS

=head2 WWW::Namecheap::Domain->new(API => $api)

Instantiate a new Domain object for making domain-related API calls.
Requires a WWW::Namecheap::API object.

=cut

sub new {
    my $class = shift;

    my $params = _argparse(@_);

    for (qw(API)) {
        Carp::croak("${class}->new(): Mandatory parameter $_ not provided.") unless $params->{$_};
    }

    my $self = {
        api => $params->{'API'},
    };

    return bless($self, $class);
}

=head2 $domain->check(Domains => ['example.com'])

Check a list of domains.  Returns a hashref of availablity status with
domain names as the keys and 0/1 as the values for not available/available.

    my $result = $domain->check(Domains => [qw(
        example.com
        example2.com
        foobar.com
    )]);

Will give a $result something like:

    $result = {
        'example.com' => 0,  # example.com is taken
        'example2.com' => 1, # example2.com is available
        'foobar.com' => 0,   # damn, foobar.com is taken
    };

=cut

sub check {
    my $self = shift;

    my $params = _argparse(@_);

    my %domains = map { $_ => -1 } @{$params->{'Domains'}};
    my $DomainList = join(',', keys %domains);
    my $xml = $self->api->request(
        Command => 'namecheap.domains.check',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
        DomainList => $DomainList,
    );

    return unless $xml;

    my $result = $xml->{CommandResponse}->{DomainCheckResult};
    # XML returns a hashref if only one returned value, otherwise an array
    $result = [$result] if (ref $result eq 'HASH');

    foreach my $entry (@$result) {
        unless ($domains{$entry->{Domain}}) {
            Carp::carp("Unexpected domain found: $entry->{Domain}");
            next;
        }
        if ($entry->{Available} eq 'true') {
            $domains{$entry->{Domain}} = 1;
        } else {
            $domains{$entry->{Domain}} = 0;
        }
    }

    return \%domains;
}

=head2 $domain->create(%hash)

Register a new domain name.

Example:

  my $result = $domain->create(
      UserName => 'username',    # optional if DefaultUser specified in $api
      ClientIp => '1.2.3.4',     # optional if DefaultIp specified in $api
      DomainName => 'example.com',
      Years => 1,                                # required; default is 2
      Registrant => {
          OrganizationName => 'Example Dot Com', # optional
          JobTitle => 'CTO',                     # optional
          FirstName => 'Domain',
          LastName => 'Manager',
          Address1 => '123 Fake Street',
          Address2 => 'Suite 555',               # optional
          City => 'Univille',
          StateProvince => 'SD',
          StateProvinceChoice => 'S',            # optional; 'S' for 'State' or 'P' for 'Province'
          PostalCode => '12345',
          Country => 'US',
          Phone => '+1.2025551212',
          PhoneExt => '4444',                    # optional
          Fax => '+1.2025551212',                # optional
          EmailAddress => 'foo@example.com',
      },
      Tech => {
          # same fields as Registrant
      },
      Admin => {
          # same fields as Registrant
      },
      AuxBilling => {
          # same fields as Registrant
      },
      Billing => {
          # Optional; fields as Registrant except OrganizationName, JobTitle
      },
      Nameservers => 'ns1.foo.com,ns2.bar.com', # optional
      AddFreeWhoisguard => 'yes',               # or 'no', default 'no'
      WGEnabled => 'yes',                       # or 'no', default 'no'
      PromotionCode => 'some-string',           # optional
      IdnCode => '',                            # optional, see Namecheap API doc
      'Extended attributes' => '',              # optional, see Namecheap API doc
      IsPremiumDomain => '',                    # optional, see Namecheap API doc
      PremiumPrice => '',                       # optional, see Namecheap API doc
      EapFreee => '',                           # optional, see Namecheap API doc
  );

Unspecified contacts will be automatically copied from Registrant, which
must be provided.

Returns:

    $result = {
        Domain => 'example.com',
        DomainID => '12345',
        Registered => 'true',
        OrderID => '12345',
        TransactionID => '12345',
        ChargedAmount => '10.45', # dollars and cents
    };

=cut

sub create {
    my $self = shift;

    my $params = _argparse(@_);

    my %request = (
        Command => 'namecheap.domains.create',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
        DomainName => $params->{'DomainName'},
        Years => $params->{Years},
    );

    # Optional parameters are only included if supplied in the function argument
    foreach my $parameter (qw(PromotionCode Nameservers IdnCode AddFreeWhoisguard WGEnabled IsPremiumDomain PremiumPrice EapFee), 'Extended attributes') {
        $request{$parameter} = $params->{$parameter} if (exists $params->{$parameter});
    }

    foreach my $contact (qw(Registrant Tech Admin AuxBilling)) {
        $params->{$contact} ||= $params->{Registrant};
        map { $request{"$contact$_"} = $params->{$contact}{$_} } keys %{$params->{$contact}};
    }

    if ($params->{Billing}) {
        my $contact = "Billing";
        # Billing does not have these keys: OrganizationName, JobTitle
        map { $request{"$contact$_"} = $params->{$contact}{$_} } keys %{$params->{$contact}};
    }

    my $xml = $self->api->request(%request);

    return unless $xml;

    return $xml->{CommandResponse}->{DomainCreateResult};
}

=head2 $domain->getinfo(DomainName => 'example.com')

Returns a hashref containing information about the requested domain.

=cut

sub getinfo {
    my $self = shift;

    my $params = _argparse(@_);

    return unless $params->{'DomainName'};

    my %request = (
        Command => 'namecheap.domains.getinfo',
        %$params,
    );

    my $xml = $self->api->request(%request);

    return unless ($xml && $xml->{Status} eq 'OK');

    return $xml->{CommandResponse}->{DomainGetInfoResult};
}

=head2 $domain->list(%hash)

Get a list of domains in your account.  Automatically handles the Namecheap
"paging" to get a full list.  May be optionally restricted:

    my $domains = $domain->list(
        ListType => 'ALL', # or EXPIRING or EXPIRED
        SearchTerm => 'foo', # keyword search
        SortBy => 'NAME', # or EXPIREDATE, CREATEDATE, or *_DESC
    );

Returns an arrayref of hashrefs:

    $domains = [
        {
            ID => '123',
            Name => 'example.com',
            User => 'owner',
            Created => 'MM/DD/YYYY',
            Expires => 'MM/DD/YYYY',
            IsExpired => 'false',
            IsLocked => 'true',
            AutoRenew => 'false',
            WhoisGuard => 'ENABLED',
        },
        ...
    ];

=cut

sub list {
    my $self = shift;

    my $params = _argparse(@_);

    my %request = (
        Command => 'namecheap.domains.getList',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
        PageSize => 100,
        Page => 1,
        ListType => $params->{'ListType'},
        SearchTerm => $params->{'SearchTerm'},
    );

    my @domains;

    my $break = 0;
    while (1) {
        my $xml = $self->api->request(%request);

        last unless $xml;

        if (ref($xml->{CommandResponse}->{DomainGetListResult}->{Domain}) eq 'ARRAY') {
            push(@domains, @{$xml->{CommandResponse}->{DomainGetListResult}->{Domain}});
        } elsif (ref($xml->{CommandResponse}->{DomainGetListResult}->{Domain}) eq 'HASH') {
            push(@domains, $xml->{CommandResponse}->{DomainGetListResult}->{Domain});
        } else {
            Carp::carp('Unexpected XML in CommandResponse->DomainGetListResult->Domain!');
        }
        if ($xml->{CommandResponse}->{Paging}->{TotalItems} <= ($request{Page} * $request{PageSize})) {
            last;
        } else {
            $request{Page}++;
        }
    }

    return \@domains;
}

=head2 $domain->getcontacts(DomainName => 'example.com')

Get the contacts on file for the provided DomainName.  Returns a big
ol' data structure:

    $contacts = {
        Domain => 'example.com',
        domainnameid => '12345',
        Registrant => {
            ReadOnly => 'false',
            ... all contact fields from create ...
        },
        Tech => {
            ... ditto ...
        },
        Admin => {
            ... ditto ...
        },
        AuxBilling => {
            ... ditto ...
        },
        WhoisGuardContact => {
            ... same contacts as outside, except the actual published
                WhoisGuard info, ReadOnly => 'true' ...
        },
    };

=cut

sub getcontacts {
    my $self = shift;

    my $params = _argparse(@_);

    return unless $params->{'DomainName'};

    my %request = (
        Command => 'namecheap.domains.getContacts',
        %$params,
    );

    my $xml = $self->api->request(%request);

    return unless $xml;

    return $xml->{CommandResponse}->{DomainContactsResult};
}

=head2 $domain->setcontacts(%hash)

Set contacts for a domain name.

Example:

  my $result = $domain->create(
      UserName => 'username', # optional if DefaultUser specified in $api
      ClientIp => '1.2.3.4', # optional if DefaultIp specified in $api
      DomainName => 'example.com',
      Registrant => {
          OrganizationName => 'Example Dot Com', # optional
          FirstName => 'Domain',
          LastName => 'Manager',
          Address1 => '123 Fake Street',
          Address2 => 'Suite 555', # optional
          City => 'Univille',
          StateProvince => 'SD',
          StateProvinceChoice => 'S', # for 'State' or 'P' for 'Province'
          PostalCode => '12345',
          Country => 'USA',
          Phone => '+1.2025551212',
          Fax => '+1.2025551212', # optional
          EmailAddress => 'foo@example.com',
      },
      Tech => {
          # same fields as Registrant
      },
      Admin => {
          # same fields as Registrant
      },
      AuxBilling => {
          # same fields as Registrant
      },
  );

Unspecified contacts will be automatically copied from the registrant, which
must be provided.

$result is a small hashref confirming back the domain that was modified
and whether the operation was successful or not:

    $result = {
        Domain => 'example.com',
        IsSuccess => 'true',
    };

=cut

sub setcontacts {
    my $self = shift;

    my $params = _argparse(@_);

    return unless $params->{'DomainName'};

    my %request = (
        Command => 'namecheap.domains.setContacts',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
        DomainName => $params->{'DomainName'},
    );

    foreach my $contact (qw(Registrant Tech Admin AuxBilling)) {
        $params->{$contact} ||= $params->{Registrant};
        map { $request{"$contact$_"} = $params->{$contact}{$_} } keys %{$params->{$contact}};
    }

    my $xml = $self->api->request(%request);

    return unless $xml;

    return $xml->{CommandResponse}->{DomainSetContactResult};
}

=head2 $domain->gettldlist()

Get a list of all TLDs available for registration, along with various
attributes for each TLD.  Results are automatically cached for one
hour to avoid excessive API load.

=cut

sub gettldlist {
    my $self = shift;

    my $params = _argparse(@_);

    my %request = (
        Command => 'namecheap.domains.getTldList',
        %$params,
    );

    if (!$self->{_tldlist_cachetime} || time() - $self->{_tldlist_cachetime} > 3600) {
        my $xml = $self->api->request(%request);
        $self->{_tldlist_cache} = $xml->{CommandResponse}->{Tlds}->{Tld};
        $self->{_tldlist_cachetime} = time();
    }

    return $self->{_tldlist_cache};
}

=head2 $domain->transfer(%hash)

Initiate a transfer in request to Namecheap from another registrar.
Request should look something like:

    my $transfer = $domain->transfer(
        DomainName => 'example.com',
        Years => 1,
        EPPCode => 'foobarbaz',
    );

The response will be a hashref:

    $transfer = {
        Transfer => 'true',
        TransferID => '15',
        StatusID => '-1',
        OrderID => '1234',
        TransactionID => '1234',
        ChargedAmount => '10.10',
    };

For transfer status code details, see the Namecheap API documentation:

L<https://www.namecheap.com/support/api/domains-transfer/transfer-statuses.aspx>

=cut

sub transfer {
    my $self = shift;

    my $params = _argparse(@_);

    my $b64epp;
    if ($params->{EPPCode} && $params->{EPPCode} !~ /^base64:/) {
        $b64epp = MIME::Base64::encode($params->{EPPCode});
        $params->{EPPCode} = "base64:$b64epp";
    }
    my %request = (
        Command => 'namecheap.domains.transfer.create',
        %$params,
    );

    my $xml = $self->api->request(%request);

    return unless $xml;

    return $xml->{CommandResponse}->{DomainTransferCreateResult};
}

=head2 $domain->transferstatus(TransferID => '1234')

Check the current status of a particular transfer.  The TransferID
is the TransferID returned by the transfer() call, or included in
the transferlist().  Returns a hashref:

    $result = {
        TransferID => '1234',
        Status => 'String',
        StatusID => '-1',
    };

=cut

sub transferstatus {
    my $self = shift;

    my $params = _argparse(@_);

    my %request = (
        Command => 'namecheap.domains.transfer.getStatus',
        %$params,
    );

    my $xml = $self->api->request(%request);

    return unless $xml;

    return $xml->{CommandResponse}->{DomainTransferGetStatusResult};
}

=head2 $domain->transferlist()

Retrieve a list of transfers associated with the connected API account.
Automatically handles the Namecheap "paging" to get a full list.  May
be optionally restricted:

    my $transfers = $domain->transferlist(
        ListType => 'ALL', # or INPROGRESS, CANCELLED, COMPLETED
        SearchTerm => 'foo', # keyword search
        SortBy => 'DOMAINNAME', # or TRANSFERDATE, STATUSDATE, *_DESC
    );

Returns an arrayref of hashrefs:

    $domains = [
        {
            ID => '123',
            DomainName => 'example.com',
            User => 'apiuser',
            TransferDate => 'MM/DD/YYYY',
            OrderID => 12345,
            StatusID => 20
            Status => 'Cancelled',
            StatusDate => 'MM/DD/YYYY',
            StatusDescription => 'String',
        }
        ...
    ];

=cut

sub transferlist {
    my $self = shift;

    my $params = _argparse(@_);

    my %request = (
        Command => 'namecheap.domains.transfer.getList',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
        PageSize => 100,
        Page => 1,
        ListType => $params->{'ListType'},
        SearchTerm => $params->{'SearchTerm'},
    );

    my @transfers;

    my $break = 0;
    while (1) {
        my $xml = $self->api->request(%request);

        last unless $xml;

        push(@transfers, @{$xml->{CommandResponse}->{TransferGetListResult}->{Transfer}});
        if ($xml->{CommandResponse}->{Paging}->{TotalItems} <= ($request{Page} * $request{PageSize})) {
            last;
        } else {
            $request{Page}++;
        }
    }

    return \@transfers;
}

=head2 $domain->api()

Accessor for internal API object.

=cut

sub api {
    return $_[0]->{api};
}

sub _argparse {
    my $hashref;
    if (@_ % 2 == 0) {
        $hashref = { @_ }
    } elsif (ref($_[0]) eq 'HASH') {
        $hashref = \%{$_[0]};
    }
    return $hashref;
}

=head1 AUTHOR

Tim Wilde, C<< <twilde at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-namecheap-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Namecheap-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Namecheap::Domain


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Namecheap-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Namecheap-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Namecheap-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Namecheap-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Tim Wilde.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Namecheap::Domain
