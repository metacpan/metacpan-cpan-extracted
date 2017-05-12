package Test::Kantan::Reporter::Base;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Moo;

has color => (is => 'ro', required => 1);
has level => (is => 'ro', default => sub { 0 });
has cutoff => (is => 'ro', default => sub { $ENV{KANTAN_CUTOFF} || 80 });
has state  => (is => 'ro', required => 1);

no Moo;

1;

