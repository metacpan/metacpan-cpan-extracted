package XML::DTD::AttDef;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $man = shift;
  my $name = shift;
  my $type = shift;
  my $dflt = shift;
  my $ws0 = shift;
  my $ws1 = shift;
  my $ws2 = shift;

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
    $self->_parse($man, $name, $type, $dflt, $ws0, $ws1, $ws2);
  }
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


# Write component-specific part of the XML representation
sub writexmlelts {
  my $self = shift;
  my $xmlw = shift;

  $xmlw->open('attdef', {'name' => $self->{'NAME'},
			 'ltws' => $self->{'WS0'}});
  $xmlw->open('atttype', {'ltws' => $self->{'WS1'}});
  $xmlw->pcdata($self->type);
  $xmlw->close;
  $xmlw->open('defaultdecl', {'ltws' => $self->{'WS2'}});
  $xmlw->pcdata($self->default);
  $xmlw->close;
  $xmlw->close;
}


# Return the attribute name
sub name {
  my $self = shift;

  return $self->{'NAME'};
}


# Return the attribute type
sub type {
  my $self = shift;

  return $self->{'ATTTYPE'};
}


# Return the attribute default declaration
sub default {
  my $self = shift;

  return $self->{'DEFAULTDECL'};
}


# Parse the element declaration
sub _parse {
  my $self = shift;
  my $entman = shift;
  my $name = shift;
  my $type = shift;
  my $dflt = shift;
  my $ws0 = shift;
  my $ws1 = shift;
  my $ws2 = shift;

  $name = $entman->peexpand($name)
    if ($name =~ /^%([\w\.:\-_]+);$/);

  $self->{'NAME'} = $name;
  $self->{'ATTTYPE'} = $type;
  $self->{'DEFAULTDECL'} = $dflt;
  $self->{'WS0'} = _lftoce($ws0);
  $self->{'WS1'} = _lftoce($ws1);
  $self->{'WS2'} = _lftoce($ws2);
}


# Substitute the &#xA; char entity for linefeeds
sub _lftoce {
  my $txt = shift;

  $txt =~ s/\n/\&\#xA;/g;
  return $txt;
}


1;
__END__

=head1 NAME

  XML::DTD::AttDef - Perl module representing the AttDef part of an
  ATTLIST declaration in an XML DTD.

=head1 SYNOPSIS

  use XML::DTD::AttDef;
  my $entman = XML::DTD::EntityManager->new;
  my $atd = XML::DTD::AttDef::new($entman,$name,$atttype,$defaultdecl);

=head1 DESCRIPTION

  XML::DTD::AttDef is a Perl module representing the AttDef part of an
  ATTLIST declaration in an XML DTD. The following methods are
  provided.

=over 4

=item B<new>

  $atd = new XML::DTD::AttDef($name,$atttype,$defaultdecl);

Construct a new XML::DTD::AttDef object.

=item B<isa>

  if (XML::DTD::AttDef->isa($atd)) {
  ...
  }

Test object type

=item B<writexmlelts>

 open(FH,'>file.xml');
 my $xo = new XML::Output({'fh' => *FH});
 $atd->writexmlelts($xo);

Write a component-specific part of the XML representation.

=item B<name>

 my $attname = $atd->name;

Return the attribute name.

=item B<type>

 my $atttype = $atd->type;

Return the attribute type.

=item B<default>

 my $atdflt = $atd->default;

Return the attribute default value.

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::AttList>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=head1 ACKNOWLEDGMENTS

Peter Lamb E<lt>Peter.Lamb@csiro.auE<gt> improved entity substitution.

=cut
