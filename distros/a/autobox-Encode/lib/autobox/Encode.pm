package autobox::Encode;
use strict;
use warnings;
use base qw/autobox/;

our $VERSION = '0.03';

sub import {
    shift->SUPER::import( SCALAR => 'autobox::Encode::Scalar' );
}

package # hide from pause :-)
    autobox::Encode::Scalar;

use Encode ();
use charnames ();

sub encode { Encode::encode($_[1], $_[0], $_[2]) }
sub decode { Encode::decode($_[1], $_[0], $_[2]) }
sub is_utf8 { Encode::is_utf8($_[0]) }
sub from_to { Encode::from_to($_[0], $_[1], $_[2]); $_[0] }

sub charname {
    my $string = shift;
    join '', map charnames::viacode(ord), split //, $string;
}

1;

__END__

=head1 NAME

autobox::Encode - Encode with autobox

=head1 SYNOPSIS

  use autobox::Encode;

  "Foo"->decode('utf-8')->encode('utf-8')

  my $latin1_bytes = ...;
  my $utf8_bytes   = $latin1_bytes->from_to('latin-1' => 'utf-8');

  "\x{1234}"->charname; # "ETHIOPIC SYLLABLE SEE"

=head1 DESCRIPTION

use Encode with autobox!

=head1 AUTHOR

Tokuhiro Matsuno <tokuhirom gmail com>

=head1 THANKS

Tatsuhiko Miyagawa and coderepos committers.

chocolateboy++(enhancment autobox!!)

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
