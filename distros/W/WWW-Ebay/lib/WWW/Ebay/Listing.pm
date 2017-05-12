
# $rcs = ' $Id: Listing.pm,v 1.12 2010-05-08 12:51:44 Martin Exp $ ' ;

=head1 COPYRIGHT

                Copyright (C) 2002-present Martin Thurn
                         All Rights Reserved

=head1 NAME

WWW::Ebay::Listing - information about an auction listing

=head1 SYNOPSIS

  use WWW::Ebay::Listing;
  my $oWEL = new WWW::Ebay::Listing;

=head1 DESCRIPTION

Encapsulates a posted / running / completed auction listing at the
eBay auction website (www.ebay.com).

=cut

package WWW::Ebay::Listing;

use strict;
use warnings;

our
$VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use Carp;
use WWW::Ebay::Status;

=head1 METHODS

=over

=item new

=cut

my (@allowed, %allowed);

sub new
  {
  my $proto = shift;
  my ($sUserID, $sPassword) = @_;
  my $class = ref($proto) || $proto;
  unless ($class)
    {
    carp "You can not call new like that";
    # Keep going, but don't give the caller what they're expecting:
    return bless({}, 'FAIL');
    } # unless
  my $self = {
              '_allowed' => \%allowed,
             };
  bless ($self, $class);
  $self->status(new WWW::Ebay::Status);
  $self->dateend(0);
  return $self;
  } # new

BEGIN
  {

=item id

The auction ID assigned when the auction was listed.

=cut

push @allowed, 'id';

=item bidcount

How many bids this auction received.

=cut

push @allowed, 'bidcount';

=item bidmax

The highest bid so far (in cents).

=cut

push @allowed, 'bidmax';

=item status

A WWW::Ebay::Status object.

=cut

push @allowed, 'status';

=item datestart

Date & time the auction was listed (epoch seconds format).

=cut

push @allowed, 'datestart';

=item dateend

Date & time the auction ended (epoch seconds format).

=cut

push @allowed, 'dateend';

=item winnerid

High bidder's ebay ID.

=cut

push @allowed, 'winnerid';

=item shipping

Shipping charge (in cents).

=cut

push @allowed, 'shipping';

=item title

Auction title.

=cut

push @allowed, 'title';

=item description

Auction description.

=cut

push @allowed, 'description';

=item dateship

Date the item was shipped (epoch seconds format).

=cut

push @allowed, 'dateship';
foreach (@allowed)
  {
  $allowed{$_} = 1;
  } # foreach
} # end of BEGIN block

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
  my $self = shift;
  # print STDERR " DDD this is ::Listing::AUTOLOAD($AUTOLOAD,@_)\n";
  our $AUTOLOAD =~ s/.*:://;
  $AUTOLOAD = lc $AUTOLOAD;
  # print STDERR " DDD   Listing::AUTOLOAD($AUTOLOAD)\n";
  unless (exists $self->{_allowed}->{$AUTOLOAD})
    {
    carp " --- Method '$AUTOLOAD' not allowed on a ", ref $self, " object";
    return;
    } # unless
  $self->_elem($AUTOLOAD, @_);
  } # AUTOLOAD

=item as_string

Returns a human-readable summary of this listing.

=cut

sub as_string
  {
  my $self = shift;
  my $s = '';
  foreach my $sKey (@allowed)
    {
    if (defined($self->{$sKey}) && ($self->{$sKey} ne ''))
      {
      my $sVal = $sKey eq 'status' ? $self->{$sKey}->as_text : $self->{$sKey};
      $s .= "$sKey=$sVal; ";
      } # if
    } # foreach
  chop $s;
  chop $s;
  return $s;
  } # as_string

# define this so AUTOLOAD does not try to handle it:

sub DESTROY
  {
  } # DESTROY


=item ended

Returns true if this auction has ended.

=cut

sub ended
  {
  my $self = shift;
  return (0 < $self->dateend);
  } # ended

=back

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

1;

__END__

