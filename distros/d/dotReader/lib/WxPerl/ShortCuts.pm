package WxPerl::ShortCuts;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

BEGIN {
  require Exporter;
  *{import} = \&Exporter::import;
  our @EXPORT = qw(
    WX TE BT SP TR
    Def DefP DefS DefPS
    Exp Ams wV wH
  );
}

use Wx ();

=head1 NAME

WxPerl::ShortCuts - shorter constants

=head1 SYNOPSIS

As an alternative to 'use Wx qw(:everything)', this module exports a
handful of methods into your namespace which act as shorthand for
several wxFOO constants.

=cut

=head1 Prefixes

=head2 WX

  WX'FOO';
  WX('FOO');

Returns Wx::wxFOO().  Multiple suffixes can be joined with '|' symbols.

  WX('FOO|BAR');

Returns Wx::wxFOO() | Wx::wxBAR().

=cut

sub WX ($) {_mk_constant('Wx::wx', shift);}

=head2 TE

Wx::wxTE_*

  TE'FOO';

=cut

sub TE ($) {_mk_constant('Wx::wxTE_', shift);}

=head2 BT

Wx::wxBITMAP_TYPE_*

  BT'ANY';

=cut

sub BT ($) {_mk_constant('Wx::wxBITMAP_TYPE_', shift);}

=head2 SP

Wx::wxSP_*

=cut

sub SP ($) {_mk_constant('Wx::wxSP_', shift);}

=head2 TR

Wx::wxTR_*

=cut

sub TR ($) {_mk_constant('Wx::wxTR_', shift);}

=head1 Other Shortcuts

=head2 Def

  wxDEFAULT

=head2 DefP

  wxDefaultPosition

=head2 DefS

  wxDefaultSize

=head2 DefPS

Returns a list of two values.

  wxDefaultPosition, wxDefaultSize

=cut

use constant Def  => Wx::wxDEFAULT();
use constant DefP => Wx::wxDefaultPosition();
use constant DefS => Wx::wxDefaultSize();
use constant DefPS => Wx::wxDefaultPosition(), Wx::wxDefaultSize();
use constant Ams => Wx::wxADJUST_MINSIZE();
use constant Exp => Wx::wxEXPAND();
use constant wV => Wx::wxVERTICAL();
use constant wH => Wx::wxHORIZONTAL();

# NOTE EVT->NAME_OF_EVENT($obj, λ{foo()});, though that should maybe be
# an AUTOLOAD in the WxPerl::SelfServe package.

=head1 GUTS

=head2 _mk_constant

  my $const = _mk_constant($prefix, $string);

=cut

sub _mk_constant {
  my ($p, $string) = @_;
  my $val = 0;
  foreach my $part (split(/\|/, $string)) {
    $val |= get_constant($p . $part);
  }
  return($val);
} # end subroutine _mk_constant definition
########################################################################

=head2 get_constant

Expects a fully qualified subname such as 'Wx::wxALIGN_RIGHT'.

  my $const = get_constant($name);

=cut

sub get_constant {
  my ($name) = @_;
  $name =~ m/^Wx::[0-9A-Za-z:_]+$/ or croak("invalid constant '$name'");
  # TODO cache?
  my $v = eval("$name()");
  $@ and croak("no such constant: '$name'");
  return($v);
} # end subroutine get_constant definition
########################################################################




=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

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

# vi:ts=2:sw=2:et:sta
1;
