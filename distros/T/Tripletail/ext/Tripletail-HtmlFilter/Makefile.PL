use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Tripletail::HtmlFilter',
  VERSION_FROM => '../../lib/Tripletail.pm',
  map{/^([A-Z_]+)=(.*)$/} @ARGV,
);

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
