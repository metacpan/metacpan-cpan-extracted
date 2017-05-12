package UMMF::XForm::AssocClassLinks;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/10 };
our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::XForm::AssocClassLinks - Create Assoociations for each AssociationEnd of each AssociationClass.

=head1 SYNOPSIS

  use UMMF::XForm::AssocClassLinks;

  my $xform = UMMF::XForm::AssocClassLinks->new();
  $model = $xform->apply_Model($model);

=head1 DESCRIPTION

This UML transform greatly simplifes and standardizes code generation for AssociationClasses.

This transform creates a new Association for each AssociationEnd of an AssociationClass.  The new Association links the participants of the AssociationClass's AssociationEnds directly to the AssociationClass using the suffix C<'_AC'> to distinguish it from the links specified by the AssociationClass's AssociationEnds itself.

For example:

     __________                                 __________
    |  XClass  |                               |  YClass  |
    |__________|                               |__________|
    |          |    2                       3  |          |
    |__________|---x-----------------------y---|__________|
                             |
                             .
                             |
                             .
                             |
                             .
                  __________________
                 |    AssocClass    |
                 |__________________|
                 |                  |
                 |__________________|


AssociationEnd C<x> has a C<multiplicity> of C<2>, AssociationEnd C<y> has a C<multiplicity> of C<3>.  This transformation results in:


     __________                                 __________
    |  XClass  |                               |  YClass  |
    |__________|                               |__________|
    |          |    2                       3  |          |
    |__________|---x-----------------------y---|__________|
         |                   |                   |
         |1                  .                   |1
         x                   |                   y
         |                   .                   |
         |                   |                   |
         |                   .                   |
         |        __________________             |
         |       |    AssocClass    |            |
         |     3 |__________________|      2     |
         +-y_AC--|                  |--x_AC------+
                 |__________________|

The AssocClass has outbound AssociationEnd with multiplicity of 1.
And:

1. XClass => YClass multiplicity == XClass => AssocClass multiplicity
2. YClass => XClass multiplicity == YClass => AssocClass multiplicity

This provides direct navigation along the original AssociationClass Association behavior, while providing additional navigation to AssociationClass Class Attributes through the C<*_AC> links.

=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/04

=head1 SEE ALSO

L<UMMF::UML::MetaMetaModel|UMMF::UML::MetaMetaModel>

=head1 VERSION

$Revision: 1.9 $

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

  $self->{'assoc_name_template'} ||= '%s_AC';
  $self->{'verbose'} = 0;

  $self;
}


#######################################################################

sub config_kind
{
  'xform.AssocClassLinks';
}

#######################################################################

sub apply_Model
{
  my ($self, $model) = @_;

  print STDERR "* Pass 1:\n" if $self->{'verbose'} > 0;
  my $factory = $model->__factory;

  my @remove_end;

  for my $cls ( Namespace_ownedElement_match($model, 'isaAssociationClass', 1) ) {
    # This xform is enabled by default.
    next unless $self->config_value_inherited_true($cls, '', 1);

    # For each AssociationEnd involved in $cls as an Association,
    for my $end ( $cls->connection ) {
      my $assoc = AssociationEnd_association($end);
      die unless $assoc eq $cls;

      my @opposite = grep($_ ne $end, $assoc->connection);
      my $opposite = $opposite[0];


      my $name = join('_',
		      grep(length,
			   $assoc->name, 
			   $self->end_name($end, $assoc), 
			   $cls->name,
			  )
		     );

      # Create a new AssociationEnd that is connected to
      # the participant of the orignal AssociationEnd
      # With multiplicity of 1.
      my $end_x = $factory
      ->create('AssociationEnd',
	       'namespace'     => $end->namespace,
	       'name'          => $self->end_name($end, $assoc),

	       'isNavigable'   => $end->isNavigable,
	       'ordering'      => $end->ordering,
	       'aggregation'   => $end->aggregation,
	       'targetScope'   => $end->targetScope,
	       'multiplicity'  => Multiplicity_fromString('1', $factory),
	       'changeability' => $end->changeability,
	       
	       'participant'   => $end->participant,
 
	       '_trace'        => $end,
	       );


      # Create an AssociationEnd that has the AssociationClass as participant,
      # with similar attributes as the opposite end
      # with same multiplicity.
      my $end_a = $factory
      ->create('AssociationEnd',
	       'namespace'     => $opposite->namespace,
	       'name'          => sprintf($self->{'assoc_name_template'}, 
					  $self->end_name($opposite, $assoc),
					 ),

	       'isNavigable'   => $opposite->isNavigable,
	       'ordering'      => $opposite->ordering,
	       'aggregation'   => $opposite->aggregation,
	       'targetScope'   => $opposite->targetScope,
	       'multiplicity'  => $opposite->multiplicity,
	       'changeability' => $opposite->changeability,
	       
	       'participant'   => $cls,

	       '_trace'        => $opposite,
	       );

      # Create an Association.
      my $ac_assoc = $factory
      ->create('Association',
	       'namespace'  => $assoc->namespace,
	       'name'       => sprintf($self->{'assoc_name_template'}, $name),
	       
	       'connection' => [ $end_x, $end_a ],
	       
	       '_trace'     => $cls,
	       );

      if ( $self->{'verbose'} > 1 ) {
	print STDERR "Created new Association for AssociationEnd:", 
	  Association_asString($ac_assoc), 
	    "\n\n";
      }

      # Remove old ends from participants.
      # push(@remove_end, $end);
    }

  }

  # Should this remove the old Association links?
  # -- kstephens@sourceforge.net 2003/08/29
  for my $end ( @remove_end ) {
    print STDERR "Removing ", AssociationEnd_asString($end), "\n\n";
    $end->set_participant(undef);
  }

  $model;
}



sub end_name
{
  my ($self, $end, $assoc) = @_;

  no warnings;

  my $name = 
    (grep(length,
	  $end->name,
	  lcfirst($end->participant->name),
	  lcfirst($assoc->name),
	 ))[0];

  # print STDERR join(' ', $end->name, $end->participant->name, $assoc->name), " => $name\n";

  $name;
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

