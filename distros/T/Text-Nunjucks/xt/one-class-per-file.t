#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path );

# Author test (card k116): every class in lib/ lives in its own .pm file at the
# path its name implies. No inner `package` blocks, no classes generated at
# runtime (string eval, glob assignment).
#
#   static:  every `package NAME` in lib/**/*.pm is declared in lib/NAME.pm,
#            and each file declares exactly one package. POD is skipped; the
#            `package # hide` + name-on-next-line form is seen.
#   runtime: load every module, walk the Text::Nunjucks:: symbol table and
#            require that each package with subs or @ISA maps to a file in lib/.
#
# TEXT_NUNJUCKS_LIB_ROOT points the test at another lib/ (to watch it fail
# against an old checkout); the default is this distribution's lib/.

my $root = path( $ENV{TEXT_NUNJUCKS_LIB_ROOT} // path(__FILE__)->parent->parent->child('lib') )->absolute;
plan skip_all => "no lib root at $root" unless $root->is_dir;

my @files = sort { $a cmp $b } $root->children(qr/\.pm\z/);
{
  my @dirs = $root->children;
  while ( my $d = shift @dirs ) {
    if    ( $d->is_dir )         { push @dirs, $d->children }
    elsif ( $d->basename =~ /\.pm\z/ && $d->parent ne $root ) { push @files, $d }
  }
  @files = sort { $a cmp $b } @files;
}

sub declared_packages {
  my ($file) = @_;
  my $src = $file->slurp_utf8;
  $src =~ s/^__(?:END|DATA)__\b.*\z//ms;
  $src =~ s/^=[a-zA-Z]\w*.*?(?:^=cut\b[^\n]*\n?|\z)//gms;    # POD is not code
  my @pkgs;
  while ( $src =~ /(?:^|[;{}])[ \t]*package(?:[ \t]*(?:\#[^\n]*)?\n|[ \t])\s*((?:\#[^\n]*\n\s*)*)([A-Za-z_]\w*(?:::\w+)*)/gm ) {
    push @pkgs, $2;
  }
  return @pkgs;
}

my %expected_file;    # package name => path it must live at
for my $file (@files) {
  my $rel  = $file->relative($root);
  my $want = join( '::', split m{/}, ( $rel =~ s/\.pm\z//r ) );
  $expected_file{$want} = $file;
  my @pkgs = declared_packages($file);

  my @bad = grep { $_ ne $want } @pkgs;
  ok( !@bad, "static: $rel declares only $want" )
    or diag join '', map { "  package $_ is declared in lib/$rel, but belongs in lib/" . ( s{::}{/}gr ) . ".pm\n" } @bad;
  is( scalar(@pkgs), 1, "static: $rel declares exactly one package" )
    or diag "  lib/$rel declares: @pkgs";
}

# --- runtime ---------------------------------------------------------------
unshift @INC, $root->stringify;
my @load_failed;
for my $file (@files) {
  my $mod = join '::', split m{/}, ( $file->relative($root) =~ s/\.pm\z//r );
  local $@;
  eval "require $mod; 1" or push @load_failed, "$mod: " . ( $@ =~ s/\n.*//sr );
}
ok( !@load_failed, 'runtime: every module under lib/ loads' ) or diag "  $_" for @load_failed;

# A package counts when it has a sub or an @ISA. Only subs actually defined
# count (`defined &name`), so stash entries without a body (forward
# declarations, constants folded away, glob autovivification) are ignored.
# Moo's has/extends/with are removed again by namespace::autoclean, so a
# clean class shows only its real subs.
sub has_content {
  my ($pkg) = @_;
  no strict 'refs';
  return 1 if @{"${pkg}::ISA"};
  for my $name ( keys %{"${pkg}::"} ) {
    next if $name =~ /::\z/ || $name eq 'BEGIN';
    return 1 if defined &{"${pkg}::$name"};
  }
  return 0;
}

my @seen;
my @walk = ('Text::Nunjucks');
while ( defined( my $pkg = shift @walk ) ) {
  push @seen, $pkg;
  no strict 'refs';
  push @walk, map { $pkg . '::' . s/::\z//r } sort grep { /::\z/ && $_ ne 'main::' } keys %{"${pkg}::"};
}

my @offenders = grep { has_content($_) && !$expected_file{$_} } @seen;
ok( !@offenders, 'runtime: every class with subs or @ISA lives in its own .pm file' )
  or diag join '', map { "  package $_ has code but there is no lib/" . ( s{::}{/}gr ) . ".pm; defined in: " . origin($_) . "\n" } @offenders;

sub origin {
  my ($pkg) = @_;
  require B;
  no strict 'refs';
  my %files;
  for my $name ( keys %{"${pkg}::"} ) {
    next unless defined &{"${pkg}::$name"};
    my $f = B::svref_2object( \&{"${pkg}::$name"} )->FILE;
    $files{ $f =~ s/\A\Q$root\E\/?//r } = 1 if $f =~ /\A\Q$root\E\// || $f =~ /\A\(eval/;
  }
  return join( ', ', sort keys %files ) || '(only @ISA)';
}

done_testing;
