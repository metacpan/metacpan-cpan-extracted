package UtilExporterSimple;

use strict;
use Clone qw/clone/;
BEGIN {
  my $err;
  {
    local $@;
    eval "use Exporter::Simple ()";
    $err = $@;
  }
  if ($err) {
    die $err;
  } else {
    use Util::Any -ExporterSimple;
    eval <<'_CODE';
         our @bar : Exportable(vars) = (2, 3, 5, 7);
         our $foo : Exported(vars)   = 42;
         our %baz : Exported         = (a => 65, b => 66);

         sub hello : Exported(greet,uk)   { "hello there" }
         sub askme : Exportable           { "what you will" }
         sub hi    : Exportable(greet,us) { "hi there" }
_CODE
  }
}

our $Utils = clone $Util::Any::Utils;
$Utils->{l2s} = [
                 ['List::Util', '', [qw(first min minstr max maxstr sum)]],
                ];

1;
