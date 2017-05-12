package UMMF::Export::Dump;

use 5.6.1;
use strict;

our $AUTHOR = q{ kstephens@sourceforge.net 2003/04/15 };
our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Dump - A code generator for human-readable output.

=head1 SYNOPSIS

  use base qw(UMMF::Export::Dump);

  my $coder = UMMF::Export::Dump->new('output' => *STDOUT);
  my $coder->export_Model($model);

=head1 DESCRIPTION

This package allow UML models to be represented as Dump.
Actually anything that can supply its own meta-model.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@sourceforge.net 2003/04/15

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>

=head1 VERSION

$Revision: 1.4 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Export);

use UMMF::Core::Util qw(:all);
use XML::Writer;

#######################################################################


sub initialize
{
  my ($self) = @_;

  # $DB::single = 1;

  $self->SUPER::initialize;

  $self->{'indent'} ||= 0;

  $self;
}


#######################################################################

sub export_Model
{
  my ($self, $model) = @_;
  

  $self->export_object($model);
  
  $self;
}


#######################################################################


sub export_object
{
  my ($self, $obj) = @_;

  my $ref = ref($obj);
  $ref =~ s/^.*:://s;

  my $name = $obj->name;
  my @gen;

  if ( $obj->isaClassifier ) {
    @gen = map(scalar ModelElement_name_qualified($_),
	       map($_->parent,
		   grep(defined, $obj->generalization),
		  )
	      );
  }
  
  $name = "'$name'";

  $self->print($ref, ' ', 
	 $name, 
	 (@gen ? ' : ' . join(', ', @gen) : ''), 
	 " /* $obj->{_id} */",
	 " {");
  ++ $self->{'indent'};

  # ModelElement taggedValue.
  my @tv = $obj->taggedValue;
  if ( @tv ) {
    $self->print("{");
    ++ $self->{'indent'};

    for my $tv ( @tv ) {
      $self->print('"', $tv->type->name, '"', ' = ', '"', $tv->dataValue, '"');
    }

    -- $self->{'indent'};
    $self->print("}\n");
  }

  # Classifier feature.
  if ( $obj->isaClassifier ) {
    for my $attr ( grep($_->isaAttribute, $obj->feature) ) {
      $self->print(Attribute_asString($attr));
    }

    for my $end ( $obj->association ) {
      $self->print(AssociationEnd_asString($end));
    }
  }

  if ( $obj->isaAssociation ) {
    $self->print(Association_asString($obj));
  }

  # Namespace ownedElement.
  if ( $obj->isaNamespace ) {
    for my $x ( $obj->ownedElement ) {
      $self->export_object($x);
    }
  }

  -- $self->{'indent'};
  $self->print("} /* End of $ref $name */\n");

  $self;
}


#######################################################################


sub print
{
  my $self = shift;

  $self->{'output'}->print('  ' x $self->{'indent'}, @_, "\n");
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

