package Text::SimpleVaddrbook;

use Text::SimpleVcard;

use warnings;
use strict;

=head1 NAME

Text::SimpleVaddrbook - a package to manage multiple vCard-files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This package provides an API to reading multiple vCard-files. A vCard is an
electronic business card. This package has been developed based on rfc2426.

You will find that many applications (KDE Address book, Apple Address book,
MS Outlook, Evolution etc) use vCards and can export/import them.

   use Text::simpleAdrbook;

   my $aBook = SimpleAddrbook->new( '/path/to/addressbook/address.vcf');

   while( my $vCard = $aBook->next()) {
      print "Got card for " . $vCard->getFullName() . "\n";
   }

=head1 FUNCTIONS

=head2 new()

   my $aBook = Text::simpleAdrbook->new( 'foo.vCard', 'std.vcf');

The method will create an addressbook-object and check for the existence
and accessibility of the provided vCards. It will produce a warning, if it
can not read a file.

=cut

sub new() {
   my $class = shift;
   my $self = {};

   $self->{ ndx} = -1;
   foreach( @_) {
      if( ! -r $_) {
	 warn "unable to access vCard-file '$_'";
	 next;
      }
      push( @{ $self->{ fn}}, $_);
   }
   bless( $self, $class);
}

=head2 next()

   my $vCard = $aBook->next();

This method will read the next C<vCard>-entry in the list of C<vCard>-files.
It returns the entry in a C<vCard>-object (see also C<Text::SimpleVcard>). it will
return C<undef> when called after the last entry was returned.

=cut

sub next() {
   my( $class) = @_;
   my( $dat, $lin);

   while( 1) {
      # open a new file if necessary
      if( $class->{ ndx} < 0 or eof( $class->{ fh})) {
	 my @ary = @{ $class->{ fn}};

	 close( $class->{ fh}) if( $class->{ ndx} >= 0);
	 return undef if( $class->{ ndx} >= $#ary);
	 $class->{ ndx}++;

	 open( $class->{ fh}, "< $ary[ $class->{ ndx}]");
      }
      my $fh = $class->{ fh};

      #skip forward until next begin of vcard is found
      my $vCardCnt = 0;
      while( $lin = <$fh>) {
	 if( $lin =~ /^BEGIN:VCARD/) {
	    $vCardCnt++;
	    last;
	 }
      }
      next if( eof( $fh));	# eof reached -> go to next file

      $dat = $lin;	# put start of vcard into buffer
      while( $lin = <$fh>) {
	 $dat .= $lin;
	 $vCardCnt++ if( $lin =~ /^BEGIN:VCARD/);
	 $vCardCnt-- if( $lin =~ /^END:VCARD/);
	 return Text::SimpleVcard->new( $dat) if( $vCardCnt == 0);
      }
   }
}

=head2 rewind()

   $aBook->rewind();

This method will rewind the filepointers, so that the next call of the method C<next()> will 
return the first entry of the first C<vCard> provided. This method is useful to re-read the
addressbooks e.g. when they changed

=cut

sub rewind() {
   my( $class) = @_;

   close( $class->{ fh}) if( $class->{ ndx} >= 0);
   $class->{ ndx} = -1;
}

=head1 AUTHOR

Michael Tomuschat, C<< <michael.tomuschat at t-online.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-simplevaddrbook at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-SimpleVAddrbook>. I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::SimpleVaddrbook


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-SimpleVAddrbook>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-SimpleVaddrbook>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-SimpleVaddrbook>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-SimpleVaddrbook>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Michael Tomuschat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::SimpleVaddrbook
