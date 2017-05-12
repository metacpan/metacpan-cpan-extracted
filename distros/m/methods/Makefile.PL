#!/usr/bin/env perl
use inc::Module::Package 'Au:dry 1';
requires $_ for qw(
    true::VERSION
    namespace::sweep
    Method::Signatures::Simple
    invoker
);
