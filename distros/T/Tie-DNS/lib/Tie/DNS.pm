use strict; use warnings;
package Tie::DNS;
$Tie::DNS::VERSION = '1.151560';
use Carp;
use Socket;
use Net::DNS;

my $NEW_NETDNS = 0;
if (Net::DNS->version >= 0.69) {
    $NEW_NETDNS = 1;
}

my %config_rec_defaults = (
    'AAAA'   => 'address',
    'AFSDB'  => 'subtype',
    'A'      => 'address',
    'CNAME'  => 'cname',
    'EID'    => 'rdlength',
    'HINFO'  => 'cpu',
    'ISDN'   => 'address',
    'LOC'    => 'version',
    'MB'     => 'madname',
    'MG'     => 'mgmname',
    'MINFO'  => 'rmailbx',
    'MR'     => 'newname',
    'MX'     => 'exchange',
    'NAPTR'  => 'order',
    'NIMLOC' => 'rdlength',
    'NSAP'   => 'idp',
    'NS'     => 'nsdname',
    'NULL'   => 'rdlength',
    'PTR'    => 'ptrdname',
    'PX'     => 'preference',
    'RP'     => 'mbox',
    'RT'     => 'intermediate',
    'SOA'    => 'mname',
    'SRV'    => 'target',
    'TXT'    => 'txtdata'
);

my %config_type = (
    'AAAA'  => ['address','ttl'],
    'AFSDB' => ['subtype','ttl'],
    'A'     => ['address','ttl'],
    'CNAME' => ['cname','ttl'],
    'EID'   => ['rdlength','rdata','ttl'],
    'HINFO' => ['cpu','os','ttl'],
    'ISDN'  => ['address','subaddress','ttl'],
    'LOC' => [
        'version','size','horiz_pre','vert_pre',
        'latitude','longitude','latlon','altitude', 'ttl'
    ],
    'MB'    => ['madname','ttl'],
    'MG'    => ['mgmname','ttl'],
    'MINFO' => ['rmailbx','emailbx','ttl'],
    'MR'    => ['newname','ttl'],
    'MX'    => ['exchange','preference'],
    'NAPTR' => [
        'order','preference','flags','service',
        'regexp','replacement','ttl'
    ],
    'NIMLOC' => ['rdlength','rdata','ttl'],
    'NSAP'   => [
        'idp','dsp','afi','idi','dfi','aa',
        'rsvd','rd','area','id','sel','ttl'
    ],
    'NS'   => ['nsdname','ttl'],
    'NULL' => ['rdlength','rdata','ttl'],
    'PTR'  => ['ptrdname','ttl'],
    'PX'   => ['preference','map822','mapx400','ttl'],
    'RP'   => ['mbox','txtdname','ttl'],
    'RT'   => ['intermediate','preference','ttl'],
    'SOA'  => [
        'mname','rname','serial','refresh',
        'retry','expire','minimum','ttl'
    ],
    'SRV' => ['target','port','weight','priority','ttl'],
    'TXT' => ['txtdata','ttl']
);

sub TIEHASH {
    my $class = shift;
    my $args = shift;

    if (defined $args) {
        die 'Bad argument format' unless ref $args eq 'HASH';
    } else {
        $args = {};
    }

    my $self = {};
    bless $self, $class;
    
    $self->{'dns'} = Net::DNS::Resolver->new(%{($args->{resolver_args} || {})});

    $self->args($args);

    return $self;
}

sub STORE {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    my $root_server = $self->get_root_server
        or die 'Dynamic update attempted but no (or bad) domain specified.';

    my $update = Net::DNS::Update->new($self->_get_arg('domain'));
    my $update_string = sprintf('%s. %s %s %s',
        $key, $self->{'ttl'}, $self->{'lookup_type'}, $value);
    $update->push('update', rr_add($update_string));

    my $res = Net::DNS::Resolver->new(%{($self->args->{resolver_args} || {})});
    $res->nameservers($root_server);
    my $reply = $res->send($update);
    if (defined $reply) {
        if ($reply->header->rcode eq 'NOERROR') {
            return $value;
        } else {
            $self->{'errstring'} = $self->{'dns'}->errorstring;
            return 0;
        }
    } else {
        $self->{'errstring'} = $self->{'dns'}->errorstring;
        return 0;
    }
}

sub args {
    my $self = shift;
    my $args = shift;
    $self->{'args'} = $args;
    $self->_process_args;
}

sub FETCH {
    my $self = shift;
    my $lookup = shift;

    if ( $lookup =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
        return $self->do_reverse_lookup($lookup);
    } else {
        return $self->do_forward_lookup($lookup);
    }
}

sub FIRSTKEY {
    my $self = shift;
    my @full_zone = $self->{'dns'}->axfr($self->{'root_name_server'});
    if (scalar(@full_zone) == 0) {
        $self->{'errstring'} = $self->{'dns'}->errorstring;
        return 0;
    }

    my @zone;
    foreach my $rr (@full_zone) {
        push @zone, $rr if $rr->type eq 'A';
    }
    my $rr = shift @zone;
    $self->{'zone'} = \@zone;
    return $rr->name;
}

sub NEXTKEY {
    my $self = shift;
    my @zone = @{$self->{'zone'}};
    if (scalar(@zone) == 0) {
        return 0;
    }
    my $rr = shift(@zone);
    $self->{'zone'} = \@zone;
    return $rr->name;
}

sub CLEAR {
    my $self = shift;

    #	die ('dynamic DNS updates are not yet available.');
}

sub DELETE {
    my $self = shift;
    die 'Tie::DNS: DELETE function not implemented';
}

sub DESTROY {
    my $self = shift;

    #There isn't any real Net::DNS requirement to call anything when
    #we go bye-bye, so we'll just go bye-bye quietly.
}

sub _process_args {
    my $self = shift;

    if (defined $self->_get_arg('domain')) {    #find the root name
                                                #server for this domain
        $self->{'root_name_server'} = $self->get_root_server;
        $self->{'dns'}->nameservers($self->{'root_name_server'});
    }

    if (defined $self->_get_arg('multiple')) {      #multiple return
            #objects
            #I don't think there's any setup required for this.
    }

    if (defined $self->_get_arg('all_fields')) {    #all fields
            #I don't think there's any setup for this one either.
    }

    if (defined $self->_get_arg('type')) {
        if ( !defined($config_type{$self->_get_arg('type')})) {
            die 'Bad record type: ' . $self->_get_arg('type');
        }
        $self->{'lookup_type'} = $self->_get_arg('type');
    } else {
        $self->{'lookup_type'} = 'A';
    }

    if (defined $self->_get_arg('ttl')) {
        $self->{'ttl'} = $self->_get_arg('ttl');
    } else {
        $self->{'ttl'} = 86400;
    }

    if (my $cache_param = $self->_get_arg('cache')) {
        eval { require Tie::Cache; };
        unless ($@) {
            tie my %cache, 'Tie::Cache', $cache_param;
            $self->{cache} = \%cache;
        }
    } else {
        delete $self->{'cache'};
    }
}

sub get_root_server {
    my $self = shift;
    my $query = $self->{'dns'}->query($self->_get_arg('domain'), 'SOA');
    if ($query) {
        foreach my $rr ($query->answer) {
            print "Root: $rr->mname\n";
            return $rr->mname;
        }
    } else {
        die 'Domain specified, but unable to get SOA record: '
          . $self->{'dns'}->errorstring;
    }
}

sub _get_arg {
    my $self = shift;
    my $arg_name = shift;
    return 0 unless defined $self->{'args'};

    return $self->{'args'}{$arg_name};
}

sub do_reverse_lookup {
    my $self = shift;
    my $lookup = shift;

    my $query = $self->{'dns'}->search($lookup);
    my @retvals;
    if ($query) {
        foreach my $rr ($query->answer) {
            next unless $rr->type eq 'PTR';
            push @retvals, $rr->ptrdname;
        }
    } else {
        $self->{'errstring'} = $self->{'dns'}->errorstring;
        return 0;
    }
    if (defined $self->_get_arg('multiple')) {
        return \@retvals;
    } else {
        return shift @retvals;
    }
}

sub do_forward_lookup {
    my $self = shift;
    my $lookup = shift;
    my @things = $self->_lookup_to_thing($lookup);
    if (defined $self->_get_arg('multiple')) {
        return \@things;
    } else {
        return shift @things;
    }
}

sub _lookup_to_thing {
    my $self = shift;
    my $lookup = shift;

    my $ttl = 0;
    my $now = time();
    my $cache = $self->{cache};

    if ($cache and my $old = $cache->{$lookup}) {
        my ($expire, $ret) = @$old;
        if ($now > $expire) {
            delete $cache->{$lookup};
        } else {
            return @$ret;
        }
    }

    my $query = $self->{'dns'}->search($lookup, $self->{'lookup_type'});

    my @retvals;
    if ($query) {
        foreach my $rr ($query->answer) {
            $ttl ||= $rr->{ttl};
            next unless $rr->type eq $self->{'lookup_type'};
            if (defined $self->_get_arg('all_fields')) {
                my %fields;
                foreach my $field (@{$config_type{$self->{'lookup_type'}}}) {
                    if ($NEW_NETDNS and $field eq 'address') {
                        $fields{$field} = inet_ntoa($rr->{$field});
                    } else {
                        $fields{$field} = $rr->{$field};
                    }
                }
                push @retvals,\%fields;
            } else {
                if (    $NEW_NETDNS and
                        $config_rec_defaults{$self->{'lookup_type'}}
                            eq 'address') {
                    push    @retvals,
                            inet_ntoa(
                                $rr->{
                                    $config_rec_defaults{
                                        $self->{'lookup_type'}
                                    }
                                }
                            );
                } else {
                    push
                        @retvals,
                        $rr->{$config_rec_defaults{$self->{'lookup_type'}}};
                }
            }
        }
    } else {
        $self->{'errstring'} = $self->{'dns'}->errorstring;
    }

    if ($cache) {
        $cache->{$lookup} = [$now + $ttl, \@retvals];
    }
    @retvals;
}

sub error {
    my $self = shift;
    return $self->{'errstring'};
}

1;
__END__

=head1 NAME

Tie::DNS - Tie interface to Net::DNS

=head1 SYNOPSIS

    use Tie::DNS;

    tie my %dns, 'Tie::DNS';

    print "$dns{'foo.bar.com'}\n";

    print "$dns{'208.180.41.1'}\n";

=head1 DESCRIPTION 

Net::DNS is a very complete, extensive and well-written module.  
It's completeness, however, makes many comman cases uses a bit
wordy, code-wise.  Tie::DNS is meant to make common DNS operations
trivial, and more complex DNS operations easier.

=head1 EXAMPLES

=head2 Forward lookup

See Above.

=head2 Zone transfer

Get all of the A records from 'foo.com'.  (Sorry foo.com if
everyone hits your name server testing this module.  :-)

    tie my %dns, 'Tie::DNS', {Domain => 'foo.com'};

    while (my ($name, $ip) = each %dns) {
        print "$name = $ip\n";
    }

This obviously requires that your host has zone transfer
privileges with a name server hosting that zone.  The
zone transfer is initiated with the first each, keys or
values operation.  The tie operation does a SOA query
to find the name server for the cited zone.

=head2 Fetching multiple records

Pass the configuration parameter of 'multiple' to any Perl true 
value, and all FETCH values from Tie::DNS will be an array
reference of records.

    tie my %dns, 'Tie::DNS', {multiple => 'true'};

    my $ip_ref = $dns{'cnn.com'};
    foreach (@{$ip_ref}) {
        print "Address: $_\n";
    }

=head2 Fetching records of type besides 'A'

Pass the configuration parameter of 'type' to one of the
Net::DNS supported record types causes all FETCHes to
get records of that type.

    tie my %dns, 'Tie::DNS', {
        multiple => 'true',
        type => 'SOA'
    };

    my $ip_ref = $dns{'cnn.com'};
    foreach (@{$ip_ref}) {
        print "primary nameserver: $_\n";
    }

Here are the most popular types supported:

    CNAME - Returns the records canonical name.
    A - Returns the records address field.
    TXT - Returns the descriptive text.
    MX - Returns name of this mail exchange.
    NS - Returns the domain name of the nameserver.
    PTR - Returns the domain name associated with this record.
    SOA - Returns the domain name of the original or
        nameserver for this zone.

    (The descriptions are right out of the Net::DNS POD.)

See Net::DNS documentation for further information about these
types and a comprehensive list of all available types.

=head2 Fetching all of the fields associated with a given record type.

    tie my %dns, 'Tie::DNS', {type => 'SOA', all_fields => 'true'};

    my $dns_ref = $dns{'cnn.com'};
    foreach my $field (keys %{$dns_ref}) {
        print "$field = " . ${$dns_ref}{$field} . "\n";
    }

This code fragment will print all of the SOA fields associated
with cnn.com.

=head2 Caching

The argument 'cache' will cause the DNS results to be cached.  The default
is no caching.  The 'cache' argument is passed through to L<Tie::Cache>.
If L<Tie::Cache> cannot be loaded, caching will be disabled.  Entries
whose DNS TTL has expired will be re-queried automatically.

    tie my %dns, 'Tie::DNS', {cache => 100};
    print "$dns{'cnn.com'}\n";
    print "$dns{'cnn.com'}\n";  ## cached!

=head2 Getting all/different fields associated with a record

    tie my %dns, 'Tie::DNS', {all_fields => 'true'};
    my $dns_ref = $dns{'cnn.com'};
    print $dns_ref->{'ttl'}, "\n";

=head2 Passing arguments to Net::DNS::Resolver->new()

    tie my %from_localhost, 'Tie::DNS', {
        resolver_args => {
            nameservers => ['127.0.0.1']
        }
    };
    print "$from_localhost{'test.local'}\n";

You can pass arbitrary arguments to the Net::DNS::Resolver constructor by 
setting the C<resolver_args> argument. In the example above, an alternative
nameserver is used instead of the default one.

=head2 Changing various arguments to the tie on the fly

    tie my %dns, 'Tie::DNS', {type => 'SOA'};
    print "$dns{'cnn.com'}\n";

    tied(%dns)->args({type => 'A'});
    print "$dns{'cnn.com'}\n";

This code fragment first does an SOA query for cnn.com, and then
changes the default mode to A queries, and displays that.

=head2 Simple Dynamic Updates

Assign into the hash, key DNS name, value IP address, to add a record
to the zone in the domain argument.  For instance:

    tie my %dns, 'Tie::DNS', {
        domain => 'realms.lan',
        multiple => 'true'
    };

    $dns{'food.realms.lan.'} = '131.22.40.1';

    foreach (@{$dns{'food'}}) {
        print " $_\n";
    }

=head2 Methods

=head3 error

Returns the last error, either from Tie::DNS or Net::DNS

=head3 get_root_server

Returns the root name server.

=head3 do_forward_lookup

Returns the results of a forward lookup.

=head3 do_reverse_lookup

Returns the results of a reverse lookup.

=head3 args

Change various arguments to the tie on the fly.

=head1 TODO

This release supports the basic functionality of 
Net::DNS.  The 1.0 release will support the following:

Different access methods for forward and reverse lookups.

The 2.0 release will strive to support DNS security options.

=head1 AUTHOR

Dana M. Diederich <dana@realms.org>

=head1 ACKNOWLEDGMENTS

kevin Brintnall <kbrint@rufus.net> for Caching patch
Alvar Freude <alvar@a-blast.org> for arguments to resolver patch
Greg Myran <gmyran@drchico.net> for fixes for Net::DNS >= 0.69

=head1 BUGS

in-addr.arpa zone transfers aren't yet supported.

Patches, flames, opinions, enhancement ideas are all welcome.

=head1 COPYRIGHT 
Copyright (c) 2009,2013,2015 Dana M. Diederich. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)

=cut
