package Treex::PML::Schema::Copy;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.22'; # version template
}
no warnings 'uninitialized';
use Carp;
use Treex::PML::Schema::Constants;
use List::Util qw(first);
use base qw(Treex::PML::Schema::XMLNode);

sub get_decl_type     { return(PML_COPY_DECL); }
sub get_decl_type_str { return('copy'); }

sub simplify {
  my ($copy,$opts)=@_;
  return if $opts->{no_copy};
  my $template_name = $copy->{template};
  my $owner = _lookup_upwards($copy->{-parent},'template',$template_name);
  unless ($owner) {
    die "Could not find template $template_name\n";
    return;
  }
  my $template = $owner->{template}{$template_name};
#  print STDERR "Copying $copy->{template} as $copy->{prefix}\n";

  if (ref $template->{type}) {
    my $parent = $copy->{-parent};
    my $prefix = $copy->{prefix} || '';
    $parent->{type}||={};
    my (@new_types, @new_templates);
    foreach my $t (values(%{$template->{type}})) {
      my $new = $template->copy_decl($t);
      _apply_prefix($copy,$template,$prefix,$new);
      my $new2 = $parent->copy_decl($new);
      push @new_types, $new2;
    }
    foreach my $t (values(%{$template->{template}})) {
      my $new = $template->copy_decl($t);
      _apply_prefix($copy,$template,$prefix,$new);
      my $new2 = $parent->copy_decl($new);
      push @new_templates, $new2;
    }
    for my $t (@new_types) {
      my $name = $prefix.$t->{-name};
      die "Type $name copied from $template_name already exists\n" if
	exists $parent->{type}{$name}
	  or (exists $parent->{derive}{$name}
		and $parent->{derive}{$name}{type} ne $name)
	  or exists $parent->{param}{$name};
#      print STDERR "copying type $name into \n";
      $t->{-name}=$name;
      $parent->{type}{$name}=$t;
    }
    for my $t (@new_templates) {
      my $name = $prefix.$t->{-name};
      die "Template $name copied from $template_name already exists\n" if
	exists $parent->{template}{$name};
#      print STDERR "copying template $name\n";
      $t->{-name}=$name;
      $parent->{template}{$name}=$t;
    }
  }
}
# traverse declarations as long as there is one
# containing a hash key $what or one occurring in an array-ref $what
# with a Hash value containing the key $name
sub _lookup_upwards {
  my ($parent, $what, $name)=@_;
  if (ref($what) eq 'ARRAY') {
    while ($parent) {
      return $parent if
	first { (ref($parent->{$_}) eq 'HASH') and exists($parent->{$_}{$name}) } @$what;
      $parent = $parent->{-parent};
    }
  } else {
    while ($parent) {
      return $parent if (ref($parent->{$what}) eq 'HASH') and exists($parent->{$what}{$name});
      $parent = $parent->{-parent};
    }
  }
  return;
}

sub _apply_prefix {
  my ($copy,$template,$prefix,$type) = @_;
  if (ref($type)) {
    if (UNIVERSAL::isa($type,'HASH')) {
      if (exists($type->{-name}) and $type->{-name} eq 'template') {
	# hopefully a template
	if ($type->{type}) {
	  _apply_prefix($copy,$template,$prefix,$_) for (values %{$type->{type}});
	}
	return;
      }
      my $ref = $type->{type};
      if (defined($ref) and length($ref)) {
	my $owner = _lookup_upwards($type->{-parent},['type','derive','param'],$ref);
	if (defined $owner and $owner==$template) {
	  # the type is defined exactly on the level of the template
	  if (exists $copy->{let}{$ref}) {
	    my $let = $copy->{let}{$ref};
	    if ($let->{type}) {
	      $type->{type}=$let->{type}
	    } else {
	      delete $type->{type};
	      foreach my $d (qw(list alt structure container sequence cdata choice constant)) {
		if (exists $type->{$d}) {
		  delete $type->{$d};
		  last;
		}
	      }
	      delete $type->{-decl};
	      delete $type->{-resolved};
	      foreach my $d (qw(list alt structure container sequence cdata choice constant)) {
		if (exists $let->{$d}) {
		  $type->{$d} = $type->copy_decl($let->{$d});
		  $type->{-decl}=$d;
		  last;
		}
	      }
	    }
	  } else {
	    $type->{type} = $prefix.$ref; # do apply prefix
	  }
	} else {
	  $type->{type} = $prefix.$ref; # do apply prefix
	}
      }
      # traverse descendant type declarations
      for my $d (qw(member attribute element)) {
	if (ref($type->{$d})) {
	  _apply_prefix($copy,$template,$prefix,$_) for (values %{$type->{$d}});
	  return;
	}
      }
      for my $d (qw(list alt structure container sequence)) {
	if (ref($type->{$d})) {
	  _apply_prefix($copy,$template,$prefix,$type->{$d});
	  return;
	}
      }
    }
  } elsif (UNIVERSAL::isa($type,'ARRAY')) {
    foreach my $d (@$type) {
      _apply_prefix($copy,$template,$prefix,$d);
    }
  }
}


1;
__END__

=head1 NAME

Treex::PML::Schema::Copy - a class representing copy instructions in a Treex::PML::Schema

=head1 DESCRIPTION

This is an auxiliary class  representing copy instructions in a Treex::PML::Schema.
Note that all copy instructions are removed from the schema during parsing.

=head1 METHODS

=over 5

=item $decl->get_decl_type ()

Returns the constant PML_COPY_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'copy'.

=item $decl->simplify ()

Process the copy instruction by.

=back

=head1 SEE ALSO

L<Treex::PML::Schema>, L<Treex::PML::Schema::Template>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
