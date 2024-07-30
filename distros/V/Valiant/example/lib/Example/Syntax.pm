package Example::Syntax;

use strict;
use warnings;

use Import::Into;
use Module::Runtime;

# Features and pragmas enabled assuming Perl version >= 5.38
sub importables {
  my ($class) = @_;
  return (
    'utf8',
    'strict',
    'warnings',
    'Patterns::UndefObject::maybe',
    ['feature', ':5.34'],
    ['Scalar::Util', 'blessed'],
    ['experimental', 'signatures'],
 #   ['experimental', 'class', 'try', 'defer'],
  );
}

sub import {
  my ($class, @args) = @_;
  my $caller = caller;
  foreach my $import_proto($class->importables) {
    my ($module, @args) = (ref($import_proto)||'') eq 'ARRAY' ? 
      @$import_proto : ($import_proto, ());
    Module::Runtime::use_module($module)
      ->import::into($caller, @args)
  }
}

1;
