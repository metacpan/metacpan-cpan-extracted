use strict;
use warnings;
use Test::More;
use Test::Deep;
use ExtUtils::ParseXS;
use XS::Install::ParseXS;

#plan skip_all => 'set TEST_FULL=1 to enable parsexs tests' unless $ENV{TEST_FULL};

my $extutils_dir = $INC{'ExtUtils/ParseXS.pm'};
$extutils_dir =~ s/ParseXS\.pm$//;
my $xsubpp = $extutils_dir.'xsubpp';
my $deftm  = $extutils_dir.'typemap';
$deftm =~ s/site_perl\///;

plan skip_all => 'xsubpp not found' unless -f $xsubpp;
plan skip_all => 'default typemap not found' unless -f $deftm;

process('t/parsexs/xs.txt');

done_testing;

sub process {
    my $file = shift;

    my %args = (
        filename => $file,
        hiertype => 1,
        csuffix => '.cc',
        typemap => [$deftm, '../../typemap'],
    );
    
    my $pxs = ExtUtils::ParseXS->new;
    #*STDOUT = *STDIN;
    $pxs->process_file(%args);
    
    is $pxs->report_error_count(), 0;
}

1;
