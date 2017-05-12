package Build::Constants;
use strict;
use warnings;

our $VERSION = '0.80';

use base qw( Exporter );

use constant TAINT_SHEBANG   => "#!perl -Tw\nuse constant TAINTMODE => 1;\n";
use constant RE_VERSION_LINE => qr{
   \A (our\s+)? \$VERSION \s+ = \s+ ["'] (.+?) ['"] ; (.+?) \z
}xms;
use constant RE_POD_LINE => qr{
    \A
        =head1 \s+ DESCRIPTION \s+
    \z
}xms;
use constant VTEMP  => q{%s$VERSION = '%s';};
use constant MONTHS => qw(
   January February March     April   May      June
   July    August   September October November December
);
use constant MONOLITH_TEST_FAIL =>
   "\nFAILED! Building the monolithic version failed during unit testing\n\n";

use constant NO_INDEX => qw(
    monolithic_version
    builder
    t
    xt
);
use constant DEFAULTS => qw(
   license          perl
   create_license   1
   sign             0
);
use constant YEAR_ADD  => 1900;
use constant YEAR_SLOT =>    5;

our @EXPORT_OK = qw(
    TAINT_SHEBANG
    RE_VERSION_LINE
    RE_POD_LINE
    VTEMP
    MONTHS
    MONOLITH_TEST_FAIL
    NO_INDEX
    DEFAULTS
    YEAR_ADD
    YEAR_SLOT
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

1;

__END__
