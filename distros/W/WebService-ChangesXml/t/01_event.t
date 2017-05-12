use strict;
use Test::More 'no_plan';

BEGIN {
    use_ok "WebService::ChangesXml";
}

my $changes = WebService::ChangesXml->new("http://www.weblogs.com/changes.xml");

$changes->add_handler(\&found_new_ping);
$changes->updated(time() - 10 * 60); # in 10 minutes

$changes->find_new_pings();
my $first = $changes->updated();

$changes->updated(1);
is 1, $changes->updated, "update() set ok";

sub found_new_ping {
    my($blog_name, $blog_url, $when) = @_;
    like $when, qr/^10\d+/, "when is epoch time: $when";
    is scalar(@_), 3, "argscount is 3";
}


