use strict;

use Test::More tests =>17;

use URL::Check;
use File::Basename qw/dirname/;


delete $ENV{URL_CHECK_CONFIG};


#check error reports

my %h;
eval {
    URL::Check::p_addOnErrorLine("onerror.pipo=y", \%h);
};
ok ($@,  'cannot parse error line');

URL::Check::p_addOnErrorLine("onerror.mailto=a,b,c", \%h);
ok($h{onError}{mailto}, "onerror mailto filled");
my @tmp = @{$h{onError}{mailto}};
is(scalar @tmp, 3, "found 3 mailto addresses");

URL::Check::p_addOnErrorLine("onerror.console=y", \%h);
ok($h{onError}{mailto}, "onerror mailto is still filled");
ok($h{onError}{console}, "onerror reported on console (y)");

URL::Check::p_addOnErrorLine("onerror.console=n", \%h);
ok(! $h{onError}{console}, "onerror not reported on console (n)");

URL::Check::p_addOnErrorLine("onerror.console=yes", \%h);
ok($h{onError}{console}, "onerror reported on console (yes)");

URL::Check::p_addOnErrorLine("onerror.console=T", \%h);
ok($h{onError}{console}, "onerror reported on console (T)");

URL::Check::p_addOnErrorLine("onerror.console=true", \%h);
ok($h{onError}{console}, "onerror reported on console (true)");


#check error rporting in case of config file misdefined
eval {
    URL::Check::readConfig();
};
ok ($@=~/no config file is passed/i,  'readConfig dies when no params nor $URL_CHECK_CONFIG');

eval {
    URL::Check::readConfig("pipofile");
};
ok ($@=~/cannot open config file/i,  'readConfig dies because cannot open config file');
undef $@;

my $configFile = "t/resources/config/simple.txt";
ok(-f $configFile, "checking presence of $configFile");


#check simple config
URL::Check::readConfig($configFile);
my %config = %URL::Check::config;

is ($config{default}{onError}{mailto}[0],  'steve.jobs@apple.com.xx', 'check on error email');
is ($config{default}{onError}{mailto}[1],  'steve.wozniak@pear.com.xx', 'check on error email');

is ( scalar(@{$config{urls}}), 4, "four urls defined");

my %url = %{$config{urls}[0]};
is ($url{url}, 'http://www.apple.com', 'check url field');

%url = %{$config{urls}[2]};
is ($url{url}, 'http://www.facebook.com', 'check url field');
