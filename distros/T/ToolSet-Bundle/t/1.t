use Test::More tests =>2;
BEGIN { use_ok('Bundle::ToolSet') };


#Test croak before we import the module to see if it was skippable
eval{ croak("Success is failure") };
my $croak = $@;

SKIP: {
  eval { require Carp };
  skip "Carp not installed", 1 if $@;
  like($croak, qr/Success is failure/, 'Carp exposure');
}
