# US.pm
# Created:  Fri May 31 12:04:36 CDT 2002
# by Xperience, Inc. (mailto:payroll@pcxperience.com)
# $Id: US.pm,v 1.15 2004/11/26 19:16:25 pcxuser Exp $
#This package is released under the same license as Perl
# Copyright (c) 2002-2003 http://www.pcxperience.org  All rights reserved.

=head1 NAME

Business::Payroll::US

=head1 SYNOPSIS

  use Business::Payroll::US;

  my $usPayroll = Business::Payroll::US->new();
  if ($usPayroll->error())
  {
    die $usPayroll->errorMessage();
  }

  my $result = Business::Payroll::XML::OutData->new(periodNames => \%periodNames);
  my @result = ();

  eval { @result = $usPayroll->process(person => $person, date => $date, period => $period,
                             info => \%countryInfo);
  if ($@)
  {
    die "$@";
  }

=head1 DESCRIPTION

This is the base package for the Business::Payroll::US Modules.

=cut

package Business::Payroll::US;
use strict;
use Business::Payroll::Base;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Business::Payroll::Base Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '0.3';

my %trueFalse = ( 1 => "true", 0 => "false" );
my %falseTrue = ( "true" => 1, "false" => 0 );

=head1 Exported FUNCTIONS

=pod

=head2  scalar new()

        Creates a new instance of the object.
        takes:

=cut

sub new
{
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  my %args = ( @_ );

  if ($self->error)
  {
    $self->prefixError();
    return $self;
  }

  # the cache of state modules we have used.
  $self->{stateCache} = {};
  
  # the cache of FedIncome, Medicare, FICA modules we have used.
  $self->{generalCache} = {};

  # do validation
  if (!$self->Business::Payroll::US::isValid)
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

  # make sure our Parent class is valid.
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

=head2 @items process(person, date, period, info, round)

  info contains the information related to this country for the specified person.
  person represents the person object in the Data structure.
  date is the date specified in the XML document.
  period is the period specified in the XML document.
  round specifies whether to round the result or not.
  
  Returns: the items array of name,value entries created.

=cut

sub process
{
  my $self = shift;
  my %args = ( person => undef, date => "", period => "daily", info => undef, round => "yes", @_ );
  my $person = $args{person};
  my $date = $args{date};
  my $period = $args{period};
  my $info = $args{info};
  my $round = $args{round};
  my $errString = "Business::Payroll::US->process()  - Error!\n";
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
    die "$errString  round = '$round' is invalid!\n";
  }

  foreach my $module ("FedIncome", "Medicare", "FICA", "Mileage")
  {
    # see if the Object is in the cache.
    if (!exists $self->{generalCache}->{$module})
    {
      eval "use Business::Payroll::US::$module;";
      if ($@)
      {
        die "$errString Failed to use Business::Payroll::US::$module!\n$@";
      }
      eval "\$self->{generalCache}->{$module} = Business::Payroll::US::" . $module . "->new();";
      if ($@)
      {
        die "$errString Failed to instantiate Business::Payroll::US::$module!\n$@";
      }
    }
  }

  # now calculate the FedIncome
  my $federal = $self->{generalCache}->{FedIncome}->calculate(gross => $info->{gross},
                date => $date, period => $period, method => $info->{method},
                allowances => $info->{allow}, marital => $person->{marital},
                round => $round);
  if (!defined $federal)
  {
    die "$errString Calculating US Federal witholding failed!\n" . $self->{generalCache}->{FedIncome}->errorMessage();
  }
  $federal -= $info->{withHold};
  $federal = sprintf("%.0f", $federal) . ".00" if ($round eq "yes");
  $items[0] = { name => "US Federal", value => $federal };
  $federal *= -1 if ($federal !~ /^(0(\.00)?)$/);
  #print "Federal = '$federal'\n";

  # now calculate the Medicare
  my $medicare = $self->{generalCache}->{Medicare}->calculate(gross => $info->{gross},
                 date => $date, YTD => $info->{grossYTD});
  if (!defined $medicare)
  {
    die "$errString Calculating US Medicare witholding failed!\n" . $self->{generalCache}->{Medicare}->errorMessage();
  }
  $items[1] = { name => "US Medicare", value => $medicare };
  $medicare *= -1 if ($medicare !~ /^(0(\.00)?)$/);
  #print "Medicare = '$medicare'\n";

  # now calculate the FICA
  my $fica = $self->{generalCache}->{FICA}->calculate(gross => $info->{gross},
             date => $date, YTD => $info->{grossYTD});
  if (!defined $fica)
  {
    die "$errString Calculating US FICA witholding failed!\n" . $self->{generalCache}->{FICA}->errorMessage();
  }
  $items[2] = { name => "US FICA", value => $fica };
  $fica *= -1 if ($fica !~ /^(0(\.00)?)$/);
  #print "FICA = '$fica'\n";

  # loop over all states in the info object.
  foreach my $state (@{$info->{states}})
  {
    # see if the state Object is in the cache.
    if (!exists $self->{stateCache}->{$state->{name}})
    {
      eval "use Business::Payroll::US::" . $state->{name} . ";";
      if ($@)
      {
        die "$errString Failed to use Business::Payroll::US::$state->{name}!\n$@";
      }
      eval "\$self->{stateCache}->{$state->{name}} = Business::Payroll::US::" . $state->{name} . "->new();";
      if ($@)
      {
        die "$errString Failed to instantiate Business::Payroll::US::$state->{name}!\n$@";
      }
    }

    # now call the state modules process method
    my @stateItems = ();
    eval { @stateItems = $self->{stateCache}->{$state->{name}}->process(person => $person, date => $date,
                         period => $period, info => $state, federal => $federal, fYTD => $info->{federalYTD},
                         round => $round); };
    if ($@)
    {
      die "$errString  Failed to process Business::Payroll::US::$state->{name}!\n$@";
    }

    foreach my $item (@stateItems)
    {
      push @items, $item;
    }
  }
  
  # now do any Mileage work
  if ($info->{mileage})
  {
    my $mileage = $self->{generalCache}->{Mileage}->calculate(miles => $info->{mileage},
             date => $date);
    if (!defined $mileage)
    {
      die "$errString Calculating US Mileage reimbursement failed!\n" . $self->{generalCache}->{Mileage}->errorMessage();
    }
    $mileage = sprintf("%.2f", $mileage);
    push @items, { name => "US Mileage", value => $mileage };
  }

  return @items;
}

1;
__END__

=
NOTE:  All data fields are accessible by specifying the object
and pointing to the data member to be modified on the
left-hand side of the assignment.
        Ex.  $obj->variable($newValue); or $value = $obj->variable;

=head1 AUTHOR

Xperience, Inc. (mailto:admin@pcxperience.com)

=head1 SEE ALSO

perl(1), Business::Payroll(3)

=cut
