package XML::DTD::Element;

use XML::DTD::Component;
use XML::DTD::ContentModel;
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
  my $elt = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    throw XML::DTD::Error("Constructor for XML::DTD::Element called ".
			  "with undefined element string")
      if (! defined($elt));
    $self = { };
    bless $self, $cls;
    $self->define('element', $elt, '<!ELEMENT', '>');
    $self->_parse($man, $elt);
  }
  return $self;
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  $xmlw->open('element', {'name' => $self->{'NAME'},
			  'ltws' => $self->{'WS0'}});
  my $ws2 = (defined($self->{'WS2'}) and $self->{'WS2'} ne '')?
    $self->{'WS2'}:undef;
  my $ws = {'ltws' => $self->{'WS1'}, 'rtws' => $ws2};
  $xmlw->open('contentspec', $ws);
  $xmlw->pcdata($self->{'CONTENTSPECTEXT'});
  $xmlw->close;
  $self->{'CONTENTSPEC'}->writexmlelts($xmlw);
  $xmlw->close;
}


# Return the element name
sub name {
  my $self = shift;

  return $self->{'NAME'};
}


# Return the content specification text
sub contentspec {
  my $self = shift;

  return $self->{'CONTENTSPECTEXT'};
}


# Return the parsed content specification as a content model object reference
sub contentmodel {
  my $self = shift;

  return $self->{'CONTENTSPEC'};
}


# Parse the element declaration
sub _parse {
  my $self = shift;
  my $entman = shift;
  my $eltdcl = shift;

  if ($eltdcl=~/<\!ELEMENT(\s+)([\w\.:\-_]+|%[\w\.:\-_]+;)(\s+)(.+)(\s*)>/s) {
    $self->{'WS0'} = $1;
    my $name = $2;
    $self->{'WS1'} = $3;
    my $cntspc = $4;
    $self->{'WS2'} = $5;

    $name = $entman->peexpand($name)
      if ($name =~ /^%([\w\.:\-_]+);$/);

    $self->{'NAME'} = $name;

    $self->{'CONTENTSPECTEXT'} = $cntspc;
    $self->{'CONTENTSPEC'} = XML::DTD::ContentModel->new($cntspc, $entman);
  } else {
    throw XML::DTD::Error("Error parsing element name and contentspec string ".
			  $eltdcl, $self);
  }
}


1;
__END__

=head1 NAME

XML::DTD::Element - Perl module representing an element declaration in a DTD

=head1 SYNOPSIS

  use XML::DTD::Element;

  my $entman = XML::DTD::EntityManager->new;
  my $elt = XML::DTD::Element->new($entman, '<!ELEMENT a (#PCDATA)>');

=head1 DESCRIPTION

XML::DTD::Element is a Perl module representing an element declaration
in a DTD.

=over 4

=item B<new>

  $entman = XML::DTD::EntityManager->new;
  $elt = new XML::DTD::Element($entman, '<!ELEMENT a (b?,c)>');

Constructs a new XML::DTD::Element object.

=item B<writexml>

  $xo = new XML::Output({'fh' => *STDOUT});
  $elt->writexml($xo);

Write an XML representation of the element.

=item B<name>

  $eltname = $elt->name;

Return the name of the element.

=item B<contentspec>

  print $elt->contentspec;

Return the content specification text. Note that this is the literal
text of the specification in the DTD, without any entity expansion.

=item B<contentmodel>

  $cm = $elt->contentmodel;

Return the parsed content specification as a content model object
reference. If a string representation of the parsed content model
with entities expanded is desired, use

  $cs = $elt->contentmodel->string;

=back


=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Component>, L<XML::DTD::ContentModel>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=head1 ACKNOWLEDGMENTS

Peter Lamb E<lt>Peter.Lamb@csiro.auE<gt> improved entity substitution.

=cut
