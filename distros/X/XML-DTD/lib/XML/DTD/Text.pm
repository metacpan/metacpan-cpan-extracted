package XML::DTD::Text;

use XML::DTD::Component;
use XML::DTD::Error;

use 5.008;
use strict;
use warnings;

our @ISA = qw(XML::DTD::Component);

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $txt = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    throw XML::DTD::Error("Constructor for XML::DTD::Textcalled ".
			  "with undefined text") if (! defined($txt));
    $self = { };
    bless $self, $cls;
    ##$txt =~ s/\n/<br\/>/sg;
    $self->define('wspace', $txt);
  }
  return $self;
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  my $tag = $self->{'CMPNTTYPE'};
  my $txt = $self->{'UNPARSEDTEXT'};
  my $tmp = $txt;
  $tmp =~ s/[^\n]//g;
  my $nlf = length($tmp);
  $txt =~ s/\n/\&\#xA;/g;
  $xmlw->open($tag, {'nlf' => $nlf});
  $xmlw->pcdata($txt);
  $xmlw->close;
}


1;
__END__

=head1 NAME

XML::DTD::Text - Perl module representing text (primarily whitespace) in a DTD

=head1 SYNOPSIS

  use XML::DTD::Text;

  my $txt = XML::DTD::Text->new('    ');

=head1 DESCRIPTION

  XML::DTD::Text is a Perl module representing text (primarily
  whitespace) in a DTD. The following methods are provided.


=over 4

=item B<new>

 my $txt = XML::DTD::Text->new('    ');

Construct a new XML::DTD::Text object.

=item B<writexml>

 $xo = new XML::Output({'fh' => *STDOUT});
 $txt->writexml($xo);

Write an XML representation of the text.

=back


=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Component>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=cut
