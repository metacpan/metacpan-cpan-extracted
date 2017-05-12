use strict;
use warnings;
use Test;
use XML::Generator::PerlData;
BEGIN { plan tests => 2 }


my $pd = XML::Generator::PerlData->new();

####################################################
# circular hashref
###################################################
{
    my $a = {b => {}};
    $a->{b}->{a} = $a;

    eval {
        local $SIG{ALRM} = sub { die 'TIMEOUT' };
        alarm 3;
        $pd->parse($a);
    };
    ok(not $@);
}

####################################################
# circular arrayref
###################################################
{
    my $a = [[]];
    $a->[0]->[0] = $a;

    eval {
        local $SIG{ALRM} = sub { die 'TIMEOUT' };
        alarm 3;
        $pd->parse($a);
    };
    ok(not $@);
}


####################################################




