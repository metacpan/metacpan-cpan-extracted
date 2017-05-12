package XML::DTD::AttList;

use XML::DTD::Component;
use XML::DTD::AttDef;
use XML::DTD::Error;

use 5.008;
use strict;
use warnings;

our @ISA = qw(XML::DTD::Component);

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $man = shift;
  my $att = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    $self = { };
    bless $self, $cls;
    $self->define('attlist', $att, '<!ATTLIST', '>');
    $self->_parse($man, $att);
  }
  return $self;
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  my $ws1 = (defined($self->{'WS1'}) and $self->{'WS1'} ne '')?
    $self->{'WS1'}:undef;
  $xmlw->open('attlist', {'name' => $self->{'NAME'},
			  'ltws' => $self->{'WS0'},
			  'rtws' => $ws1});
  $xmlw->open('attdefs');
  my $c;
  foreach $c ( @{$self->{'ATTNAMES'}} ) {
    $self->{'ATTDEFS'}->{$c}->writexmlelts($xmlw);
  }
  $xmlw->close;
  $xmlw->close;
}


# Return the attribute list name
sub name {
  my $self = shift;

  return $self->{'NAME'};
}


# Return a list of attribute names
sub attribnames {
  my $self = shift;

  return $self->{'ATTNAMES'};
}


# Return the attribute definition object for the named attribute
sub attribute {
  my $self = shift;
  my $name = shift;

  return $self->{'ATTDEFS'}->{$name};
}

# Merge another attribute list's attribute declarations with this one's.
# Where the same attribute name is declared in both, keep the one already
# in $self
sub merge {
  my $self = shift;
  my $attlst = shift;
  foreach my $aname (@{$attlst->attribnames}) {
    if (!exists $self->{'ATTDEFS'}{$aname}) {
      push @{$self->{'ATTNAMES'}}, $aname;
      $self->{'ATTDEFS'}->{$aname} = $attlst->attribute($aname);
    }
  }
}

# Parse the element declaration
sub _parse {
  my $self = shift;
  my $entman = shift;
  my $attlst = shift;

  if ($attlst =~ /<\!ATTLIST(\s+)([\w\.:\-_]+|%[\w\.:\-_]+;)(\s+.+)>/s) {
    $self->{'WS0'} = $1;
    my $name = $2;
    my $attdefs = $3;

    $name = $entman->peexpand($name)
      if ($name =~ /^%([\w\.:\-_]+);$/);

    $attdefs = $entman->includeaspe($attdefs);

    $self->{'NAME'} = $name;
    $self->{'ATTNAMES'} = [];
    $self->{'ATTDEFS'} = {};
    my ($aname,$atype,$dflt,$ws0,$ws1,$ws2);
    while ($attdefs =~ /^(\s+)([\w\.:\-_]+)(\s+)([\w\.:\-_]+|\'[^\']+\'|\"[^\"]+\"|\([^\(\)]+\))(\s+)(\#REQUIRED|\#IMPLIED|(?:(\#FIXED\s+)([\w\.:\-_]+|\'[^\']+\'|\"[^\"]+\"))|(\'[^\']*\'|\"[^\"]*\"))/s) {
      $ws0 = $1;
      $aname = $2;
      $ws1 = $3;
      $atype = $4;
      $ws2 = $5;
      $dflt = $6;

      # Only do substitutions on the default attribute values.
      if (defined $7) {
      	$dflt = $7;
	my $attval = $8;
        $dflt = $dflt . $entman->entitysubst($attval, 1);
      } elsif (defined $9) {
	my $attval = $9;
        $dflt = $entman->entitysubst($attval, 1);
      }

      $attdefs = $';
      # The first declaration is binding
      if (!exists($self->{'ATTDEFS'}->{$aname})) {
        push @{$self->{'ATTNAMES'}}, $aname;
	$self->{'ATTDEFS'}->{$aname} =
               XML::DTD::AttDef->new($entman, $aname, $atype, $dflt, $ws0,
                                     $ws1, $ws2);
      }
    }
    if ($attdefs =~ /^\s*$/) {
      $self->{'WS1'} = $attdefs;
    } else {
      throw XML::DTD::Error("Some ATTLIST text could not be parsed: ".
			    $attdefs, $self)
	if ($attdefs !~ /^\w*$/);
    }
  } else {
    throw XML::DTD::Error("Error parsing ATTLIST name and definitions ".
			  "in: $attlst", $self);
  }
}


1;
__END__

=head1 NAME

XML::DTD::AttList - Perl module representing an ATTLIST declaration in
an XML DTD.

=head1 SYNOPSIS

  use XML::DTD::AttList;
  my $entman = XML::DTD::EntityManager->new;
  my $att = XML::DTD::AttList::new($entman, '<!ATTLIST a b CDATA #IMPLIED>');

=head1 DESCRIPTION

  XML::DTD::AttList is a Perl module representing an ATTLIST
  declaration in an XML DTD. The following methods are provided.

=over 4

=item B<new>

  $entman = XML::DTD::EntityManager->new;
  $attlist = new XML::DTD::AttList($entman, '<!ATTLIST a b CDATA #IMPLIED>');

  Constructs a new XML::DTD::AttList object.

=item B<writexml>

  $xo = new XML::Output({'fh' => *STDOUT});
  $attlist->writexml($xo);

Write an XML representation of the attribute list.

=item B<name>

  $eltname = $attlist->name();

Return the name of the element with which the attribute list is associated.

=item B<attribnames>

  $nmlst = $attlist->attribnames;

Return an array of attribute names (associated with a specific
element) as an array reference.

=item B<attribute>

  $attdefobj = $attlist->attribute('attribname');

Return the attribution definition object (of type XML::DTD::AttDef)
associated with the specified name.

=item B<merge>

  $attlist->merge($otherattlist);

Merge another attribute list's attribute declarations with this one's.
Where the same attribute name is declared in both, keep the one already
in <$attlist>.

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Component>, L<XML::DTD::AttDef>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=head1 ACKNOWLEDGMENTS

Peter Lamb E<lt>Peter.Lamb@csiro.auE<gt> improved entity substitution
and corrected handling of multiple declarations of attributes for the
same element.

=cut
