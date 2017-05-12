
=head1 NAME

TinyDNS::Reader::Merged - Read a TinyDNS file and merge records.

=head1 DESCRIPTION

The L<TinyDNS::Reader> module will allow you to parse a TinyDNS zonefile,
into a number of distinct records, one for each line.

However there is no handling the case where you'd expect a single DNS
value to have multiple values.

For example if you were to parse this file you would get two records:

=for example begin

     db.example.com:1.2.3.4:300
     db.example.com:10.20.30.40:300

=for example end

On a purely record-by-record basis that is as-expected, however when you
actually come to manipulate your DNS records you'd expect to have a single
logical object with values something like this:

=for example begin

     {
       'ttl' => '300',
       'value' => [
                    '1.2.3.4',
                    '10.20.30.40'
                  ],
       'name' => 'db.example.com',
       'type' => 'A'
     },

=for example end

This module takes care of that for you, by merging records which consist
of identical "name" + "type" pairs.

Use it as a drop-in replacing for L<TinyDNS::Reader>.

=cut


=head2 METHODS

=cut


package TinyDNS::Reader::Merged;

use TinyDNS::Reader;

use strict;
use warnings;


=head2 new

Constructor.

This module expects to be given a C<file> parameter, pointing to a
file which can be parsed, or a C<text> parameter containing the text of the
records to parse.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );

    #
    #  Create our child object.
    #
    if ( $supplied{ 'file' } )
    {
        $self->{ 'obj' } = TinyDNS::Reader->new( file => $supplied{ 'file' } );
    }
    elsif ( $supplied{ 'text' } )
    {
        $self->{ 'obj' } = TinyDNS::Reader->new( text => $supplied{ 'text' } );
    }
    else
    {
        die "Missing 'text' or 'file' argument";
    }
    return $self;
}


=head2 parse

Parse the records and return a merged set.

The parsing is delegated to L<TinyDNS::Reader>, so all supported record-types
work as expected.

=cut

sub parse
{
    my ($self) = (@_);

    my $records = $self->{ 'obj' }->parse();


    #
    #  Process each entry
    #
    my $res;

    my %seen = ();

    foreach my $r (@$records)
    {

        # Test that the record was recognized.
        next unless ( $r->valid() );

        my $name = $r->name();
        my $type = $r->type();
        my $val  = $r->value();
        my $ttl  = $r->ttl();
        my $hash = $r->hash();

        # skip if we've seen this name+type pair before.
        next if ( $seen{ $name }{ $type } );

        #
        #  Look for other values with the same type.
        #
        #  NOTE: O(N^2) - needs improvement.
        #
        foreach my $x (@$records)
        {

            # Test that the record was recognized.
            next if ( !$x->valid() );

            my $name2 = $x->name();
            my $type2 = $x->type();
            my $val2  = $x->value();
            my $hash2 = $x->hash();

            next if ( $hash eq $hash2 );

            #
            #  If this record has the same name/type as the
            # previous one then merge in the new value.
            #
            #  NOTE: This means the TTL comes from the first
            # of the records.  Which is fine.
            #
            if ( ( $name eq $name2 ) &&
                 ( $type eq $type2 ) )
            {
                $r->add($val2);
            }
        }

        push( @$res,
              {  name  => $name,
                 value => $r->value(),
                 ttl   => $ttl,
                 type  => $type
              } );


        #
        #  We've seen this name/type pair now.
        #
        $seen{ $name }{ $type } += 1;
    }

    #
    #  Return the merged/updated results.
    #
    return ($res);
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
