package UMMF::XForm::FoldMultipleInheritance;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/04 };
our $VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::XForm::FoldMultipleInheritance - Inlines multiple inheritance bodies.

=head1 SYNOPSIS

  use UMMF::XForm::FoldMultipleInheritance;

  my $xform = UMMF::XForm::FoldMultipleInheritance->new();
  $model = $xform->apply_Model($model);

=head1 DESCRIPTION

This transform is useful for converting a Model containing multiple inheritance to a Model using single inheritance by creating Interfaces for classes that are inherited from in multiple inheritance context and inlining Features and Operations from the multiple inheritance Classifiers.

=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/04

=head1 SEE ALSO

L<UMMF::UML::MetaMetaModel|UMMF::UML::MetaMetaModel>

=head1 VERSION

$Revision: 1.8 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::XForm);

#######################################################################

use UMMF::Core::Util qw(:all);
use Carp qw(confess);
use UMMF::XForm::ClassInterface;

#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'verbose'} ||= 0;

  $self;
}


#######################################################################

sub apply_Model
{
  my ($self, $model) = @_;

  my $x1 = UMMF::XForm::ClassInterface
    ->new(
	  'verbose'              => $self->{'verbose'},
	  'config_enabled_force' => 1,
	 );

  # Do Class => Interface production.
  $model = $x1->apply_Model($model);

  # Get mappings of production.
  my $iface = $x1->{'iface'};
  my $icls = $x1->{'icls'};

  print STDERR "* Pass 1:\n" if $self->{'verbose'} > 0; 
  #   For each Class that has more than one Generalization:
  #    1.  Leave the first Generalization (to reduce code bloat).
  #    2.  Remove the remaining Generalizations.
  #    3.  Create Abstraction to analogous generated Interface from
  #        each remaining Generalization.
  #    4.  Copy Features and Assocations from all remaining Generalizations and
  #        their Generalization parents, avoiding all Classifiers that are Generalizations
  #         of the first Generalization.
  my (@op);
  for my $cls ( Namespace_class($model) ) {
    my @gen = $cls->generalization;
    
    next unless @gen > 1;

    # Leave the first Generalization and all its Generalization parents
    # out of the traversal.
    my $keep = (shift @gen)->parent;
    my @avoid = (
		 $keep, 
		 GeneralizableElement_generalization_parent_all($keep),
		 );
    
    # Remove extra generalizations.
    my @copy_op;
    my @abs_op;
    my $op = [ $cls, $keep, \@avoid, [ @gen ], \@abs_op, \@copy_op ];
    push(@op, $op);
    
    # Map to actual Classifier.
    @gen = map($_->parent, @gen);
    # $DB::single = 1;
    
    # Create Abstractions to the new Interfaces.
    # Select only defined Interfaces of the Generalization parent.
    {
      my %visit;
      my @x = @gen;
      while ( @x ) {
	my $x = pop @x;
	next if $visit{$x} ++;
	push(@x, map($_->parent, $x->generalization));
	for my $abs ( $iface->{$x}, 
		      map($_->supplier, 
			  grep($_->isaAbstraction, $x->clientDependency)
			 )
		      ) {

	  push(@abs_op, $abs) if $abs && ! grep($_ eq $abs, @abs_op);
	}
      }
    }
    
    # Start visiting others, except all Classes already covered
    # by first Generalization.
    {
      my %visit = ( map(($_ => 1), @avoid) );
      while ( @gen ) {
	my $scls = pop(@gen);
	
	next if $visit{$scls} ++;
	
	push(@gen, map($_->parent, $scls->generalization));
	
	# What to do.
	push(@copy_op, [ $scls, [ $scls->feature ], [ $scls->association ] ]);
      }
    }
  }

  # Apply Model deltas now.
  for my $x ( @op ) {
    my ($cls, $keep, $avoid, $gen, $abs, $copy) = @$x;
    
    print STDERR "Classifier '", $cls->name, "' :\n" if $self->{'verbose'} > 0;

    print STDERR "  Keeping Generalization => ", $keep->name, "\n" if $self->{'verbose'} > 0;
    
    if ( @$gen ) {
      print STDERR "  Removing Generalizations : ", join(', ', map($_->parent->name, @$gen)), "\n" if $self->{'verbose'} > 0;
      $cls->remove_generalization(@$gen);
    }

    if ( @$abs ) {
      print STDERR "  Adding Abstractions : ", join(', ', map($_->name, @$abs)), "\n" if $self->{'verbose'} > 0;

      for my $iface ( @$abs ) {
	my $factory = $cls->__factory;
	$factory->create('Abstraction',
			 'namespace' => $cls->namespace,
			 'supplier' => [ $iface ],
			 'client' => [ $cls ],
			 );
	
      }
    }

    print STDERR "  Avoiding Features from ", join(', ', map($_->name, @$avoid)), "\n" if $self->{'verbose'} > 0;

    $self->{'assoc_copied'} = { };
    for my $y ( @$copy ) {
      my ($scls, $features, $assocs) = @$y; 
      
      $self->copy_Classifier_Feature($cls, $scls, $features);
      $self->copy_Classifier_AssociationEnd($cls, $scls, $assocs);
    }
  }

  # Replace all Class type usages with Interfaces.
  $x1->{'verbose'} = 9;
  $model = $x1->pass_4($model);

  $model;
}



#######################################################################


1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

