package Test::Synopsis::__TestBait_TestForAfterCode;
# Dummy module used during testing of Test::Synopsis

use strict;
use warnings;

# VERSION

1;

=pod

=head1 SYNOPSIS

    print( $assa );

=for test_synopsis my $assa;

=head1 DESCRIPTION

The C<=for test_synopsis> directive appears B<after> the SYNOPSIS code
block. It must still be applied to the code (GH #20).

=cut
