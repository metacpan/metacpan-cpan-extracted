
=head1 NAME

TinyDNS::Record - Parse a single TinyDNS Record.

=head1 DESCRIPTION

This module provides an object API to a single TinyDNS record/line.

It is not quite valid because:

=over 8

=item *
We ignore SOA records, which Amazon would handle for us.

=item *
Our TXT records handling uses "T" not ":".

=item *
Our SRV records are non-standard.

=item *
Our MX record handling allows a name to be set without IP.

=back

There are probably other differences.

=cut

=head1 METHODS

=cut

use strict;
use warnings;

package TinyDNS::Record;


use Carp;


#
#  Allow our object to treated as a string.
#
use overload '""' => 'stringify';



=head2 new

Constructor, which sets the type of the object.

The constructor is expected to be passed a valid line of text which
describes a single record, for example C<+example.example.com:1.2.3.4:200>.

=cut

sub new
{
    my ( $proto, $line ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );


    #
    #  Ensure we process as lower-case
    #
    $line = lc($line);

    #
    #  Record the line we were created with.
    #
    $self->{ 'input' } = $line;

    #
    #  The record-type is the first character.
    #
    my $rec = substr( $line, 0, 1 );

    #
    #  Remove the record-type from the line
    #
    $line = substr( $line, 1 );

    #
    # Tokenize - NOTE This is ignored for TXT records,
    # (because a TXT record used for SPF might have an embedded
    # ":" for example.)
    #
    my @data = split( /:/, $line );

    #
    #  Nasty parsing for each record type..
    #
    #  We should do better.
    #
    #
    if ( ( $rec eq '+' ) || ( $rec eq '=' ) )
    {

        # name : ipv4 : ttl
        $self->{ 'type' }  = "A";
        $self->{ 'name' }  = $data[0];
        $self->{ 'value' } = $data[1];
        $self->{ 'ttl' }   = $data[2] || 300;
    }
    elsif ( $rec eq '_' )
    {

        # The long-form is:
        #  $name.$proto.$domain : $hostname : $port : $prior : $weight : $ttl
        #
        # The short-form is much more common and useful:
        #  $name.$proto.$domain : $hostname : $port : $ttl
        #
        $self->{ 'type' } = "SRV";
        $self->{ 'name' } = "_" . $data[0];

        if ( scalar(@data) == 4 )
        {
            my $host = $data[1] || 0;
            my $port = $data[2] || 0;
            my $ttl  = $data[3] || 300;

            # Bogus priority + weight
            $self->{ 'value' } = "1 10 $port $host";
            $self->{ 'ttl' }   = $ttl;
        }
        else
        {
            my $host     = $data[1] || 0;
            my $port     = $data[2] || 0;
            my $priority = $data[3] || 1;
            my $weight   = $data[4] || 10;
            my $ttl      = $data[5] || 300;

            # Bogus priority + weight
            $self->{ 'value' } = "$priority $weight $port $host";
            $self->{ 'ttl' }   = $ttl;
        }

    }
    elsif ( $rec eq '6' )
    {

        # name : ipv6 : ttl
        $self->{ 'type' } = "AAAA";
        $self->{ 'name' } = $data[0];
        $self->{ 'ttl' }  = $data[2] || 300;

        #
        #  Convert an IPv6 record of the form:
        #     "200141c8010b01010000000000000010"
        #  to the expected value:
        #     "2001:41c8:010b:0101:0000:0000:0000:0010".
        #
        my $ipv6 = $data[1];
        my @tmp  = ( $ipv6 =~ m/..../g );
        $self->{ 'value' } = join( ":", @tmp );
    }
    elsif ( $rec eq '@' )
    {

        #
        # @name:destination:priority:TTL
        #
        if ( scalar(@data) == 4 )
        {
            $self->{ 'type' }     = "MX";
            $self->{ 'name' }     = $data[0];
            $self->{ 'priority' } = $data[2] || "15";
            $self->{ 'ttl' }      = $data[3] || 300;
            $self->{ 'value' }    = $self->{ 'priority' } . " " . $data[1];
        }
        if ( scalar(@data) == 3 )
        {
            #
            # @name:destination:priority
            #
            $self->{ 'type' }     = "MX";
            $self->{ 'name' }     = $data[0];
            $self->{ 'priority' } = $data[2] || "15";
            $self->{ 'ttl' }      = 300;
            $self->{ 'value' }    = $self->{ 'priority' } . " " . $data[1];
        }
    }
    elsif ( $rec eq '&' )
    {

        #
        #  NS
        #   &host.example.com:IGNORED:ns1.secure.net:ttl
        #
        $self->{ 'type' }  = "NS";
        $self->{ 'name' }  = $data[0];
        $self->{ 'value' } = $data[2];
        $self->{ 'ttl' }   = $data[3] || 300;
    }
    elsif ( ( $rec eq 'c' ) || ( $rec eq 'C' ) )
    {

        #
        # name :  dest : [ttl]
        #
        $self->{ 'type' }  = "CNAME";
        $self->{ 'name' }  = $data[0];
        $self->{ 'value' } = $data[1];
        $self->{ 'ttl' }   = $data[2] || 300;
    }
    elsif ( ( $rec eq 't' ) || ( $rec eq 'T' ) )
    {

        #
        # name : "data " : [TTL]
        #
        if ( $line =~ /([^:]+):"([^"]+)":*([0-9]*)$/ )
        {
            $self->{ 'type' }  = "TXT";
            $self->{ 'name' }  = $1;
            $self->{ 'value' } = "\"$2\"";
            $self->{ 'ttl' }   = $3 || 3600;
        }
        else
        {
            die "Invalid TXT record - $line\n";
        }
    }
    elsif ( $rec eq '^' )
    {

        #
        #  ptr : "rdns " : [TTL]
        #
        $self->{ 'type' }  = "PTR";
        $self->{ 'name' }  = $data[0];
        $self->{ 'value' } = $data[1];
        $self->{ 'ttl' }   = $data[2] || 300;
    }
    else
    {
        carp "Unknown record type [$rec]: $line";
        return;
    }
    return $self;

}


=head2 input

Return the text that this record was created with.

=cut

sub input
{
    my ($self) = (@_);

    return ( $self->{ 'input' } );
}


=head2 valid

Is this record valid?  Return 0 or 1 as appropriate.

=cut

sub valid
{
    my ($self) = (@_);

    return ( $self->{ 'type' } ? 1 : 0 );
}


=head2 type

Return the type this record has, such as "A", "AAAA", "NS", etc.

=cut

sub type
{
    my ($self) = (@_);

    return ( $self->{ 'type' } );
}


=head2 ttl

Return the TTL of this recrd.

If no TTL was explicitly specified we default to 300 seconds, or five minutes.

=cut

sub ttl
{
    my ($self) = (@_);

    if ( $self->{ 'ttl' } &&
         $self->{ 'ttl' } =~ /^([0-9]+)$/ )
    {
        return $self->{ 'ttl' };
    }

    return 300;
}


=head2 name

Get the name of this record.

=cut

sub name
{
    my ($self) = (@_);
    return ( $self->{ 'name' } );
}


=head2 value

Get the value of this record.

=cut

sub value
{
    my ($self) = (@_);

    return ( $self->{ 'value' } );
}


=head2 add

Add a new value to the existing record.

This is used by the L<TinyDNS::Reader::Merged> module.


=cut

sub add
{
    my ( $self, $addition ) = (@_);

    my $value = $self->{ 'value' };
    if ( ref \$value eq "SCALAR" )
    {
        my $x;
        push( @$x, $value );
        push( @$x, $addition );
        $self->{ 'value' } = $x;
    }
    else
    {
        push( @$value, $addition );
        $self->{ 'value' } = $value;
    }
}


=head2 stringify

Convert the record to a string, suitable for printing.

=cut

sub stringify
{
    my ($self) = (@_);
    my $txt = "";

    $txt .= ( "Type " . $self->type() . "\n" )    if ( $self->type() );
    $txt .= ( " Name:" . $self->name() . "\n" )   if ( $self->name() );
    $txt .= ( " Value:" . $self->value() . "\n" ) if ( $self->value() );
    $txt .= ( " TTL:" . $self->ttl() . "\n" )     if ( $self->ttl() );

}


=head2 hash

Return a consistent hash of the record.

=cut

sub hash
{
    my ($self) = (@_);

    my $hash;
    $hash .= $self->type();
    $hash .= $self->name();
    $hash .= $self->value();
    $hash .= $self->ttl();

    return ($hash);
}

1;


=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 Steve Kemp <steve@steve.org.uk>.

This code was developed for an online Git-based DNS hosting solution,
which can be found at:

=over 8

=item *
https://dns-api.com/

=back

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut
