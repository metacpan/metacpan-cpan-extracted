# OutData.pm - Will pull settings from an XML config file into a format usable by the system.
# Created by James A. Pattie.  Copyright (c) 2002-2004, Xperience, Inc.

package Business::Payroll::XML::OutData;

use strict;
use XML::LibXML;
use vars qw ($AUTOLOAD @ISA @EXPORT $VERSION);

require Exporter;
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

$VERSION = "1.2";

# new
sub new
{
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = bless {}, $class;
  my %args = ( periodNames => undef, @_ );
  my $errStr = "Business::Payroll::XML::OutData->new()  - Error:";

  $self->{periodNames} = $args{periodNames};
  if (!defined $args{periodNames})
  {
    die "$errStr  periodNames not defined!\n";
  }
  $self->{version} = "1.1";
  $self->{type} = "cooked";
  $self->{dataFile} = ""; # only used for debugging purposes.
  $self->{date} = "";
  $self->{period} = "";
  $self->{startPeriod} = "";
  $self->{endPeriod} = "";
  $self->{genSysId} = "";
  $self->{persons} = [];
  $self->{errorCodes} = {
    0  => "version = '%s' is invalid",
    1  => "type = '%s' is invalid",
    2  => "date must be specified",
    3  => "date = '%s' is invalid",
    4  => "period = '%s' is invalid",
    5  => "no persons defined",
    6  => "person: %s = '%s' is invalid",
    7  => "person id='%s', %s does not exist",
    8  => "person id='%s', %s='%s' is invalid",
    9  => "person id='%s' duplicated!",
    10 => "person id='%s', item name='%s' duplicated!",
    11 => "genSysId = '%s' is invalid",
    12 => "%s = '%s' is invalid",  # used by start/end Period variables.
  };

  return $self;
}

sub AUTOLOAD
{
  my $self = shift;
  my $type = ref($self) || die "$self is not an object";
  my $name = $AUTOLOAD;
  $name =~ s/.*://;	# strip fully-qualified portion
  unless (exists $self->{$name})
  {
    die "Can't access `$name' field in object of class $type";
  }
  if (@_)
  {
    return $self->{$name} = shift;
  }
  else
  {
    return $self->{$name};
  }
}

sub DESTROY
{
  my $self = shift;
}

sub isValid
{
  my $self = shift;
  my @errors = ();

  if ($self->{version} !~ /^(1.1)$/)
  {
    push @errors, sprintf($self->{errorCodes}->{0}, $self->{version});
  }
  if ($self->{type} ne "cooked")
  {
    push @errors, sprintf($self->{errorCodes}->{1}, $self->{type});
  }
  if (length $self->{date} == 0)
  {
    push @errors, $self->{errorCodes}->{2};
  }
  elsif ($self->{date} !~ /^(\d{8})$/)
  {
    push @errors, sprintf($self->{errorCodes}->{3}, $self->{date});
  }
  if (length $self->{startPeriod} == 0)
  {
    push @errors, sprintf($self->{errorCodes}->{12}, "startPeriod", $self->{startPeriod});
  }
  elsif ($self->{startPeriod} !~ /^(\d{8})$/)
  {
    push @errors, sprintf($self->{errorCodes}->{12}, "startPeriod", $self->{startPeriod});
  }
  if (length $self->{endPeriod} == 0)
  {
    push @errors, sprintf($self->{errorCodes}->{12}, "endPeriod", $self->{endPeriod});
  }
  elsif ($self->{endPeriod} !~ /^(\d{8})$/)
  {
    push @errors, sprintf($self->{errorCodes}->{12}, "endPeriod", $self->{endPeriod});
  }
  if (! exists $self->{periodNames}->{$self->{period}})
  {
    push @errors, sprintf($self->{errorCodes}->{4}, $self->{period});
  }
  if (length $self->{genSysId} == 0)
  {
    push @errors, sprintf($self->{errorCodes}->{11}, $self->{genSysId});
  }
  if (scalar @{$self->{persons}} == 0)
  {
    push @errors, $self->{errorCodes}->{5};
  }
  else
  {
    # validate persons
    my %encounteredPersons = ();
    foreach my $person (@{$self->{persons}})
    {
      if ($person->{id} !~ /^.+$/)
      {
        push @errors, sprintf($self->{errorCodes}->{6}, 'id', $person->{id});
      }
      if (length $person->{name} == 0)
      {
        push @errors, sprintf($self->{errorCodes}->{6}, 'name', $person->{name});
      }
      # validate items
      my %encounteredItems = ();
      foreach my $item (@{$person->{items}})
      {
        if (!exists $item->{name})
        {
          push @errors, sprintf($self->{errorCodes}->{7}, $person->{id}, 'name');
        }
        elsif ($item->{name} !~ /^(.+)$/)
        {
          push @errors, sprintf($self->{errorCodes}->{8}, $person->{id}, 'name', $item->{name});
        }
        if (!exists $item->{value})
        {
          push @errors, sprintf($self->{errorCodes}->{7}, $person->{id}, 'value');
        }
        elsif ($item->{value} !~ /^(-?\d+(\.\d+)?)$/)
        {
          push @errors, sprintf($self->{errorCodes}->{8}, $person->{id}, 'value', $item->{value});
        }
        if (!exists $item->{comment})
        {
          push @errors, sprintf($self->{errorCodes}->{7}, $person->{id}, 'comment');
        }
      }
      if (exists $encounteredPersons{$person->{id}})
      {
        push @errors, sprintf($self->{errorCodes}->{9}, $person->{id});
      }
      else
      {
        $encounteredPersons{$person->{id}} = 1;
      }
    }
  }

  return ((scalar @errors > 0 ? 0 : 1), \@errors);
}

sub generateXML
{
  my $self = shift;
  my $result = "";
  my $errStr = "Business::Payroll::XML::OutData->generateXML()  - Error:";

  my @valid = $self->isValid();
  if ($valid[0])
  {
    $result .= <<"END_OF_XML";
<?xml version="1.0" encoding="ISO-8859-1"?>
<payroll type="cooked" version="$self->{version}" date="$self->{date}" period="$self->{period}" genSysId="$self->{genSysId}" startPeriod="$self->{startPeriod}" endPeriod="$self->{endPeriod}">
END_OF_XML
    for (my $i=0; $i < scalar @{$self->{persons}}; $i++)
    {
      $result .= "  <person id=\"$self->{persons}[$i]->{id}\" name=\"$self->{persons}[$i]->{name}\">\n";
      foreach my $item (@{$self->{persons}[$i]->{items}})
      {
        my $tmpName = $self->encodeEntities(string => $item->{name});
        my $tmpComment = $self->encodeEntities(string => $item->{comment});
        $result .= "    <item name=\"$tmpName\" value=\"$item->{value}\"" . ($item->{comment} ? " comment=\"$tmpComment\"" : "") . "/>\n";
      }
      $result .= "  </person>\n";
    }
    $result .= <<"END_OF_XML";
</payroll>
END_OF_XML
  }
  else
  {
    $result .= "$errStr Data not valid!\n\n";
    $result .= join("\n", @{$valid[1]}) . "\n";
    die $result;
  }

  return $result;
}

# string encodeEntities(string)
# requires: string - string to encode
# optional:
# returns: string that has been encoded.
# summary: replaces all special characters with their XML entity equivalent. " => &quot;
sub encodeEntities
{
  my $self = shift;
  my %args = ( string => "", @_ );
  my $string = $args{string};

  my @entities = ('&', '"', '<', '>', '\n');
  my %entities = ('&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;', '\n' => '\\n');

  return $string if (length $string == 0);

  foreach my $entity (@entities)
  {
    $string =~ s/$entity/$entities{$entity}/g;
  }

  return $string;
}

1;
__END__

=head1 NAME

OutData - The XML Business::Payroll OutData Module.

=head1 SYNOPSIS

  use Business::Payroll::XML::OutData;
  my $obj = Business::Payroll::XML::OutData->new(periodNames => \%periodNames);

=head1 DESCRIPTION

Business::Payroll::XML::OutData will contain the parsed XML file.
It provides a method to validate that it is complete and also a method
to generate a valid XML file from the data stored in the data hash.

=head1 FUNCTIONS

  scalar new(periodNames)
    Creates a new instance of the Business::Payroll::XML::OutData
    object.

  array isValid(void)
    Determines if the data structure is complete and usable for
    generating an XML file from.
    Returns an array.  The first index is boolean (1 or 0 to indicate
    if the object is valid or not).  The second index is an array of
    error messages that were generated based upon the errors found.

  string generateXML(void)
    Creates an XML file based upon the info stored in the
    Business::Payroll::XML::OutData object.  It first calls isValid() 
    to make sure this is possible.  If not then we die with an 
    informative error message.

=head1 VARIABLES

  version - version of the XML file parsed

  dataFile - the name of the file parsed or the string of XML

  date - the date the Payroll was generated on

  period - the period of time the payroll is for (weekly, bimonthly, etc.)

  startPeriod - beginning date of the payroll period.

  endPeriod - ending date of the payroll period.
  
  genSysId - the id used by the generating system to identify this payroll

  persons - the array of person data structures

  NOTE:  All data fields are accessible by specifying the object
         and pointing to the data member to be modified on the
         left-hand side of the assignment.
         Ex.  $obj->variable($newValue); or $value = $obj->variable;

=head1 AUTHOR

Xperience, Inc. (mailto:admin at pcxperience.com)

=head1 SEE ALSO

perl(1), Business::Payroll::XML::Parser(3)

=cut
