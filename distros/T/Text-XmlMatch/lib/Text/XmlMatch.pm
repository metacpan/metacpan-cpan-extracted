package Text::XmlMatch;
use strict;
use warnings;

#XML package designed to provide easy, configurable groups via XML
#configuration file

# 06/30/06 - Jason A. Lee - Original Code write
#
# 07/06/06 - JAL - Added new method listGroups();
#
# 07/13/06 - JAL - Removed unused variables, EXPORT, EXPORT_OK, etc.
#
# 02/06/07 - JAL - Hotfix 2 -> Correct POD section.  No tag means hash
#                  value = '0'
#
# 02/07/07 - JAL - Hotfix 3 -> Corrected bug where config file with a
#                  single pattern caused the module to fail.
#
# 02/12/07 - JAL - Hotfix 4 -> Minor POD cleanup, added 'use warnings'
#
# 06/06/07 - JAL - Hotfix 5 -> Fixed bug in listGroups() failing when
#                  config file contains only a single pattern
#
# 06/06/07 - JAL - Hotfix 6 -> calling findMatch() prior to
#                  listGroups() was concealing another bug in
#                  listGroups() when only a single pattern name is
#                  specified in a config file.


BEGIN {
        use XML::Simple;
        use Data::Dumper; #Here for debug/development
	use vars qw ($VERSION);
  	$VERSION = 1.0006;
}


sub new {		#Standard object constructor
  my $obj = shift;
  my $configFile = shift; #This is the filename passed as an argument
  my $xmlConfig = XMLin($configFile);
  bless $xmlConfig, $obj;
  return $xmlConfig; 
}

sub findMatch {
  my $config = shift; #this holds the XML object
  our $name = shift; #this holds the string to be matched against, typically a FQDN

  my $r_matchResults = {}; #this is an intermediate hash, used prior to returning final hash, key->'pattern name'

  #Now crawl through the hash looking for matches
  foreach my $group (keys %{$config->{pattern}}) { #walk through each pattern name
    ############
    # Hotfix 3 #
    #################################################################
    #The block below handles a special case where the user provides a
    #configuration that contains a single pattern.  In such cases,
    #XML::Simple creates a hash structure that is completely different
    #than the one that is created when two or more patterns are
    #specified.  This block creates a new hash structure that matches
    #the expected format.  Note that although we are currently in a
    #foreach loop, the loop gets killed for this special case as there
    #are no keys to step through.
    #################################################################

    #print "DEBUG: Processing pattern $group\n";
    if (defined $config->{pattern}->{name}) { #if this key is defined then hash is collapsed
      #print "DEBUG: Hash not found, must be single pattern!\n";
      #print "Dumper Single: " . Dumper($config->{pattern}->{$group}) . "\n";
      #rebuild hash structure so that it looks like what's expected
      my $singlePatternName = $config->{pattern}->{name};
      my $newHashStructure = {};
      foreach my $single (keys %{$config->{pattern}}) {
        next if ($single eq 'name'); # we're rebuilding hash to standard form, don't need this key
        $newHashStructure->{pattern}->{$singlePatternName}->{$single} = $config->{pattern}->{$single};
      }
      #print "DEBUG: new hash structure: " . Dumper($newHashStructure) . "\n";
      $config->{pattern} = $newHashStructure->{pattern}; #copy newly structured hash over the original
      #print "DEBUG: new config: " . Dumper($config) . "\n";
      $group = $singlePatternName;
    }
    #End of Hotfix 3 block#########################################

    #print "DEBUG Standard Dumper: " . Dumper($config->{pattern}->{$group}) . " \n";
    foreach my $criteria (keys %{$config->{pattern}->{$group}}) { #within each pattern, walk through qualifiers
      #Now determine the criteria relative to each
      #Sometimes it's a single element, other times it's an array ref or hash ref
      #This can't be controlled, as XML::Simple will translate the XML to whatever makes more sense
      #so must check for ARRAY, HASH, and SCALAR references
      my $deviceTag;
      if (ref ($config->{pattern}->{$group}->{$criteria}) eq "ARRAY") {
        foreach my $matchPattern (@{$config->{pattern}->{$group}->{$criteria}}) { #walk through exclusion, inclusion, tag
          #print "Array ref: $group $criteria $matchPattern\n";
          _criteriaSort($r_matchResults,$criteria,$matchPattern,$group);
        }
      } elsif (ref ($config->{pattern}->{$group}->{$criteria}) eq "HASH") {
        foreach my $matchPattern (keys %{$config->{pattern}->{$group}->{$criteria}}) {#walk through exclusion, inclusion, tag
          #print "hash ref: $group $criteria $matchPattern\n";
          _criteriaSort($r_matchResults,$criteria,$matchPattern,$group);
        }
      } else { #Not array reference, just print value
        #print "scalar: $group $criteria $config->{pattern}->{$group}->{$criteria}\n";
        my $matchPattern = $config->{pattern}->{$group}->{$criteria};
        next if ($matchPattern eq ''); #Don't want to process null values in _criteriaSort
        _criteriaSort($r_matchResults,$criteria,$matchPattern,$group);
      }
    }
    ##########
    #Hotfix 3#
    ################################################################# 
    #this line stops the looping through keys, as there are no keys to
    #step through in the case of a single pattern XML config file.

    last if (defined $config->{pattern}->{name}); #If case of single pattern, don't try to step through more
  }

  #After sifting through the XML mess and walking the trees, time to print final result
  my $r_returnMatchList = {};

  foreach my $nameMap (keys %{$r_matchResults->{$name}}) {
    my $oldNameMap = $nameMap;
    #my $newNameMap = ''; #we might change group name soon
    #It's possible the group name became changed if user specified back-references, check for that here
    if ( $r_matchResults->{$name}->{$nameMap}->{newName} ) { #if group name has changed
      #print "$nameMap is changing name to $r_matchResults->{$name}->{$nameMap}->{newName}\n";
      $nameMap = $r_matchResults->{$name}->{$nameMap}->{newName};
    }
    if ( ($r_matchResults->{$name}->{$oldNameMap}->{inclusion}) && !($r_matchResults->{$name}->{$oldNameMap}->{exclusion})) {
      #print "name $name is clearly a member of group $nameMap\n";
      #print "nameMap is currently $nameMap\n";
      $r_returnMatchList->{$nameMap} = ($r_matchResults->{$name}->{$oldNameMap}->{tag}) ? $r_matchResults->{$name}->{$oldNameMap}->{tag} : 0;  #If it has a tag, store it, if not, give it a default of 0
      #if ($r_matchResults->{$name}->{$oldNameMap}->{tag}) {
        #print "and this group is a $r_matchResults->{$name}->{$oldNameMap}->{tag}\n";
      #}
    }
  }
  #print Dumper($r_matchResults);
  return $r_returnMatchList;

  sub _criteriaSort {  
    #differentiate between tag, inclusion, and exclusion, as this sub will walk through all three possible 
    #values
    my ($r_matchResults,$criteria,$matchPattern,$group) = @_;
    my $newGroupName; #used in case the name gets updated as a result of a match
    #because this module supports "back-references," it will allow the user to refer to regex matches
    #made when defining group names.
    #print "sub got criteria: $criteria\n";

    if ($criteria eq 'tag') {
      my $deviceTag = $matchPattern; #in this case, $matchPattern isn't a pattern, but a group name
      #print "device tag: $name $deviceTag\n";
      $$r_matchResults{$name}->{$group}->{tag} = $deviceTag;
      #if the 'name' matches a regex defined in the inclusion list, then $name is a candidate for 
      #inclusion in this group.  We won't know till the end of the XML as it could be excluded
    } elsif (($criteria eq 'inclusion') && (_match($name,$matchPattern,\$group,\$newGroupName) == 1)) {
      #print "device inclusion: $name $matchPattern newGroupName: $newGroupName\n";
      $$r_matchResults{$name}->{$group}->{inclusion} += 1;
      $$r_matchResults{$name}->{$group}->{newName} = $newGroupName;
    } elsif (($criteria eq 'exclusion') && (_match($name,$matchPattern,\$group,\$newGroupName) == 1)) {
      #print "device exclusion: $name $matchPattern newGroupName: $newGroupName\n";
      $$r_matchResults{$name}->{$group}->{exclusion} += 1;
      $$r_matchResults{$name}->{$group}->{newName} = $newGroupName;
    }
    #print "value of new group is: $newGroupName\n";
    #foreach (keys %{$$r_matchResults{$name}->{$group}}) {
    #  $$r_matchResults{$name}->{$newGroupName}->{$_} = $$r_matchResults{$name}->{$group}->{$_};
    #}
  }
  sub _match {
    my $name = shift;
    my $matchPattern = shift;
    my $r_group = shift;  #like MARKET-MSO, MSO-$1, etc.
    my $r_newGroupName = shift; #in case the name gets updated
    #print "comparing $name to $matchPattern\n";
    if ($name =~ qr /$matchPattern/) {
      #print "MATCH  $name <-> $matchPattern - match variable $1,$2,$3,$4,$5\n";
      my ($mv1,$mv2,$mv3,$mv4,$mv5) = ($1,$2,$3,$4,$5);  #Store up to 5 memory variables from regex
      my $newGroupName = "$$r_group";
      $newGroupName =~ s/\$1/$mv1/;
      $newGroupName =~ s/\$2/$mv2/;
      $newGroupName =~ s/\$3/$mv3/;
      $newGroupName =~ s/\$4/$mv4/;
      #print "derived group name $newGroupName\n";
      $$r_newGroupName = $newGroupName;
      return 1
    } else {
      return 0;
    }
  }
}

sub listGroups {
  my $config = shift; #this holds the XML object
  #our $name = shift; #this holds the item to be matched against, typically a FQDN
  #setup initialization variables before we start searching through the XML turned into a hash
  my $r_groupList = []; #reference to anonymous array

  #Now crawl through the hash and iterate over each group name
  #print "DEBUG: Original " . Dumper ($config) . "\n";
  foreach my $group (keys %{$config->{pattern}}) { #walk through each pattern name
    next if ($group =~ /^(inclusion|tag)$/);
    ############
    # Hotfix 6 #
    #################################################################
    #The block below handles a special case where the user provides a
    #configuration that contains a single pattern.  In such cases,
    #XML::Simple creates a hash structure that is completely different
    #than the one that is created when two or more patterns are
    #specified.  This block creates a new hash structure that matches
    #the expected format.  Note that although we are currently in a
    #foreach loop, the loop gets killed for this special case as there
    #are no keys to step through.
    #################################################################

    #print "DEBUG: Processing pattern $group\n";
    if (defined $config->{pattern}->{name}) { #if this key is defined then hash is collapsed
      #print "DEBUG: Hash not found, must be single pattern!\n";
      #print "Dumper Single: " . Dumper($config->{pattern}->{$group}) . "\n";
      #rebuild hash structure so that it looks like what's expected
      my $singlePatternName = $config->{pattern}->{name};
      my $newHashStructure = {};
      foreach my $single (keys %{$config->{pattern}}) {
        next if ($single eq 'name'); # we're rebuilding hash to standard form, don't need this key
        $newHashStructure->{pattern}->{$singlePatternName}->{$single} = $config->{pattern}->{$single};
      }
      #print "DEBUG: new hash structure: " . Dumper($newHashStructure) . "\n";
      $config->{pattern} = $newHashStructure->{pattern}; #copy newly structured hash over the original
      #print "DEBUG: new config: " . Dumper($config) . "\n";
      $group = $singlePatternName;
    }
    #End of Hotfix 6 block#########################################

    push @$r_groupList, $group;  #store each group name in the array

    ##########
    #Hotfix 6#
    #################################################################
    #this line stops the looping through keys, as there are no keys to
    #step through in the case of a single pattern XML config file.

    last if (defined $config->{pattern}->{name}); #If case of single pattern, don't try to step through more

  }
  return wantarray ? @$r_groupList : $r_groupList;
  #return $r_groupList;  #pass the reference to the anonymous array back to the caller 
}

1;

__END__

=head1 NAME

Text::XmlMatch - Pattern-matching and grouping via XML configuration file

=head1 SYNOPSIS

 use Text::XmlMatch;
 my $matcher = Text::XmlMatch->new('ConfigurationFile.xml');

 #Find group, results returned as hash reference
 my $results = $matcher->findMatch('09460-3640-2-s-x.csc.na.testdomain.com');
 foreach (keys %$results) {
   print "Group Name\t--   Group Type \n";
   print "$_\t--   $$results{$_} \n";
 }

 Sample XML Configuration "ConfigurationFile.xml":

 <config>
  <!-- Find FQDN's that match a particular datacenter -->
  <pattern name="DATACENTER-ndc">
    <inclusion>^corp.*\.net</inclusion>
    <tag>datacenter</tag>
  </pattern>

  <!-- Find devices that match a particular market -->
  <pattern name="Market CSC">
    <inclusion>\S+-\S+-\d+-\w-\w\.csc</inclusion>
    <tag>market</tag>
  </pattern>
 </config>

=head1 DESCRIPTION

This module provides matching/grouping functions via a configuration
file specified in XML format.  By specifying inclusion criteria and
pattern names, the user may pass strings to the created object to
perform sophisticated pattern matching/grouping.  In addition, optional
exclusion criteria may be specified as well as an optional descriptor to
further refine the behavior of the searching and the returned search
results.

This grouping and classification function is required frequently in
network management systems, where hundreds and often thousands of items
need to be grouped according to a variety of criteria.  Such grouping
can be discreet or overlapping depending on the configuration
specified.  In complex management systems where multiple platforms are
required, this module can ease administrative burdens by allowing
multiple systems to share a common configuration file.  Each system can
then be configured to only respond to items matching a specific pattern
name.

In addition, this module allows for dynamic group name creation via
support of back-references.  By following the convention of Perl's
memory variables, grouping can be accomplished such that a pattern name
depends on the content of what is being matched.  All of this behavior
is determined by way of a simple XML configuration file.

=head2 METHODS

B<findMatch(string)>

Using the XML configuration file that was specified during the
Text::XmlMatch object creation, it will return all matches in the form of a
hash reference.  The keys of this hash are the pattern names that
correspond to matches in the XML configuration file.  The values of the
hash contain the tag information (if any was specified, otherwise it
simply contains the value '0').

A "match" for a pattern name in this module implies the following are
both true:

=over 4

=item *

The contents of any lines wrapped in <inclusion> tags regex match the
supplied string.  Multiple <inclusion> tags per pattern are allowed.

=item *

Any lines wrapped in <exclusion> tags do not regex match the supplied
string.  Multiple <exclusion> tags per pattern are allowed.

=back

B<listGroups()>

This simply returns a an array or reference to an array containing a
list of all the pattern names that were derived from the XML
configuration file.  The caller's context determines whether an array
or reference is returned.

=head1 XML Configuration file

The format for the XML configuration file is as follows:

 <config>
   <pattern name="group_name_goes_here">
     <inclusion>regular_expression_#1_here</inclusion>
     <inclusion>regular_expression_#2_here</inclusion>
     <exclusion>optional_regular_expression_#1_here</exclusion>
     <exclusion>optional_regular_expression_#2_here</exclusion>
     <tag>optional_descriptor</tag>
   </pattern>
 </config>

=over 4

=item config tag

A mandatory tag that specifies the start of the XML configuration
file.  Any valid configuration file for this module must open with this
tag.

=item pattern name tag

A mandatory tag that specifies the name for the group that is to be
established.  Any submitted strings that match the criteria specified
for this pattern will return this name as described when findMatch() is
called.

Note that this opening tag must include at least one inclusion tag (see
below).  The following keywords are reserved and must not be used as a
pattern name: 'inclusion', 'tag', 'name'.

=item inclusion tag

A tag that contains a regular expression.  At least one of these must
be defined within the pattern name tags, but multiple regular
expressions can be specified by including multiple <inclusion> tags.
Note, if multiple inclusion tags are specified, they are treated as a
logical B<OR>.  If any string submitted via I<findMatch()> matches any
one of the regular expressions identified by an inclusion cause, then
that string is considered a match for the group if and only if the
string does not match a regular expression identified within an
I<exclusion> tag (see below).

=item exclusion tag

This is an optional tag that contains a regular expression.  Multiple
regular expressions can be specified by including multiple I<exclusion>
tags.  Note, if multiple exclusion tags are specified, they are treated
as a logical B<OR>.  For a given pattern name, a string that matches any
regular expression contained within an exclusion set will cause pattern
name to not be returned by I<findMatch()>.

=item tag tag

Other than having an unfortunate choice of name, this provides an
optional descriptor for each pattern section.  As an example, if one
wants to establish pattern name "types," the I<tag> section could
be set so that all matches can be further categorized later.  The user
would then have the option of using the results of the individual
patterns along with more sophisticated grouping based on the returned
tags.

=back

=head1 XML Configuration with Back-references

Using up to five memory variables: $1, $2, $3, $4, and $5, the XML
configuration can be configured to provide dynamic pattern name
creation.  By using standard memory parentheses in the <inclusion>
tags, the memory variables may be directly referenced in pattern name.
For example, take the following configuration:

 <!-- Standard COID based facility name -->
  <pattern name="COID-$1">
    <inclusion>^(\d{5})(\w{2})?-\w{4}-\d+-\w-\w\.\w{3}</inclusion>
    <tag>facility</tag>
  </pattern>

The results of the match are captured in the memory parentheses (\d{5})
will be present in the final group name of "COID-$1," where $1 will be
replaced by the results of the match.

=head1 LIMITATIONS

Configuration files that contain duplicated pattern names will cause
undesired behavior.  Instead of specifying a pattern name more than
once, consider using multiple <inclusion> tags under a single pattern
name, or create multiple Text::XmlMatch objects pointing to different
configuration files.

=head1 PREREQUISITES

This module requires C<XML::Simple 2.14>.

=head1 SEE ALSO

The I<extras> directory contains sample XML configuration files that
are also used to provide the configurations for the test scripts.

=head1 AUTHOR

Jason A. Lee E<lt>leeja@cpan.orgE<gt>

=head1 COPYRIGHT

 Text::XmlMatch version 1.0006

 Copyright 2007, Jason Lee
   All rights reserved.

=cut
