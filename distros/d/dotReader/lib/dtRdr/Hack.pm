package dtRdr::Hack;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;


use Carp qw(
  croak
  carp
  cluck
  confess
  );

=head1 NAME

dtRdr::Hack - self-documenting adaptive finger-wagging global vars

=head1 SYNOPSIS

This is a global store for things that cannot otherwise be cleanly
solved at the moment.

  package WayOver::OnThe::Left;
  use dtRdr::Hack;  dtRdr::Hack->set_variableB(45);

  package Bottom::Right::Corner;
  use dtRdr::Hack;
  my $variableB = dtRdr::Hack->get_variableB;

Basically, just a way to formalize global variable sharing.

Arrays, hashes, objects, and globs are all passed and stored directly as
references.

=head1 Declarations

Variables are declared in the C<%declarations> and C<%deprecated> hashes
in the Hack.pm code.  To deprecate variables, move them rather than
duplicating.

The behavior is controlled by the following constants, which should be
similar to perl's warnings and strict pragmas (less the lexical aspects
and dynamic switchability.)

  my %declared = (
    some_scalar => '',                       # scalar
    some_array  => [],                       # array
    some_hash   => {},                       # hash
    some_univ   => bless({}, 'UNIVERSAL'),   # any object
    some_obj    => bless({}, 'dtRdr::Book'), # class or subclass
    some_sub    => sub {_die 'ex_sub'},      # declare subs like this
    some_undef  => undef,                    # run-time typing
  );

B<TODO:> you can currently set an object where you declared a hash, but
STRICT should probably not allow that.

Moving variables to C<%deprecated> allows you to denote that your code
should no longer be using these.

  my %deprecated = (
    some_other_scalar => '',
    some_other_array  => [],
    some_other_hash   => {},
    some_other_sub    => sub {_die 'ex_sub'},
  );

B<NOTE:>  The C<sub {_die 'ex_sub'}> idiom lets you stop yourself from
calling what you thought was set elsewhere.

=over

=item STRICT

Throws errors when you:

=over

=item * get/set to an undeclared variable

=item * set the wrong type to a variable

=item * (TODO) set the wrong type to a dynamically typed variable

=back

=item WARNINGS

Complains when you:

=over

=item * get/set deprecated variables

=item * get/set undeclared variables (allowed if STRICT=0)

=item * get/set the wrong type for a variable (allowed if STRICT=0)

=back

=item TRACE

Is not implemented yet.

=back

B<NOTE:>  Running without STRICT=1 is only lightly tested and is not
recommended.

=cut

my $widget_img = <<'WIDGET_IMG';
<img src="data:image/png;base64,
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBI
WXMAAAsRAAALEQF/ZF+RAAACC0lEQVQ4y3VTz2sTQRT+kmzBihGpvXlwQWS7KQpe9CLMpL0pWPwV
IR5qEwXRc4OH0N2tgZK2/0IFb0KtNj30YAk7iyC15ya7e1AaxEthU0OhhWTJeOmE7e72wcC8eW++
7733zYBzDs45OtUJ0yukeNdmRJwFV9dmxCukeDhnkCCCneqEGb58tG5oZ8UTnHMAQLsocUkhbEgh
DCE73pjXxT49W6dDY8QSvgQAPccicclxFrwMINpCuMeuzcjW9NXYGOccySB7sMTi82e8traqbTb2
6afebaRn6xQAfNeipyoIMh+tG1qcAkEVIhVIgaH1XIse1+Y14f+t3jM3p6/ztr1NIswnllrY+v1R
Ugjrey3Zdy3quxbtuRZNXpb3/vBL+Lr7j1472JHTbUfuey35QvHDTBBgIONyRTPbzjZ9d9Nngk30
fbg0OahyZMVPBAGSALBYMUzbduidhy/1i6V69puvYq8/gsOlSRZ+A5EWbt0Y1358t14oaoYVX7+Z
WawY5s4+5HPKXaYc/JT7XksWzKlRuRUBOC8lmKJmWKmsZZ1mg2x8+awraoa9LS9kf/VHYdtNeiXZ
gaQQFgeA6nt98LYL+Rwv5HPcbuwS4b/KPxnIHCdvslTWsmIOAKCoGTaWGbdqa6saANx/lNOHH8zp
ABCU+NQQnWaDuHaTAoAAFDb1+KkxPDVnnPU3/gMTNJSCnLOiXgAAAABJRU5ErkJggg==
">
WIDGET_IMG
########################################################################
# Declare your variables.  See import() for examples.
########################################################################
# DECLARED variables
my %declared = (
  widget_img => $widget_img, # to check if widgets work
  );

########################################################################
# DEPRECATED variables -- warnings, but not errors
my %deprecated = (
  inline_image_sub  => sub { # base64 encoding
    my ($imagepath,$ext,$book)=@_;
    use MIME::Base64;
    my $image = $book->get_member_string($imagepath) or
      warn qq( couldn't get image $!);
    my $enc_image = MIME::Base64::encode($image);
    return qq(<img src="data:image/$ext;base64,$enc_image" />);
  },
  current_book  => bless({}, 'dtRdr::Book'), # assumes only one book
  );
########################################################################

# anything else throws errors if strict is on
use constant {
  WARNINGS => 1,
  STRICT   => 1,
  TRACE    => 0,
  };

our $AUTOLOAD;
my %defs;  # type cache
my %store; # actual storage

sub _die ($);

# import is only here to enable testing
# TODO? add trace=> 1 option to turn on tracing
sub import {
  my ($package, %opts) = @_;

  if($opts{testing}) { # assign testing vars
    # don't use ex_ or exd_ prefixes -- those are mine
    my %tdeclared = (
      ex_scalar => '', # scalar
      ex_array  => [], # array
      ex_hash   => {}, # hash
      ex_obj    => bless({}, 'dtRdr::Book'), # stricter than hash
      ex_sub    => sub {_die 'ex_sub'}, # declare subs like this
      ex_undef  => undef, # anything you want
      ex_univ  => bless({}, 'UNIVERSAL'), # anything object you want
    );
    my %tdeprecated = (
      exd_scalar => '', # scalar
      exd_array  => [], # array
      exd_hash   => {}, # hash
      exd_sub    => sub {_die 'ex_sub'}, # declare subs like this
    );
    my @pairs = (
      [\%declared, \%tdeclared],
      [\%deprecated, \%tdeprecated],
    );
    foreach my $pair (@pairs) {
      foreach my $key (keys(%{$pair->[1]})) {
        exists($pair->[0]{$key}) and die "I said don't use names like $key";
        $pair->[0]{$key} = $pair->[1]{$key};
      }
    }
  }
} # end subroutine import definition
########################################################################

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ( $var_name, $action ) = _parse_autoload_method($AUTOLOAD);

  # one-time
  %defs or _build_defs();

  # THE PLAN
  # is var_name declared?
  #   yes => (strict? rtime check_type : whatever)
  #   no =>  (strict? ctime croak      : (warnings? ctime warn : ok))
  # is var_name deprecated? => (warnings? rtime warn : ok)

  # we have something like compile time
  #   ctime:  first call -- only time we're in AUTOLOAD
  # and something like runtime
  #   rtime:  every call

  # NOTE we want to install the closure in our package so we only hit
  # the AUTOLOAD() once -- this isn't safe to be inherited because it
  # smashes your sub on $self->SUPER::foo() calls

  unless(exists($defs{$var_name})) {
    STRICT and croak("'$var_name' undeclared in ", __PACKAGE__);
    WARNINGS and carp("WARNING $var_name undeclared in ", __PACKAGE__);
  }

  # grab pre-determined type
  my $type = $defs{$var_name};

  # $check_type is an rtime croak if STRICT
  my $check_type = STRICT ? sub {_check_type($var_name, $type, @_)} : sub {};

  # $run_warn is an rtime warning
  my $run_warn = sub {};
  if(WARNINGS) {
    if(exists($deprecated{$var_name})) {
      $run_warn = sub {_warn_deprecated($action . "_" . $var_name)};
    }
    # TODO? check for other things to warn about?
  }

  # cluck("action: '$action' on '$var_name'");

  my $install_sub;
  if($action eq 'set') {
    # warn "defining set_$var_name";
    $install_sub = sub {
      my $self = shift;
      @_ or croak("'set_$var_name()' requires variable");
      my $val = shift(@_);
      $check_type->($val);
      $run_warn->();
      return($store{$var_name} = $val);
    };
  }
  elsif($action eq 'get') {
    $install_sub = sub {
      my $self = shift;
      $run_warn->();
      return($store{$var_name});
    };
  }
  else {
    die "action '$action' not implemented";
  }

  $install_sub or die "problem";
  {
    no strict 'refs';
    *{$AUTOLOAD} = $install_sub;
  }
  goto &$AUTOLOAD;
} # end subroutine AUTOLOAD definition
########################################################################

=begin internals

=head1 internals

# TODO? may need a can()
  sub can {confess "not implemented"}

=head2 _check_type

croaks unless $var isa $type

  _check_type($var_name, $type, $var);

=cut

sub _check_type {
  my ($var_name, $type, $var) = @_;
  croak("trouble") unless(scalar(@_) == 3);

  # warn "check '$var_name', '$type', '$var'";

  # TODO? I guess I could look that up myself...
  return(1) unless(defined($type));

  # TODO and I could implement strong dynamic typing for undef()
  # declarations here as well.

  return(1) if(_type($var) eq $type);

  # XXX should we allow set hash to any object?
  # this allows that and any object -> bless({}, 'UNIVERSAL')
  return(1) if eval {$var->isa($type)};

  croak("'$var_name' type declared as '$type' not '", _type($var), "'");
} # end subroutine _check_type definition
########################################################################

=head2 _warn_deprecated

  _warn_deprecated($var_name);

=cut

sub _warn_deprecated {
  my ($var_name) = @_;

  my $color = sub {
    my $def = sub {""}; (-t STDERR) or return($def);
    eval { require Term::ANSIScreen }; $@ and return($def);
    return(\&Term::ANSIScreen::color);
  }->();

  my ($cp, $cl) = (caller(2))[0,2];
  local $SIG{__WARN__}; # wag finger no matter what
  warn(((-t STDOUT) ? "" : "\n"),
    $color->('bold white on red'), "DEPRECATED:", $color->('reset'),
    "  dtRdr::Hack->",
    $color->('bold red on black') . $var_name, $color->('reset') ,
    " at '$cp' line $cl\n");
} # end subroutine _warn_deprecated definition
########################################################################

=head2 _type

  _type($var);

=cut

sub _type {
  my ($var) = @_;
  defined($var) or return(); # undefined
  my $ref = ref($var);
  $ref or return('');        # scalar -- XXX?
  # should package/hash/array/code/glob refs be more rigorously checked?
  return($ref);
} # end subroutine _type definition
########################################################################

=head2 _build_defs

  _build_defs();

=cut

sub _build_defs {
  %defs and croak "do not call this twice";

  foreach my $hash (\%declared, \%deprecated) {
    foreach my $k (keys(%$hash)) {
      $defs{$k} = _type($hash->{$k});
      exists($store{$k}) and die "$k declared twice";
      $store{$k} = $hash->{$k};
    }
  }

} # end subroutine _build_defs definition
########################################################################

# adopted from Best Practical's Jifty::DBI::Record
sub _parse_autoload_method {
  my $method = shift;

  my ( $var_name, $action );

  if($method !~ m/^.*::(?:set_|get_)/o) {
    croak("method must start with get_|set_ ('$method')");
  }
  elsif ( $method =~ m/^.*::([gs]et)_(\w+)$/o ) {
    $action = $1;
    $var_name = $2;
  }
  else {
    croak("missing variable in '$method'");
  }
  return ( $var_name, $action );
} # end subroutine _parse_autoload_method definition
########################################################################

=head2 _die

  _die();

=cut

sub _die ($) {
  my $var = shift;
  confess("undeclared sub $var");
} # end subroutine _die definition
########################################################################

=end internals

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

See L<dtRdr>

=head1 COPYRIGHT

Copyright (C) 2006 OSoft, Eric L. Wilhelm, All Rights Reserved.

Portions derived from Jifty::DBI - Copyright Best Practical.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
