#!/bin/false
# not to be used stand-alone
#
# helper function to run a separate Perl instance in a sub-process with a
# string as command:

# see https://stackoverflow.com/questions/56856646/how-do-i-collect-coverage-from-child-processes-when-running-cover-test-and-n
my $under_cover = defined(eval('$Devel::Cover::VERSION'));
note('running with' . ($under_cover ? '' : 'out') .' Devel::Cover');
#diag('running with' . ($under_cover ? '' : 'out') .' Devel::Cover');
my $run_perl = $^X;
$under_cover  and  $run_perl .= ' -MDevel::Cover=-silent,1';

$ENV{PERL5LIB} = join(':', @INC);

sub _sub_perl($)
{
    local $_ = join('', @_);
    $_ = `$run_perl -e '$_' 2>&1`;
    return $_;
}

1;
