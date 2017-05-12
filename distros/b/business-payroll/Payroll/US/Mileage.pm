# Mileage.pm
# Created:  Feb 27 15:24:49 CST 2002
# by James A. Pattie
# $Id: Mileage.pm,v 1.9 2005/12/30 15:11:01 moreejt Exp $
# License: same as perl
# 2002-2003 Xperience, Inc. www.pcxperience.com

=head1 NAME

Mileage

=head1 SYNOPSIS

  use Business::Payroll::US::Mileage;
  my $mileage = Business::Payroll::US::Mileage->new();
  if ($mileage->error())
  {
    die $mileage->errorMessage();
  }
  my $value = $mileage->calculate(date => $date, miles => $miles);

=head1 DESCRIPTION

This module will calculate Mileage re-imbursements for the US based on internal tables when given the number of miles.

=cut

package Business::Payroll::US::Mileage;
use strict;
use Business::Payroll::Base;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Business::Payroll::Base Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '.3';

use constant TRUE => 1;
use constant FALSE => 0;

=head1 Exported FUNCTIONS

=over 4

=head2  scalar new()

        Creates a new instance of the object.

=cut

sub new
{
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my %args = ( @_ );

  # verify our Parent isValid.
  if ($self->error)
  {
    $self->prefixError();
    return $self;
  }
  
    $self->{debug} = 'no';
    $self->{dataTables} =  {
            '19990101' => {rate => '0.325'},
            '19990401' => {rate => '0.31'},
            '20000101' => {rate => '0.325'},
            '20010101' => {rate => '0.345'},
            '20020101' => {rate => '0.365'},
            '20030101' => {rate => '0.36'},
            '20040101' => {rate => '0.375'},
            '20050101' => {rate => '0.405'}, #originally .40 but the 2006 circular from irs says this is the correct amount for 2005.
            '20050901' => {rate => '0.485'},
            '20060101' => {rate => '0.445'},
    };
  if (defined $args{debug})
  { $self->{debug} = $args{debug}; }

  return $self;
}

=head2 integer isValidArg( miles => $miles)

        miles - integer > 0
        date -  YYYYMMDD
  )

        This method will check an argument sent in for validity.  returns 0 for no, 1 for yes .
        NOTE:  Only send one argument at a time.  If you send all you will not know which one is invalid
=cut

sub isValidArg
{
        my $self = shift;
        my %args =  ( @_   );
        if (exists $args{miles} )
        {
                if ($args{miles} !~ /^\d+$/)
                {  return 0; }
                else
                { return 1; }
        }
        if (exists $args{date} )
        {
                if ($args{date} !~ /^\d{8}$/ )
                {  return 0; }
                else
                {  return 1; }
        }

        return 0;
}

=head2 integer calculate(
        miles - total miles to reimburse
        date - date to be paid on.  affects tax rates  format YYYYMMDD
  )
=cut

sub calculate
{
        my $self = shift;
        my %args = (
                miles => "",
                date => "",
                @_
          );
        my $answer     = 0;
        my $miles        = $args{miles};
        my $date          = $args{date};
        my $foundDate = $self->lookupDate(date=> $date);
        if (exists $args{debug} && defined $args{debug})
        {        $self->{debug} = $args{debug}; }

        if (! $self->isValidArg(miles => $miles))
        {  $self->error("Invalid miles: $miles\n"); return undef; }
        if (not defined $foundDate)
        {  $self->error("Could not lookup date: $date\n"); return undef; }

        $answer = $self->{dataTables}->{$foundDate}->{rate} * $miles;
        if ($self->{debug} eq "yes")
        {
          print "\nanswer: '$answer'\n";
          print "found: '$foundDate'\n";
          print "rate: " . $self->{dataTables}->{$foundDate}->{rate} . " \n";
          print "miles: $miles\n";
        }
        return sprintf("%.2f", $answer);
}

=head2 string lookupDate (date)

        Returns the date closest to the given date that is less than or equal to it

=cut

sub lookupDate
{
  my $self = shift;
  my $found = undef;
  my %args = (date => "", @_ );

  if ( $self->isValidArg(date => $args{date}) == FALSE)
  {  $self->error("Invalid format for date:'$args{date}' in lookupDate\n"); return undef;  }

  #check boundaries of data hash first
  my $first =$self->firstDate();
  if ( $args{date} < $first )
  {  $self->error("Error.  Date is earlier than first date in list: $first\n"); return undef; }

  #walk over dataTables hash looking for a close match
  foreach my $current (reverse sort keys %{$self->{dataTables}} )
  {
    if ($current <= $args{date})
    {
      $found = $current;
      last;
    }
  }
  return $found;
}

=head2 string firstDate()

        This method will return the earliest date in the datatables.
        Combined with the lastDate method, you can find the date range of the data

=cut

sub firstDate
{
  my $self = shift;
  #grab keys from hash and order so that the first one is first
  return (sort keys %{$self->{dataTables}})[0] ;
}

=head2 string lastDate()

        This method will return the earliest date in the datatables.
        Combined with the firstDate method, you can find the date range of the data

=cut

sub lastDate
{
  my $self = shift;
  #grab keys from hash and order reverse so that the latest one is first
  return (reverse sort keys %{$self->{dataTables}})[0] ;
}

=back

=cut

1;
__END__

=head1 NOTE

All data fields are accessible by specifying the object
and pointing to the data member to be modified on the
left-hand side of the assignment.
        Ex.  $obj->variable($newValue); or $value = $obj->variable;

=head1 AUTHOR

JT Moree - www.pcxperience.org

=head1 SEE ALSO

perl

=cut
