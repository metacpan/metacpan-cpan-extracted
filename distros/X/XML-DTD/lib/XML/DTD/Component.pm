package XML::DTD::Component;

use 5.008;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
  } else {
    # Called as the main constructor
    $self = { };
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


# Set the unparsed component text
sub define {
  my $self = shift;
  my $type = shift;
  my $text = shift;
  my $ltdl = shift;
  my $rtdl = shift;

  $self->{'CMPNTTYPE'} = $type;
  $self->{'UNPARSEDTEXT'} = $text;
  $text =~ s/^$ltdl// if defined ($ltdl);
  $text =~ s/$rtdl$// if defined ($rtdl);
  $self->{'WITHINDELIM'} = $text if (defined($ltdl) and defined ($rtdl));
}


# Get a string containing the unparsed component text
sub unparsed {
  my $self = shift;

  return $self->{'UNPARSEDTEXT'};
}


# Print the unparsed component text
sub fwrite {
  my $self = shift;
  my $fh = shift;

  print $fh $self->{'UNPARSEDTEXT'};
}


# Return the unparsed component text as a string
sub swrite {
  my $self = shift;

  return $self->{'UNPARSEDTEXT'};
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  my $tag = $self->{'CMPNTTYPE'};
  my $atr = $self->xmlattrib;
  $xmlw->open($tag, $atr);
  $xmlw->open('unparsed');
  if (defined($self->{'WITHINDELIM'})) {
    $xmlw->pcdata($self->{'WITHINDELIM'});
  } else {
    $xmlw->pcdata($self->{'UNPARSEDTEXT'});
  }
  $xmlw->close;
  $self->writexmlelts($xmlw);
  $xmlw->close;
}


# Return attributes for XML representation
sub xmlattrib {
  my $self = shift;

  return {};
}


# Write component-specific part of the XML representation
sub writexmlelts {
  my $self = shift;
  my $xmlw = shift;

}


1;
__END__

=head1 NAME

XML::DTD::Component - Perl module representing a component of an XML DTD

=head1 DESCRIPTION

  XML::DTD::Component is a Perl module representing a component of an
  XML DTD. It is intended to be a base class for derived classes, and
  should not itself be instantiated. The following methods are
  provided.

=over 4

=item B<new>

 $obj = new XML::DTD::Component;

=item B<isa>

 if (XML::DTD::Component->isa($obj) {
 ...
 }

Test object type

=item B<define>

 $obj->define('component type', 'component text', 'left delimiter',
              'right delimiter');

Set the component description

=item B<unparsed>

 $txt = $obj->unparsed;

 Get the unparsed component text

=item B<fwrite>

 open(FH,'>file.xml');
 $obj->fwrite(*FH);

Write the unparsed component text to the specified file handle

=item B<swrite>

 $obj->swrite;

Return the unparsed component text as a string

=item B<writexml>

 open(FH,'>file.xml');
 my $xo = new XML::Output({'fh' => *FH});
 $obj->writexml($xo);

Write an XML representation.

=item B<xmlattrib>

 $obj->xmlattrib;

Return a hash of attributes for XML representation

=item B<writexmlelts>

 open(FH,'>file.xml');
 my $xo = new XML::Output({'fh' => *FH});
 $obj->writexmlelts($xo);

Write a component-specific part of the XML representation

=back

=head1 SEE ALSO

L<XML::DTD>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
