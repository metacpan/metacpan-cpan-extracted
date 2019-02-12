#!/usr/bin/env perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => 'xt/author/criticrc');

all_critic_ok(qw( lib ));
