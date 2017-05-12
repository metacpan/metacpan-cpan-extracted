package XML::DTD::Ignore;

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
  my $ign = shift;
  my $ilt = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    throw XML::DTD::Error("Constructor for XML::DTD::Ignore called ".
			  "with undefined ignore content")
      if (! defined($ign));
    $self = { };
    bless $self, $cls;
    $self->define('ignore', $ign);
    $self->{'IGNLT'} = $ilt;
    $self->{'WITHINDELIM'} = substr($ign, length($ilt),
				    length($ign)-length($ilt)-3);
  }
  return $self;
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  $xmlw->open('ignore', {'ltdlm' => $self->{'IGNLT'}});
  $xmlw->pcdata($self->{'WITHINDELIM'}, {'subst' => {"\n" => '&#xA;'}});
  $xmlw->close;
}


1;
__END__

=head1 NAME

XML::DTD::Ignore - Perl module representing an ignore section in a DTD

=head1 SYNOPSIS

  use XML::DTD::Ignore;

  my $ign = XML::DTD::Ignore->new('<![ IGNORE [  ignored text ]]>');

=head1 DESCRIPTION

XML::DTD::Ignore is a Perl module representing an ignore section in a
DTD. The following methods are provided.

=over 4

=item B<new>

 my $ign = XML::DTD::Ignore->new('<![ IGNORE [  ignored text ]]>');

Construct a new XML::DTD::Ignore object.

=item B<writexml>

 $xo = new XML::Output({'fh' => *STDOUT});
 $ign->writexml($xo);

Write an XML representation of the ignore section.

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
