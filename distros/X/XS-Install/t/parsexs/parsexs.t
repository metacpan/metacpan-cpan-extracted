use strict;
use warnings;
use Test::More;
use Test::Deep;
use ExtUtils::ParseXS;
use XS::Install::ParseXS;

plan skip_all => 'set TEST_FULL=1 to enable parsexs tests' unless $ENV{TEST_FULL};

my $extutils_dir = $INC{'ExtUtils/ParseXS.pm'};
$extutils_dir =~ s/ParseXS\.pm$//;
my $xsubpp = $extutils_dir.'xsubpp';
my $deftm  = $extutils_dir.'typemap';

plan skip_all => 'xsubpp not found' unless -f $xsubpp;
plan skip_all => 'default typemap not found' unless -f $deftm;

my $res = process('t/parsexs/xs.txt');
print $res;

done_testing;

sub process {
    my $file = shift;

    @ARGV = (qw# -hiertype -C++ -csuffix .cc -typemap #, $deftm, qw# -typemap ../../typemap #, $file);

    pipe(my $r, my $w) or die $!;
    
    my $pid = fork() // die $!;
    
    unless ($pid) {
        close $r;
        *STDOUT = $w;
        do $xsubpp or die $@;
    }
    
    close $w;
    waitpid $pid, 0;
    my $child_status = $?;
    
    is $child_status, 0, "[$file] parsexs success";
    
    my $result = join '', <$r>;
    ok $result, "[$file] we have result";
    
    return $result;
}

1;