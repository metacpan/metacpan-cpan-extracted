use strict;
use warnings;
use lib qw(../../ .);
use Test::Requires 'CHI';
use Test::More tests => (4 + 12) * 2;
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

    my $bad_key = "x" x 1024 . rand();
    injection(sub { $store->select($bad_key); });
    injection(sub { $store->insert($bad_key, {foo => 'bar'}); });
    injection(sub { $store->update($bad_key, {foo => 'bar'}); });

    $bad_key = "x\r\nstats\r\n" . rand();
    injection(sub { $store->select($bad_key); });
    injection(sub { $store->insert($bad_key, {foo => 'bar'}); });
    injection(sub { $store->update($bad_key, {foo => 'bar'}); });

    $bad_key = "m e m c a c h e d" . rand();
    injection(sub { $store->select($bad_key); });
    injection(sub { $store->insert($bad_key, {foo => 'bar'}); });
    injection(sub { $store->update($bad_key, {foo => 'bar'}); });

    $bad_key = qq!\x{3042}!x100;
    injection(sub { $store->select($bad_key); });
    injection(sub { $store->insert($bad_key, {foo => 'bar'}); });
    injection(sub { $store->update($bad_key, {foo => 'bar'}); });
}

sub injection {
    my $code = shift;
    eval { $code->() };
    like $@, qr/injection/;
}
