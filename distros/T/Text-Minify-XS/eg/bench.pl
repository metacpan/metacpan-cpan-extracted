#!/usr/bin/env perl

use strict;
use warnings;

use Dumbbench;

use Text::Minify::XS qw/ minify_utf8 minify_ascii /;

my $string = q{
<html>
  <head>
    <title>Test for benchmarking</title>
  </head>
  <body>__

    <h1>Test for benchmarking</h1>_______________________

    <div>___________
      <blockquote>

        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed
        do eiusmod tempor incididunt ut labore et dolore magna
        aliqua. Ut enim ad minim veniam, quis nostrud exercitation
        ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis
        aute irure dolor in reprehenderit in voluptate velit esse
        cillum dolore eu fugiat nulla pariatur. Excepteur sint___
        occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.

      </blockquote>
    </div>
   </body>
</html>
} =~ s/_/ /gr;

my $bench = Dumbbench->new(
    target_rel_precision => 0.005,
    initial_runs         => 10_000,
);

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new( code => sub { minify_utf8($string) } ),
    Dumbbench::Instance::PerlSub->new( code => sub { minify_ascii($string) } ),
);

$bench->run;
$bench->report;
