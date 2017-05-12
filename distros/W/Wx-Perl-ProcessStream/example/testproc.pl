use strict;
my $counter = 0;

# NO BUFFERING
$| = 1;

# do work
while( $counter < 10 ) {
    print qq(Process $$ continues $counter\n);
    $counter++;
    sleep 3;
}
