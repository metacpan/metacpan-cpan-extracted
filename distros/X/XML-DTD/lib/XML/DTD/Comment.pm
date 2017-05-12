package XML::DTD::Comment;

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
  my $cmnt = shift;

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    throw XML::DTD::Error("Constructor for XML::DTD::Comment called ".
			  "with undefined comment string")
      if (! defined($cmnt));
    $self = { };
    bless $self, $cls;
    $self->define('comment', $cmnt, '<!--', '-->');
  }
  return $self;
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  my $tag = $self->{'CMPNTTYPE'};
  $xmlw->open($tag);
  $xmlw->pcdata($self->{'WITHINDELIM'}, {'subst' => {'&' => '&amp;'}});
  $xmlw->close;
}


1;
__END__

=head1 NAME

XML::DTD::Comment - Perl module representing a comment in a comment in a DTD

=head1 SYNOPSIS

  use XML::DTD::Comment;

  my $cmt = XML::DTD::Comment->new('<!-- A comment -->');

=head1 DESCRIPTION

XML::DTD::Comment is a Perl module representing a comment in a comment
in a DTD. The following methods are provided.

=over 4

=item B<new>

  my $cmt = XML::DTD::Comment->new('<!-- A comment -->');

Construct a new XML::DTD::Comment object.

=item B<writexml>

 open(FH,'>file.xml');
 my $xo = new XML::Output({'fh' => *FH});
 $cmt->writexml($xo);

Write an XML representation.

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
