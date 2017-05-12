package lambda;
$VERSION = v0.0.1;

use warnings;
use strict;

=encoding utf8

=head1 NAME

lambda - a shortcut for sub {...}

=head1 SYNOPSIS

Instead of:

  my $code = sub {...};

Just:

  my $code = λ{...};

Note: If your perldoc (or terminal (or browser)) isn't properly
rendering unicode, the above looks like an 'I' followed by a double
arrow (or maybe just an 'X'.)  It is a unicode lowercase lambda (0x3BB.)

=head1 utf8

This module has import() and unimport() methods which mimic utf8.pm.
Thus, instead of saying 'C<use utf8; use lambda;>', you can simply say
'C<use lambda;>'.

The caveat to this is that 'C<no lambda;>' also means 'C<no utf8;>'.  I
blame C<$^H> (suggestions welcome, and yes 5.10 might require this to
change.)

=head1 VIM SHORTCUT

My .vimrc has:

  imap <C-S-L> λ{}<ESC>:set encoding=utf8<CR>i

In insert mode (only), this types the lambda and matching braces, sets
the encoding, then puts your cursor between the braces.

=cut

use utf8;

sub import {
  $^H |= $utf8::hint_bits;
  my $callpkg = caller();
  no strict 'refs';
  *{$callpkg . '::' . 'λ'} = sub (&) {$_[0]};
}

sub unimport {
  $^H &= ~$utf8::hint_bits;
  my $callpkg = caller();
  no strict 'refs';
  delete ${$callpkg . '::'}{'λ'};
}

=head1 Methods

=head2 import

Puts λ in your symbol table, turns on utf8 parsing.

=head2 unimport

Removes λ from your symbol table, turns off utf8 parsing.

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta:encoding=utf8
1;
