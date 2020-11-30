#!/usr/bin/perl
use Test::More;

plan skip_all => "These tests are for authors only!" unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

eval { require Test::Kwalitee; Test::Kwalitee->import() };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

