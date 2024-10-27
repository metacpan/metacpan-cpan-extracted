package builtin::compat;
use strict;
use warnings;

our $VERSION = '0.003003';
$VERSION =~ tr/_//d;

use namespace::clean ();

sub true ();
sub false ();
sub is_bool ($);
sub inf ();
sub nan ();
sub weaken ($);
sub unweaken ($);
sub is_weak ($);
sub blessed ($);
sub refaddr ($);
sub reftype ($);
sub created_as_string ($);
sub created_as_number ($);
sub stringify ($);
sub ceil ($);
sub floor ($);
sub trim ($);
sub indexed (@);
sub load_module ($);

BEGIN { eval { require builtin } }
{
  package #hide
    experimental::builtin;
  if(!$warnings::Offsets{+__PACKAGE__}) {
    require warnings::register;
    warnings::register->import;
  }
}

my @fb = (
  true      => 'sub true () { !!1 }',
  false     => 'sub false () { !!0 }',
  is_bool   => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
use Scalar::Util ();
sub is_bool ($) {
  my $value = shift;

  return (
    defined $value
    && !length ref $value
    && Scalar::Util::isdual($value)
    && (
      $value
        ? ( $value == 1 && $value eq '1' )
        : ( $value == 0 && $value eq ''  )
    )
  );
}
END_CODE
  inf       => 'sub inf () { 9**9**9**9 }',
  nan       => 'sub nan () { 9**9**9**9*0 }',
  weaken    => \'Scalar::Util::weaken',
  unweaken  => \'Scalar::Util::unweaken',
  is_weak   => \'Scalar::Util::isweak',
  blessed   => \'Scalar::Util::blessed',
  refaddr   => \'Scalar::Util::refaddr',
  reftype   => \'Scalar::Util::reftype',
  created_as_number => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
sub created_as_number ($) {
  my $value = shift;

  no warnings 'numeric';
  return (
    defined $value
    && !length ref $value
    && !is_bool($value)
    && !utf8::is_utf8($value)
    && length( (my $dummy = '') & $value )
    && 0 + $value eq $value
  );
}

END_CODE
  created_as_string => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
sub created_as_string ($) {
  my $value = shift;

  return (
    defined $value
    && !length ref $value
    && !is_bool($value)
    && !created_as_number($value)
  );
}
END_CODE
  stringify => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
sub stringify ($) {
  "$_[0]"
}
END_CODE
  ceil      => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
use POSIX ();
sub ceil ($) {
  goto &POSIX::ceil;
}
END_CODE
  floor     => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
use POSIX ();
sub floor ($) {
  goto &POSIX::floor;
}
END_CODE
  trim      => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
sub trim ($) {
  my $string = shift;
  s/\A\s+//, s/\s+\z// for $string;
  return $string;
}
END_CODE
  indexed   => sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE',
sub indexed (@) {
  my $i = 0;
  map +($i++, $_), @_;
}
END_CODE
  is_tainted => \'Scalar::Util::tainted',
  load_module => ( ( "$]" < 5.011 && !("$]" >= 5.009004 && "$]" < 5.010001) )
    ? sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE'
sub builtin::compat::load_module::__GUARD__::DESTROY {
  delete $INC{$_[0]->[0]} if @{$_[0]};
}

sub load_module ($) {
  my $module = $_[0];
  (my $file = $module) =~ s{::}{/}g;
  $file .= ".pm";

  local %^H;
  my $guard = bless [ $file ], 'builtin::compat::load_module::__GUARD__';
  CORE::require($file);
  pop @$guard;

  return $module;
}
END_CODE
    : sprintf(qq{#line %s "%s"\n}, __LINE__+1, __FILE__).<<'END_CODE'
sub load_module ($) {
  my $module = $_[0];
  (my $file = $module) =~ s{::}{/}g;
  $file .= ".pm";
  CORE::require($file);
  return $module;
}
END_CODE
  ),
);

my @EXPORT_OK;

my $code = '';

no strict 'refs';

while (my ($sub, $fb) = splice @fb, 0, 2) {
  push @EXPORT_OK, $sub;
  if (defined &{'builtin::'.$sub}) {
    no warnings 'prototype';
    *$sub = \&{'builtin::'.$sub};
    next;
  }
  if (ref $fb) {
    my ($mod) = $$fb =~ /\A(.*)::/s;
    (my $file = "$mod.pm") =~ s{::}{/}g;
    require $file;
    die "Unable to find $$fb"
      unless defined &{$$fb};
    *$sub = \&{$$fb};
  }
  else {
    $code .= $fb . "\n";
  }

  if (!defined &{'builtin::'.$sub}) {
    my $subref = \&$sub;
    if ($] < '5.038000' && (ref $fb || prototype($subref) eq '')) {
      require Scalar::Util;
      my $wrap = sub { goto &$subref };
      Scalar::Util::set_prototype(\&$wrap, prototype($subref));
      *{'builtin::'.$sub} = $wrap;
    }
    else {
      *{'builtin::'.$sub} = $subref;
    }
  }
}

my $e;
{
  local $@;
  eval "$code; 1" or $e = $@;
}
die $e
  if defined $e;

my %EXPORT_OK = map +($_ => 1), @EXPORT_OK;

our $NO_DISABLE_WARNINGS;
sub import {
  my $class = shift;
  return
    unless @_;

  # search for caller that is being compiled. can't just use caller directly,
  # beause it may not be the same level as builtin would use for its lexical
  # exports
  my $caller;
  my $level = 0;
  while (my @caller = caller(++$level)) {
    if ($caller[3] =~ /\A(.*)::BEGIN\z/s) {
      $caller = $1;
      last;
    }
  }
  if (!defined $caller) {
    require Carp;
    Carp::croak("builtin::compat::import can only be called at compile time");
  }

  for my $import (@_) {
    require Carp;
    Carp::croak("'$import' is not recognised as a builtin function")
      if !$EXPORT_OK{$import};
    *{$caller.'::'.$import} = \&$import;
  }

  unless ($NO_DISABLE_WARNINGS) {
    local $@;
    eval { warnings->unimport('experimental::builtin') };
  }
  namespace::clean->import(-cleanee => $caller, @_);
  return;
}

if (!defined &builtin::import) {
  *builtin::import = sub {
    local $NO_DISABLE_WARNINGS = 1;
    &import;
  };
}

$INC{'builtin.pm'} ||= __FILE__;

1;
__END__

=head1 NAME

builtin::compat - Provide builtin functions for older perl versions

=head1 SYNOPSIS

  use builtin::compat qw(
    true
    false
    is_bool
    inf
    nan
    weaken
    unweaken
    is_weak
    blessed
    refaddr
    reftype
    created_as_string
    created_as_number
    stringify
    ceil
    floor
    trim
    indexed
    load_module
  );

=head1 DESCRIPTION

Provides L<builtin> functions for perl versions that do not include the
L<builtin> module.

No functions are exported by default.

This module does its best to behave similar to L<builtin>, which creates its
exported functions as lexicals. The functions will be created in the currently
compiling scope, not the immediate caller of C<< builtin::compat->import >>.
The functions will also be removed at the end of the compilation scope using
L<namespace::clean>.

The L<builtin> functions will be used directly when they are available.

=head1 FUNCTIONS

=over 4

=item true

See L<builtin/true>.

=item false

See L<builtin/false>.

=item is_bool

See L<builtin/is_bool>.

Prior to perl 5.36, it was not possible to track boolean values fully
accurately. This function will not be perfectly accurate on earlier perl
versions.

=item inf

See L<builtin/inf>.

=item nan

See L<builtin/nan>.

=item weaken

See L<builtin/weaken>.

=item unweaken

See L<builtin/unweaken>.

=item is_weak

See L<builtin/is_weak>.

=item blessed

See L<builtin/blessed>.

=item refaddr

See L<builtin/refaddr>.

=item reftype

See L<builtin/reftype>.

=item created_as_string

See L<builtin/created_as_string>.

Prior to perl 5.36, it was not possible to check if a scalar value was created
as a number or as a string fully accurately. This function will not be entirely
accurate before then, but should be as accurate as is possible on these perl
versions. In particular, a string like "12345" that has been used as a number
will cause C<create_as_string> to return false and C<created_as_number> to
return true.

=item created_as_number

See L<builtin/created_as_number>.

Has the same caveats as C<created_as_string>.

=item stringify

See L<builtin/stringify>.

=item ceil

See L<builtin/ceil>.

=item floor

See L<builtin/floor>.

=item trim

See L<builtin/trim>.

=item indexed

See L<builtin/indexed>.

=item load_module

See L<builtin/load_module>.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2022 the builtin::compat L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
