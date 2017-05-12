package Workflow::XPDL;

use 5.008008;
use strict;
use warnings;
use XML::XPath;
use Data::Dumper;
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);
our $debug = 0;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Workflow::XPDL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	header_info
	is_valid_workflow
	get_transition_ids
	get_imp_details
	get_app_datatypes
	new
	xml_file
	workflow_id
	activity_id
	application_id
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.40';


# Preloaded methods go here.

sub header_info {
  my $self = shift;
  my $xml_file = $self->{XML_FILE};
  my $headerval;
  my $headertext;
  my %headerhash;
  my $sub_name = "header_info";
  my $dump;
  chomp $xml_file;
  _debug ("$sub_name: Got $xml_file\n");
  
   my $xp = XML::XPath->new(filename => $xml_file);
   my $nodeset = $xp->find("//*[ancestor::PackageHeader]"); 
    
    foreach my $node ($nodeset->get_nodelist) {
            my $headerval = $node->getLocalName();
            my $headertext = $node->string_value();
            $headerhash{$headerval} = "$headertext";

    }

  $dump = Dumper(%headerhash);
  _debug ("$dump");
  return (%headerhash);
}

sub is_valid_workflow {  
  my $self = shift;
   if ($_[0]) {
    $self->{WORKFLOW_ID} = $_[0]; 
   }
  my $sub_name = "is_valid_workflow";
  my $xml_file = $self->{XML_FILE};
  my $workflow_id = $self->{WORKFLOW_ID};
  my $found_id = 1;
  chomp $xml_file;
  _debug ("$sub_name: Got $xml_file\n");
  _debug ("$sub_name: Got $workflow_id\n");
  
   my $xp = XML::XPath->new(filename => $xml_file);
   my $nodeset = $xp->exists("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]"); # find all paragraphs
   if ($nodeset) {
     $found_id = 0;
   }
  return $found_id;
}

sub _debug {
  my $output = $_[0];
  if ($debug) {
    print STDERR "$output";
  }
}

sub get_transition_ids {
   my $self = shift;
   if ($_[0]) {
    $self->{ACTIVITY_ID} = $_[0]; 
   }
  my $xml_file = $self->{XML_FILE};
  my $workflow_id = $self->{WORKFLOW_ID};
  my $activity_id = $self->{ACTIVITY_ID};
  my $trans_id;
  my %transition_hash;
  my $split_type;
  my $restrictions_exist = 0;
  my $restriction_type;
  my $transitions_exist = 0;
  my $conditions_exist = 0;
  my $dump;

  
  chomp $xml_file;
  my $xp = XML::XPath->new(filename => $xml_file);
  $transitions_exist = $xp->exists("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Transitions/Transition[\@From=$activity_id]");
  if ($transitions_exist) { 
    $transition_hash{'trans_exist'} = 'TRUE';
    my $nodeset = $xp->find("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Transitions/Transition[\@From=$activity_id]");
    foreach my $node ($nodeset->get_nodelist) {
      my $condition;
      my $trans_to_id = $node->findvalue('@To');
      _debug("Trans to id is $trans_to_id\n");
      my $trans_id = $node->findvalue('@Id');
      _debug("Trans id is $trans_id\n");
      my $conditions_exist = $xp->exists ("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Transitions/Transition[\@Id=$trans_id]/Condition");
      if ($conditions_exist) {
        my $conditionset = $xp->find("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Transitions/Transition[\@Id=$trans_id]/Condition");
        foreach my $conditions ($conditionset->get_nodelist) {
          $condition = $conditions->string_value();
          my %temp_hash = ( 'transition_to_id' => $trans_to_id, 'transition_condition' => $condition );
          $transition_hash{$trans_id} = \%temp_hash;
        }
      }
      else {
        my %temp_hash = ( 'transition_to_id' => $trans_to_id, 'transition_condition' => 'NULL' );
        $transition_hash{$trans_id} = \%temp_hash;
      }
    }
    $restrictions_exist = $xp->exists("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Activities/Activity[\@Id=$activity_id]/TransitionRestrictions/TransitionRestriction/Split/TransitionRefs/TransitionRef");
    if ($restrictions_exist) {
      my $nodeset = $xp->find("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Activities/Activity[\@Id=$activity_id]/TransitionRestrictions/TransitionRestriction/Split");
      foreach my $node ($nodeset->get_nodelist) {
      $restriction_type = $node->findvalue('@Type');
      $transition_hash{'restriction_type'} = $restriction_type;
      }
    }
    else {
      $transition_hash{'restriction_type'} = 'NULL';
    }
  }
  else {
   $transition_hash{'trans_exist'} = 'FALSE'; 
  }
  $dump = Dumper(%transition_hash);
  _debug("$dump");
  return %transition_hash;
}

sub get_imp_details {
   my $self = shift;
   if ($_[0]) {
    $self->{ACTIVITY_ID} = $_[0]; 
   }
  my $xml_file = $self->{XML_FILE};
  my $workflow_id = $self->{WORKFLOW_ID};
  my $activity_id = $self->{ACTIVITY_ID};
  my $impl_name;
  my $exists = 0;
  my @imp_array = "";
  my $appl_id;
  my $appl_type;
  my $dump;
  
  my $xp = XML::XPath->new(filename => $xml_file);
  $exists = $xp->exists("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Activities/Activity[\@Id=$activity_id]/Implementation");
   
  if ($exists) {
   my $nodeset = $xp->find("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Activities/Activity[\@Id=$activity_id]/Implementation/*");
    foreach my $node ($nodeset->get_nodelist) {
       $impl_name = $node->getLocalName();
       if ( $impl_name  eq "Tool") {
         $appl_id = $node->findvalue('@Id');          
         $appl_type = $node->findvalue('@Type');
       }
       elsif ( $impl_name eq "No") {
         $appl_id = "";
         $appl_type = "";
       }        
       elsif ( $impl_name eq "SubFlow") {   
         $appl_id = $node->findvalue('@Id');
         $appl_type = $node->findvalue('@Execution');
       }
       else {
         $impl_name = "NULL";
         $appl_id = "";
         $appl_type = "";
       }
     }
   }
   else {
     $impl_name = "NULL";
     $appl_id = "";
     $appl_type = "";
   } 
   @imp_array = [$impl_name,  $appl_id, $appl_type];  
   $dump = Dumper(@imp_array);
   _debug("$dump");
   return (@imp_array);
}

sub get_app_datatypes {
   my $self = shift;
   if ($_[0]) {
    $self->{APPLICATION_ID} = $_[0]; 
   }
  my $xml_file = $self->{XML_FILE};
  my $workflow_id = $self->{WORKFLOW_ID};
  my $application_id = $self->{APPLICATION_ID};
  my $impl_name;
  my $exists = 0;
  my @imp_array = "";
  my $appl_id;
  my $appl_type;
  my $dump;
  my %param_hash;

  
  my $xp = XML::XPath->new(filename => $xml_file);
  $exists = $xp->exists("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Applications/Application[\@Id=\'$application_id\']/FormalParameters");
  
  if ($exists) {
    my $nodeset = $xp->find("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Applications/Application[\@Id=\'$application_id\']/FormalParameters/FormalParameter");
    foreach my $node ($nodeset->get_nodelist) {
      my $param_id = $node->findvalue('@Id');
      my $param_index = $node->findvalue('@Index');
      my $param_mode = $node->findvalue('@Mode');
      my $param_type = "";
      my $param_type_val = "";
      my $nodeset2 = $xp->find("/Package/WorkflowProcesses/WorkflowProcess[\@Id=$workflow_id]/Applications/Application[\@Id=\'$application_id\']/FormalParameters/FormalParameter[\@Id=\'$param_id\']/DataType/*");
      foreach my $node2 ($nodeset2->get_nodelist) {
        $param_type = $node2->getLocalName();
        if ($param_type eq "BasicType") {
          $param_type_val = $node2->findvalue('@Type');
        }
        else {
          $param_type_val = $node2->findvalue('@Id'); 
        }
      }
      $param_hash{$param_id} = [ $param_index, $param_mode, $param_type, $param_type_val];
      
    }
  }
  else {
    _debug("Not found.");
  }
  $dump = Dumper(%param_hash);
   _debug("$dump");
  return %param_hash;
}

sub get_formal_parameters {
  return "Not yet implemented\n"; 
}

sub new {
  my $classed = 1;
  my $self  = {};
  my $class;
  my @args;
  ($class, @args) = @_;
  my $count = 2;
  foreach my $params (@args) {
    if ($params eq "xml_file") {
      $self->{XML_FILE} = $_[$count];
    }
    if ($params eq "workflow_id") {
      $self->{WORKFLOW_ID} = $_[$count];
    }
    if ($params eq "activity_id") {
      $self->{ACTIVITY_ID} = $_[$count];
    }
    if ($params eq "application_id") {
      $self->{APPLICATION_ID} = $_[$count];
    }
    $count++;
  }
  unless ($self->{XML_FILE}) {
    $self->{XML_FILE} = undef;
  }
  unless ($self->{WORKFLOW_ID}) {
    $self->{WORKFLOW_ID} = undef;
  }
  unless ($self->{ACTIVITY_ID}) {
    $self->{ACTIVITY_ID} = undef;
  }
  unless ($self->{APPLICATION_ID}) {
    $self->{APPLICATION_ID} = undef;
  }
  bless($self, $class);
  return $self;
}

sub xml_file {
   my $self = shift;
   if ($_[0]) {
    $self->{XML_FILE} = $_[0]; 
   }
  return $self->{XML_FILE};
}

sub workflow_id {
   my $self = shift;
   if ($_[0]) {
    $self->{WORKFLOW_ID} = $_[0]; 
   }
  return $self->{WORKFLOW_ID};
}

sub activity_id {
   my $self = {};
   if ($_[0]) {
    $self->{ACTIVITY_ID} = $_[0]; 
   }
  return $self->{ACTIVITY_ID};
}

sub application_id {
   my $self = {};
   if ($_[0]) {
    $self->{APPLICATION_ID} = $_[0]; 
   }
  return $self->{APPLICATION_ID};
}

sub DESTROY {
  my $self = shift;
  if ($debug ) {
    carp "Destroying $self\n";
  }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Workflow::XPDL - Perl extension for reading XDPL

=head1 SYNOPSIS

  use Workflow::XPDL qw(:all);
  
  my $oo_xpdl = Workflow::XPDL->new();
  $oo_xpdl->xml_file('workflow.xml');
  my $is_valid_workflow_result = $oo_xpdl->is_valid_workflow('1');
  my @impl_result = $oo_xpdl->get_imp_details('58');
  $oo_xpdl->application_id('transformData');
  my %app_data_result = $oo_xpdl->get_app_datatypes('transformData');
  my %transition_result = $oo_xpdl->get_transition_ids('1');
  

=head1 DESCRIPTION

Workflow::XPDL is essentially a object oriented reference library to read 
XML documents in XPDL format (http://www.Workflow.org/standards/xpdl.htm).
Workflow::XPDL takes sections of the XPDL document based on input values and 
returns scalars, hashes, and arrays for use in the calling programs. 


=head2 EXPORT

None by default.

=head2 FUNCTIONS

=over 4 

=item new();

C<new()> can be called as the default constructor, or can also be called 
with references to the XML file being read (xml_file), the Workflow Id 
to be processed (workflow_id), the Activity Id to be processed (activity_id),
and the Application Id to be processed application_id). It returns a new Workflow::XPDL 
object.


=item activity_id();

C<activity_id()> gets or sets the current activity_id of 
interest.


=item application_id();
C<application_id> gets or sets the current activity_id of 
interest.


=item get_app_datatypes();
C<get_app_datatypes> can optionally take an application id (which will override any 
existing setting). It returns all the datatypes associated with a particular XPDL 
application in a hash, with key values being the datatype name, i.e. something like:

(
       'orderInfo' => ['2', 'OUT', 'DeclaredType', 'Order'],
       'orderStringIn' => ['1', 'IN', 'BasicType', 'STRING'] 
);

Where the values are 'Index Id', 'Mode', 'Data Type',
and 'Variable Type'.


=item get_formal_parameters();
Not yet implemented.


=item get_imp_details();
C<get_imp_details> gets detailed information about an application implementation of an activity. 
It can optionally take an application id (which will override any 
existing setting). It returns an array similar to the following: 

[ 'Tool', 'transformData', 'APPLICATION' ];

Which are the values of 'Implementation Type', 'Name', 'Application Type'. 
If no application is defined to an activity, the first value of the array is 
set to zero.


=item get_transition_ids();
C<get_transition_ids> optionally takes an activity id, and returns a hash that describes all the 
activities that an activity can transition to, and the type of transition. 
Returns output similar too:

( 
  '22' => {
    'transition_to_id' => '12',
    'transition_condition' => 'status == "Valid Data"'
  },
  'trans_exist' => 'TRUE',
  '23' => {
    'transition_to_id' => '39',
    'transition_condition' => 'status == "Invalid Data"'
  },
  'restriction_type' => 'XOR',
);

The key in the hash is the transition id. The value of the key is another hash, 
containing the name/value pairs of the transition. The key 'restriction_type' 
defines the type of restriction placed on the transition (only 'XOR' and 'AND' are 
valid restriction types).

In the case where there are no transitions exist (i.e. the end of a workflow), the 
key 'trans_exist' is set with a value of 'FALSE'.


=item header_info();

C<header_info> returns header information about the XPDL file, in hash. The returning 
value will look like:

(
        'Created' => '6/18/2002 5:27:17 PM',
        'Vendor' => 'XYZ, Inc',
        'XPDLVersion' => '0.09'
);


=item is_valid_workflow();

C<is_valid_workflow> can optionally accept a workflow id (which will override any 
existing setting). It returns 0 if the requested workflow is found, 1 if it does not exist. 

=back

=head1 SEE ALSO

L<Workflow::Wfmc>

=head1 AUTHOR

Stephen Rhoton, E<lt>srhoton@andrew.cmu.eduE<gt>

=head1 TODO

Future interations will also include the ability to write the XPDL
document.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Stephen Rhoton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
