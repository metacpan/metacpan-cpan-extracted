use strict;
use warnings;
use Path::Tiny qw( path );
use lib path(__FILE__)->parent->child('lib')->stringify;

# unlike the Wasm:Wasmtime interface, Wasm.pm does all
# the linking for us.  Linking1.pm and Linking2.pm are
# just thin wrappers around the .wat code.
use Linking1;

# Linking1 uses -export => 'all', which uses Exporter
# to export to any module that uses Linking1
run();
