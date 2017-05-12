
# $rcs = ' $Id: Customer.pm,v 1.16 2010-05-08 12:50:29 Martin Exp $ ' ;

=head1 COPYRIGHT

                Copyright (C) 2001 Martin Thurn
                         All Rights Reserved

=head1 NAME

WWW::Ebay::Customer - information about an auction customer

=head1 SYNOPSIS

  use WWW::Ebay::Customer;
  my $oCustomer = new WWW::Ebay::Customer;

=head1 DESCRIPTION

An object that encapsulates information about an auction customer.

=head1 OPTIONS

Object (hash) values and editor (GUI) widgets
correspond to pieces of information needed to identify a
buyer or seller of a (successful) auction.

=head1 METHODS

=cut

package WWW::Ebay::Customer;

use strict;
use warnings;

require 5;

use Carp;
use Data::Dumper;  # for debugging only

use vars qw( $AUTOLOAD $VERSION );
$VERSION = do { my @r = (q$Revision: 1.16 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use constant DEBUG_NEW => 0;

my %hsPermitted = (
                   'ebayid' => '',
                   'email' => '',
                   'paypalid' => '',
                   'name' => '',
                   'address1' => '',
                   'address2' => '',
                   'address3' => '',
                  );

=head2 new

Create a new object of this type.

=cut

sub new
  {
  my $proto = shift;
  my $rh = shift || {};
  print STDERR " + this is new Customer, arg is ", Dumper($rh) if DEBUG_NEW;
  my $class = ref($proto) || $proto;
  unless ($class)
    {
    carp "You can not call new like that";
    # Keep going, but don't give the caller what they're expecting:
    return bless({}, 'FAIL');
    } # unless
  my $self = {
              %hsPermitted,
             };
  # Make a COPY of the remaining arguments:
  while (my ($key,$val) = each %$rh)
    {
    $self->{$key} = $val;
    } # while
  bless ($self, $class);
  print STDERR " + new Customer is ", Dumper($self) if DEBUG_NEW;
  return $self;
  } # new

sub _elem
  {
  my $self = shift;
  my $elem = shift;
  my $ret = $self->{$elem};
  if (@_)
    {
    $self->{$elem} = shift;
    } # if
  return $ret;
  } # _elem


sub AUTOLOAD
  {
  # print STDERR " + this is ::Single::AUTOLOAD($AUTOLOAD,@_)\n";
  $AUTOLOAD =~ s/.*:://;
  unless (exists $hsPermitted{$AUTOLOAD})
    {
    carp " --- element '$AUTOLOAD' is not allowed";
    return undef;
    } # unless
  shift->_elem($AUTOLOAD, @_);
  } # AUTOLOAD


# define this so AUTOLOAD does not try to handle it:

sub DESTROY
  {
  } # DESTROY


=head2 editor

Creates a Tk widget for editing a customer's information.
Takes one argument, an existing Tk widget into which the editor
widget will be packed.  Should be a Frame or MainWindow or similar.

=cut

sub editor
  {
  my $self = shift;
  # Takes one argument, a Tk Widget (that can have items packed into it).
  my $w = shift;
  # Create some shortcuts:
  my @asAllPack = qw( -pady 3 );
  my @asHeadPack = (@asAllPack, qw( -column 0 -sticky e ));
  my @asDataPack = (@asAllPack, qw( -column 1 -sticky w ));
  # Add a Frame, in case $w is not using the grid manager:
  my $f1 = $w->Frame(
                    )->pack(qw( -side top -fill x -padx 4 -pady 4 ));
  # Pack it up:
  $f1->Label(
             -text => 'eBay ID: ',
            )->grid(@asHeadPack, qw( -row 0 ));
  $f1->Entry(
             -textvariable => \$self->{ebayid},
             -width => 35,
             # This is the key, do not let them change it:
             -state => 'disabled',
            )->grid(@asDataPack, qw( -row 0 ));
  $f1->Label(
             -text => 'email address: ',
            )->grid(@asHeadPack, qw( -row 1 ));
  $f1->Entry(
             -textvariable => \$self->{email},
             -width => 35,
            )->grid(@asDataPack, qw( -row 1 ));
  $f1->Label(
             -text => 'PayPal ID: ',
            )->grid(@asHeadPack, qw( -row 2 ));
  $f1->Entry(
             -textvariable => \$self->{paypalid},
             -width => 35,
            )->grid(@asDataPack, qw( -row 2 )); 
  $f1->Label(
             -text => 'name: ',
            )->grid(@asHeadPack, qw( -row 3 ));
  $f1->Entry(
             -textvariable => \$self->{name},
             -width => 35,
            )->grid(@asDataPack, qw( -row 3 ));
  $f1->Label(
             -text => 'address1: ',
            )->grid(@asHeadPack, qw( -row 4 ));
  $f1->Entry(
             -textvariable => \$self->{address1},
             -width => 35,
            )->grid(@asDataPack, qw( -row 4 ));
  $f1->Label(
             -text => 'address2: ',
            )->grid(@asHeadPack, qw( -row 5 ));
  $f1->Entry(
             -textvariable => \$self->{address2},
             -width => 35,
            )->grid(@asDataPack, qw( -row 5 ));
  $f1->Label(
             -text => 'address3: ',
            )->grid(@asHeadPack, qw( -row 6 ));
  $f1->Entry(
             -textvariable => \$self->{address3},
             -width => 35,
            )->grid(@asDataPack, qw( -row 6 ));
  } # editor

use constant DEBUG_PASTE => 0;

=head2 editor_paste

Takes one argument, a string.
Tries to interpret the argument as a name and/or address as follows:
If the string contains three or more lines,
put the first line into the name and the remaining lines into the address.
If the string contains two lines,
put the two lines into the address.
Otherwise, do nothing.

=cut

sub editor_paste
  {
  # Smart paste:
  my $self = shift;
  my $sPaste = shift;
  # Delete \r:
  $sPaste =~ s!\r!!g;
  # Delete "blank" lines:
  $sPaste =~ s!\n\s*\n!\n!g;
  # Delete leading and trailing whitespace:
  $sPaste =~ s!\A[\ \s\f\t\n]+!!;
  $sPaste =~ s![\ \s\f\t\n]+\Z!!;
  my @asPaste = split(/\n/, $sPaste);
  chomp @asPaste;
  my $iNumLines = scalar(@asPaste);
  print STDERR " +   paste has $iNumLines lines\n" if DEBUG_PASTE;
  my @asDest;
  if (3 < $iNumLines)
    {
    # Fill them all!
    @asDest = qw(name address1 address2 address3);
    }
  elsif (2 < $iNumLines)
    {
    # Assume it's a name and standard U.S. address:
    @asDest = qw(name address1 address2);
    }
  elsif (1 < $iNumLines)
    {
    # Assume it's a standard U.S. address:
    @asDest = qw(address1 address2);
    }
  else
    {
    # Only one item, or none, or too many: do nothing:
    @asDest = ();
    }
  foreach my $sDest (@asDest)
    {
    my $sLine = shift @asPaste;
    # Delete leading and trailing whitespace:
    $sLine =~ s!\A[\ \s\f\t]+!!;
    $sLine =~ s![\ \s\f\t]+\Z!!;
    # Normalize whitespace:
    $sLine =~ s![\ \s\f\t]+! !g;
    $self->$sDest($sLine);
    } # foreach
  } # editor_paste


=head2 editor_finish

You should call this method after editing is finished,
before destroying the Tk widget.

=cut

sub editor_finish
  {
  my $self = shift;
  # Retrieve the volatile items from the GUI:
  } # editor_finish


=head2 clone

Make a new Ebay::Customer object identical to ourself, and return it.

=cut

sub clone
  {
  my $self = shift;
  my $oC = new __PACKAGE__;
  $self->copy_to($oC);
  return $oC;
  } # clone


=head2 copy_to

Given another Ebay::Customer object, copy our values into him.

=cut

sub copy_to
  {
  my $self = shift;
  my $oC = shift;
  unless (ref($oC) eq __PACKAGE__)
    {
    carp sprintf(" --- argument on copy_to() is not a %s object", __PACKAGE__);
    return;
    } # unless
  foreach my $key (keys %hsPermitted)
    {
    $oC->$key($self->$key());
    } # foreach
  } # copy_to


1;

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

__END__

