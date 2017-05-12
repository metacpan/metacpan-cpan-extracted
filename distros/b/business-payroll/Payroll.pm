# Payroll.pm
# Created:  Fri May 31 12:04:36 CDT 2002
# by Xperience, Inc. (mailto:payroll@pcxperience.com)
# $Id: Payroll.pm,v 1.33 2005/12/30 15:11:01 moreejt Exp $
#This package is released under the same license as Perl
# Copyright (c) 2002-2003 http://www.pcxperience.org  All rights reserved.

=head1 NAME

Business::Payroll

=head1 SYNOPSIS

  use Business::Payroll;
  
  my $file = "payrollIn.xml";
  my $string = "";  # If dynamically created or read from STDIN.

  my $payroll = Business::Payroll->new();
  if ($payroll->error())
  {
    die $payroll->errorMessage();
  }

  my $result = $payroll->process(file => $file, string => $string);
  my $output = $result->generateXML();

  # now you either print it or write to a file.
  print $output;

=head1 DESCRIPTION

This is the base package for the Business::Payroll Module.  
It can be used programmatically per the synopsis above or with standalone
xml files.  There are two perl scripts included with this module to
update and process the xml files.  The standard procedure would be

  1) Create xml file by hand or use example from this doc as a template.  This is called 'raw' data.
  2) 'cook' the data by running the process_payroll script.  (no arguments will give help output)
  3) For the next pay period you can manually copy and change the previous raw data or run update_payroll
  4) Repeat step 2

NOTE: There are no requirements on file names.  We use two directories of input and output files and use dates for file names.  You can also put all files in one directory and name them something like input_DATE.xml output_DATE.xml. 

Example:

=over 4

<?xml version="1.0" encoding="ISO-8859-1"?>
<payroll type="raw" version="1.0" date="20040713" period="biweekly" genSysId="20040628-20040711">
  <person id="1" name="Person A" marital="single">
    <country name="US" gross="1362.00" allow="2" withHold="0.00" grossYTD="13166.00" federalYTD="1071.00" method="">
      <state name="MO" gross="1362.00" allow="1" withHold="5.00" method="">
      </state>
    </country>
  </person>
  <person id="2" name="Person B" marital="single">
    <country name="US" gross="541.00" allow="1" withHold="0.00" grossYTD="9899.00" federalYTD="835.00" method="">
      <state name="MO" gross="541.00" allow="0" withHold="2.00" method="">
      </state>
    </country>
  </person>
</payroll>

=back

=cut

package Business::Payroll;
use strict;
use Business::Payroll::Base;
use Business::Payroll::XML::Parser;
use Business::Payroll::XML::OutData;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Business::Payroll::Base Exporter AutoLoader);
@EXPORT = qw();

$VERSION = '1.3';

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

  if ($self->error)
  {
    $self->prefixError();
    return $self;
  }

  # the cache of countries modules we have used.
  $self->{cache} = {};

  # keep a list of all countries that are supported.
  $self->{validCountries} = { "US" => 1 };

  # define the period names and how many days are in them.
  $self->{periodNames} = {"annual" => 260, "semiannual" => 130, "quarterly" => 65,
                    "monthly" => 21.67, "semimonthly" => 10.84, "biweekly" => 10,
                    "weekly" => 5, daily => 1 };

  eval { $self->{parserObj} = Business::Payroll::XML::Parser->new(validCountries => $self->{validCountries}, periodNames => $self->{periodNames}); };
  if ($@)
  {
    die "Error:  Instantiating Business::Payroll::XML::Parser failed!\n$@";
  }

  # do validation
  if (!$self->Business::Payroll::isValid)
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

=head2 Business::Payroll::XML::OutData process(file, string)

  Processes the xml data specified in the file or the string.  If both
  are specified, then the string takes precedence.
  
  Returns an instance of Business::Payroll::XML::OutData which holds 
  the perl data structure and can be turned into XML by calling it's 
  generateXML() method.

=cut

sub process
{
  my $self = shift;
  my %args = ( file => "", string => "", @_ );
  my $file = $args{file};
  my $string = $args{string};
  my $errString = "Business::Payroll->process()  - Error!\n";

  if (length $file > 0 && ($file ne "-" && ! -f $file))
  {
    die "$errString file = '$file' does not exist!\n";
  }
  if (length $file == 0 && length $string == 0)
  {
    die "$errString You must specify the file and/or the string!\n";
  }
  if (!exists $self->{parserObj})
  {
    die "$errString You must call new() first!\n";
  }

  my $outgoingData = Business::Payroll::XML::OutData->new(periodNames => $self->{periodNames});

  my $incomingData = undef;
  eval { $incomingData = $self->{parserObj}->parse(file => $file, string => $string); };
  if ($@)
  {
    die "$errString  Parse of XML data failed!\n$@";
  }

  my @result = $incomingData->isValid();
  if (!$result[0])
  {
    die "$errString  Payroll File not valid!\n\n" . join("\n", @{$result[1]}) . "\n";
  }

  # at this point we have valid data and $incomingData is ready to be processed.

  my $period = $incomingData->{period};
  my $date = $incomingData->{date};
  
  $outgoingData->{period} = $period;
  $outgoingData->{date} = $date;
  $outgoingData->{genSysId} = $incomingData->{genSysId};
  $outgoingData->{startPeriod} = $incomingData->{startPeriod};
  $outgoingData->{endPeriod} = $incomingData->{endPeriod};

  # loop over all persons in the data.
  foreach my $person (@{$incomingData->{persons}})
  {
    my $id = $person->{id};
    my $marital = $person->{marital};
    
    my @items = ();  # stores all the "items" returned for this person.
    my $gross = "0.00";
    my $net = "0.00";

    # now loop over the countries this person worked in.
    foreach my $country (@{$person->{countries}})
    {
      if (!exists $self->{validCountries}->{$country->{name}})
      {
        print "Warning:  Country = '$country->{name}' is not supported!  Skipping...\n";
        next;
      }
      # see if the country Object is in the cache.
      if (!exists $self->{cache}->{$country->{name}})
      {
        eval "use Business::Payroll::" . $country->{name} . ";";
        if ($@)
        {
          die "$errString Failed to use Business::Payroll::$country->{name}!\n$@";
        }
        eval "\$self->{cache}->{$country->{name}} = Business::Payroll::" . $country->{name} . "->new();";
        if ($@)
        {
          die "$errString Failed to instantiate Business::Payroll::$country->{name}!\n$@";
        }
      }

      # add the gross to our running total.
      $gross += $country->{gross};
      $net += $country->{gross};

      # now call the country modules process method
      my @result = ();
      eval { @result = $self->{cache}->{$country->{name}}->process(person => $person, period => $period, date => $date, info => $country); };
      if ($@)
      {
        die "$errString  Failed to process Business::Payroll::$country->{name}!\n$@";
      }

      foreach my $item (@result)
      {
        if (!exists $item->{comment})
        {
          $item->{comment} = "";
        }
        push @items, $item;
        $net += $item->{value};  # only because the values are negative.
      }
    }
    
    # now handle any adjustments
    foreach my $adjustment (@{$person->{adjustments}})
    {
      push @items, { name => $adjustment->{name}, value => $adjustment->{value}, comment => $adjustment->{comment} };
      $net += $adjustment->{value};
    }

    # create the gross and net entries.
    $gross = sprintf("%.2f", $gross);
    $net = sprintf("%.2f", $net);

    push @items, { name => "gross", value => $gross, comment => "" };
    push @items, { name => "net", value => $net, comment => "" };

    # update this persons entry in the outgoingData object.
    my %person = ( id => $id, name => $person->{name}, items => \@items );
    push @{$outgoingData->{persons}}, \%person;
  }

  return $outgoingData;
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
