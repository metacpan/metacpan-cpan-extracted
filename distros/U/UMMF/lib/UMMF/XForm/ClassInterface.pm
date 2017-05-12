package UMMF::XForm::ClassInterface;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/04 };
our $VERSION = do { my @r = (q$Revision: 1.11 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::XForm::ClassInterface - Generate Interface that represent Class.

=head1 SYNOPSIS

  use UMMF::XForm::ClassInterface;

  my $xform = UMMF::XForm::ClassInterface->new();
  $model = $xform->apply_Model($model);

=head1 DESCRIPTION


=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/04

=head1 SEE ALSO

L<UMMF::UML::MetaMetaModel|UMMF::UML::MetaMetaModel>

=head1 VERSION

$Revision: 1.11 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::XForm);

#######################################################################

use UMMF::Core::Util qw(:all);
use Carp qw(confess);

#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'interface_name_template'} ||= 'I%s';

  $self->{'verbose'} = 1;

  $self;
}


#######################################################################

sub config_kind
{
  'xform.ClassInterface';
}


#######################################################################

sub apply_Model
{
  my ($self, $model) = @_;

  my %iface;
  my %icls;

  $self->{'iface'} = \%iface;
  $self->{'icls'} = \%icls;

  print STDERR "* Pass 1:\n" if $self->{'verbose'} > 0;
  # Create Interfaces for all Classes.
  for my $cls ( Namespace_class($model) ) {
    my $cls_name = ModelElement_name_qualified($cls);

    # Make sure this xform is enabled.
    next unless $self->config_enabled($cls);

    # Get the interface name template.
    my $interface_name = $self->config_value($cls, 'interface.name', $self->{'interface_name_template'});

    my $factory = $cls->__factory;
    my $iface = $factory
    ->create('Interface',
	     'name' => sprintf($interface_name, $cls->name),
	     'namespace' => $cls->namespace,
	     );
    
    print STDERR $cls->name, ":\n" if $self->{'verbose'} > 0;
    print STDERR "  Created Interface ", $iface->name, "\n" if $self->{'verbose'} > 0;
    
    $self->copy_Classifier_Feature($iface, $cls);
    
    # Create an Abstraction from the Class to the Interface.
    $factory->create('Abstraction',
		     'namespace' => $cls->namespace,
		     'supplier' => [ $iface ],
		     'client' => [ $cls ],
		     );
    
    $iface{$cls} = $iface;
    $icls{$iface} = $cls;
  }
  print STDERR "* Pass 1: DONE\n" if $self->{'verbose'} > 0; 

  print STDERR "* Pass 2:\n" if $self->{'verbose'} > 0; 
  #   Scan for Classes that have generated Interfaces.
  #   Move each AssociationEnd participant to the generated Interface.
  for my $cls ( values %icls ) {
    my $iface = $iface{$cls};

    next unless $iface;

    print STDERR $cls->name, ":\n" if $self->{'verbose'} > 0;
    for my $end ( $cls->association ) {
      my $assoc = AssociationEnd_association($end);
      print STDERR "  Mapping \t", Association_asString($assoc), "\n" if $self->{'verbose'} > 0;
      $end->set_participant($iface);
      print STDERR "  To \t", Association_asString($assoc), "\n" if $self->{'verbose'} > 0;
    }
  }
  print STDERR "* Pass 2: DONE\n" if $self->{'verbose'} > 0; 

  print STDERR "* Pass 3:\n" if $self->{'verbose'} > 0; 
  #   Foreach generated Interfaces,
  #   Find an AssocationEnd Copy each Association.
  #   Clone the entire Association.
  #   Move the clone's opposite AssociationEnd participants back to source Class.
  my @op_assoc;
  for my $iface ( values %iface ) {
    my $cls = $icls{$iface};
    
    my %assoc;
    for my $cls_end ( $iface->association ) {
      my $assoc = AssociationEnd_association($cls_end);
      $assoc{$assoc} = $assoc;
    }

    for my $assoc ( values %assoc ) {
      my $endi = -1;
      for my $end ( $assoc->connection ) {
	++ $endi;
	if ( $end->participant eq $iface ) {
	  push(@op_assoc, [ $cls, $iface, $assoc, $endi ]);
	}
      }
    }
  }
  for my $x ( @op_assoc ) {
    my ($cls, $iface, $assoc, $endi) = @$x;

    my $assoc_x = Association_clone($assoc);
    # my $assoc_x = $assoc;
    
    my $end_x = ($assoc_x->connection)[$endi];
    if ( ! $end_x ) {
      print STDERR "Bogus association copy for $endi\n";
      print STDERR "  Copying\t", Association_asString($assoc), "\n";
      print STDERR "  As\t", Association_asString($assoc_x), "\n\n";

      die("ARRAGHTHTH!!");
    }

    print STDERR "  Copying\t", Association_asString($assoc), "\n" if $self->{'verbose'} > 0;

    $end_x->{'_phantom'} = $cls;
    $end_x->{'_trace'} = $cls;
    $end_x->clear_participant();
    $end_x->set_participant($cls);
    
    print STDERR "  To\t", Association_asString($assoc_x), "\n\n" if $self->{'verbose'} > 0;
  }
  print STDERR "* Pass 3: DONE\n" if $self->{'verbose'} > 0; 


  $self->pass_4($model);

  $model;
}


#######################################################################

sub pass_4
{
  my ($self, $model) = @_;

  my $iface = $self->{'iface'};

  print STDERR "* Pass 4:\n" if $self->{'verbose'} > 0; 

  # Replace all Class type usages with Interfaces.
  for my $cls ( Namespace_classifier($model) ) {
    for my $attr ( Classifier_attribute($cls) ) {
      my $t = $attr->type;
      $t = $iface->{$t} || $t;
      if ( $attr->type ne $t ) {
	print STDERR "  Changing ", $cls->name, " Attribute '", $attr->name, "' type from ", $attr->type->name, " to ", $t->name, "\n" if $self->{'verbose'} > 0;
	# $DB::single = 1;
	$attr->set_type($t);
      }
    }
    for my $op ( Classifier_operation($cls) ) {
      for my $param ( $op->parameter ) {
	my $t = $param->type;
	$t = $iface->{$t} || $t;
	if ( defined($t) && $param->type ne $t ) {
	  print STDERR "  Changing ", $cls->name, " Operation '", $op->name, "' Parameter '", $param->name, '" type from ', $param->type->name, ' to ', $t->name, "\n" if $self->{'verbose'} > 0;
	  $param->set_type($t);
	}
      }
    }
  }

  print STDERR "* Pass 4: DONE\n" if $self->{'verbose'} > 0; 


  $model;
}

#######################################################################


1;

#######################################################################


### Keep these comments at end of file: kstephens@sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

