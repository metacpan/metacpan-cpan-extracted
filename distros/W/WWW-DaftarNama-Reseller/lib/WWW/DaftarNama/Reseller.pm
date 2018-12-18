package WWW::DaftarNama::Reseller;

our $DATE = '2018-12-17'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter::Rinci qw(import);

our %SPEC;

my %args_common = (
    username => {
        schema => 'str*',
        req => 1,
        tags => ['common', 'category:credential'],
    },
    password => {
        schema => 'str*',
        req => 1,
        is_password => 1,
        tags => ['common', 'category:credential'],
    },
    idkey => {
        schema => 'str*',
        req => 1,
        is_password => 1,
        tags => ['common', 'category:credential'],
    },
);

my %arg0_domain = (
    domain => {
        schema => 'domain::name*',
        req => 1,
        pos => 0,
    },
);

my %args_ns = (
    ns1 => {schema => 'net::hostname*', req=>1},
    ns2 => {schema => 'net::hostname*', req=>1},
    ns3 => {schema => 'net::hostname*', req=>1},
    ns4 => {schema => 'net::hostname*', req=>1},
);

my %args_contact = (
    firstname => {schema => 'str*', req=>1},
    lastname => {schema => 'str*', req=>1},
    company => {schema => 'str*', req=>1},
    address => {schema => 'str*', req=>1},
    city => {schema => 'str*', req=>1},
    state => {schema => 'str*', req=>1},
    zip => {schema => 'str*', req=>1},
    country => {schema => 'str*', req=>1},
    email => {schema => 'str*', req=>1}, # XXX email
    phone => {schema => 'str*', req=>1}, # XXX phone::number
);

my %arg_ns = (
    ns => {schema => 'net::hostname*', req=>1},
);

sub _request {
    require HTTP::Tiny;
    require JSON::MaybeXS;

    my (%args) = @_;

    my $url = "https://www.daftarnama.id/api/provider.php";
    my $res = HTTP::Tiny->new->post_form($url, \%args);
    return [$res->{status}, "Can't post to $url: $res->{reason}"]
        unless $res->{success};

    my $data;
    eval { $data = JSON::MaybeXS::decode_json($res->{content}) };
    return [500, "Invalid JSON response from server: $@"] if $@;

    [200, "OK", $data];
}

$SPEC{get_ns} = {
    v => 1.1,
    summary => 'Get nameservers for a domain',
    args => {
        %args_common,
        %arg0_domain,
    },
};
sub get_ns {
    my %args = @_;
    _request(
        action => 'getDNS',
        %args,
    );
}

$SPEC{update_ns} = {
    v => 1.1,
    summary => 'Update nameservers for a domain',
    args => {
        %args_common,
        %arg0_domain,
        %args_ns,
    },
};
sub update_ns {
    my %args = @_;
    _request(
        action => 'updateDNS',
        %args,
    );
}

$SPEC{get_lock_status} = {
    v => 1.1,
    summary => 'Get lock status for a domain',
    args => {
        %args_common,
        %arg0_domain,
    },
};
sub get_lock_status {
    my %args = @_;
    _request(
        action => 'getStatus',
        %args,
    );
}

$SPEC{update_lock_status} = {
    v => 1.1,
    summary => 'Update lock status for a domain',
    args => {
        %args_common,
        %arg0_domain,
        statusKey => {schema => 'str*', req=>1},
    },
};
sub update_lock_status {
    my %args = @_;
    _request(
        action => 'changeStatus',
        %args,
    );
}

$SPEC{register} = {
    v => 1.1,
    summary => 'Register a domain',
    args => {
        %args_common,
        %arg0_domain,

        periode => {schema => ['int*', between=>[1,10]]},
        %args_ns,
        %args_contact,
    },
};
sub register {
    my %args = @_;
    _request(
        action => 'domainRegister',
        %args,
    );
}

$SPEC{transfer} = {
    v => 1.1,
    summary => 'Transfer a domain',
    args => {
        %args_common,
        %arg0_domain,
        eppCode => {schema => 'str*', req=>1},
    },
};
sub transfer {
    my %args = @_;
    _request(
        action => 'domainRegister',
        %args,
    );
}

$SPEC{renew} = {
    v => 1.1,
    summary => 'Renew a domain',
    args => {
        %args_common,
        %arg0_domain,
        eppCode => {schema => 'str*', req=>1},
    },
};
sub renew {
    my %args = @_;
    _request(
        action => 'domainRenewal',
        %args,
    );
}

$SPEC{get_contact} = {
    v => 1.1,
    summary => 'Get contact information for a domain',
    args => {
        %args_common,
        %arg0_domain,
    },
};
sub get_contact {
    my %args = @_;
    _request(
        action => 'whoisDomain',
        %args,
    );
}

$SPEC{update_contact} = {
    v => 1.1,
    summary => 'Update contact information for a domain',
    args => {
        %args_common,
        %arg0_domain,
        %args_contact,
        contacttype => {
            schema => ['str*', in=>[qw/all reg admin tech billing/]],
            req => 1,
        },
    },
};
sub update_contact {
    my %args = @_;
    _request(
        action => 'updateWhois',
        %args,
    );
}

$SPEC{get_epp} = {
    v => 1.1,
    summary => 'Get EPP Code for a domain',
    args => {
        %args_common,
        %arg0_domain,
    },
};
sub get_epp {
    my %args = @_;
    _request(
        action => 'getEPP',
        %args,
    );
}

$SPEC{register_ns} = {
    v => 1.1,
    summary => 'Register a nameserver',
    args => {
        %args_common,
        %arg0_domain,
        %arg_ns,
        ip => {schema => 'net::ipv4*', req=>1},
    },
};
sub register_ns {
    my %args = @_;
    _request(
        action => 'hostRegister',
        %args,
    );
}

$SPEC{delete_ns} = {
    v => 1.1,
    summary => 'Delete a nameserver',
    args => {
        %args_common,
        %arg0_domain,
        %arg_ns,
    },
};
sub delete_ns {
    my %args = @_;
    _request(
        action => 'deleteHost',
        %args,
    );
}

$SPEC{get_registrar} = {
    v => 1.1,
    summary => 'Get registrar of a domain',
    args => {
        %args_common,
        %arg0_domain,
    },
};
sub get_registrar {
    my %args = @_;
    _request(
        action => 'getRegistrar',
        %args,
    );
}

$SPEC{check_availability} = {
    v => 1.1,
    summary => 'Check the availability of a domain',
    args => {
        %args_common,
        %arg0_domain,
    },
};
sub check_availability {
    my %args = @_;
    _request(
        action => 'checkAvailibility',
        %args,
    );
}

# XXX: uploadDocument
# XXX: changeStatuses
# XXX: checkDocument
# XXX: docType
# XXX: deleteDomain
# XXX: deleteDNSSec
# XXX: getEXP
# XXX: getRegistrar
# XXX: updateDNSSec
# XXX: domainRestore

1;
# ABSTRACT: Reseller API client for DaftarNama.id

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaftarNama::Reseller - Reseller API client for DaftarNama.id

=head1 VERSION

This document describes version 0.002 of WWW::DaftarNama::Reseller (from Perl distribution WWW-DaftarNama-Reseller), released on 2018-12-17.

=head1 SYNOPSIS

 use WWW::DaftarNama::Reseller qw(
     get_dns
     # ...
 );

 my $res = get_dns(
     # to get these credentials, first sign up as a reseller at https://daftarnama.id
     username => '...',
     password => '...',
     idkey    => '...',

     domain   => 'shopee.co.id',
 );

=head1 DESCRIPTION

DaftarNama.id, L<https://daftarnama.id>, is an Indonesian TLD (.id) registrar.
This module provides interface to the reseller API.

=head1 FUNCTIONS


=head2 check_availability

Usage:

 check_availability(%args) -> [status, msg, payload, meta]

Check the availability of a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 delete_ns

Usage:

 delete_ns(%args) -> [status, msg, payload, meta]

Delete a nameserver.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<ns>* => I<net::hostname>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_contact

Usage:

 get_contact(%args) -> [status, msg, payload, meta]

Get contact information for a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_epp

Usage:

 get_epp(%args) -> [status, msg, payload, meta]

Get EPP Code for a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_lock_status

Usage:

 get_lock_status(%args) -> [status, msg, payload, meta]

Get lock status for a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_ns

Usage:

 get_ns(%args) -> [status, msg, payload, meta]

Get nameservers for a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_registrar

Usage:

 get_registrar(%args) -> [status, msg, payload, meta]

Get registrar of a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 register

Usage:

 register(%args) -> [status, msg, payload, meta]

Register a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<address>* => I<str>

=item * B<city>* => I<str>

=item * B<company>* => I<str>

=item * B<country>* => I<str>

=item * B<domain>* => I<domain::name>

=item * B<email>* => I<str>

=item * B<firstname>* => I<str>

=item * B<idkey>* => I<str>

=item * B<lastname>* => I<str>

=item * B<ns1>* => I<net::hostname>

=item * B<ns2>* => I<net::hostname>

=item * B<ns3>* => I<net::hostname>

=item * B<ns4>* => I<net::hostname>

=item * B<password>* => I<str>

=item * B<periode> => I<int>

=item * B<phone>* => I<str>

=item * B<state>* => I<str>

=item * B<username>* => I<str>

=item * B<zip>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 register_ns

Usage:

 register_ns(%args) -> [status, msg, payload, meta]

Register a nameserver.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<ip>* => I<net::ipv4>

=item * B<ns>* => I<net::hostname>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 renew

Usage:

 renew(%args) -> [status, msg, payload, meta]

Renew a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<eppCode>* => I<str>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 transfer

Usage:

 transfer(%args) -> [status, msg, payload, meta]

Transfer a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<eppCode>* => I<str>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 update_contact

Usage:

 update_contact(%args) -> [status, msg, payload, meta]

Update contact information for a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<address>* => I<str>

=item * B<city>* => I<str>

=item * B<company>* => I<str>

=item * B<contacttype>* => I<str>

=item * B<country>* => I<str>

=item * B<domain>* => I<domain::name>

=item * B<email>* => I<str>

=item * B<firstname>* => I<str>

=item * B<idkey>* => I<str>

=item * B<lastname>* => I<str>

=item * B<password>* => I<str>

=item * B<phone>* => I<str>

=item * B<state>* => I<str>

=item * B<username>* => I<str>

=item * B<zip>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 update_lock_status

Usage:

 update_lock_status(%args) -> [status, msg, payload, meta]

Update lock status for a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<password>* => I<str>

=item * B<statusKey>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 update_ns

Usage:

 update_ns(%args) -> [status, msg, payload, meta]

Update nameservers for a domain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<domain>* => I<domain::name>

=item * B<idkey>* => I<str>

=item * B<ns1>* => I<net::hostname>

=item * B<ns2>* => I<net::hostname>

=item * B<ns3>* => I<net::hostname>

=item * B<ns4>* => I<net::hostname>

=item * B<password>* => I<str>

=item * B<username>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WWW-DaftarNama-Reseller>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WWW-DaftarNama-Reseller>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW-DaftarNama-Reseller>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
