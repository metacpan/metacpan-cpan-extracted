use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use Test::More;
use Test::LogFile;

my $file = log_file;

my $pid = fork();
if ( $pid == 0 ) {

    # run any worker
    my $agent = catfile( $Bin, '../agent.pl' );
    system( $agent, '--log', $file );
}
elsif ($pid) {

    # wait for worker
    waitpid($pid, 0);

    # testing
    count_ok(
        file  => $file,
        str   => "number",
        count => 3,          # count that appear str arg in logfile
        hook  => sub {
            my $line = shift;

            # other test when hitting str arg
            if ( $line =~ /1/ ) {
                note $line;
                ok 1, "found 1";
            }
        }
    );
    done_testing;
}

