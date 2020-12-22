use 5.014;

use strict;
use warnings;
use routines;

use lib 't/lib';

use Test::Auto;
use Test::More;
use Test::Zing;

=name

Zing::Cartridge

=cut

=tagline

Executable Process File

=cut

=abstract

Executable Process File Abstraction

=cut

=includes

method: pid
method: install

=cut

=synopsis

  use Zing::Cartridge;

  my $cartridge = Zing::Cartridge->new(name => 'myapp');

  # $cartridge->pid;

=cut

=libraries

Zing::Types

=cut

=inherits

Zing::Entity

=cut

=attributes

appdir: ro, opt, Str
appfile: ro, opt, Str
libdir: ro, opt, ArrayRef[Str]
piddir: ro, opt, Str
pidfile: ro, opt, Str
name: ro, opt, Str
scheme: ro, opt, Scheme

=cut

=description

This package provides an executable process file abstraction.

=cut

=method pid

The pid method returns the process ID of the executed process (if any).

=signature pid

pid() : Maybe[Int]

=example-1 pid

  # given: synopsis

  my $pid = $cartridge->pid;

=cut

=method install

The install method creates an executable process file on disk for the scheme
provided.

=signature install

install(Scheme $scheme) : Object

=example-1 install

  # given: synopsis

  $cartridge = $cartridge->install(['MyApp', [], 1]);

=cut

=example-2 install

  use Zing::Cartridge;

  my $cartridge = Zing::Cartridge->new(scheme => ['MyApp', [], 1]);

  $cartridge = $cartridge->install;

=cut

package main;

use File::Spec ();

$ENV{ZING_APPDIR} = File::Spec->tmpdir;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'pid', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'install', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !$result->{scheme};
  is_deeply $result->scheme, ['MyApp', [], 1];

  $result
});

ok 1 and done_testing;
