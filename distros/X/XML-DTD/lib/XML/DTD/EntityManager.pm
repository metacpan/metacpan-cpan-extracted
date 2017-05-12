package XML::DTD::EntityManager;

use XML::DTD::Error;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.09';

# Constructor
sub new {
  my $arg = shift;
  my $ent = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
  } else {
    # Called as the main constructor
    $self = { };
    $self->{'PARAMETER'} = { };
    $self->{'GENERAL'} = { };
  }
  bless $self, $cls;
  return $self;
}


# Determine whether object is of this type
sub isa {
  my $cls = shift;
  my $r = shift;

  if (defined($r) && ref($r) eq $cls) {
    return 1;
  } else {
    return 0;
  }
}


# Insert an entity
sub insert {
  my $self = shift;
  my $ent = shift;

  if ($ent->isparam) {
    $self->insertpe($ent);
  } else {
    $self->insertge($ent);
  }
}


# Insert a parameter entity declaration
sub insertpe {
  my $self = shift;
  my $pe = shift;

  my $name = $pe->name;
  if (defined($self->{'PARAMETER'}->{$name})) {
    return 0;
  } else {
    $self->{'PARAMETER'}->{$name} = $pe;
    return 1;
  }
}


# Lookup a parameter entity declaration
sub pevalue {
  my $self = shift;
  my $peref = shift;

  $peref = $1 if ($peref =~ /^%(.+);$/);
  my $ent = $self->{'PARAMETER'}->{$peref};
  if (defined $ent) {
    if ($ent->isextern) {
      # The value of an external entity is just itself
      return $ent->value;
    } else {
      # The value of an internal entity has character and
      # parameter entity expansion carried out on it
      return $self->entitysubst($ent->value);
    }
  } else {
    return undef;
  }
}

# Lookup a parameter entity declaration and return
# its expansion, otherwise return the peref
sub peexpand {
  my $self = shift;
  my $peref = shift;

  my $peval = $self->pevalue($peref);
  if (defined $peval) {
    $peref = $peval;
  } else {
    $peref = '%'.$peref.';';
  }
  return $peref;
}

# Lookup a parameter entity's containing URI
sub peuri {
  my $self = shift;
  my $peref = shift;

  $peref = $1 if ($peref =~ /^%(.+);$/);
  my $ent = $self->{'PARAMETER'}->{$peref};
  if (defined $ent) {
    return $ent->uri;
  } else {
    return undef;
  }
}


# Insert a general entity declaration
sub insertge {
  my $self = shift;
  my $ge = shift;

  my $name = $ge->name;
  if (defined($self->{'GENERAL'}->{$name})) {
    return 0;
  } else {
    $self->{'GENERAL'}->{$name} = $ge;
    return 1;
  }
}


# Lookup a general entity declaration
sub gevalue {
  my $self = shift;
  my $geref = shift;

  $geref = $1 if ($geref =~ /^\&(.+);$/);
  my $ent = $self->{'GENERAL'}->{$geref};
  if (defined $ent) {
    return $ent->value;
  } else {
    return undef;
  }
}


# Convert a character entity declaration
sub cevalue {
  my $self = shift;
  my $ceref = shift;

  $ceref = $1 if ($ceref =~ /^\&#(.+);$/);
  if ($ceref =~ /^x([0-9a-fA-F]+)$/) {
    return chr hex $1;
  } elsif ($ceref =~ /^[0-9]+$/) {
    return chr $ceref;
  } else {
    return undef;
  }
}


# Perform entity substitution in text
sub entitysubst {
  my $self = shift;
  my $txt = shift;
  my $gesf = shift; # Flag selecting substitution of general entity refs

  my $lt = '';
  my $rt = $txt;
  while($rt =~ /(?:(%|\&)([\w\.:\-_]+)|(?:\&#(([0-9]+)|(x[0-9a-fA-F]+))));/) {
    $rt = $';
    $lt .= $`;
    my ($type, $val);
    my $entv;
    if (defined $1) {
      # Entity ref or parameter ref
      ($type, $val) = ($1, $2);
      if ($type eq '%') {
	# Substitute parameter refs
        $entv = $self->pevalue($type.$val.';');
      } else {
	if ($gesf) {
	  $entv = $self->gevalue($type.$val.';');
	} else {
	  # Bypass entity ref
	  $entv = $type.$val.';';
	}
      }
    } else {
      # Character ref
      ($type, $val) = ('&', '#'.$3);
      $entv = $self->cevalue($type.$val.';');
    }
    if (defined $entv) {
      $lt .= $entv;
    } else {
      $lt .= $type.$val.';';
      throw XML::DTD::Error("Reference to undefined entity in string: $txt",
			    $self);
    }
  }
  $lt .= $rt;
  return $lt;
}


# Perform entity substitution in text
sub includeaspe {
  my $self = shift;
  my $txt = shift;

  my $lt = '';
  my $rt = $txt;
  while($rt =~ /(%[\w\.:\-_]+;)/) {
    $rt = $';
    $lt .= $`;
    my $entv;
    if (defined $1) {
	# Substitute parameter ref
        $entv = $self->pevalue($1);
    }
    if (defined $entv) {
      $lt .= ' '.$entv.' ';
    } else {
      $lt .= $1;
      throw XML::DTD::Error("Reference to undefined entity in string: $txt",
			    $self);
    }
  }
  $lt .= $rt;
  return $lt;
}


1;
__END__

=head1 NAME

XML::DTD::EntityManager - Perl module for managing entity declarations in a DTD

=head1 SYNOPSIS

  use XML::DTD::EntityManager;

  my $em = XML::DTD::EntityManager->new;

=head1 DESCRIPTION

XML::DTD::EntityManager is a Perl module for managing entity
declarations in a DTD. The following methods are provided.

=over 4

=item B<new>

 my $em = XML::DTD::EntityManager->new;

Construct a new XML::DTD::EntityManager object.

=item B<isa>

 if (XML::DTD::EntityManager->isa($obj) {
 ...
 }

Test object type.

=item B<insert>

 my $ent = XML::DTD::Entity->new('<!ENTITY a "b">');
 $em->insert($ent);

Insert an entity declaration. This method is a wrapper which
determines the type of entity and calls insertpe or insertge as
appropriate.

=item B<insertpe>

 my $ent = XML::DTD::Entity->new('<!ENTITY % a "b">');
 $em->insertpe($ent);

Insert a parameter entity declaration.

=item B<pevalue>

 my $val = $em->pevalue('%a;');

Lookup a parameter entity value.  Recursively expands internal
parameter and character entity references.  Leaves general entity
references unmodified.

May also be called as:

 my $val = $em->pevalue('a');

with the same effect.

=item B<insertge>

 my $ent = XML::DTD::Entity->new('<!ENTITY a "b">');
 $em->insertge($ent);

Insert a general entity declaration.

=item B<gevalue>

 my $val = $em->gevalue('&a;');

Lookup a general entity value.

May also be called as:

 my $val = $em->gevalue('a');

with the same effect.

=item B<cevalue>

 my $txt = $em->cevalue('&#x3c;');

Convert a character entity declaration. The example returns the
character C<< < >>.

May also be called as:

 my $val = $em->peexpand('x3c');

with the same effect.

=item B<peexpand>

 my $val = $em->peexpand('%a;');

Lookup a parameter entity declaration and return its expansion as in
L<pevalue> if it exists, otherwise return the peref.

May also be called as:

 my $val = $em->peexpand('a');

with the same effect. Note: returns C<%a;> if there is no definition
of C<a>, even if called in this form.

=item B<entitysubst>

 my $txt = $em->entitysubst('abc &a; def');

Perform entity substitution in text.  Recursively expands internal
parameter and character entity references.  Leaves general entity
references unmodified.

For details see sections I<4.4 XML Processor Treatment of Entities and
References> (L<http://www.w3.org/TR/2006/REC-xml-20060816/#entproc>)
and I<4.5 Construction of Entity Replacement Text>
(L<http://www.w3.org/TR/2006/REC-xml-20060816/#intern-replacement>) in
I<Extensible Markup Language (XML) 1.0 (Fourth Edition)>
(L<http://www.w3.org/TR/2006/REC-xml-20060816/>)

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Entity>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=head1 ACKNOWLEDGMENTS

Peter Lamb E<lt>Peter.Lamb@csiro.auE<gt> added fetching of external
entities and improved entity substitution.

=cut
