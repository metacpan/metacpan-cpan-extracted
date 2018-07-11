package XAO::PageSupport;
require 5.010;
use strict;
use warnings;

require DynaLoader;

our $VERSION = 2.3;
our @ISA = qw(DynaLoader);

bootstrap XAO::PageSupport $VERSION;

1;
__END__

=head1 NAME

XAO::PageSupport - Fast text collection for XAO::Objects::Page

=head1 SYNOPSIS

  use XAO::PageSupport;

=head1 DESCRIPTION

This is very specific module oriented to support fast text adding
for XAO displaying engine. Helps a lot with template processing,
especially when template splits into thousands or even milions of
pieces.

The idea is to have one long buffer that extends automatically and a
stack of positions in it that can be pushed/popped when application
need new portion of text.

=head2 EXPORT

None.

=head1 AUTHOR

Andrew Maltsev, <amaltsev@valinux.com>

=head1 SEE ALSO

perl(1).

=cut
