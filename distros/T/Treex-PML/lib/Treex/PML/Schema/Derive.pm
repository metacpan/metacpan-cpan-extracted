package Treex::PML::Schema::Derive;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}
no warnings 'uninitialized';
use Carp;
use Treex::PML::Schema::Constants;
use base qw(Treex::PML::Schema::XMLNode);

sub get_decl_type     { return(PML_DERIVE_DECL); }
sub get_decl_type_str { return('derive'); }

sub init {
  my ($derive,$opts)=@_;
  if (!exists($derive->{type})) {
    die "<derive> must have a type attribute\n";
  }
  if (!exists($derive->{name})) {
    $derive->{name}=$derive->{type};
  }
}

sub simplify {
  my ($derive,$opts)=@_;
  $derive->{name} ||= $derive->{-name};
  my $schema = $derive->{-parent};
  return if
    (($schema->get_decl_type == PML_TEMPLATE_DECL and $opts->{no_template_derive}) or
     ($schema->get_decl_type == PML_SCHEMA_DECL and $opts->{no_derive}));

  my $name = $derive->{name};
  my $type;
  my $source = $derive->{type};
  unless (defined($source) and length($source)) {
    croak "Derive must specify source type in the attribute 'type' in $schema->{URL}\n";
  }
  if (defined($name) and length($name)) {
    if (exists ($schema->{type}{$name}) and $source ne $name) {
      croak "Refusing to derive already existing type '$name' from '$source' in $schema->{URL}\n";
    }
    $type = $schema->{type}{$name} = $schema->copy_decl($schema->{type}{$source});
    $type->{-name} = $name;
  } else {
    $name = $source;
    $type = $schema->{type}{$name};
  }

  # deriving possible for structures, sequences and choices
  if ($derive->{structure}) {
    if ($type->{structure}) {
      my $derive_structure = $derive->{structure};
      my $target_structure = $type->{structure};
      foreach my $attr (qw(role name)) {
	if (exists $derive_structure->{$attr}) {
	  $target_structure->{$attr} = $derive_structure->{$attr};
	  push @{$target_structure->{-attributes}},$attr
	    unless grep { $_ eq $attr } @{$target_structure->{-attributes}};
	}
      }
      $target_structure->{member} ||= {};
      my $members = $target_structure->{member};
      while (my ($member,$value) = each %{$derive_structure->{member}}) {
	$members->{$member} = $target_structure->copy_decl($value); # FIXME: no need if we remove derives in the end
      }
      if (ref $derive_structure->{delete}) {
	for my $member (@{$derive_structure->{delete}}) {
	  delete $members->{$member};
	}
      }
    } else {

      croak "Cannot derive structure type '$name' from a non-structure '$source'\n";
    }
  } elsif ($derive->{sequence}) {
    if ($type->{sequence}) {
      my $derive_sequence = $derive->{sequence};
      my $target_sequence = $type->{sequence};
      if (exists $derive_sequence->{role}) {
	$target_sequence->{role} = $derive_sequence->{role};
	push @{$target_sequence->{-attributes}},'role'
	  unless grep { $_ eq 'role' } @{$target_sequence->{-attributes}};
      }
      if (exists $derive_sequence->{content_pattern}) {
        $target_sequence->{content_pattern} = $derive_sequence->{content_pattern};
        push @{$target_sequence->{-attributes}},'content_pattern'
	  unless grep { $_ eq 'content_pattern' } @{$target_sequence->{-attributes}};
      }
      $target_sequence->{element} ||= {};
      my $elements = $target_sequence->{element};
      while (my ($element,$value) = each %{$derive_sequence->{element}}) {
	$elements->{$element} = $target_sequence->copy_decl($value); # FIXME: no need if we remove derives in the end
      }
      if (ref $derive_sequence->{delete}) {
	for my $element (@{$derive_sequence->{delete}}) {
	  delete $elements->{$element};
	}
      }
    } else {
      require Data::Dumper;
#      print STDERR Data::Dumper::Dumper([$type]);
      croak "Cannot derive sequence type '$name' from a non-sequence '$source'\n";
    }
  } elsif ($derive->{container}) {
    if ($type->{container}) {
      my $derive_container = $derive->{container};
      my $target_container = $type->{container};
      for my $attr (qw(type role)) {
	next unless exists $derive_container->{$attr};
	if ($attr eq 'type' and !exists($target_container->{type})) {
	  foreach my $d (qw(list alt structure container sequence cdata)) {
	    if (exists $target_container->{$d}) {
	      delete $target_container->{$d};
	      last;
	    }
	  }
	  delete $target_container->{-decl};
	  delete $target_container->{-resolved};
	}
	$target_container->{$attr} = $derive_container->{$attr};
	push @{$target_container->{-attributes}},$attr
	  unless grep { $_ eq $attr } @{$target_container->{-attributes}};
      }
      $target_container->{attribute} ||= {};
      my $attributes = $target_container->{attribute};
      while (my ($attribute,$value) = each %{$derive_container->{attribute}}) {
	$attributes->{$attribute} = $target_container->copy_decl($value); # FIXME: no need if we remove derives in the end
      }
      if (ref $derive_container->{delete}) {
	for my $attribute (@{$derive_container->{delete}}) {
	  delete $attributes->{$attribute};
	}
      }
    } else {
      croak "Cannot derive a container '$name' from a different type '$source'\n";
    }
  } elsif ($derive->{choice}) {
    my $choice = $derive->{choice};
    if ($type->{choice}) {
      my (@add,%delete);
      if (UNIVERSAL::isa($choice,'HASH')) {
	@add = @{$choice->{values}} if ref $choice->{values};
	@delete{ @{$choice->{delete}} }=() if ref $choice->{delete};
      } else {
	@add = @$choice;
      }
      my %seen;
      @{$type->{choice}{values}} =
	grep { !($seen{$_}++) and ! exists $delete{$_} } (@{$type->{choice}{values}},@add);
    } else {
      croak "Cannot derive a choice type '$name' from a non-choice type '$source'\n";
    }
  } else {
    unless ($name ne $source) {
      croak "<derive type='$source'> has no effect in $schema->{URL}\n";
    }
  }
}

1;
__END__

=head1 NAME

Treex::PML::Schema::Derive - a class representing derive instructions in a Treex::PML::Schema

=head1 DESCRIPTION

This is an auxiliary class  representing derive instructions in a L<Treex::PML::Schema>.
Note that all derive instructions are removed from the schema during parsing.

=head1 METHODS

This class inherits from L<Treex::PML::Schema::Decl>.

=over 5

=item $decl->get_decl_type ()

Returns the value of the PML_DERIVE_DECL constant of L<Treex::PML::Schema>.

=item $decl->get_decl_type_str ()

Returns the string 'derive'.

=item $decl->simplify ()

Process the derive instruction.

=back

=head1 SEE ALSO

L<Treex::PML::Schema>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

