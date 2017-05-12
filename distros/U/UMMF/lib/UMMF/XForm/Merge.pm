package UMMF::XForm::Merge;

use 5.6.1;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/08/12 };
our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::XForm::Merge - Merge ModelElements from multiple Models.

=head1 SYNOPSIS

  use UMMF::XForm::Merge;

  my $xform = UMMF::XForm::Merge->new();
  $model = $xform->apply_Model([ $model1, $model2, ... ]);

=head1 DESCRIPTION

This UML transform merges Models by overlaying elements from $model2 on top of $model1.  ModelElements that have a TaggedValue 'ummf.Merge.placeholder' with a true value, will be used as a placeholder (i.e. a pointer) to a non-placeholder ModelElement in another model.

=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@sourceforge.net 2003/08/12

=head1 SEE ALSO

L<UMMF::UML::MetaMetaModel|UMMF::UML::MetaMetaModel>

=head1 VERSION

$Revision: 1.6 $

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

  $self;
}


#######################################################################


sub apply_Model
{
  my ($self, $models) = @_;

  $self->merge_Model($models);
  
}


#######################################################################


sub merge_Model
{
  my ($self, $models) = @_;

  my @models = @$models;
  my $model = shift @models;

  while ( @models ) {
    my $modelx = shift @models;

    $self->merge_ModelElements($model, $modelx); 

    $self->replace_flush($model, $modelx);

    $self->merge_Links($model, $modelx);

    $self->replace_flush($model, $modelx);
  }

  $model;
}


#######################################################################


sub merge_ModelElements
{
  my ($self, $model, $modelx) = @_;

  $self->merge_ModelElements_1($model, $modelx,
			     $model, $modelx,
			     );
}


sub merge_ModelElements_1
{
  my ($self, $model, $modelx, $ns, $nsx) = @_;

  for my $objx ( $nsx->ownedElement ) {
    my $name = $objx->name;
    my $obj = Namespace_ownedElement_name($ns, $name);

    if ( $objx->isaModelElement ) {
      if ( $obj ) {
	if ( ref($obj) ne ref($objx) ) {
	  confess("Not same object type: $obj : $objx");
	}
	
	$self->message('exists', $obj);
	
	if ( $self->isa_placeholder($obj) ) {
	  $self->message('placeholder', $obj);
	  if ( $self->isa_placeholder($objx) ) {
	    $self->message('placeholder', $objx);
	  }

	  # Replace $obj with $objx in $model.
	  $self->replace($model, $modelx, $obj, $objx);

	  # Explicitly move $objx to $model.
	  $self->message('move', $objx, 'from', $nsx, 'to', $ns);
	  $nsx->remove_ownedElement($objx);
	  $ns->add_ownedElement($objx);
	}
      } else {
	$self->message('does not exist', $objx, 'in 1');
	
	if ( $self->isa_placeholder($objx) ) {
	  $self->message('placeholder', $objx);
	}

	# Explicitly move $objx to $model.
	$self->message('move', $objx, 'from', $nsx, 'to', $ns);
	$nsx->remove_ownedElement($objx);
	$ns->add_ownedElement($objx);
      }
    }

    if ( $objx->isaNamespace ) {
      if ( $obj ) {
	$self->merge_ModelElements_1($model, $modelx, $obj, $objx);
      }
    }
  }
}


#######################################################################


sub merge_Links
{
  my ($self, $model, $modelx) = @_;

  $self->merge_Links_1($model, $model);
  $self->merge_Links_1($model, $modelx);

  $self;
}


sub merge_Links_1
{
  my ($self, $model, $ns) = @_;

  # This entire function should be replaced with something
  # that interprets the UML meta-metamodel to swizzle the references
  # between objects that have moved from or replaced with $modelx.
  for my $obj ( $ns->ownedElement ) {
    my $ref = ref($obj); $ref =~ s/^.*:://s;
    my $name = $obj->name;

    if ( $obj->isaGeneralization ) {
      my $gen = $obj;
      for my $end ( 'child', 'parent' ) {
	my $p = $gen->$end();
	my $real_p = Namespace_ownedElement_name
	  ($model, 
	   [ ModelElement_name_qualified($p) ],
	  );
	
	if ( $p ne $real_p ) {
	  $self->message("fixed", $gen, $end, 'from', $p, 'to', $real_p);
	  my $m = "set_$end";
	  $gen->$m($real_p) if $real_p;
	}
      }
    }

    if ( $obj->isaDependency ) {
      my $dep = $obj;
      for my $end ( 'supplier', 'client' ) {
	for my $p ( $dep->$end() ) {
	  my $real_p = Namespace_ownedElement_name
	    ($model, 
	     [ ModelElement_name_qualified($p) ],
	    );
	  
	  if ( $p ne $real_p ) {
	    $self->message("fixed", $dep, $end, 'from', $p, 'to', $real_p);
	    my $remove = "remove_$end";
	    my $add = "add_$end";
	    $dep->$remove($p);
	    $dep->$add($real_p) if $real_p;
	  }
	}
      }
    }

    if ( $obj->isaAssociation ) {
      # Handle AssociationEnds.
      for my $assoc ( $obj ) {
	for my $end ( $assoc->connection ) {
	  my $p = $end->participant;
	  my $real_p = Namespace_ownedElement_name
	    ($model, 
	     [ ModelElement_name_qualified($p) ],
	    );
	  
	  if ( $p ne $real_p ) {
	    $self->message('fixed', $end, 'particpant', 'from', $p, 'to', $real_p);
	    $end->set_participant(undef);
	    $end->set_participant($real_p);

	    $p = $real_p;
	  }

	  if ( ! grep($_ eq $end, $p->association) ) {
	    $self->message('added', $p, 'association', $end);
	    $p->add_association($end);
	  }
	}
      }
    }

    if ( $obj->isaNamespace ) {
      $self->merge_Links_1($model, $obj);
    }
  }
}


#######################################################################


sub replace
{
  my ($self, $model, $modelx, $obj, $objx) = @_;

  $self->message("replace", $obj, 'with', $objx);

  $self->{'.replace'}{$model} ||= { };
  $self->{'.replace'}{$model}{$obj} = $objx;
}


sub replace_flush
{
  my ($self, $model, $modelx) = @_;

  my $x = $self->{'.replace'};

  $self->{'.replace'} = $x->{$model};
  $self->replace_1($model, { }, '');

  $self->{'.replace'} = $x->{$modelx};
  $self->replace_1($modelx, { }, '');

  $self->{'.replace'} = undef;
}



sub replace_1
{
  my ($self, $x, $visited, $path) = @_;

  return unless ref($x);

  return if ( $visited->{$x} );

  $visited->{$x} = 1;

  my $map = $self->{'.replace'};

  if ( UNIVERSAL::isa($x, 'Set::Object') ) {
    for my $v ( $x->members ) {
      if ( my $nv = $map->{$v} ) {
	$self->message('replaced', $v, 'with', $nv, 'in', $path . "Set::Object");
	$x->remove($v);
	$x->insert($nv);
	$v = $nv;
      }
      $self->replace_1($v, $visited, $path . "{Set::Object}");
    }
  }
  elsif ( $x =~ /HASH\(.*\)$/ ) {
    confess("$x is $@") unless eval { keys %$x };

    for my $k ( keys %$x ) {
      my $v = \$x->{$k};
      if ( my $nv = $map->{$$v} ) {
	$self->message('replaced', $$v, 'with', $nv, 'at', $path . "{$k}");
	$$v = $nv;
      }
      $self->replace_1($$v, $visited, $path . "{$k}");
    }
  }
  elsif ( $x =~ /ARRAY\(.*\)$/ ) {
    confess($@) unless eval { scalar @$x };

    my $i = -1;
    for my $v ( @$x ) {
      ++ $i;
      if ( my $nv = $map->{$v} ) {
	$self->message('replaced', $v, 'with', $nv, 'at', $path . "[$i]");
	$v = $nv;
      }
      $self->replace_1($v, $visited, $path . "[$i]");
    }
  }
}


#######################################################################


sub add
{
  my ($self, $model, $modelx, $obj, $objx) = @_;

  $self->message("add", $objx);
}


#######################################################################


sub isa_placeholder
{
  my ($self, $obj) = @_;

  ModelElement_taggedValue_name_true($obj, 'ummf.Merge.placeholder');
}


#######################################################################


sub message
{
  my ($self, @x) = @_;
  
  for my $x ( @x ) {
    if ( ref($x) ) {
      my $ref = ref($x); $ref =~ s/^.*:://s;
      my $q_name = ModelElement_name_qualified($x);
      my $m_name = ModelElement_namespace_root($x)->name;
      my $id = $x->{'_id'} || '?';

      $x = "$ref($id $q_name in $m_name)";
    }
  }

  print STDERR "  ", join(' ', @x), "\n";
}


#######################################################################


#######################################################################


1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/08/12 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###

