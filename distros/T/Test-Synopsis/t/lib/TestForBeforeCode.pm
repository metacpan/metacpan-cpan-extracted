package Test::Synopsis::__TestBait_TestForBeforeCode;
# Dummy module used during testing of Test::Synopsis

use strict;
use warnings;

# VERSION

1;

=pod

=head1 SYNOPSIS

=for test_synopsis my $assa;

    print( $assa );

=head1 DESCRIPTION

The C<=for test_synopsis> directive appears B<before> the SYNOPSIS code
block. This has always worked and must keep working (GH #20).

=cut
