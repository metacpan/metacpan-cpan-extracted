package UMMF::XForm;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@sourceforge.net 2003/05/05 };
our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::XForm - Base class for UML Model transformations.

=head1 SYNOPSIS

  use base qw(UMMF::XForm);


=head1 DESCRIPTION


=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, ks.perl@kurtstephens.com 2003/05/05

=head1 SEE ALSO

L<UMMF::UML::MetaMetaModel|UMMF::UML::MetaMetaModel>

=head1 VERSION

$Revision: 1.9 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Core::Configurable);

#######################################################################

use UMMF::Core::Util qw(:all);
use Carp qw(confess);

#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'verbose'} ||= 0;

  $self;
}


#######################################################################


#######################################################################

=head2 apply_Model

  $model = $xform->apply_Model($model);

Apply transformation to the model.  The $xform may mutate the $model to achieve the transform.

Subclasses must implement this behavior.

=cut
sub apply_Model
{
  my ($self, $model) = @_;

  confess(ref($self) . '::apply_Model(): not implemented');
}


#######################################################################
# Support transforms
#

=head2 copy_Classifier_Feature

  $xform->copy_Classifier_Feature($to_cls, $from_cls, [ $features ]);

Copies cloned features (Attributes and Operations) from C<$from_cls> to C<$to_cls>.

If C<$features> is defined, only those features are copied.

=cut
sub copy_Classifier_Feature
{
  my ($self, $cls, $scls, $features) = @_;

  $features ||= [ $scls->feature ];

  if ( @$features ) {
    print STDERR "  Copying Features from '", $scls->name, "':\n" if $self->{'verbose'} > 0;
  }

  for my $attr ( grep($_->isaAttribute, @$features) ) {
    next if $attr->{'_trace'};
    $attr = Attribute_clone($attr);
    $attr->{'_trace'} = $scls;

    print STDERR "  Copying ", $scls->name, " Attribute '", $attr->name, "' into ", $cls->name, "\n" if $self->{'verbose'} > 0;
    # $DB::single = 1;
    
    $cls->add_feature($attr);
  }
  
  for my $op ( grep($_->isaOperation, @$features) ) {
    next if $op->{'_trace'};
    $op = Operation_clone($op);
    $op->{'_trace'} = $scls;

    print STDERR "  Copying ", $scls->name, " Operation '", $op->name, "' into ", $cls->name, "\n" if $self->{'verbose'} > 0;
    # $DB::single = 1;
    $cls->add_feature($op);
  }
 
  $self;
}



=head2 copy_Classifier_AssociationEnd

  $xform->copy_Classifier_AssociationEnd($to_cls, $from_cls, [ $assocs ]);

Copies cloned AssociationEnds from C<$from_cls> to C<$to_cls>.

If C<$assoc> is defined, only those AssociationEnds are copied, otherwise all the AssociationEnds attached to C<$from_cls> are copied.

This actually clones new Associations to resolve sharing issues.

=cut
sub copy_Classifier_AssociationEnd
{
  my ($self, $cls, $scls, $assocs) = @_;

  # Get all Associations that have $scls as a participant.
  $assocs ||= [ $scls->association ];

  if ( @$assocs ) {
    print STDERR "  Copying ", $scls->name, " Associations\n" if $self->{'verbose'} > 0;
  }

  my %assoc;
  for my $end ( @$assocs ) {
    my $assoc = AssociationEnd_association($end);
    $assoc{$assoc} = $assoc;
  }

  # Remap AssocationEnd participants from $scls to $cls.
  for my $assoc ( values %assoc ) {
    # $DB::single = 1;
    # my $parts = join(', ', map(($_->participant, $_->participant->association), $assoc->connection));

    print STDERR "Copying\t", Association_asString($assoc), "\n" if $self->{'verbose'} > 0;

    my $assoc_x = Association_clone($assoc);
    $assoc_x->{'_trace'} = $scls;

    for my $end ( $assoc_x->connection ) {
      my $x = $end->participant;
      if ( $x eq $scls ) {
	# $DB::single = 1;
	$end->{'_trace'} = $scls;
	$end->{'_phantom'} = $cls;
	$x = $cls;
      }
      # Force reconnect.
      $end->clear_participant;
      $end->set_participant($x);
    }
    
    print STDERR "As\t", Association_asString($assoc_x), "\n\n" if $self->{'verbose'} > 0;

    # my $parts_n = join(', ', map(($_->participant, $_->participant->association), $assoc->connection));
    # my $parts_x = join(', ', map(($_->participant, $_->participant->association), $assoc_x->connection));
    # print STDERR<
    # $DB::single = 1;
    
  }

  $self;
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

