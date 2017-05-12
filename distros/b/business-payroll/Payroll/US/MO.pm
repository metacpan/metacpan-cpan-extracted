# MO.pm
# Created:  Fri May 31 12:04:36 CDT 2002
# by Xperience, Inc. (mailto:admin@pcxperience.com)
# $Id: MO.pm,v 1.13 2005/12/30 15:11:01 moreejt Exp $
# Copyright (c) 2002-2003 http://www.pcxperience.org  All rights reserved.
# License: same as perl

=head1 NAME

Business::Payroll::US::MO

=head1 SYNOPSIS

  use Business::Payroll::US::MO;

  my $moPayroll = Business::Payroll::US::MO->new();
  if ($moPayroll->error())
  {
    die $moPayroll->errorMessage();
  }

  my $result = Business::Payroll::XML::OutData->new(periodNames => \%periodNames);
  my @result = ();

  eval { @result = $moPayroll->process(person => $person, date => $date, period => $period,
                             info => \%countryInfo, federal => $federal, fYTD => $fYTD);
  if ($@)
  {
    die "$@";
  }

=head1 DESCRIPTION

This is the base package for the Business::Payroll::US::MO Modules.

=cut

package Business::Payroll::US::MO;
use strict;
use Business::Payroll::Base;
use Business::Payroll::US::MO::StateIncome;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Business::Payroll::Base Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '0.3';

my %trueFalse = ( 1 => "true", 0 => "false" );
my %falseTrue = ( "true" => 1, "false" => 0 );

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

  # make sure our Parent isValid.
  if ($self->error)
  {
    $self->prefixError();
    return $self;
  }
  
  # the cache of state related modules we have used.
  $self->{moduleCache} = {};

  # do validation
  if (!$self->Business::Payroll::US::MO::isValid)
  {
    return $self;
  }

  return $self;
}

=head2 bool isValid(void)

        Returns 0 or 1 to indicate if the object is valid.  The error will be available via errorMessage().

=cut

sub isValid
{
  my $self = shift;

  # make sure my Parent isValid.
  if (!$self->SUPER::isValid())
  {
    $self->prefixError();
    return 0;
  }
  
  # do validation code here.

  if ($self->numInvalid() > 0 || $self->numMissing() > 0)
  {
    $self->error($self->genErrorString("all"));
    return 0;
  }
  return 1;
}

=head2 @items process(person, date, period, info, federal, fYTD, round)

  info contains the information related to this country for the specified person.
  person represents the person object in the Data structure.
  date is the date specified in the XML document.
  period is the period specified in the XML document.
  federal is the calculated federal taxes.
  fYTD is the currently withheld federal YTD taxes.
  round indicates if we are to round the results.

  Returns: the items array of name,value entries created.

=cut

sub process
{
  my $self = shift;
  my %args = ( person => undef, date => "", period => "daily", info => undef, federal => "0", fYTD => "0", round => "yes", @_ );
  my $person = $args{person};
  my $date = $args{date};
  my $period = $args{period};
  my $info = $args{info};
  my $federal = $args{federal};
  my $fYTD = $args{fYTD};
  my $round = $args{round};
  my $errString = "Business::Payroll::US::MO->process()  - Error!\n";
  my @items = ();

  if (!defined $person)
  {
    die "$errString  person not defined!\n";
  }
  if ($date !~ /^(\d{8})$/)
  {
    die "$errString  date = '$date' is invalid!\n";
  }
  if (length $period == 0)
  {
    die "$errString period must be specified!\n";
  }
  if (!defined $info)
  {
    die "$errString  info not defined!\n";
  }
  if ($round !~ /^(yes|no)$/)
  {
    die "$errString round = '$round' is invalid!\n";
  }
  if ($federal !~ /^(\d+(\.\d+)?)$/)
  {
    die "$errString federal = '$federal' is invalid!\n";
  }
  if ($fYTD !~ /^(\d+\.\d+)$/)
  {
    die "$errString fYTD = '$fYTD' is invalid!\n";
  }

  # now calculate the StateIncome
  if (!exists $self->{moduleCache}->{StateIncome})
  {
    eval "\$self->{moduleCache}->{StateIncome} = Business::Payroll::US::MO::StateIncome->new();";
    if ($@)
    {
      die "$errString Failed to instantiate Business::Payroll::US::MO::StateIncome!\n$@";
    }
  }
  
  #print "US MO:  gross = '$info->{gross}', federal => '$federal'\n";

  my $answer = $self->{moduleCache}->{StateIncome}->calculate(gross => $info->{gross},
               date => $date, method => $info->{method}, allowances => $info->{allow},
               period => $period, marital => $person->{marital}, federal => $federal,
               fYTD => $fYTD, round => $round);
  if (!defined $answer)
  {
    die "$errString " . $self->{moduleCache}->{StateIncome}->errorMessage;
  }
  $answer -= $info->{withHold};
  $answer = sprintf("%.0f", $answer) . ".00" if ($round eq "yes");
  $items[0] = { name => "US MO", value => $answer };

  # we should handle locals here, but am just going to ignore them for now.

  return @items;
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

perl(1), Business::Payroll(3), Business::Payroll::US(3)

=cut
