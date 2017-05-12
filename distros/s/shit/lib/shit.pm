package shit;
{
  $shit::VERSION = '0.02';
}

#ABSTRACT: just use stuff

use strict;
use warnings;

sub import {
  warnings->import();
  strict->import();
}

sub unimport {
  strict->unimport();
  warnings->unimport();
}

q[for when it hits the fan];


__END__
=pod

=head1 NAME

shit - just use stuff

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use shit;

  no shit;

=head1 DESCRIPTION

Enables L<strict> and L<warnings> without all the typing.

To enable just C<use shit> in your script.

C<no shit> disables L<strict> and L<warnings>.

=begin Pod::Coverage

  import

  unimport

=end Pod::Coverage

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

