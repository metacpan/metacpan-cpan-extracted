use warnings;
use strict;

use Test::More tests => 51;

BEGIN {
    use_ok q{Try::ALRM};
}

is timeout, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
ok timeout(5), q{'timeout' method called as "setter" without issue};
is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );

is tries, $Try::ALRM::TRIES, sprintf( qq{default tries is %d attempts}, tries );
ok tries(5), q{'tries' method called as "setter" without issue};
is 5, $Try::ALRM::TRIES, sprintf( qq{default tries is %d attempts}, tries );

retry {
    my ($attempt) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    printf qq{Attempt %d/%d of something that might take more than 3 second\n}, $attempt, tries;
    sleep 3;
}
ALRM {
    my ($attempt) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    my $tries = tries;
    ok $attempt <= $tries, qq{retry attempt <= limit, $attempt <= $tries};
    note qq{\tTIMED OUT - Retrying ...\n};
}
finally {
    my ( $attempt, $succeeded ) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    my $tries = tries;
    is $attempt, $tries, qq{expected number of tries found ($tries)};
}
timeout => 1, tries => 2;

is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
is 5, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},  tries );

retry {
    my ($attempt) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    printf qq{Attempt %d/%d of something that might take more than 3 second\n}, $attempt, tries;
    sleep 3;
}
ALRM {
    my ($attempt) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    my $tries = tries;
    ok $attempt <= tries, qq{retry attempt <= limit, $attempt <= $tries};
    note qq{\tTIMED OUT - Retrying ...\n};
}
timeout => 1, tries => 2;

is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
is 5, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},  tries );

retry {
    my ($attempt) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    my $tries = tries;
    printf qq{Attempt %d/%d of something that might take more than 3 second\n}, $attempt, tries;
    sleep 3;
}
finally {
    my ( $attempt, $succeeded ) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    my $tries = tries;
    is $attempt, tries, qq{expected number of tries found ($tries)};
}
timeout => 1, tries => 2;

is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
is 5, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},  tries );

retry {
    my ($attempt) = @_;
    is 1, $Try::ALRM::TIMEOUT, sprintf( qq{temporary timeout is %d seconds}, timeout );
    is 2, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},    tries );
    my $tries = tries;
    ok $attempt <= tries, qq{retry attempt <= limit, $attempt <= $tries};
    sleep 3;
}
timeout => 1, tries => 2;

is 5, $Try::ALRM::TIMEOUT, sprintf( qq{default timeout is %d seconds}, timeout );
is 5, $Try::ALRM::TRIES,   sprintf( qq{default tries is %d attempts},  tries );
