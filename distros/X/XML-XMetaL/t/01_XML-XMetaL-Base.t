# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN {
    use lib ('lib', '../lib');
    use_ok('XML::XMetaL::Base');
    use_ok('XML::XMetaL::Factory');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dispatcher;
my $xmetal;
SET_UP: {
    my $factory = XML::XMetaL::Factory->new();
    my $xml = join "", <DATA>;
    $xmetal = $factory->create_xmetal($xml);
    $dispatcher = XML::XMetaL::Base->new(-application => $xmetal);
}

AUTOLOAD_TEST: {
    my $alert_status;
    eval {
        $xmetal->{DisplayAlerts} = 0;# -1 => Alert boxes ON ; 0 => Alert boxes OFF
        $alert_status = $dispatcher->NO_SUCH_EVENT();
        $xmetal->{DisplayAlerts} = -1;
    };
    diag($@) if $@;
    is($alert_status, 0, "AUTOLOAD() test");
}



__DATA__
<?xml version="1.0"?>
<!DOCTYPE Article PUBLIC "-//SoftQuad Software//DTD Journalist v2.0 20000501//EN" "journalist.dtd">
<Article> 
    <Title>XMetaL Test Document</Title>
    <Sect1> 
        <Title>Section</Title>
        <Para>First paragraph</Para>
        <Para>Second paragraph</Para> 
    </Sect1> 
</Article>