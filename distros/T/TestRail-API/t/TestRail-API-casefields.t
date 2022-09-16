use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep;

use TestRail::API;

{
    my $this = { this => 'thing' };
    my $that = { that => 'thing' };
    my $theOther = { other => 'thing'};

    no warnings qw{redefine once};
    local *TestRail::API::_doRequest= sub { return $this };
    use warnings;

    my $tr = bless({},'TestRail::API');

    is_deeply($tr->getCaseFields(),$this, "getCaseFields appears to operate correctly on initial hit");

    no warnings qw{redefine once};
    local *TestRail::API::_doRequest= sub { my ($self,$url, $method, $input) = @_; return $that unless $method; return $input };
    use warnings;

    is_deeply($tr->getCaseFields(),$this, "getCaseFields caches correctly");
    is_deeply($tr->addCaseField(%$theOther),$theOther,"addCaseField appears to grab and pass options correctly");

    is_deeply($tr->getCaseFields(),$that, "getCaseFields invalidates cache correctly");

}
