#!perl

use strict;
use warnings;

use File::Find;
use Perl::Critic;
use Test::More;

sub test_files {
    my ($critic, $files) = @_;

    for my $file (@$files) {
        my @findings = $critic->critique($file);

        ok(scalar(@findings) == 0, "Critique for $file");
        for my $finding (@findings) {
            diag($finding->description);
        }
    }

    return;
}


my @on_disk;
sub collect {
    return if $File::Find::name !~ m/\.pm$/;

    my $module = $File::Find::name;
    push @on_disk, $module
}
find(\&collect, 'lib/');

test_files(Perl::Critic->new(
               -profile => 't/perlcriticrc',
               -severity => 5,
               -theme => '',
               -exclude => [
                    'OTRS::',  # some CPANtesters use this by default
               ],
               -include => [
#                    'Documentation::'
               ]),
           \@on_disk);


done_testing;

