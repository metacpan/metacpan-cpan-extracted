use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

ore

=cut

=abstract

Sugar for Perl 5 one-liners

=cut

=synopsis

  BEGIN {
    $ENV{New_File_Temp} = 'ft';
  }

  use ore;

  $ft

  # "File::Temp"

=cut

=description

This package provides automatic package handling and object instantiation based
on environment variables. This is not a toy, but it's also not a joke. This
package exists because I was bored, shut-in due to the COVID-19 epidemic of
2020, and inspired by L<new> and the ravings of a madman (mst). Though you
could use this package in a script it's meant to be used from the command-line.

+=head2 new-example

Simple command-line example using env vars to drive object instantiation:

  $ New_File_Temp=ft perl -More -e 'dd $ft'

  # "File::Temp"

+=head2 use-example

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

+=head2 arg-example

Here's another simple command-line example using args as env vars with ordered
variable interpolation:

  $ perl -More -E 'dd $pt' New_File_Temp=ft New_Path_Tiny='pt; $ft'

  # /var/folders/pc/v4xb_.../T/JtYaKLTTSo

+=head2 etc-example

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

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('File::Temp');

  $result
});

ok 1 and done_testing;
