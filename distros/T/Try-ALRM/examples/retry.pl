use strict;
use warnings;

my $TIMEOUT = 60;
my $TRIES   = 3;

use Try::ALRM qw/tries timeout/;

Try::ALRM::retry {
    my ($attempt) = @_;    # @_ is populated as described in this line
    printf qq{Attempt %d/%d ... \n}, $attempt, tries;
    sleep(5);
}
Try::ALRM::ALRM {
    my ($attempt) = @_;    # @_ is populated as described in this line
    printf qq{\tTIMED OUT};
    if ( $attempt < tries ) {
        printf qq{ - Retrying ...\n};
    }
    else {
        printf qq{ - Giving up ...\n};
    }
}
Try::ALRM::finally {
    my ( $attempts, $success ) = @_;    # @_ is populated as described in this line
    my $tries   = tries;                # will be 1
    my $timeout = timeout;              # will be 3
    printf qq{%s after %d of %d attempts (timeout of %d)\n}, ($success) ? q{Success} : q{Failure}, $attempts, $tries, $timeout;
}
timeout => 3, tries => 1;

__END__

Example output:

Eventual success:
	Attempt 1/4 of something that might take more than 3 second
		TIMED OUT - Retrying ...
	Attempt 2/4 of something that might take more than 3 second
		TIMED OUT - Retrying ...
	Attempt 3/4 of something that might take more than 3 second
	OK after 3/4 attempts

Total fail:

	Attempt 1/4 of something that might take more than 3 second
		TIMED OUT - Retrying ...
	Attempt 2/4 of something that might take more than 3 second
		TIMED OUT - Retrying ...
	Attempt 3/4 of something that might take more than 3 second
		TIMED OUT - Retrying ...
	Attempt 4/4 of something that might take more than 3 second
		TIMED OUT - Retrying ...
	NOT OK after 4/4 attempts

