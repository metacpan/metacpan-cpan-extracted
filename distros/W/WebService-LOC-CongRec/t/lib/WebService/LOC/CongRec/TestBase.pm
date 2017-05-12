use warnings;

=head1 NAME

WebService::LOC::CongRec::TestBase

=head1 AUTHOR

Drew Stephens <drew@dinomite.net>

=head1 DESCRIPTION

Base class for test classes.  Initializes logging.

=cut

package WebService::LOC::CongRec::TestBase;
use base 'Test::Class';

use Carp;
use FindBin;
use Log::Log4perl;

=head3 getTestDir()

Find the top-leve test directory (the one that contains our log4perl.conf)

=cut

my $testDir;
sub getTestDir {
    return $testDir if (defined $testDir);

    # Find the test directory
    if (-e $FindBin::Bin . '/log4perl.conf') {
        $testDir = $FindBin::Bin;
    } else {
        my $dir = $FindBin::Bin;

        # Look for log4perl.conf in parent directories
        for (my $numUp = 0; $numUp < 5; $numUp++) {
            $dir =~ s/\/[^\/]*$//;

            my $configFile = $dir . '/log4perl.conf';
            if (-e $configFile) {
                $testDir = $dir;
                last;
            }
        }
    }

    croak "Couldn't find the root test directory :-(" unless (defined $testDir);

    return $testDir;
}

# Setup logging
Log::Log4perl->init_once(getTestDir() . '/log4perl.conf');

1;
