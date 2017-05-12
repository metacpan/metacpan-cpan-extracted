package XML::DTD::Include;

use XML::DTD::Parser;
use XML::DTD::AttList;
use XML::DTD::Comment;
use XML::DTD::Element;
use XML::DTD::Entity;
use XML::DTD::Ignore;
use XML::DTD::Notation;
use XML::DTD::PERef;
use XML::DTD::PI;
use XML::DTD::Text;

use 5.008;
use strict;
use warnings;

our @ISA = qw(XML::DTD::Parser);

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $ent = shift;
  my $ilt = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
  } else {
    # Called as the main constructor
    $self = { };
    $self->{'ALL'} = [];
    $self->{'ENTMAN'} = $ent;
    $self->{'INCFLAG'} = 1;
    $self->{'INCLT'} = $ilt;
    $self->{'INCRT'} = ']]>';
  }
  bless $self, $cls;
  return $self;
}


# Print the include section
sub fwrite {
  my $self = shift;
  my $fh = shift;

  print $fh $self->{'INCLT'};
  my $c;
  foreach $c ( @{$self->{'ALL'}} ) {
    $c->fwrite($fh);
  }
  print $fh $self->{'INCRT'};
}


# Return a string containing the include section
sub swrite {
  my $self = shift;

  my $str = $self->{'INCLT'};
  my $c;
  foreach $c ( @{$self->{'ALL'}} ) {
    $str .= $c->swrite();
  }
  $str .= $self->{'INCRT'};
  return $str;
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  $xmlw->open('include', {'ltdlm' => $self->{'INCLT'}});
  my $c;
  foreach $c ( @{$self->{'ALL'}} ) {
    $c->writexml($xmlw);
  }
  $xmlw->close;
}


1;
__END__

=head1 NAME

XML::DTD::Include - Perl module representing an include section in a DTD

=head1 SYNOPSIS

  use XML::DTD::Include;

  my $inc = XML::DTD::Include->new('<![ INCLUDE [');
  $inc->parse($fh, $rt);

=head1 DESCRIPTION

  XML::DTD::Include is a Perl module representing an include section
  in a DTD. The following methods are provided.

=over 4

=item B<new>

 my $inc = XML::DTD::Include->new('<![ INCLUDE [');
 $inc->parse($fh, $rt);

Construct a new XML::DTD::Include object.

=item B<fwrite>

 open(FH,'>file.xml');
 $inc->fwrite(*FH);

Write the include section to the specified file handle.

=item B<swrite>

 $inc->swrite;

Return the include section as a string.

=item B<writexml>

 $xo = new XML::Output({'fh' => *STDOUT});
 $inc->writexml($xo);

Write an XML representation of the include section.

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Parser>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
