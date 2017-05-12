package WWW::Selenium::Utils::PostResults;
use strict;
use warnings;
use CGI qw/:standard/;
use Config;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(write_results);

sub write_results {
    my ($q, $dest) = @_;

    open(my $fh, ">$dest") or die "Can't open $dest: $!";
    my $date = localtime;
    print $fh "Selenium results from $date\n";
    for my $p (qw(result totalTime numTestPasses numTestFailures
                  numCommandPasses numCommandFailures numCommandErrors
                  suite
                 )) {
        my $r = $q->param($p) || '';
        print $fh "$p: $r\n";
    }
    my $i = 0;
    while (1) {
        $i++;
        my $t = $q->param("testTable.$i");
        last unless $t;
        print $fh "testTable.$i: $t\n";
    } 
    close $fh or die "Can't write to $dest: $!";
}

1;
