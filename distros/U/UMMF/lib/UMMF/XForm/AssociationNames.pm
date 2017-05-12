package UMMF::XForm::AssociationNames;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/04 };
our $VERSION = do { my @r = (q$Revision: 1.14 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::XForm::AssociationNames - Generates names for all Associations, renames AssociationEnds that collide across Generalizations.

=head1 SYNOPSIS

  use UMMF::XForm::AssociationNames;

  my $xform = UMMF::XForm::AssociationNames->new();
  $model = $xform->apply_Model($model);

=head1 DESCRIPTION


=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/04

=head1 SEE ALSO

L<UMMF::Core::MetaModel|UMMF::Core::MetaModel>

=head1 VERSION

$Revision: 1.14 $

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

  $self->{'generate_names'} ||= 1;
  # $self->{'verbose'} = 1;

  $self;
}


#######################################################################


sub apply_Model
{
  my ($self, $model) = @_;

  print STDERR "* Pass 1: Find all Associations\n" if $self->{'verbose'} > 0;
  # Find all Associations
  my %assoc;
  for my $cls ( Namespace_classifier($model) ) {
    for my $cls_end ( $cls->association ) {
      my $assoc = AssociationEnd_association($cls_end);
      $assoc{$assoc} = $assoc;
    }	
  }
  my @assoc = values %assoc;
  $self->{'association'} = \@assoc;

  my %name_given; # Maps objects to names given.
  if ( $self->{'generate_names'} ) {
    print STDERR "* Pass 2: make objects to names given\n" if $self->{'verbose'} > 0;
    # Generate names for all Associations and AssociationEnds
    for my $assoc ( @assoc ) {
      my @gave_names;

      my @x = $assoc->connection;

      die("Too many AssociationEnds") if @x > 2;
      
      my $p0 = $x[0]{'participant'};
      my $n0 = $x[0]{'name'};
      my $p1 = $x[1]{'participant'};
      my $n1 = $x[1]{'name'};

      # IMPLEMENT: Use set_name methods for namespace ownedElement
      # name collision checks.
      UMMF::Core::Util::__fix_association_end_names
      ($p0, $n0, $p1, $n1);

      # Do not rename unnavigable ends.
      no warnings; 

      if ( String_toBoolean($x[1]->isNavigable) && $x[1]{'name'} ne $n1 ) {
	$x[1]{'name'} = $n1;
	$name_given{$x[1]} = 1;
	push(@gave_names, 'End[1]');
      }
      if ( String_toBoolean($x[0]->isNavigable) && $x[0]{'name'} ne $n0 ) {
	$x[0]{'name'} = $n0;
	$name_given{$x[0]} = 1;
	push(@gave_names, 'End[0]');
      }

      # Give the Association a name?
      unless ( $assoc->{'name'} ) {
	$assoc->{'name'} = join('_', map(ucfirst($_), grep(defined, $n0, $n1)));
	$name_given{$assoc} = 1;
	push(@gave_names, 'Assoc');
      }

      if ( @gave_names ) {
	print STDERR 
	  "******************************************************************\n",
	    "Gave names to: ", join(', ', reverse @gave_names), "\n  ", Association_asString($assoc), "\n"
	      if $self->{'verbose'} >= 2;
      }
    }
  }


  print STDERR "* Pass 3: Check for AssociationEnd name collisions\n" 
  if $self->{'verbose'} > 0;

  my @rename;
  for my $cls ( Namespace_classifier($model) ) {
    # Get all Attributes and opposite AssociationEnds for $cls and all its Generalization parents.
    my @attr = ();
    my @other_end = ();

    my @x = ($cls);
    my @gens;
    while ( @x ) {
      my $x = pop @x;

      next if grep($_ eq $x, @gens);
      push(@gens, $x);

      push(@x, map($_->parent, $x->generalization));
   
      # Collect Attributes.
      push(@attr, Classifier_attribute($x));

      # Collect other end(s) of Associations.
      for my $cls_end ( $x->association ) {
	push(@other_end, AssociationEnd_opposite($cls_end));
      }
    }

    @other_end = unique_ref(\@other_end);

    my $print_gens;
    for my $end ( @other_end ) {
      no warnings; # Use of uninitialized value in string eq at

      my $collision = sub {
	my ($same_name_end, $reason_end) = @_;

	my $reason = '';

	unless ( $print_gens ++ ) {
	  $reason .= "\nIn Classifier $cls->{name}:\n" . join('', map("\t$_->{name}\n", @gens)) . "\n\n";
	}
	
	$reason .= "\nCollision in $cls->{name}:\n  " .
	  Association_asString(AssociationEnd_association($end), 
			       $end => ($name_given{$end} ? '/*GIVEN NAME*/' : ''),
			      ) . 
	    "\n";
	
	$reason .= $reason_end;

	# Rename only ends that have given names.
	push(@rename, 
	     [ $end, $reason ],
	    ) if $name_given{$end};

	push(@rename,
	     [ $same_name_end, $reason ],
	    ) if $same_name_end && $name_given{$same_name_end};

	if ( $self->{'verbose'} > 0 ) {
	  print STDERR $reason, "\n";
	}
      };

      # Find AssociationEnd with same name.
      for my $same_name_end (
			     grep($_ ne $end && $_->name && $_->name eq $end->name, 
				  @other_end
				  )
			     ) {
	my $reason = '';

	$reason .= "\n  with AssociationEnd: \n  " . 
	  Association_asString(AssociationEnd_association($same_name_end),
			       $same_name_end => ($name_given{$same_name_end} ? '/*GIVEN NAME*/' : ''),
			       ) .
	    "\n";

	$collision->($same_name_end, $reason);
	
      }

      # Find Attributes with same name.
      for my $same_name_attr (
			     grep($_ ne $end && $_->name && $_->name eq $end->name, 
				  @attr
				  )
			     ) {
	my $reason = '';

	$reason .= "\n  with Attribute: \n  " . 
	  Attribute_asString($same_name_attr) .
	    "\n";

	$collision->(undef, $reason);
      }
    }
  }

  print STDERR "* Pass 4: Rename\n" 
  if $self->{'verbose'} > 0;

  @rename = unique_proc(sub { $_[0][0] }, \@rename);
  for my $end ( @rename ) {
    $self->rename_end($end);
  }
  
  $model;
}


sub rename_end
{
  my ($self, $x) = @_;

  my ($end, $reason) = @$x;

  my $name = $end->name;
  my ($other_end) = AssociationEnd_opposite($end);
  $name = $name . '_' . ($other_end->name || $other_end->participant->name);
  
  my $assoc = AssociationEnd_association($end);
  my $i = index_array($end, $assoc->connection);

  print STDERR 
    "******************************************************************\n",
    "Changing AssociationEnd [$i] name:\n\t", Association_asString($assoc), "\n"
      if $self->{'verbose'} >= 0;

  $end->set_name($name);
  
  print STDERR "  To: \n  ", AssociationEnd_asString($end), "\n\n"
  if $self->{'verbose'} >= 0;

  print STDERR "  Because: \n  ", $reason, "\n",
  if $reason && ($self->{'verbose'} >= 0);

  print STDERR "\n" 
  if $self->{'verbose'} >= 0;

  $self
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

