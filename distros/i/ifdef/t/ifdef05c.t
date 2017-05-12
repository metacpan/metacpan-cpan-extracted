
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ('../lib','.');
    }
}

use Test::More tests => 2;
use strict;
use warnings;

use_ok( 'ifdef','_testing_' );
my $original = <<'EOD';
=begin DEBUGGING

=cut

# XXX This line needs to be fixed

=begin FOObar

=cut

=begin DEBUGGING
EOD

foreach my $prefix (':') {
    ifdef->import( '_testing_', $prefix.'selected' );
    is( ifdef::process( $original ),<<'EOD',"Check process output ${prefix}selected" );




# XXX This line needs to be fixed






EOD
}
