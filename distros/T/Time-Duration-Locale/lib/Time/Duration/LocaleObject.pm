# Copyright 2009, 2010, 2011, 2013, 2016, 2017 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

package Time::Duration::LocaleObject;
use 5.004;
use strict;
use Carp;
use Module::Load;
use vars qw($VERSION @ISA $AUTOLOAD);

use Class::Singleton;
@ISA = ('Class::Singleton');
*_new_instance = \&new;

$VERSION = 12;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  ### LocaleObject new(): @_
  my ($class, %self) = @_;
  my $self = bless \%self, $class;

  # Load language module now, if given.  You're not supposed to pass both
  # 'module' and 'language', but for now the latter has precedence.
  #
  if (my $module = delete $self{'module'}) {
    $self->module ($module);
  }
  if (my $lang = delete $self{'language'}) {
    $self->language ($lang);
  }

  return $self;
}

# don't go through AUTOLOAD
sub DESTROY {}

sub module {
  my $self = shift;
  ref $self or $self = $self->instance;
  if (@_) {
    # set
    my ($module) = @_;
    if (defined $module) {
      # guard against infinite recursion on Time::Duration::Locale
      # maybe should restrict to lower-case module names
      if ($module eq 'Time::Duration::Locale'
          || $module eq 'Time::Duration::LocaleObject') {
        croak 'Don\'t set module to Locale or LocaleObject';
      }
      Module::Load::load ($module);
    }
    $self->{'module'} = $module;
  }
  # get
  return $self->{'module'};
}

sub language {
  my $self = shift;
  ref $self or $self = $self->instance;
  if (@_) {
    # set
    my ($lang) = @_;
    $self->module (_language_to_module ($lang));
  }
  # get
  my $module = $self->{'module'};
  return (defined $module ? _module_to_language($module) : undef);
}

# maybe it'd be easier to create a Time::Duration::en than mangle the names
sub _language_to_module {
  my ($lang) = @_;
  return ($lang eq 'en' ? 'Time::Duration' : "Time::Duration::$lang");
}
sub _module_to_language {
  my ($module) = @_;
  return ($module eq 'Time::Duration' ? 'en'
          : $module =~ /^Time::Duration::(.*)/ ? $1
          : $module);
}

#------------------------------------------------------------------------------
# setlocale

sub setlocale {
  my ($self) = @_;
  ref $self or $self = $self->instance;
  ### TDLObj setlocale()

  # I18N::LangTags version 0.30 for implicate_supers_strictly(), don't worry
  # about a I18N::LangTags->VERSION(0.30), it'll bomb
  #
  require I18N::LangTags;
  require I18N::LangTags::Detect;

  # Prefer implicate_supers_strictly() over implicate_supers() since the
  # latter loses territory preferences when it converts
  #
  #    en-au, en-gb -> en-au, en, en-gb
  #
  # whereas implicate_supers_strictly() keeps gb ahead of generic en
  #
  #    en-au, en-gb -> en-au, en-gb, en
  #
  # Not that it makes a difference as of July 2010 since there's no
  # territory flavours (only the joke en_PIGLATIN).
  #
  # Chances are though that if you put in territory preferences in $LANGUAGE
  # you'll want to include generics explicitly at the desired points, and in
  # that case implicate_supers() and implicate_supers_strictly() come out
  # the same.
  #
  my %seen;
  my $error;
  foreach my $dashlang (I18N::LangTags::implicate_supers_strictly
                        (I18N::LangTags::Detect::detect()),
                        'en') {
    next if $seen{$dashlang}++;

    (my $lang = $dashlang) =~ s/-(.*)/_\U$1/g;
    ### $dashlang
    ### attempt lang: $lang

    if (eval { $self->language($lang); 1 }) {
      # return value not documented ... don't use it yet
      return $lang;
    }
    $error = $@;
    ### $error
  }
  croak "Time::Duration not available -- $error";
}

#------------------------------------------------------------------------------
# call-through
#
# ENHANCE-ME: Umm, like all AUTOLOAD for class methods this is slightly
# dangerous.  If the base Class::Singleton already has a method the same
# name as the Time::Duration function/method which is supposed to be created
# here then the AUTOLOAD here doesn't run.  Example in
# devel/autoload-singleton.pl.
#
# Should be ok in practice.  The trick would be to stub up funcs for the
# possible methods in the target module, except that's not done immediately
# in new(), and later is too late.  Maybe it'd be worth explicit stubs for
# the normal Time::Duration funcs at least ...
#

sub can {
  my ($self, $name) = @_;
  ### print "TDLObj can(): $name
  return $self->SUPER::can($name) || _make_dispatcher($self,$name);
}
sub AUTOLOAD {
  my $name = $AUTOLOAD;
  ### TDLObj AUTOLOAD(): $name
  $name =~ s/.*://;
  my $code = _make_dispatcher($_[0],$name)
    || croak "No such function $name()";
  goto $code;
}

use vars '$_make_dispatcher';
sub _make_dispatcher {
  my ($class_or_self, $name) = @_;
  ### TDLObj _make_dispatcher(): $class_or_self, $name

  # $_make_dispatcher is recursion protection against bad
  # language_preferences method, or any other undefined method module() or
  # setlocale() might accidentally call here.
  if ($_make_dispatcher
      || do {
        local $_make_dispatcher = 1;
        $class_or_self->module || $class_or_self->setlocale;
        my $module = $class_or_self->module;
        ### module exists: $module
        ### check can(): $name
        ! $module->can($name) }) {
    return undef;
  }

  my $subr = sub {
    #### TDLObj dispatch: $name

    my $self = shift;
    ref $self or $self = $self->instance;
    $self->{'module'} || $self->setlocale;

    my $target = "$self->{'module'}::$name";
    no strict 'refs';
    return &$target(@_);
  };
  { no strict 'refs'; *$name = $subr }
  return $subr;
}

1;
__END__

=for stopwords OOPery POSIX TDLObj LocaleObject ja funcs subr coderef Ryde

=head1 NAME

Time::Duration::LocaleObject - time duration string in language chosen by an object

=head1 SYNOPSIS

 use Time::Duration::LocaleObject;
 my $tdl = Time::Duration::LocaleObject->new;
 print "next update: ", $tdl->duration(120) ,"\n";

=head1 DESCRIPTION

C<Time::Duration::LocaleObject> is an object-oriented wrapper around
possible language-specific C<Time::Duration> modules.  The methods
correspond to the function calls in those modules.  The target module is
established from the user's locale, or can be set explicitly.

Most of the time this module is unnecessary.  A single global language
choice based on the locale is usually enough, as per
C<Time::Duration::Locale>.  But some OOPery is not much more trouble than
plain functions and it's handy if your program works with multiple locales
simultaneously (something fairly painful with POSIX global-only things).

=head1 METHODS

In the following methods TDLObj means either a LocaleObject instance or the
class name C<Time::Duration::Locale>.

    print Time::Duration::LocaleObject->ago(120),"\n";
    print $tdl->ago(120),"\n";

The class name form operates on a global singleton instance which is used by
C<Time::Duration::Locale>.

=head2 Creation

=over 4

=item C<$tdl = Time::Duration::LocaleObject-E<gt>new (key =E<gt> $value, ...)>

Create and return a new LocaleObject.  Optional key/value pairs can give an
explicit C<module> or C<language> to be applied per the L<Settings Methods>
below.

    # locale settings
    my $tdl = Time::Duration::LocaleObject->new;

    # explicit language
    my $tdl = Time::Duration::LocaleObject->new (language => 'ja');

    # explicit language specified by module
    my $tdl = Time::Duration::LocaleObject->new
                (module => 'Time::Duration::en_PIGLATIN');

=back

=head2 Duration Methods

As per the C<Time::Duration> functions.  Any new future functions should
work too since methods pass through transparently.

=over 4

=item C<TDLObj-E<gt>later ($seconds, [$precision])>

=item C<TDLObj-E<gt>later_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>earlier ($seconds, [$precision])>

=item C<TDLObj-E<gt>earlier_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>ago ($seconds, [$precision])>

=item C<TDLObj-E<gt>ago_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>from_now ($seconds, [$precision])>

=item C<TDLObj-E<gt>from_now_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>duration ($seconds, [$precision])>

=item C<TDLObj-E<gt>duration_exact ($seconds, [$precision])>

=item C<TDLObj-E<gt>concise ($str)>

For example,

    # instance method using selected language
    my $tdl = Time::Duration::LocaleObject->new (language => 'ja');
    print $tdl->duration(120),"\n";

    # class method using locale language
    print Time::Duration::LocaleObject->later(10),"\n";

=back

=head2 Settings Methods

=over 4

=item C<$lang = TDLObj-E<gt>language ()>

=item C<$module = TDLObj-E<gt>module ()>

=item C<TDLObj-E<gt>language ($lang)>

=item C<TDLObj-E<gt>module ($module)>

Get or set the language to use, either in the form of a language code like
"en" or "ja", or a module name like "Time::Duration" or
"Time::Duration::ja".

A setting C<undef> means no language has yet been selected.  When setting
the language the necessary module must exist and is loaded if not already
loaded.

=item C<TDLObj-E<gt>setlocale ()>

Set the language according to the user's locale settings.  The current
implementation uses C<I18N::LangTags::Detect>.

This is called automatically by the duration methods above if no language
has otherwise been set, so there's normally no need to explicitly
C<setlocale>.  Call it if you change the environment variables and want
TDLObj to follow.

=back

=head1 OTHER NOTES

In the current implementation C<TDLObj-E<gt>can()> checks whether its target
module has such a function.  This is probably what you want, though if you
later select a different language in the TDLObj object then it might
suddenly reveal extra funcs in another module.

A C<TDLObj-E<gt>can()> subr returned is stored as a method in the
C<Time::Duration::LocaleObject> symbol table.  This caches it ready for
future C<can()> calls and avoids C<AUTOLOAD> if invoked directly.  Not
certain if this is worth the trouble, but it's probably sensible to have
repeated C<can()> calls return the same coderef each time.

=head1 ENVIRONMENT VARIABLES

C<LANGUAGE>, C<LANG>, C<LC_MESSAGES> etc, as per C<I18N::LangTags::Detect>.

=head1 SEE ALSO

L<Time::Duration::Locale>,
L<Time::Duration>,
L<Time::Duration::es>,
L<Time::Duration::fr>,
L<Time::Duration::id>,
L<Time::Duration::ja>,
L<Time::Duration::pl>,
L<Time::Duration::pt>,
L<Time::Duration::sv>,
L<I18N::LangTags::Detect>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/time-duration-locale/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2013, 2016, 2017 Kevin Ryde

Time-Duration-Locale is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Time-Duration-Locale is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

=cut
