package WWW::Namecheap::DNS;

use 5.006;
use strict;
use warnings;
use Carp();

=head1 NAME

WWW::Namecheap::DNS - Namecheap API DNS methods

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Namecheap API DNS methods.

See L<WWW::Namecheap::API> for main documentation.

    use WWW::Namecheap::DNS;

    my $dns = WWW::Namecheap::DNS->new(API => $api);
    $dns->sethosts(...);
    ...

=head1 SUBROUTINES/METHODS

=head2 WWW::Namecheap::Domain->new(API => $api)

Instantiate a new DNS object for making DNS-related API calls.
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

=head2 $dns->setnameservers(%hash)

Set the nameservers used by a domain under your management.  They may
be set to custom nameservers or the Namecheap default nameservers.

    my $result = $dns->setnameservers(
        DomainName => 'example.com',
        Nameservers => [
            'ns1.example.com',
            'ns2.example.com',
        ],
        DefaultNS => 0,
    );

or, for the Namecheap default:

    my $result = $dns->setnameservers(
        DomainName => 'example.com',
        DefaultNS => 1,
    );

$result is a small hashref confirming back the domain that was modified
and whether the operation was successful or not:

    $result = {
        Domain => 'example.com',
        Update => 'true',
    };

=cut

sub setnameservers {
    my $self = shift;

    my $params = _argparse(@_);

    return unless $params->{DomainName};

    my %request = (
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
    );

    if ($params->{DefaultNS}) {
        $request{Command} = 'namecheap.domains.dns.setDefault';
    } else {
        $request{Command} = 'namecheap.domains.dns.setCustom';
        $request{Nameservers} = join(',', @{$params->{Nameservers}});
    }

    my ($sld, $tld) = split(/[.]/, $params->{DomainName}, 2);
    $request{SLD} = $sld;
    $request{TLD} = $tld;

    my $xml = $self->api->request(%request);

    return unless $xml;

    if ($params->{DefaultNS}) {
        return $xml->{CommandResponse}->{DomainDNSSetDefaultResult};
    } else {
        return $xml->{CommandResponse}->{DomainDNSSetCustomResult};
    }
}

=head2 $dns->getnameservers(DomainName => 'example.com')

Get a list of nameservers currently associated with a domain under
your management.  Returns a data structure that looks like this:

    $nameservers = {
        Domain => 'example.com',
        IsUsingOurDNS => 'true', # if using the "default NS" option
        Nameserver => [
            'ns1.example.com',
            'ns2.example.com',
        ],
    };

=cut

sub getnameservers {
    my $self = shift;

    my $params = _argparse(@_);

    return unless $params->{DomainName};

    my %request = (
        Command => 'namecheap.domains.dns.getList',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
    );

    my ($sld, $tld) = split(/[.]/, $params->{DomainName}, 2);
    $request{SLD} = $sld;
    $request{TLD} = $tld;

    my $xml = $self->api->request(%request);

    return unless $xml;

    return $xml->{CommandResponse}->{DomainDNSGetListResult};
}

=head2 $dns->gethosts(DomainName => 'example.com')

Get a list of DNS hosts for a domain name under management and using the
Namecheap provided DNS service.  Returns a data structure as follows:

    $hosts = {
        Domain => 'example.com',
        IsUsingOurDNS => 'true',
        Host => [
            {
                HostId => '10',
                Name => '@',
                Type => 'A',
                Address => '1.2.3.4',
                MXPref => 10, # yes, even for non-MX records
            },
            ...
        ],
    };

See the documentation for the sethosts() method for more details of the
possible values of each of these fields.

=cut

sub gethosts {
    my $self = shift;

    my $params = _argparse(@_);

    return unless $params->{DomainName};

    my %request = (
        Command => 'namecheap.domains.dns.getHosts',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
    );

    my ($sld, $tld) = split(/[.]/, $params->{DomainName}, 2);
    $request{SLD} = $sld;
    $request{TLD} = $tld;

    my $xml = $self->api->request(%request);

    return unless $xml;

    unless ($xml->{CommandResponse}->{DomainDNSGetHostsResult}->{Host}) {
        $xml->{CommandResponse}->{DomainDNSGetHostsResult}->{Host} = $xml->{CommandResponse}->{DomainDNSGetHostsResult}->{host};
    }

    if ($xml->{CommandResponse}->{DomainDNSGetHostsResult}->{Host} &&
        ref($xml->{CommandResponse}->{DomainDNSGetHostsResult}->{Host}) eq 'HASH') {
        my $arrayref = [ $xml->{CommandResponse}->{DomainDNSGetHostsResult}->{Host} ];
        $xml->{CommandResponse}->{DomainDNSGetHostsResult}->{Host} = $arrayref;
    }

    return $xml->{CommandResponse}->{DomainDNSGetHostsResult};
}

=head2 $dns->sethosts

Set DNS hosts for a domain.

IMPORTANT NOTE: You must include all hosts for the domain in your sethosts
command, any hosts not present in the command but previously present in the
domain configuration will be deleted.  You can simply modify the arrayref
you get back from gethosts and pass it back in, we'll even strip out the
HostIds for you!  :)

    my $result = $dns->sethosts(
        DomainName => 'example.com',
        Hosts => [
            {
                Name => 'foo', # do not include domain name
                Type => 'A',
                Address => '1.2.3.4',
                TTL => 1800, # optional, default 1800
            },
            {
                Name => '@', # for example.com itself
                Type => 'MX',
                Address => 'mail.example.com',
                MXPref => 10,
            },
        ],
        EmailType => 'MX', # or 'MXE' or 'FWD'
    );

Results in a not very useful response:

    $result = {
        Domain => 'example.com',
        IsSuccess => 'true', # or false
    };

Further verification can be performed using a subsequent gethosts() call.

Possible values for "Type" are listed below.  All relevant data (including
URLs for the URL, URL301, and FRAME types) goes into the "Address" field.

 * A
 * AAAA
 * CNAME
 * MX
 * MXE
 * TXT
 * URL
 * URL301
 * FRAME

Type=MXE expects an IP address and synthesizes appropriate MX and host
records.

=cut

sub sethosts {
    my $self = shift;

    my $params = _argparse(@_);

    return unless $params->{DomainName};

    my %request = (
        Command => 'namecheap.domains.dns.setHosts',
        ClientIp => $params->{'ClientIp'},
        UserName => $params->{'UserName'},
        EmailType => $params->{'EmailType'},
    );

    my ($sld, $tld) = split(/[.]/, $params->{DomainName}, 2);
    $request{SLD} = $sld;
    $request{TLD} = $tld;

    my $hostcount = 1;
    foreach my $host (@{$params->{Hosts}}) {
        next unless ($host->{Name} && $host->{Type} && $host->{Address});
        $host->{Name} =~ s/[.]$params->{DomainName}\.?$//;
        $host->{Name} =~ s/^$params->{DomainName}\.?$/\@/;
        $request{"HostName$hostcount"} = $host->{Name};
        $request{"RecordType$hostcount"} = $host->{Type};
        $request{"Address$hostcount"} = $host->{Address};
        $request{"MXPref$hostcount"} = $host->{MXPref} || 10;
        $request{"TTL$hostcount"} = $host->{TTL};
        $hostcount++;
    }

    my $xml = $self->api->request(%request);

    return unless $xml;

    return $xml->{CommandResponse}->{DomainDNSSetHostsResult};
}

=head2 $dns->api()

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

    perldoc WWW::Namecheap::DNS


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

1; # End of WWW::Namecheap::DNS
