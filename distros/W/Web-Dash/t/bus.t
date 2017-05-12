use strict;
use warnings;
use Test::More;
use Net::DBus;
use Test::MockModule;

BEGIN {
    use_ok('Web::Dash::Lens');
}

my %common_params = (
    service_name => 'com.canonical.Unity.Lens.Applications',
    object_name => '/com/canonical/unity/lens/applications',
);

my $mockdbus = Test::MockModule->new('Net::DBus');
my %calls = ();
foreach my $method (qw(session system new)) {
    $mockdbus->mock($method, sub {
        my (@args) = @_;
        push(@{$calls{$method}}, [@args]);
        return $mockdbus->original($method)->(@args);
    });
}

{
    %calls = ();
    my $lens = eval {
        Web::Dash::Lens->new(%common_params, bus_address => ':session');
    };
    is(@{$calls{session}}, 1, "session called once");
}

{
    %calls = ();
    my $lens = eval {
        Web::Dash::Lens->new(%common_params, bus_address => ':system')
    };
    is(@{$calls{system}}, 1, "system called once");
}

{
    %calls = ();
    my $lens = eval {
        Web::Dash::Lens->new(%common_params, bus_address => 'hoge')
    };
    is(@{$calls{new}}, 1, "new called once");
    is($calls{new}[0][1], 'hoge', "... and its address param is hoge");
}

done_testing();
