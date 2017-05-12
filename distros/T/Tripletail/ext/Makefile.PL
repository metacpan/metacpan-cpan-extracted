use strict;
use warnings;
use ExtUtils::MakeMaker;

$SIG{__WARN__} = \&Carp::confess; use Carp;
WriteMakefile(
    NAME => 'Tripletail-ext',
   );

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
