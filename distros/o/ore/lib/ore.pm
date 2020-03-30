package ore;

use 5.014;

use strict;
use warnings;
use routines;

use base 'Exporter';

use Data::Dump;
use Data::Object::Space;

no strict 'refs';

our @EXPORT = ('dd');

our $VERSION = '0.04'; # VERSION

sub import {
  my $args = [map { /([^=]+)=(.*)/; $ENV{$1} = $2 if $1; $1 || () } @ARGV];

  new_vars([grep /^New_/, @$args ? @$args : keys %ENV]);
  use_vars([grep /^Use_/, @$args ? @$args : keys %ENV]);

  ore->export_to_level(1, @_);
}

fun new_vars($args) {
  [map new_vars_pump(new_vars_form($_)), @$args]
}

fun new_vars_args($spec) {
  [map { /^\$(\w+)$/ ? ${"ore::$1"} : $_ } @$spec[2..$#$spec]]
}

fun new_vars_form($name) {
  new_vars_make(new_vars_spec($name))
}

fun new_vars_make($spec) {
  [$spec->[1], Data::Object::Space->new($spec->[0])->build(@{new_vars_args($spec)})]
}

fun new_vars_name($name) {
  $name =~ s/^New_//gr =~ s/_/\//gr
}

fun new_vars_spec($name) {
  [new_vars_name($name), split /;\s*/, $ENV{$name}]
}

fun new_vars_pump($conf) {
  ${"ore::$$conf[0]"} = $$conf[1]; push @EXPORT, '$'.$$conf[0]; $conf
}

fun use_vars($args) {
  [map use_vars_pump(use_vars_form($_)), @$args]
}

fun use_vars_args($spec) {
  [map { /^\$(\w+)$/ ? ${"ore::$1"} : $_ } @$spec[2..$#$spec]]
}

fun use_vars_form($name) {
  use_vars_make(use_vars_spec($name))
}

fun use_vars_make($spec) {
  [$spec->[1], Data::Object::Space->new($spec->[0])]
}

fun use_vars_name($name) {
  $name =~ s/^Use_//gr =~ s/_/\//gr
}

fun use_vars_spec($name) {
  [use_vars_name($name), split /;\s*/, $ENV{$name}]
}

fun use_vars_pump($conf) {
  ${"ore::$$conf[0]"} = $$conf[1]; push @EXPORT, '$'.$$conf[0]; $conf
}

1;

=encoding utf8

=head1 NAME

ore

=cut

=head1 ABSTRACT

Sugar for Perl 5 one-liners

=cut

=head1 SYNOPSIS

  BEGIN {
    $ENV{New_File_Temp} = 'ft';
  }

  use ore;

  $ft

  # "File::Temp"

=cut

=head1 DESCRIPTION

This package provides automatic package handling and object instantiation based
on environment variables. This is not a toy, but it's also not a joke. This
package exists because I was bored, shut-in due to the COVID-19 epidemic of
2020, and inspired by L<new> and the ravings of a madman (mst). Though you
could use this package in a script it's meant to be used from the command-line.

=head2 new-example

Simple command-line example using env vars to drive object instantiation:

  $ New_File_Temp=ft perl -More -e 'dd $ft'

  # "File::Temp"

=head2 use-example

Another simple command-line example using env vars to return a
L<Data::Object::Space> object which calls C<children> and returns an arrayref
of L<Data::Object::Space> objects:

  $ Use_DBI=dbi perl -More -e 'dd $dbi->children'

  # [
  #   ...,
  #   "DBI/DBD",
  #   "DBI/Profile",
  #   "DBI/ProfileData",
  #   "DBI/ProfileDumper",
  #   ...,
  # ]

=head2 arg-example

Here's another simple command-line example using args as env vars with ordered
variable interpolation:

  $ perl -More -E 'dd $pt' New_File_Temp=ft New_Path_Tiny='pt; $ft'

  # /var/folders/pc/v4xb_.../T/JtYaKLTTSo

=head2 etc-example

Here's a command-line example using the aforementioned sugar with the
ever-awesome L<Reply> repl:

  $ New_Path_Tiny='pt; /tmp' reply -More

  0> $pt

  # $res[0] = bless(['/tmp', '/tmp'], 'Path::Tiny')

Or, go even further and hack together your own environment vars driven
L<Dotenv>, L<Reply>, and C<perl -More> based REPL:

  #!/usr/bin/env perl

  use Dotenv -load => "$0.env";

  use ore;

  my $reply = `which reply`;

  chomp $reply;

  require $reply;

Then, provided you've the set appropriate env vars in C<reply.env>, you could
use your custom REPL at the command-line as per usual:

  $ ./reply

  0> $pt

  # $res[0] = bless(['/tmp', '/tmp'], 'Path::Tiny')

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/ore/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/ore/wiki>

L<Project|https://github.com/iamalnewkirk/ore>

L<Initiatives|https://github.com/iamalnewkirk/ore/projects>

L<Milestones|https://github.com/iamalnewkirk/ore/milestones>

L<Contributing|https://github.com/iamalnewkirk/ore/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/ore/issues>

=cut
