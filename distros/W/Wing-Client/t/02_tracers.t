use Test::More;
use Test::Deep;

use lib 'lib';
use 5.010;
use Ouch;
use JSON;
use HTTP::Thin;
use List::Util qw{first};

use_ok 'Wing::Client';

# process responses
my $wing = Wing::Client->new(uri=>'https://www.thegamecrafter.com');

if (HTTP::Thin->new->get('http://www.apple.com')->content =~ m,<title>Apple</title>,) { # skip online tests if we have no online access
    # get
    my $result = $wing->get('_test');
    ok exists $result->{tracer};
    my $tracer = first { $_->{name} eq 'tracer' } $wing->agent->cookie_jar->cookies_for('https://www.thegamecrafter.com');
    is $tracer->{value}, $result->{tracer}, 'cookie and result JSON match';
} # end skip online tests if we have no online access 
else {
    note "Skipping online tests, because we don't appear to have internet access.";
}

done_testing();
