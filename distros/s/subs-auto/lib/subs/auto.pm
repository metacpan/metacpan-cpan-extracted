package subs::auto;

use 5.010;

use strict;
use warnings;

=head1 NAME

subs::auto - Read barewords as subroutine names.

=head1 VERSION

Version 0.08

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.08';
}

=head1 SYNOPSIS

    {
     use subs::auto;
     foo;             # Compile to "foo()"     instead of "'foo'"
                      #                        or croaking on strict subs
     foo $x;          # Compile to "foo($x)"   instead of "$x->foo"
     foo 1;           # Compile to "foo(1)"    instead of croaking
     foo 1, 2;        # Compile to "foo(1, 2)" instead of croaking
     foo(@a);         # Still ok
     foo->meth;       # "'foo'->meth" if you have use'd foo somewhere,
                      #  or "foo()->meth" otherwise
     print foo 'wut'; # print to the filehandle foo if it's actually one,
                      #  or "print(foo('wut'))" otherwise
    } # ... but function calls will fail at run-time if you don't
      # actually define foo somewhere

    foo; # BANG

=head1 DESCRIPTION

This pragma lexically enables the parsing of any bareword as a subroutine name, except those which corresponds to an entry in C<%INC> (expected to be class names) or whose symbol table entry has an IO slot (expected to be filehandles).

You can pass options to C<import> as key / value pairs :

=over 4

=item *

C<< in => $pkg >>

Specifies on which package the pragma should act.
Setting C<$pkg> to C<Some::Package> allows you to resolve all functions name of the type C<Some::Package::func ...> in the current scope.
You can use the pragma several times with different package names to allow resolution of all the corresponding barewords.

Defaults to the current package.

=back

This module is B<not> a source filter.

=cut

use B;

use B::Keywords;

use Variable::Magic 0.31 qw<wizard cast dispell getdata>;

BEGIN {
 unless (Variable::Magic::VMG_UVAR) {
  require Carp;
  Carp::croak('uvar magic not available');
 }
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

my %core;
@core{
 @B::Keywords::Barewords,
 @B::Keywords::Functions,
 'DATA',
} = ();
delete @core{qw<my local>};

BEGIN {
 *_REFCNT_PLACEHOLDERS = eval 'sub () { ' . ("$]" < 5.011_002 ? 0 : 1) . '}'
}

my $tag = wizard data => sub { \(my $data = _REFCNT_PLACEHOLDERS ? 2 : 1) };

sub _reset {
 my $fqn = join '::', @_;

 my $cb = do {
  no strict 'refs';
  no warnings 'once';
  *$fqn{CODE};
 };

 if ($cb and defined(my $data = getdata(&$cb, $tag))) {
  $$data--;
  return if $$data > 0;

  _delete_sub($fqn);
 }
}

sub _fetch {
 (undef, my $data, my $name) = @_;

 return if $data->{guard};
 local $data->{guard} = 1;

 return if $name =~ /::/
        or exists $core{$name};

 my $op_name = $_[-1] || '';
 return if $op_name =~ /method/;

 my $pkg = $data->{pkg};

 my $hints = (caller 0)[10];
 if ($hints and $hints->{+(__PACKAGE__)}) {
  my $pm = $name . '.pm';
  return if exists $INC{$pm};

  my $fqn = $pkg . '::' . $name;
  my $cb  = do { no strict 'refs'; *$fqn{CODE} };
  if ($cb) {
   if (_REFCNT_PLACEHOLDERS and defined(my $data = getdata(&$cb, $tag))) {
    ++$$data;
   }
   return;
  }
  return if do { no strict 'refs'; *$fqn{IO} };

  $cb = sub {
   my ($file, $line) = (caller 0)[1, 2];
   ($file, $line) = ('(eval 0)', 0) unless $file && $line;
   die "Undefined subroutine &$fqn called at $file line $line\n";
  };
  cast &$cb, $tag;

  no strict 'refs';
  *$fqn = $cb;
 } else {
  _reset($pkg, $name);
 }

 return;
}

sub _store {
 (undef, my $data, my $name) = @_;

 return if $data->{guard};
 local $data->{guard} = 1;

 _reset($data->{pkg}, $name);

 return;
}

my $wiz = wizard data    => sub { +{ pkg => $_[1], guard => 0 } },
                 fetch   => \&_fetch,
                 store   => \&_store,
                 op_info => Variable::Magic::VMG_OP_INFO_NAME;

my %pkgs;

my $pkg_rx = qr/
 ^(?:
     ::
    |
     (?:::)?
     [A-Za-z_][A-Za-z0-9_]*
     (?:::[A-Za-z_][A-Za-z0-9_]*)*
     (?:::)?
  )$
/x;

sub _validate_pkg {
 my ($pkg, $cur) = @_;

 return $cur unless defined $pkg;

 if (ref $pkg or $pkg !~ $pkg_rx) {
  require Carp;
  Carp::croak('Invalid package name');
 }

 $pkg =~ s/::$//;
 $pkg = $cur . $pkg if $pkg eq '' or $pkg =~ /^::/;
 $pkg;
}

sub import {
 shift;
 if (@_ % 2) {
  require Carp;
  Carp::croak('Optional arguments must be passed as keys/values pairs');
 }
 my %args = @_;

 my $cur = caller;
 my $in  = _validate_pkg $args{in}, $cur;
 ++$pkgs{$in};
 {
  no strict 'refs';
  cast %{$in . '::'}, $wiz, $in;
 }

 $^H{+(__PACKAGE__)} = 1;
 $^H |= 0x020000;

 return;
}

sub unimport {
 $^H{+(__PACKAGE__)} = 0;
}

{
 no warnings 'void';
 CHECK {
  no strict 'refs';
  dispell %{$_ . '::'}, $wiz for keys %pkgs;
 }
}

=head1 EXPORT

None.

=head1 CAVEATS

C<*{'::foo'}{CODE}> will appear as defined in a scope where the pragma is enabled, C<foo> is used as a bareword, but is never actually defined afterwards.
This may or may not be considered as Doing The Right Thing.
However, C<*{'::foo'}{CODE}> will always return the right value if you fetch it outside the pragma's scope.
Actually, you can make it return the right value even in the pragma's scope by reading C<*{'::foo'}{CODE}> outside (or by actually defining C<foo>, which is ultimately why you use this pragma, right ?).

You have to open global filehandles outside of the scope of this pragma if you want them not to be treated as function calls.
Or just use lexical filehandles and default ones as you should be.

This pragma doesn't propagate into C<eval STRING>.

=head1 DEPENDENCIES

L<perl> 5.10.0.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<Variable::Magic> with C<uvar> magic enabled (this should be assured by the required perl version).

L<B::Keywords>.

L<Carp> (standard since perl 5), L<XSLoader> (since 5.6.0).

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-subs-auto at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=subs-auto>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc subs::auto

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/subs-auto>.

=head1 ACKNOWLEDGEMENTS

Thanks to Sebastien Aperghis-Tramoni for helping to name this pragma.

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010,2011,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of subs::auto
