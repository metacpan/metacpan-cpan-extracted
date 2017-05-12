#! /usr/bin/perl
# parse_test.pl - Tests the Business::Payroll::XML::Parser module.
use strict;
use Business::Payroll::XML::Parser;
use Business::Payroll::XML::OutData;

my $version = "1.1";
my $errStr = "(parse_test) - Error:";

my %validCountries = ( "US" => 1, "Canada" => 1 );
my %periodNames = ("annual" => 260, "semiannual" => 130, "quarterly" => 65,
                   "monthly" => 21.67, "semimonthly" => 10.84, "biweekly" => 10,
                   "weekly" => 5, daily => 1 );

my $resultSetObj = Business::Payroll::XML::Parser->new(validCountries => \%validCountries, periodNames => \%periodNames);

my $xmlString = <<"DATA";
<?xml version="1.0" encoding="ISO-8859-1"?>
<payroll type="raw" version="1.1" date="20040715" period="weekly" genSysId="12" startPeriod="20040701" endPeriod="20040715">
  <person id="123456789" name="John Doe" marital="single">
    <country name="US" gross="1000.00" allow="1" withHold="1.00" grossYTD="3000.00" federalYTD="100.00" method="">
      <state name="MO" gross="400.00" allow="0" withHold="5.00" method="">
        <local name="St. Louis" gross="10.00" allow="0" withHold="0.00" method=""/>
      </state>
      <state name="IL" gross="600.00" allow="0" withHold="5.00" method="">
        <local name="E. St. Louis" gross="50.00" allow="1" withHold="0.00" method=""/>
      </state>
      <mileage>24</mileage>
    </country>
    <adjustment name="Reimbursement" value="20.25" comment="Parking fees"/>
  </person>
</payroll>
DATA

my $dataObj = undef;

#eval { $dataObj = $resultSetObj->parse(file => "test.xml"); };
eval { $dataObj = $resultSetObj->parse(string => $xmlString); };
if ($@)
{
  die "$errStr  Eval failed: $@\n";
}

# invalidate the data.
#$dataObj->{persons}->[0]->{countries} = [];
#$dataObj->{persons}->[0]->{countries}->[0]->{name} = "Canada";
#$dataObj->{persons}->[0]->{countries}->[0]->{states}->[0]->{name} = "IL";
#$dataObj->{persons}->[0]->{countries}->[0]->{states}->[0]->{locals}->[0]->{name} = "Kansas City";

my @result = $dataObj->isValid();
if (!$result[0])
{
  print "Payroll File not valid!\n\n";
  print join("\n", @{$result[1]}) . "\n";
  exit 0;
}

# test the actual data as we implement different parsing code.

eval { print $dataObj->generateXML; };
if ($@)
{
  print "Error: $@";
  exit 0;
}

print "\n----------- OutData Test ----------\n";

my $outObj = Business::Payroll::XML::OutData->new(periodNames => \%periodNames);
$outObj->{dataFile} = "";
$outObj->{date} = "20040730";
$outObj->{period} = "monthly";
$outObj->{genSysId} = "12";
$outObj->{startPeriod} = "20040716";
$outObj->{endPeriod} = "20040730";
my @items = ( { name => "gross", value => "500.00", comment => "" }, { name => "net", value => "-500.00", comment => "" }, { name => "Reimbursement", value => "20.25", comment => "Parking fees" } );
my %person = ( id => "123457902", name => "James", items => \@items );
push @{$outObj->{persons}}, \%person;
my %person = ( id => "223453234", name => "Jason", items => \@items );
push @{$outObj->{persons}}, \%person;

my @result = $outObj->isValid();
if (!$result[0])
{
  print "Output Payroll File not valid!\n\n";
  print join("\n", @{$result[1]}) . "\n";
  exit 0;
}

# test the actual data as we implement different parsing code.

eval { print $outObj->generateXML; };
if ($@)
{
  print "Error: $@";
  exit 0;
}


my $outDataObj = undef;
eval { $outDataObj = $resultSetObj->parse(string => $outObj->generateXML()); };
if ($@)
{
  die "$errStr  Eval failed: $@\n";
}

my @result = $outDataObj->isValid();
if (!$result[0])
{
  print "Output Payroll File not valid!\n\n";
  print join("\n", @{$result[1]}) . "\n";
  exit 0;
}

foreach my $person (@{$outDataObj->{persons}})
{
  print "id='$person->{id}', name='$person->{name}'\n";
  foreach my $item (@{$person->{items}})
  {
    print "\tname='$item->{name}', value='$item->{value}', comment='$item->{comment}'\n";
  }
}
