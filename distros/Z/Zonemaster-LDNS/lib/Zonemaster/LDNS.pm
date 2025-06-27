package Zonemaster::LDNS;

use 5.014;

our $VERSION = '5.0.0';

use parent 'Exporter';
our @EXPORT_OK = qw[lib_version to_idn has_idn has_gost load_zonefile];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

use Zonemaster::LDNS::RR;
use Zonemaster::LDNS::RRList;
use Zonemaster::LDNS::Packet;

1;

=head1 NAME

Zonemaster::LDNS - Perl wrapper for the ldns DNS library.

=head1 SYNOPSIS

    my $resolver = Zonemaster::LDNS->new('8.8.8.8');
    my $packet   = $resolver->query('www.iis.se');
    say $packet->string;

=head1 DESCRIPTION

C<Zonemaster::LDNS> represents a resolver, which is the part of the system responsible for sending queries and receiving answers to them.

=head1 EXPORTABLE FUNCTIONS

=over

=item lib_version()

Returns the ldns version string.

=item to_idn($name, ...)

Takes a number of domain names (in string format) and returns them with all
labels converted to A-labels unless they are already in ASCII.

Assumes that the strings have been converted to Perl's internal encoding before
it's called. Can be exported, but is not by default.

This function requires that GNU libidn2 was present when L<Zonemaster::LDNS> was
compiled. If not, calling C<to_idn> will result in an exception getting thrown.

=item has_idn()

Takes no arguments. Returns true if libidn2 was present at compilation, false if not.

=item has_gost()

Takes no arguments. Returns true if GOST support was present at compilation, false if not.

=item load_zonefile($filename)

Load all resource records in a zone file, returning them as a list.

=back

=head1 CLASS METHOD

=over

=item new($addr,...)

Creates a new resolver object. If given no arguments, if will pick up nameserver addresses from the system configuration (F</etc/resolv.conf> or
equivalent). If given a single argument that is C<undef>, it will not know of any nameservers and all attempts to send queries will throw
exceptions. If given one or more arguments that are not C<undef>, attempts to parse them as IPv4 and IPv6 addresses will be made, and if successful
make up a list of servers to send queries to. If an argument cannot be parsed as an IP address, an exception will be thrown.

=back

=head1 INSTANCE METHODS

=over

=item query($name, $type, $class)

Send a query for the given triple. If type or class are not provided they default to A and IN, respectively. Returns a L<Zonemaster::LDNS::Packet> or
undef.

=item query_with_pkt($packet)

Send a L<Zonemaster::LDNS::Packet>. Returns a L<Zonemaster::LDNS::Packet> or undef.

=item name2addr($name)

Asks this resolver to look up A and AAAA records for the given name, and return a list of the IP addresses (as strings). In scalar context, returns
the number of addresses found.

=item addr2name($addr)

Takes an IP address, asks the resolver to do PTR lookups and returns the names found. In scalar context, returns the number of names found.

=item recurse($flag)

Returns the setting of the recursion flag. If given an argument, it will be treated as a boolean and the flag set accordingly.

=item debug($flag)

Gets and optionally sets the debug flag.

=item dnssec($flag)

Get and optionally sets the DNSSEC flag.

=item cd($flag)

Get and optionally sets the CD flag.

=item igntc($flag)

Get and optionally sets the igntc flag.

=item fallback($flag)

Get and optionally sets the fallback flag.

=item usevc($flag)

Get and optionally sets the usevc flag.

=item retry($count)

Get and optionally set the number of retries.

=item retrans($seconds)

Get and optionally set the number of seconds between retries.

=item port($port)

Get and optionally set the destination port for requests.

=item edns_size($size)

Get and optionally set the EDNS0 UDP maximum size.


=item axfr( $domain, $callback, $class )

Perform an AXFR operation. C<$callback> must be a code reference, which will be
called once for every received resource record with the RR object as its one
and only argument. After every such call, the return value of the callback will
be examined, and if the value is false the AXFR process will be aborted. The
return value of the C<axfr()> method itself will be true if the transfer
completed normally, and false if it was aborted because the callback returned a
false value.

If anything goes wrong during the process, an exception will be thrown.

As an example, saving all the RRs received from an AXFR can be done like this:

    my @rrs;
    $resolver->axfr( $domain, sub { my ($rr) = @_; push @rrs, $rr; return 1;} );

=item axfr_start($domain,$class)

Deprecated. Use L<axfr()> instead.

Set this resolver object up for a zone transfer of the specified domain. If C<$class> is not given, it defaults to IN.

=item axfr_next()

Deprecated. Use L<axfr()> instead.

Get the next RR in the zone transfer. L<axfr_start()> must have been done before this is called, and after this is called L<axfr_complete()>
should be used to check if there are more records to get. If there's any problem, an exception will be thrown. Basically, the sequence should be
something like:

    $res->axfr_start('example.org');
    do {
        push @rrlist, $res->axfr_next;
    } until $res->axfr_complete;

=item axfr_complete()

Deprecated. Use L<axfr()> instead.

Returns false if there is a started zone transfer with more records to get, and true if the started transfer has completed.

=item axfr_last_packet()

Deprecated. Use L<axfr()> instead.

If L<axfr_next()> threw an exception, this method returns the L<Zonemaster::LDNS::Packet> that made it do so. The packet's RCODE is likely to say what
the problem was (for example, NOTAUTH or NXDOMAIN).

=item timeout($time)

Get and/or set the socket timeout for the resolver.

=item source($addr)

Get and/or set the IP address the resolver should try to send its queries from.

=back

=head1 AUTHORS

Mattias P <mattias.paivarinta@iis.se>
- Current maintainer

Calle Dybedahl <calle@init.se>
- Original author

=head1 LICENSE

This is free software under a 2-clause BSD license. The full text of the license can
be found in the F<LICENSE> file included with this distribution.

=cut
