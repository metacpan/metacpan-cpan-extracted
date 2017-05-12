# Parser.pm - Will parse an XML file and return the Payroll Data result set.
# Created by James A. Pattie.  Copyright (c) 2001-2004, Xperience, Inc.
=head1 NAME

Parser - The XML Configuration Parser Module.

=head1 SYNOPSIS

  use Business::Payroll::XML::Parser;
  my $obj = Business::Payroll::XML::Parser->new(periodNames => \%periodNames,
            validCountries => \%knownCountries);
  my $dataObj = $obj->parse(file => "config.xml");
  # this is a Data object.

=head1 DESCRIPTION

Parser will parse XML files that have been generated to the payroll
specification.  See the Business::Payroll::XML::Data man page for the
structure of the returned data.

=cut
package Business::Payroll::XML::Parser;

use strict;
use XML::LibXML;
use Business::Payroll::XML::Data;
use Business::Payroll::XML::OutData;
use vars qw ($AUTOLOAD @ISA @EXPORT $VERSION);

require Exporter;
@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();

$VERSION = "1.2";

=head1 FUNCTIONS

=head2 (validCountries, periodNames)
 required: validCountries - hash ref of available countries,
           periodNames - hash ref of periods
=cut
sub new
{
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = bless {}, $class;
  my %args = ( validCountries => undef, periodNames => undef, @_ );
  my $errStr = "Business::Payroll::XML::Parser->new()  - Error:";

  if (not defined $args{validCountries})
  {
    die "$errStr You must specify the validCountries hash ref!\n";
  }

  if (not defined $args{periodNames})
  {
    die "$errStr You must specify the periodNames hash ref!\n";
  }

  $self->{dataRawVersion} = "1.1";  # version of type="raw" file
  $self->{dataCookedVersion} = "1.1"; # version of type="cooked" file
  $self->{validCountries} = $args{validCountries};
  $self->{periodNames} = $args{periodNames};

  $self->{dataObj} = undef;
  $self->{dataFile} = "";

  eval { $self->{xmlObj} = XML::LibXML->new(); };
  if ($@)
  {
    die "$errStr $@\n";
  }

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

=head2 Business::Payroll::XML::Data parse(file, string)
    Does the actual parsing of the XML file and generates the
    resulting data object and returns it.

    file points to the XML Config file to use.

    If you don't specify a file to work with then you must specify the
    xml via the string argument.  If you specify both, then the string
    will take precedence.  The file must still point to a valid file.

    returns: Business::Payroll::XML::Data instance with parsed info.
=cut
sub parse
{
  my $self = shift;
  my %args = ( "file" => "", string => "", @_ );
  my $nodes = undef;
  my $errStr = "Business::Payroll::XML::Parser->parse()  - Error:";

  if (length $args{file} > 0)
  {
#removed by JT bc this is a STUPID check.  who cares what the file extentions are.  in fact I'm now using .raw and .cook
#    if ($args{file} !~ /^(-|.*\.xml)$/)
#    {
#      die "$errStr file = '$args{file}' is not a valid file!\n";
#    }
    if ($args{file} ne "-" && ! -e $args{file})
    {
      die "$errStr Can not find config file = '$args{file}'!  $!\n";
    }
  }
  elsif (length $args{string} == 0)
  {
    die "$errStr You must specify either 'file' or 'string'!\n";
  }

  $self->{dataFile} = (length $args{string} > 0 ? $args{string} : $args{file});

  if (length $args{file} > 0 && length $args{string} == 0)
  {
    eval { $self->{xmlDoc} = $self->{xmlObj}->parse_file($self->{dataFile}); };
  }
  else
  {
    eval { $self->{xmlDoc} = $self->{xmlObj}->parse_string($self->{dataFile}); };
  }
  if ($@)
  {
    die "$errStr $@\n";
  }

  # get the type
  my $type = $self->getType;

  if ($type =~ /^(raw)$/)
  {
    eval { $self->{dataObj} = Business::Payroll::XML::Data->new(validCountries =>
      $self->{validCountries}, periodNames => $self->{periodNames}); };
    if ($@)
    {
      die "$errStr $@\n";
    }

    # start by validating the version of the XML file.
    $self->validateRawVersion;

    # initiate the data structure.  Fill in any default values possible.
    $self->{dataObj}->{version} = $self->{dataRawVersion};
    $self->{dataObj}->{dataFile} = $self->{dataFile};

    # gather the date and period info
    $self->getGlobalInfo;

    # gather the <person> values
    $self->getPeopleIn;
  }
  elsif ($type =~ /^(cooked)$/)
  {
    eval { $self->{dataObj} = Business::Payroll::XML::OutData->new(periodNames =>
      $self->{periodNames}); };
    if ($@)
    {
      die "$errStr $@\n";
    }

    # start by validating the version of the XML file.
    $self->validateCookedVersion;

    # initiate the data structure.  Fill in any default values possible.
    $self->{dataObj}->{version} = $self->{dataCookedVersion};
    $self->{dataObj}->{dataFile} = $self->{dataFile};

    # gather the date and period info
    $self->getGlobalInfo;

    # gather the <person> values
    $self->getPeopleOut;
  }
  else
  {
    die "$errStr  Unknown payroll type = '$type'!\n";
  }

  return $self->{dataObj};
}

=head2 hash getAttributes(node)
# requires: node - XPath Node
# returns:  hash of attributes for the specified node.
=cut
sub getAttributes
{
  my $self = shift;
  my %args = ( node => undef, @_ );
  my $node = $args{node};
  my %attributes = ();
  my $errStr = "Business::Payroll::XML::Parser->getAttributes()  - Error:";

  if (!defined $node)
  {
    die "$errStr  You must specify the XPath Node to work with!\n";
  }
  if ($node->getType() != XML_ELEMENT_NODE)
  {
    die "$errStr  You did not specify an XPath Node: " . $node->getType() . "\n";
  }
  foreach my $attribute ($node->getAttributes)
  {
    my $name = $attribute->getName;
    $attributes{$name} = $attribute->getValue;
  }

  return %attributes;
}

=head2 array getNodes(path, context)
# required: path - XPath to search for
# optional: context - the XPath object to base the search from.  Make sure your
path is relative to it!
# returns:  array - array of nodes returned.  These are the XPath objects
representing each node.
=cut
sub getNodes
{
  my $self = shift;
  my %args = ( path => "*", context => undef, @_ );
  my $path = $args{path};
  my $context = $args{context};
  my @nodes = ( );
  my $nodes = undef;
  my $errStr = "Business::Payroll::XML::Parser->getNodes()  - Error:";

  if (length $path == 0)
  {
    die "$errStr  You must specify a path!\n";
  }

  if (! defined $context)
  {
    $nodes = $self->{xmlDoc}->findnodes($path);
  }
  else
  {
    $nodes = $context->findnodes($path);
  }
  if (!$nodes->isa('XML::LibXML::NodeList'))
  {
    die "$errStr  Query '$path' didn't return a nodelist: " . $nodes->getType()
      . "\n";
  }
  if ($nodes->size)
  {
    #print "Found " . $nodes->size . " nodes...\n";
    foreach my $node ($nodes->get_nodelist)
    {
      push @nodes, $node;
    }
  }

  return @nodes;
}

=head2 string getType(void)
    returns the type value from the parent <payroll> tag.
=cut
sub getType
{
  my $self = shift;
  my $errStr = "Business::Payroll::XML::Parser->getType()  - Error:";

  my @nodes = $self->getNodes(path => "/payroll");
  if (scalar @nodes == 0)
  {
    die "$errStr  Your XML file doesn't contain a <payroll> tag!\n";
  }
  if (scalar @nodes > 1)
  {
    die "$errStr  You have too many <payroll> tags!  You should only have one!\n";
  }
  my %attributes = $self->getAttributes(node => $nodes[0]);
  if (!exists $attributes{type})
  {
    die "$errStr  You do not have the type defined!\n";
  }

  return $attributes{type};
}

=head2  string getVersion(void)
    returns the version value from the parent <payroll> tag.

=cut
sub getVersion
{
  my $self = shift;
  my $errStr = "Business::Payroll::XML::Parser->getVersion()  - Error:";

  my @nodes = $self->getNodes(path => "/payroll");
  if (scalar @nodes == 0)
  {
    die "$errStr  Your XML file doesn't contain a <payroll> tag!\n";
  }
  if (scalar @nodes > 1)
  {
    die "$errStr  You have too many <payroll> tags!  You should only have one!\n";
  }
  my %attributes = $self->getAttributes(node => $nodes[0]);
  if (!exists $attributes{version})
  {
    die "$errStr  You do not have the version defined!\n";
  }

  return $attributes{version};
}

# This routine looks up the <payroll version=""> tag and validates that the
# version specified is the same as what we know how to work with.
sub validateRawVersion
{
  my $self = shift;
  my $errStr = "Parser->validateRawVersion()  - Error:";

  my $version = $self->getVersion;
  if ($version !~ /^($self->{dataRawVersion})$/)
  {
    die "$errStr  '$version' is not equal to Version '$self->{dataRawVersion}'!\n";
  }
}

# This routine looks up the <payroll version=""> tag and validates that the
# version specified is the same as what we know how to work with.
sub validateCookedVersion
{
  my $self = shift;
  my $errStr = "Parser->validateCookedVersion()  - Error:";

  my $version = $self->getVersion;
  if ($version !~ /^($self->{dataCookedVersion})$/)
  {
    die "$errStr  '$version' is not equal to Version '$self->{dataCookedVersion}'!\n";
  }
}

# void getGlobalInfo(void)
# gathers the date and period entries.
sub getGlobalInfo
{
  my $self = shift;
  my $errStr = "Business::Payroll::XML::Parser->getGlobalInfo()  - Error:";

  my @nodes = $self->getNodes(path => "/payroll");
  if (scalar @nodes == 0)
  {
    die "$errStr  Your XML file doesn't contain a <payroll> tag!\n";
  }
  if (scalar @nodes > 1)
  {
    die "$errStr  You have too many <payroll> tags!  You should only have one!\n";
  }
  my %attributes = $self->getAttributes(node => $nodes[0]);
  if (!exists $attributes{date})
  {
    die "$errStr  You do not have the date defined!\n";
  }
  if (!exists $attributes{period})
  {
    die "$errStr  You do not have the period defined!\n";
  }
  if (!exists $attributes{genSysId})
  {
    die "$errStr  You do not have the genSysId defined!\n";
  }
  if (!exists $attributes{startPeriod})
  {
    die "$errStr  You do not have the startPeriod defined!\n";
  }
  if (!exists $attributes{endPeriod})
  {
    die "$errStr  You do not have the endPeriod defined!\n";
  }

  # validate the date
  if ($attributes{date} !~ /^(\d{8})$/)
  {
    die "$errStr  date = '$attributes{date}' does not appear to be valid!\n";
  }
  if ($attributes{startPeriod} !~ /^(\d{8})$/)
  {
    die "$errStr  startPeriod = '$attributes{startPeriod}' does not appear to be valid!\n";
  }
  if ($attributes{endPeriod} !~ /^(\d{8})$/)
  {
    die "$errStr  endPeriod = '$attributes{endPeriod}' does not appear to be valid!\n";
  }

  # validate the period
  if (!exists $self->{periodNames}->{$attributes{period}})
  {
    die "$errStr  period = '$attributes{period}' is not valid!\n";
  }
  if (length $attributes{genSysId} == 0)
  {
    die "$errStr  genSysId = '$attributes{genSysId}' is not valid!\n";
  }

  $self->{dataObj}->{date} = $attributes{date};
  $self->{dataObj}->{period} = $attributes{period};
  $self->{dataObj}->{genSysId} = $attributes{genSysId};
  $self->{dataObj}->{startPeriod} = $attributes{startPeriod};
  $self->{dataObj}->{endPeriod} = $attributes{endPeriod};
}

# void getPeopleIn()
# requires: nothing
# returns: nothing
sub getPeopleIn
{
  my $self = shift;
  my %args = ( @_ );
  my $errStr = "Business::Payroll::XML::Parser->getPeopleIn()  - Error:";
  my $tag = "person";

  my @nodes = $self->getNodes(path => "/payroll/$tag");
  if (scalar @nodes == 0)
  {
    die "$errStr  Your XML file doesn't contain a <$tag> tag!\n";
  }
  my %encounteredPerson = ();
  foreach my $node (@nodes)
  {
    # gather all attributes of the <person> tag.
    my %attributes = $self->getAttributes(node => $node);
    my %encountered = ();
    foreach my $attribute (keys %attributes)
    {
      if (exists $encountered{$attribute})
      {
        die "$errStr  You have already defined '$attribute' in the <$tag> tag!\n";
      }
      if ($attribute !~ /^(id|name|marital)$/)
      {
        die "$errStr  '$attribute' is invalid in the <$tag> tag!\n";
      }
      $encountered{$attribute} = 1;
      if ($attribute =~ /^(id)$/ && $attributes{$attribute} !~ /^.+$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!\n";
      }
      if ($attribute =~ /^(name)$/ && $attributes{$attribute} !~ /^(.+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!\n";
      }
      if ($attribute =~ /^(marital)$/ && $attributes{$attribute} !~ /^(married|single|spouseWorks|head)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!\n";
      }
    }
    foreach my $required ("id", "name", "marital")
    {
      if (!exists $encountered{$required})
      {
        die "$errStr  '$required' is required in the <$tag> tag!\n";
      }
    }

    # validate that no persons have been duplicated.
    if (exists $encounteredPerson{$attributes{id}})
    {
      die "$errStr  person id='$attributes{id}' duplicated!\n";
    }
    else
    {
      $encounteredPerson{$attributes{id}} = 1;
    }

    # now gather the <country> tags and their children.
    my @countries = $self->getCountries(node => $node, id => $attributes{id});

    # now gather the <adjustment> tags.
    my @adjustments = $self->getAdjustments(node => $node, id => $attributes{id});

    # create the person object and store it.
    my %person = ( id => $attributes{id}, name => $attributes{name}, marital => $attributes{marital}, countries => \@countries, adjustments => \@adjustments );
    push @{$self->{dataObj}->{persons}}, \%person;
  }
}

# @countries getCountries(node, id)
# requires: node - <person> node, id - person we are working on.
# returns: array of <country> entries
sub getCountries
{
  my $self = shift;
  my %args = ( node => undef, id => "", @_ );
  my $node = $args{node};
  my $id = $args{id};
  my $errStr = "Business::Payroll::XML::Parser->getCountries()  - Error:";
  my $tag = "country";
  my @countries = ();

  if (!defined $node)
  {
    die "$errStr  node is not defined!\n";
  }
  if (length $id == 0)
  {
    die "$errStr  id must be specified!\n";
  }

  my @nodes = $self->getNodes(path => "$tag", context => $node);
  if (scalar @nodes == 0)
  {
    die "$errStr  You do not have a <$tag> tag for <person id='$id'>!\n";
  }
  foreach my $node (@nodes)
  {
    my $nodeName = $node->getName;
    if ($nodeName ne $tag)
    {
      die "$errStr  <$nodeName> is invalid inside the <person id='$id'> tag, outside the <$tag> tag!\n";
    }
    # gather all attributes of the <country> tag.
    my %attributes = $self->getAttributes(node => $node);
    my %encountered = ();
    foreach my $attribute (keys %attributes)
    {
      if (exists $encountered{$attribute})
      {
        die "$errStr  You have already defined '$attribute' in the <$tag> tag! person id='$id'\n";
      }
      if ($attribute !~ /^(name|gross|allow|withHold|grossYTD|federalYTD|method)$/)
      {
        die "$errStr  '$attribute' is invalid in the <$tag> tag!  person id='$id'\n";
      }
      $encountered{$attribute} = 1;
      if ($attribute =~ /^(gross|grossYTD|federalYTD|withHold)$/ && $attributes{$attribute} !~ /^(\d+\.\d+|\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id'\n";
      }
      if ($attribute =~ /^(allow)$/ && $attributes{$attribute} !~ /^(\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id'\n";
      }
      if ($attribute =~ /^(name)$/ && !exists $self->{validCountries}->{$attributes{name}})
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id'\n";
      }
      if ($attribute =~ /^(method)$/ && $attributes{$attribute} !~ /^(.*)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!  <$tag>, person id='$id'\n";
      }
    }
    foreach my $required ("name", "gross", "allow", "withHold", "grossYTD", "federalYTD", "method")
    {
      if (!exists $encountered{$required})
      {
        die "$errStr  '$required' is required in the <$tag> tag! person id='$id'\n";
      }
    }

    # now gather the <state> tags and their children.
    my @states = $self->getStates(node => $node, id => $id, country => $attributes{name});

    # now gather the mileage tag, if it exists.
    my $mileage = $self->getMileage(node => $node, id => $id, country => $attributes{name});

    # create the country object and store it.
    my %country = ( name => $attributes{name},
      states => \@states,
      gross => $attributes{gross},
      allow => $attributes{allow},
      withHold => $attributes{withHold},
      grossYTD => $attributes{grossYTD},
      federalYTD => $attributes{federalYTD},
      method => $attributes{method},
      mileage => $mileage );
    push @countries, \%country;
  }

  # validate that no countries have been duplicated for this <person>.
  my %encountered = ();
  foreach my $country (@countries)
  {
    if (exists $encountered{$country->{name}})
    {
      die "$errStr  country name='$country->{name}' duplicated for person id='$id'!\n";
    }
    else
    {
      $encountered{$country->{name}} = 1;
    }
  }

  return @countries;
}

# @adjustments getAdjustments(node, id)
# requires: node - <person> node, id - person we are working on.
# returns: array of <adjustment> entries
sub getAdjustments
{
  my $self = shift;
  my %args = ( node => undef, id => "", @_ );
  my $node = $args{node};
  my $id = $args{id};
  my $errStr = "Business::Payroll::XML::Parser->getAdjustments()  - Error:";
  my $tag = "adjustment";
  my @adjustments = ();

  if (!defined $node)
  {
    die "$errStr  node is not defined!\n";
  }
  if (length $id == 0)
  {
    die "$errStr  id must be specified!\n";
  }

  my @nodes = $self->getNodes(path => "$tag", context => $node);
  if (scalar @nodes == 0)
  {
    return @adjustments;  # this is valid.
  }
  foreach my $node (@nodes)
  {
    my $nodeName = $node->getName;
    if ($nodeName ne $tag)
    {
      die "$errStr  <$nodeName> is invalid inside the <person id='$id'> tag, outside the <$tag> tag!\n";
    }
    # gather all attributes of the <adjustment> tag.
    my %attributes = $self->getAttributes(node => $node);
    my %encountered = ();
    foreach my $attribute (keys %attributes)
    {
      if (exists $encountered{$attribute})
      {
        die "$errStr  You have already defined '$attribute' in the <$tag> tag! person id='$id'\n";
      }
      if ($attribute !~ /^(name|value|comment)$/)
      {
        die "$errStr  '$attribute' is invalid in the <$tag> tag!  person id='$id'\n";
      }
      $encountered{$attribute} = 1;
      if ($attribute =~ /^(value)$/ && $attributes{$attribute} !~ /^(-?\d+\.\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id'\n";
      }
      if ($attribute =~ /^(name)$/ && $attributes{name} !~ /^(.+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id'\n";
      }
    }
    foreach my $required ("name", "value")
    {
      if (!exists $encountered{$required})
      {
        die "$errStr  '$required' is required in the <$tag> tag! person id='$id'\n";
      }
    }
    
    if (!exists $attributes{comment})
    {
      $attributes{comment} = "";
    }

    # create the adjustment object and store it.
    my %adjustment = ( name => $attributes{name},
      value => $attributes{value}, comment => $attributes{comment} );
    push @adjustments, \%adjustment;
  }

  # validate that no adjustments have been duplicated for this <person>.
  # actually, this is ok to have mulitple adjustments named the same thing.

  return @adjustments;
}

# @states getStates(node, id, country)
# requires: node - <person> node, id - person we are working on.
#           country - name of country we are in.
# returns: array of <state> entries
sub getStates
{
  my $self = shift;
  my %args = ( node => undef, id => "", country => "", @_ );
  my $node = $args{node};
  my $id = $args{id};
  my $country = $args{country};
  my $errStr = "Business::Payroll::XML::Parser->getStates()  - Error:";
  my $tag = "state";
  my @states = ();

  if (!defined $node)
  {
    die "$errStr  node is not defined!\n";
  }
  if (length $id == 0)
  {
    die "$errStr  id must be specified!\n";
  }
  if (!exists $self->{validCountries}->{$country})
  {
    die "$errStr  country = '$country' is invalid!\n";
  }

  my @nodes = $self->getNodes(path => "$tag", context => $node);
  if (scalar @nodes == 0)
  {
    return @states;  # jump out early as this is potentially valid.
  }
  foreach my $node (@nodes)
  {
    my $nodeName = $node->getName;
    if ($nodeName ne $tag)
    {
      die "$errStr  <$nodeName> is invalid inside the <person id='$id'><country name='$country'> tag, outside the <$tag> tag!\n";
    }
    # gather all attributes of the <state> tag.
    my %attributes = $self->getAttributes(node => $node);
    my %encountered = ();
    foreach my $attribute (keys %attributes)
    {
      if (exists $encountered{$attribute})
      {
        die "$errStr  You have already defined '$attribute' in the <$tag> tag! person id='$id', country='$country'\n";
      }
      if ($attribute !~ /^(name|gross|allow|withHold|method)$/)
      {
        die "$errStr  '$attribute' is invalid in the <$tag> tag!  person id='$id', country='$country'\n";
      }
      $encountered{$attribute} = 1;
      if ($attribute =~ /^(gross|withHold)$/ && $attributes{$attribute} !~ /^(\d+\.\d+|\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id', country='$country'\n";
      }
      if ($attribute =~ /^(allow)$/ && $attributes{$attribute} !~ /^(\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id', country='$country'\n";
      }
      if ($attribute =~ /^(name)$/ && $attributes{name} !~ /^(.+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id', country='$country'\n";
      }
      if ($attribute =~ /^(method)$/ && $attributes{$attribute} !~ /^(.*)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id', country='$country'\n";
      }
    }
    foreach my $required ("name", "gross", "allow", "withHold", "method")
    {
      if (!exists $encountered{$required})
      {
        die "$errStr  '$required' is required in the <$tag> tag! person id='$id', country='$country'\n";
      }
    }

    # now gather the <local> tags.
    my @locals = $self->getLocals(node => $node, id => $id, country => $country, state => $attributes{name});

    # create the state object and store it.
    my %state = ( name => $attributes{name}, locals => \@locals, 
      gross => $attributes{gross},
      allow => $attributes{allow},
      withHold => $attributes{withHold}, 
      method => $attributes{method} );
    push @states, \%state;
  }

  # validate that no states have been duplicated for this <country><person> combo.
  my %encountered = ();
  foreach my $state (@states)
  {
    if (exists $encountered{$state->{name}})
    {
      die "$errStr  state name='$state->{name}' duplicated for person id='$id', country='$country'!\n";
    }
    else
    {
      $encountered{$state->{name}} = 1;
    }
  }

  return @states;
}

# scalar getMileage(node, id, country)
# requires: node - <person> node, id - person we are working on.
#           country - name of country we are in.
# returns: mileage value or empty if none specified.
sub getMileage
{
  my $self = shift;
  my %args = ( node => undef, id => "", country => "", @_ );
  my $node = $args{node};
  my $id = $args{id};
  my $country = $args{country};
  my $errStr = "Business::Payroll::XML::Parser->getMileage()  - Error:";
  my $tag = "mileage";
  my $result;

  if (!defined $node)
  {
    die "$errStr  node is not defined!\n";
  }
  if (length $id == 0)
  {
    die "$errStr  id must be specified!\n";
  }
  if (!exists $self->{validCountries}->{$country})
  {
    die "$errStr  country = '$country' is invalid!\n";
  }

  my @nodes = $self->getNodes(path => "$tag", context => $node);
  if (scalar @nodes == 0)
  {
    return $result;  # jump out early as this is potentially valid.
  }
  if (scalar @nodes > 1)
  {
    die "$errStr  You can not have more than 1 mileage tag in <person id='$id'><country name='$country'>!\n";
  }
  foreach my $node (@nodes)
  {
    my $nodeName = $node->getName;
    if ($nodeName ne $tag)
    {
      die "$errStr  <$nodeName> is invalid inside the <person id='$id'><country name='$country'> tag, outside the <$tag> tag!\n";
    }

    # now get the mileage value.
    $result = $node->textContent;

    if ($result !~ /^(\d+)$/)
    {
      die "$errStr  mileage = '$result' is invalid in <person id='$id'><country name='$country'>!\n";
    }
  }

  return $result;
}

# @locals getLocals(node, id, country, state)
# requires: node - <person> node, id - person we are working on.
#           country - name of country we are in.
#           state - the state we are in.
# returns: array of <local> entries
sub getLocals
{
  my $self = shift;
  my %args = ( node => undef, id => "", country => "", state => "", @_ );
  my $node = $args{node};
  my $id = $args{id};
  my $country = $args{country};
  my $state = $args{state};
  my $errStr = "Business::Payroll::XML::Parser->getLocals()  - Error:";
  my $tag = "local";
  my @locals = ();

  if (!defined $node)
  {
    die "$errStr  node is not defined!\n";
  }
  if (length $id == 0)
  {
    die "$errStr  id must be specified!\n";
  }
  if (!exists $self->{validCountries}->{$country})
  {
    die "$errStr  country = '$country' is invalid!\n";
  }
  if (length $state == 0)
  {
    die "$errStr  state = '$state' is invalid!\n";
  }

  my @nodes = $self->getNodes(path => "*", context => $node);
  if (scalar @nodes == 0)
  {
    return @locals;  # jump out early as this is a valid condition.
  }
  foreach my $node (@nodes)
  {
    my $nodeName = $node->getName;
    if ($nodeName ne $tag)
    {
      die "$errStr  <$nodeName> is invalid inside the <person id='$id'><country name='$country'><state name='$state'> tag, outside the <$tag> tag!\n";
    }
    # gather all attributes of the <local> tag.
    my %attributes = $self->getAttributes(node => $node);
    my %encountered = ();
    foreach my $attribute (keys %attributes)
    {
      if (exists $encountered{$attribute})
      {
        die "$errStr  You have already defined '$attribute' in the <$tag> tag! person id='$id', country='$country', state='$state'\n";
      }
      if ($attribute !~ /^(name|gross|allow|withHold|method)$/)
      {
        die "$errStr  '$attribute' is invalid in the <$tag> tag!  person id='$id', country='$country', state='$state'\n";
      }
      $encountered{$attribute} = 1;
      if ($attribute =~ /^(gross|withHold)$/ && $attributes{$attribute} !~ /^(\d+\.\d+|\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id', country='$country', state='$state'\n";
      }
      if ($attribute =~ /^(allow)$/ && $attributes{$attribute} !~ /^(\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid! <$tag>, person id='$id', country='$country', state='$state'\n";
      }
      if ($attribute =~ /^(name)$/ && $attributes{name} !~ /^(.+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!  <$tag>, person id='$id', country='$country', state='$state'\n";
      }
      if ($attribute =~ /^(method)$/ && $attributes{$attribute} !~ /^(.*)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!  <$tag>, person id='$id', country='$country', state='$state'\n";
      }
    }
    foreach my $required ("name", "gross", "allow", "withHold", "method")
    {
      if (!exists $encountered{$required})
      {
        die "$errStr  '$required' is required in the <$tag> tag! person id='$id', country='$country', state='$state'\n";
      }
    }

    # create the local object and store it.
    my %local = ( name => $attributes{name},
      gross => $attributes{gross},
      allow => $attributes{allow},
      withHold => $attributes{withHold},
      method => $attributes{method} );
    push @locals, \%local;
  }

  # validate that no locals have been duplicated for this <state><country><person> combo.
  my %encountered = ();
  foreach my $local (@locals)
  {
    if (exists $encountered{$local->{name}})
    {
      die "$errStr  local name='$local->{name}' duplicated for person id='$id', country='$country', state='$state'!\n";
    }
    else
    {
      $encountered{$local->{name}} = 1;
    }
  }

  return @locals;
}

# void getPeopleOut()
# requires: nothing
# returns: nothing
sub getPeopleOut
{
  my $self = shift;
  my %args = ( @_ );
  my $errStr = "Business::Payroll::XML::Parser->getPeopleOut()  - Error:";
  my $tag = "person";

  my @nodes = $self->getNodes(path => "/payroll/$tag");
  if (scalar @nodes == 0)
  {
    die "$errStr  Your XML file doesn't contain a <$tag> tag!\n";
  }
  my %encounteredPerson = ();
  foreach my $node (@nodes)
  {
    # gather all attributes of the <person> tag.
    my %attributes = $self->getAttributes(node => $node);
    my %encountered = ();
    foreach my $attribute (keys %attributes)
    {
      if (exists $encountered{$attribute})
      {
        die "$errStr  You have already defined '$attribute' in the <$tag> tag!\n";
      }
      if ($attribute !~ /^(id|name)$/)
      {
        die "$errStr  '$attribute' is invalid in the <$tag> tag!\n";
      }
      $encountered{$attribute} = 1;
      if ($attribute =~ /^(id)$/ && $attributes{$attribute} !~ /^.+$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!\n";
      }
      if ($attribute =~ /^(name)$/ && $attributes{$attribute} !~ /^(.+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!\n";
      }
    }
    foreach my $required ("id", "name")
    {
      if (!exists $encountered{$required})
      {
        die "$errStr  '$required' is required in the <$tag> tag!\n";
      }
    }

    # validate that no persons have been duplicated.
    if (exists $encounteredPerson{$attributes{id}})
    {
      die "$errStr  person id='$attributes{id}' duplicated!\n";
    }
    else
    {
      $encounteredPerson{$attributes{id}} = 1;
    }

    # now gather the <item> tags.
    my @items = $self->getItems(node => $node, id => $attributes{id});

    # create the person object and store it.
    my %person = ( id => $attributes{id}, name => $attributes{name}, items => \@items );
    push @{$self->{dataObj}->{persons}}, \%person;
  }
}

# @items getItems(node, id)
# requires: node - <person> node, id - person we are working on.
# returns: array of <item> entries
sub getItems
{
  my $self = shift;
  my %args = ( node => undef, id => "", @_ );
  my $node = $args{node};
  my $id = $args{id};
  my $errStr = "Business::Payroll::XML::Parser->getItems()  - Error:";
  my $tag = "item";
  my @items = ();

  if (!defined $node)
  {
    die "$errStr  node is not defined!\n";
  }
  if (length $id == 0)
  {
    die "$errStr  id must be specified!\n";
  }

  my @nodes = $self->getNodes(path => "*", context => $node);
  if (scalar @nodes == 0)
  {
    die "$errStr  You do not have a <$tag> tag for <person id='$id'>!\n";
  }
  foreach my $node (@nodes)
  {
    my $nodeName = $node->getName;
    if ($nodeName ne $tag)
    {
      die "$errStr  <$nodeName> is invalid inside the <person id='$id'> tag, outside the <$tag> tag!\n";
    }
    # gather all attributes of the <item> tag.
    my %attributes = $self->getAttributes(node => $node);
    my %encountered = ();
    foreach my $attribute (keys %attributes)
    {
      if (exists $encountered{$attribute})
      {
        die "$errStr  You have already defined '$attribute' in the <$tag> tag!  person id='$id'\n";
      }
      if ($attribute !~ /^(name|value|comment)$/)
      {
        die "$errStr  '$attribute' is invalid in the <$tag> tag!  person id='$id'\n";
      }
      $encountered{$attribute} = 1;
      if ($attribute =~ /^(value)$/ && $attributes{$attribute} !~ /^(-?\d+\.\d+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!  <$tag>, person id='$id'\n";
      }
      if ($attribute =~ /^(name)$/ && $attributes{$attribute} !~ /^(.+)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!  <$tag>, person id='$id'\n";
      }
      if ($attribute =~ /^(comment)$/ && $attributes{$attribute} !~ /^(.*)$/)
      {
        die "$errStr  '$attribute' = '$attributes{$attribute}' is invalid!  <$tag>, person id='$id'\n";
      }
    }
    foreach my $required ("name", "value")
    {
      if (!exists $encountered{$required})
      {
        die "$errStr  '$required' is required in the <$tag> tag! person id='$id'\n";
      }
    }
    if (!exists $attributes{comment})
    {
      $attributes{comment} = "";
    }

    # create the item object and store it.
    my %item = ( name => $attributes{name}, value => $attributes{value}, comment => $attributes{comment} );
    push @items, \%item;
  }

  # validate that no items have been duplicated for this <person>.
  my %encountered = ();
  foreach my $item (@items)
  {
    if (exists $encountered{$item->{name}})
    {
      die "$errStr  item name='$item->{name}' duplicated for person id='$id'!\n";
    }
    else
    {
      $encountered{$item->{name}} = 1;
    }
  }

  return @items;
}

1;
__END__

=head1 VARIABLES

  dataFile - The xml file name we are working with or the contents
               of the string of xml passed in.

  dataInVersion - The version of the input XML file we require.

  dataOutVersion - The version of the output XML file we require.

  dataObj - Data object that represents the xml file.

  xmlObj - The XML::LibXML object being used to parse the XML File.

  NOTE:  All data fields are accessible by specifying the object
         and pointing to the data member to be modified on the
         left-hand side of the assignment.
         Ex.  $obj->variable($newValue); or $value = $obj->variable;

=head1 AUTHOR

PC & Web Xperience, Inc. (mailto:admin at pcxperience.com)

=head1 SEE ALSO

perl(1), Business::Payroll::XML::Data(3)

=cut
