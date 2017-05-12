# StateIncome.pm
# Created:  Thu Feb 14 15:30:24 CST 2002
# by Xperience, Inc. (mailto:admin@pcxperience.com)
# $Id: StateIncome.pm,v 1.17 2005/12/30 15:11:01 moreejt Exp $
# Copyright (c) 2002-2003 http://www.pcxperience.org  All rights reserved.
# license: same as perl

=head1 NAME

StateIncome

=head1 SYNOPSIS

  use Business::Payroll::US::MO::StateIncome;
  my $stateIncome = Business::Payroll::US::MO::StateIncome->new();
  if ($stateIncome->error())
  {
    die $stateIncome->errorMessage();
  }

=head1 DESCRIPTION

This package will calculate the income tax based on a gross salary amount given.

=cut

package Business::Payroll::US::MO::StateIncome;
use strict;
use Business::Payroll::Base;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Business::Payroll::Base Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '0.3';

=head1 Exported FUNCTIONS

=over 4

=head2  scalar new()

        Creates a new instance of the object.
        takes:

=cut

sub new
{
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my %args = ( @_ );

  # make sure your Parent isValid.
  if ($self->error)
  {
    $self->prefixError();
    return $self;
  }

      $self->{periodDays} = {
        annual => 1,
        semiannual => 2,
        quarterly => 4,
        monthly => 12,
        semimonthly => 24,
        biweekly => 26,
        weekly => 52,
        daily => 260
     };

    $self->{dataTables} =  {
            '19990101' => {
               standardDeduction => {single => '4300', married => '3600' , spouseWorks => '3600', head => '3600' },
               allowance1 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance2 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance3 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance4 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance5 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               federalLimit => { single => '5000', married => '10000', spouseWorks => '5000'},
               percentTable => [
                    {bottom => '0', percent => '.015' },
                    {bottom => '1000.01', percent => '.02' },
                    {bottom => '2000.01', percent => '.025' },
                    {bottom => '3000.01', percent => '.03' },
                    {bottom => '4000.01', percent => '.035' },
                    {bottom => '5000.01', percent => '.04' },
                    {bottom => '6000.01', percent => '.045' },
                    {bottom => '7000.01', percent => '.05' },
                    {bottom => '8000.01', percent => '.055' },
                    {bottom => '9000.01', percent => '.06' }
                ]
            },
            '20020101' => {
               standardDeduction => {single => '4700', married => '7850' , spouseWorks => '3925', head => '6900' },
               allowance1 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '3500'},
               allowance2 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '0'},
               allowance3 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '0'},
               allowance4 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '0'},
               allowance5 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               federalLimit => { single => '5000', married => '10000', spouseWorks => '5000'},
               percentTable => [
                    {bottom => '0', percent => '.015' },
                    {bottom => '1000.01', percent => '0.02' },
                    {bottom => '2000.01', percent => '0.025' },
                    {bottom => '3000.01', percent => '0.03' },
                    {bottom => '4000.01', percent => '0.035' },
                    {bottom => '5000.01', percent => '0.04' },
                    {bottom => '6000.01', percent => '0.045' },
                    {bottom => '7000.01', percent => '0.05' },
                    {bottom => '8000.01', percent => '0.055' },
                    {bottom => '9000.01', percent => '0.06' }
                ]
            },
            '20030101' => {
               standardDeduction => {single => '4750', married => '7950' , spouseWorks => '3975', head => '7000' },
               allowance1 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '3500'},
               allowance2 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '0'},
               allowance3 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '0'},
               allowance4 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '0'},
               allowance5 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               federalLimit => { single => '5000', married => '10000', spouseWorks => '5000' },
               percentTable => [
                    {bottom => '0', percent => '.015' },
                    {bottom => '1000.01', percent => '0.02' },
                    {bottom => '2000.01', percent => '0.025' },
                    {bottom => '3000.01', percent => '0.03' },
                    {bottom => '4000.01', percent => '0.035' },
                    {bottom => '5000.01', percent => '0.04' },
                    {bottom => '6000.01', percent => '0.045' },
                    {bottom => '7000.01', percent => '0.05' },
                    {bottom => '8000.01', percent => '0.055' },
                    {bottom => '9000.01', percent => '0.06' }
                ]
            },
            '20040101' => {
               standardDeduction => {single => '4850', married => '7900' , spouseWorks => '4850', head => '7150' },
               allowance1 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '3500'},
               allowance2 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance3 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance4 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance5 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               federalLimit => { single => '5000', married => '10000' , spouseWorks => '5000' },
               percentTable => [
                    {bottom => '0', percent => '.015' },
                    {bottom => '1000.01', percent => '0.02' },
                    {bottom => '2000.01', percent => '0.025' },
                    {bottom => '3000.01', percent => '0.03' },
                    {bottom => '4000.01', percent => '0.035' },
                    {bottom => '5000.01', percent => '0.04' },
                    {bottom => '6000.01', percent => '0.045' },
                    {bottom => '7000.01', percent => '0.05' },
                    {bottom => '8000.01', percent => '0.055' },
                    {bottom => '9000.01', percent => '0.06' }
                ]
            },
            '20050101' => {
               standardDeduction => {single => '5000', married => '10000' , spouseWorks => '5000', head => '7300' },
               allowance1 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '3500'},
               allowance2 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance3 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance4 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance5 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               federalLimit => { single => '5000', married => '10000' , spouseWorks => '5000' },
               percentTable => [
                    {bottom => '0', percent => '.015' },
                    {bottom => '1000.01', percent => '0.02' },
                    {bottom => '2000.01', percent => '0.025' },
                    {bottom => '3000.01', percent => '0.03' },
                    {bottom => '4000.01', percent => '0.035' },
                    {bottom => '5000.01', percent => '0.04' },
                    {bottom => '6000.01', percent => '0.045' },
                    {bottom => '7000.01', percent => '0.05' },
                    {bottom => '8000.01', percent => '0.055' },
                    {bottom => '9000.01', percent => '0.06' }
                ]
            },
            '20060101' => {
               standardDeduction => {single => '5150', married => '10300' , spouseWorks => '5150', head => '7550' },
               allowance1 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '3500'},
               allowance2 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance3 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance4 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               allowance5 => { single => '1200', married => '1200' , spouseWorks => '1200', head => '1200'},
               federalLimit => { single => '5000', married => '10000' , spouseWorks => '5000' },
               percentTable => [
                    {bottom => '0', percent => '.015' },
                    {bottom => '1000.01', percent => '0.02' },
                    {bottom => '2000.01', percent => '0.025' },
                    {bottom => '3000.01', percent => '0.03' },
                    {bottom => '4000.01', percent => '0.035' },
                    {bottom => '5000.01', percent => '0.04' },
                    {bottom => '6000.01', percent => '0.045' },
                    {bottom => '7000.01', percent => '0.05' },
                    {bottom => '8000.01', percent => '0.055' },
                    {bottom => '9000.01', percent => '0.06' }
                ]
            },
        };

  return $self;
}

=head2 integer calculate

  (
    gross,            # - gross pay
    date,             #- date of payment format YYYYMMDD
    method,         #- specifies method to use. currently only 1
    allowances    #, - state allowances claimed, integer
    period,             #- annual, semiannual, quarterly, monthly, semimonthly, biweekly, weekly, daily
    marital,             #- single, married, spouseWorks, head
    federal,             #- amount of federal tax withheld here
    fYTD,             #- total federal tax withheld year to date
    round,             #yes, no - defaults to yes
  )

=cut

sub calculate
{
    my $self = shift;
    my %args = (gross => 0,
        date => "",             #- date of payment format YYYYMMDD
        method => "",         #- specifies mthod to use. currently only 1
        allowances => 0,    #, - state allowances claimed, integer
        period => "",             #- annual, semiannual, quarterly, monthly, semimonthly, biweekly, weekly, daily
        marital => "",             #- single, married, spouseWorks, head
        federal => 0,             #- amount of federal tax withheld here
        fYTD => 0,             #- total federal tax withheld yeart to date
        round => "yes",             #yes, no - defaults to yes
        @_
    );

    my $aFed = 0;
    my $aGross = 0;
    my $allowances = $args{allowances};
    my $date = $args{date};
    my $federal = $args{federal};
    my $fYTD = $args{fYTD};
    my $foundDate = "";
    my $gross = $args{gross};
    my $marital = $args{marital};
    my $mGross = 0;
    my $period = $args{period};
    my $round = $args{round};
    my $tax = 0;

    if (! $self->isValidArg(gross => $gross) )
    {  $self->error("Invalid gross: $gross\n"); return undef; }
    if (! $self->isValidArg(allowances => $allowances) )
    {  $self->error("Invalid allowances: $allowances\n"); return undef; }
    if (! $self->isValidArg(marital => $marital) )
    {  $self->error("Invalid marital: $marital\n"); return undef; }
    if ($round =~ /^yes$/i)
    {  $round = "yes"; }
    elsif ($round =~ /^no$/i)
    {  $round = "no"; }
    else
    {  $self->error("Invalid round: $round.  Use 'yes' or 'no'\n"); return undef; }
    if (! $self->isValidArg(period => $period ) )
    { $self->error("Invalid period: $period\n"); return undef; }
    if (! $self->isValidArg(date => $date ) )
    { $self->error("Invalid date '$date'"); return undef; }
    else
    {  $foundDate = $self->lookupDate(date=> $date);       }
    if (not defined $foundDate)
    {  $self->error("Invalid found date: $date\n"); return undef; }
    #Step 1.1
    $aGross = $self->annualize(amount => $gross, period => $period);
    if (!defined $aGross)
    {
      return undef;
    }
    #print "\nGross Annualized: " . $aGross . "\n";
    #Step 1.2
    $aGross -= $self->{dataTables}->{$foundDate}->{standardDeduction}->{$marital};
    #print "\nGross after standardDeduction for marital = '$marital': $aGross\n";
    #Step 1.3
    if ($allowances >= 1)
    {        $aGross -= $self->{dataTables}->{$foundDate}->{allowance1}->{$marital};          }
    if ($allowances >= 2)
    {        $aGross -= $self->{dataTables}->{$foundDate}->{allowance2}->{$marital};          }
    if ($allowances >= 3)
    {        $aGross -= $self->{dataTables}->{$foundDate}->{allowance3}->{$marital};         }
    if ($allowances >= 4)
    {        $aGross -= $self->{dataTables}->{$foundDate}->{allowance4}->{$marital};         }
    if ($allowances >= 5)
    {        $aGross -= ($self->{dataTables}->{$foundDate}->{allowance5}->{$marital} * ($allowances - 4) );      }
    #print "\nGross after '$allowances' allowances deducted: $aGross\n";
    #Step 1.4
    $aFed = $self->annualize(amount => $federal, period => $period);
    if (!defined $aFed)
    {
      return undef;
    }
    #print "\nAnnualized Fed: $aFed\n";
    if ($aFed > $self->{dataTables}->{$foundDate}->{federalLimit}->{$marital} )
    { $aFed = $self->{dataTables}->{$foundDate}->{federalLimit}->{$marital};    }
    #print "\nPossibly adjusted Fed: $aFed\n";
    $aGross -= $aFed;
    #print "\nGross after subtracting Fed: $aGross\n";
    #Step 1.5 Subtract the total annual numbers of 2,3,4 (done along the way)

    #Step 2.1   lookup tables for percentages
    #need to place table in reverse oder so that we can know the top is
    my @table = @{$self->{dataTables}->{$foundDate}->{percentTable}};
    for (my $x = scalar(@table) - 1 ; $x >= 0; $x--)
    {
       if ($aGross >= $table[$x]->{bottom})
       {
          #print "x = '$x'\n";
          if ($table[$x]->{bottom} == 0)
          {
                $tax += ($aGross) * $table[$x]->{percent};
                $aGross = 0;
          }
          else
          {
             $tax += ($aGross - $table[$x]->{bottom} + 0.01) * $table[$x]->{percent};  #bottom is inclusive
             $aGross = $table[$x]->{bottom} - 0.01;
          }
          #print "tax = '$tax', aGross = '$aGross'\n";
       }
    }
    #Step 2.2
    $tax = $self->annualize(amount => $tax, period=> $period, reverse => "yes");
    if (!defined $tax)
    {
      return undef;
    }

    $tax *= -1 if ($tax !~ /^(0(\.00)?)$/);
    if ($round eq "no")
    {        return $tax;        }
    return sprintf("%.0f",$tax) . ".00"; #round to whole number
}

=head2 integer isValidArg( gross => $gross)

        gross - floating point > 0
        date -  YYYYMMDD
        method -
        allowances - integer > 0
        period - annual, semiannual, quarterly, monthly, semimonthly, biweekly, weekly, daily
        marital - single | married | spouseWorks | head
        periodDays -
        round - yes, no
  )

        This method will check an argument sent in for validity.  returns 0 for no, 1 for yes .
        NOTE:  Only send one argument at a time.  If you send all you will not know which one is invalid
=cut

sub isValidArg
{
        my $self = shift;
        my %args =  ( @_   );
        if (exists $args{gross} )
        {
                if ($args{gross} !~ /^(\d+(\.\d+)?)$/)
                {  return 0; }
                else
                { return 1; }
        }
        if (exists $args{marital} )
        {
                if ($args{marital} !~ /^(married|single|spouseWorks|head)$/ )
                {  return 0; }
                else
                {  return 1; }
        }
        if (exists $args{date} )
        {
                if ($args{date} !~ /^\d{8}$/ )
                {  return 0; }
                else
                {  return 1; }
        }
        if (exists $args{allowances} )
        {
                if ($args{allowances} !~ /^\d+$/ )
                {  return 0; }
                else
                {  return 1; }
        }
        if (exists $args{round} )
        {
                if ($args{round} =~ /^(yes)|(no)$/i )
                {  return 1; }
                else
                {  return 0; }
        }
        if (exists $args{period}  )
        {
                if (exists $self->{periodDays}->{$args{period}} )
                {  return 1; }
                else
                {  return 0; }
        }

        return 0;
}

=head2 float annualize(amount, period)

        This method will change the given floating point to an
        annual number based on the corresponding period.
        i.e.  X, monthly will yield (X * 12)

=cut

sub annualize
{
        my $self = shift;
        my %args = (amount => "", period => "", reverse => "no",  @_  );
        my $errStr = "Business::Payroll::US::MO::StateIncome->annualize()  - Error!\n";
        if ( $self->isValidArg(amount => $args{amount} ) )
        {
                $self->error("Invalid amount: $args{amount}\n");
                return undef;
        }
        if ($args{amount} =~ /^(0(\.0)?)$/)
        {  return 0;  }
        if (not exists $self->{periodDays}->{$args{period}})
        {  $self->error("Invalid period: '$args{period}'\n"); return undef; }
        else
        {
             if ($args{reverse} =~ /^yes$/i)
             {   return $args{amount} / $self->{periodDays}->{$args{period}};     }
             else
             {   return $args{amount} * $self->{periodDays}->{$args{period}};   }
        }
        return undef;
}

=head2 string lookupDate (date)

        Returns the date closest to the given date that is less than or equal to it

=cut

sub lookupDate
{
  my $self = shift;
  my $found = undef;
  my %args = (date => "", @_ );

  if ( $args{date} !~ /^\d{8}$/)
  {
    $self->error("invalid date format");
    return undef;
  }

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
  #grab keys from hash and order reverse so that the latest one is first
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

Xperience, Inc. (mailto:admin@pcxperience.com)

=head1 SEE ALSO

perl(1)

=cut
