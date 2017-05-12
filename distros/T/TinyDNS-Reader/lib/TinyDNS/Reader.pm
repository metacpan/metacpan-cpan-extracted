
=head1 NAME

TinyDNS::Reader - Read TinyDNS files.

=head1 DESCRIPTION

This module allows the parsing of a TinyDNS data-file, or individual records
taken from one.

=cut

=head1 SYNOPSIS

   use TinyDNS::Reader;

   my $tmp = TinyDNS::Reader->new( file => "./zones/example.com" );
   my $dns = $tmp->parse();

   foreach my $record ( @$dns )
   {
      print $record . "\n";
   }


=head1 DESCRIPTION

This module contains code for reading a zone-file which has been
created for use with L<DJB's tinydns|http://cr.yp.to/djbdns/tinydns.html>.

A zonefile may be parsed and turned into a series of L<TinyDNS::Record> objects,
one for each valid record which is found.

If you wish to merge multiple records, referring to the same hostname, you should also consult the documentation for the L<TinyeDNS::Reader::Merged> module.

=cut

=head1 METHODS

=cut

use strict;
use warnings;

package TinyDNS::Reader;

use TinyDNS::Record;

our $VERSION = '0.7.7';



=head2 new

The constructor should be given either a "C<file>" or "C<text>" parameter,
containing the filename to parse, or the text to parse, respectively.

=cut

sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );

    if ( $supplied{ 'file' } )
    {
        $self->{ 'data' } = $self->_readFile( $supplied{ 'file' } );
    }
    elsif ( $supplied{ 'text' } )
    {
        $self->{ 'data' } = $supplied{ 'text' };
    }
    else
    {
        die "Missing 'text' or 'file' argument.";
    }

    return $self;

}


=begin doc

Read the contents of the specified file.

Invoked by the constructor if it was passed a C<file> argument.

=end doc

=cut

sub _readFile
{
    my ( $self, $file ) = (@_);

    open( my $handle, "<", $file ) or
      die "Failed to read $file - $!";

    my $text = "";

    while ( my $line = <$handle> )
    {
        $text .= $line;
    }
    close($handle);

    return ($text);
}


=head2 parse

Process and return an array of L<TinyDNS::Records> from the data contained
in the file specified by our constructor, or the scalar reference.

=cut

sub parse
{
    my ($self) = (@_);

    my $records;

    foreach my $line ( split( /[\n\r]/, $self->{ 'data' } ) )
    {
        chomp($line);

        # Skip empty lines.
        next if ( !$line || !length($line) );

        # Strip trailing comments.
        $line =~ s/#.*$//s;

        # Skip empty lines.
        next if ( !$line || !length($line) );

        #
        #  Ignore "." + ":" records
        #
        next if ( $line =~ /^\s*[:.]/ );

        #
        #  Ensure the line is lower-cased
        #
        $line = lc($line);

        #
        #  Construct a new object, and add it to the list.
        #
        my $rec = TinyDNS::Record->new($line);
        push( @$records, $rec ) if ($rec);
    }

    return ($records);
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
