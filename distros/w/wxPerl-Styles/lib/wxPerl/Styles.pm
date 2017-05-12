package wxPerl::Styles;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

# hmm, might as well depend on it, though caller probably does already
use Wx ();
# or do this at runtime:
#   croak("you need to require Wx first") unless(Wx->VERSION);

=head1 NAME

wxPerl::Styles - shortcuts for wxFOO style constants

=head1 SYNOPSIS

This package encapsulates stringwise access to wxPerl constants,
primarily for use in specifying styles, but also for comparing
constants.

  use Wx qw(
    ALIGN_RIGHT
  );
  ... wxALIGN_RIGHT ... ;

Becomes:

  use Wx ();
  use wxPerl::Styles 'wxVal';
  ... wxVal('align_right') ... ;

Names will be uppercased automatically.

When using wxPerl::Constructors, style is always a named parameter, so
this gives you the 'style => ...' bit:

  use Wx ();
  use wxPerl::Constructors;
  use wxPerl::Styles 'style';
  ...

  my $text_ctrl = wxPerl::TextCtrl->new($self, 'some text here',
    style('hscroll', te => 'process_enter|multiline')
  );

=head1 NOTE

This does delay typo errors until run-time, but widget-construction is
pretty close to compile time, and the error messages are likely to be
more informative than 'syntax error'.  Also, I think that's a small
price to pay for not having all of those extra methods kicking around in
your class.

=cut

BEGIN {
  require Exporter;
  *{import} = \&Exporter::import;
  our @EXPORT_OK = qw(
    style
    wxVal
    ID
  );
}


=head2 wxVal

  my $style = wxVal('align_right',
    te => 'PROCESS_ENTER|MULTILINE'
  );

=cut

sub wxVal {
  my $bare;
  if(@_ % 2) {
    $bare = shift(@_);
  }
  my (%args) = @_;

  my $val = defined($bare) ? _mk_constant('', $bare) : 0;
  foreach my $key (keys(%args)) {
    $val |= _mk_constant(uc($key) . '_', $args{$key});
  }
  return($val);
} # end subroutine wxVal definition
########################################################################

=head2 style

Same as wxVal(), but returns (style => $style) for use with
wxPerl::Constructors named parameter lists.

  my %param = style(@list);

=cut

sub style {
  return(style => wxVal(@_));
} # end subroutine style definition
########################################################################

=head2 ID

Hash-parameter shortcut for 'id => Wx::wxID_OK()' and etc.

  my %param = ID('ok');

=cut

sub ID ($) {
  my ($val, @and) = @_;
  @and and croak("too many arguments for ID");
  return(id => wxVal(id => $val));
} # end subroutine ID definition
########################################################################

=head2 _mk_constant

  my $const = _mk_constant($prefix, $string);

=cut

sub _mk_constant {
  my ($p, $string) = @_;
  my $val = 0;
  foreach my $part (split(/\|/, uc($string))) {
    $val |= _get_constant($p . $part);
  }
  return($val);
} # end subroutine _mk_constant definition
########################################################################

=head2 _get_constant

Expects a fully qualified subname such as 'Wx::wxALIGN_RIGHT'.

  my $const = _get_constant($name);

=cut

my %cache;
sub _get_constant {
  my ($name) = @_;

  exists($cache{$name}) and return($cache{$name});

  $name =~ m/^[A-Z][0-9A-Z_]+$/ or croak("invalid constant '$name'");
  my $v = eval("Wx::wx$name()");
  $@ and croak("no such constant: '$name'");
  return($cache{$name} = $v);
} # end subroutine _get_constant definition
########################################################################

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

# vi:ts=2:sw=2:et:sta
1;
