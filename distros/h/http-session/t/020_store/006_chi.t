use strict;
use warnings;
use Test::Requires 'CHI';
use Test::More tests => 4*2;
use t::Exception;
use HTTP::Session;
use CGI;
use HTTP::Session::State::Null;
require HTTP::Session::Store::CHI;

run_tests(
    HTTP::Session::Store::CHI->new(
        chi => CHI->new(driver => 'Memory', datastore => {}),
        expires => 60*60,
    )
);
run_tests(
    HTTP::Session::Store::CHI->new(
        chi => +{ driver => 'Memory', datastore => {} },
        expires => 60*60,
    )
);

sub run_tests {
    my $store = shift;
    $store->insert('foo' => 'bar');
    is $store->select('foo'), 'bar';
    $store->update('foo' => 'baz');
    is $store->select('foo'), 'baz';
    $store->delete('foo' => 'baz');
    is $store->select('foo'), undef;
    $store->insert('foo' => {boo => 'fy'});
    is $store->select('foo')->{'boo'}, 'fy', 'complex';
}

