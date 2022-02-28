package Example::Syntax;

use strict;
use warnings;

use Import::Into;
use Module::Runtime;

sub importables {
  my ($class) = @_;
  return (
    'utf8',
    'strict',
    'warnings',
    ['feature', ':5.16'],
    ['experimental', 'signatures', 'postderef'],
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
