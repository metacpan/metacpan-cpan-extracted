use 5.008001;
use strict;
use warnings;
use utf8;
use Test::More 0.96;
use Test::Deep '!blessed';
use Test::File::ShareDir -share =>
  { -dist => { 'Time-OlsonTZ-Clustered' => 'share' } };

use Time::OlsonTZ::Clustered qw/:all/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $brasilia = find_cluster('America/Sao_Paulo');

my $desc = $brasilia->{description};

ok( utf8::is_utf8($desc), "Brasília description internally is UTF-8" );

is(
    $desc,
    "Horário de Brasília",
    "Sao Paolo cluster description is correct UTF-8"
);

done_testing;
#
# This file is part of Time-OlsonTZ-Clustered
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
