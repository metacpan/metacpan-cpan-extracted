package XML::DTD::PI;

use XML::DTD::Component;

use 5.008;
use strict;
use warnings;

our @ISA = qw(XML::DTD::Component);

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $pi = shift;

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
    $self->define('pi', $pi, '<\?', '\?>');
  }
  return $self;
}


1;
__END__

=head1 NAME

XML::DTD::PI - Perl module representing a processing instruction in a DTD

=head1 SYNOPSIS

  use XML::DTD::PI;

  my $pi = XML::DTD::PI->new('example pi');

=head1 DESCRIPTION

  XML::DTD::PI is a Perl module representing a processing instruction
  in a DTD. The following methods are provided.

=over 4

=item B<new>

 my $pi = XML::DTD::PI->new('<?example pi?>');

Construct a new XML::DTD::PI object.

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
