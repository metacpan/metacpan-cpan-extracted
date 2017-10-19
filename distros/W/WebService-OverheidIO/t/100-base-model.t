use strict;
use warnings;

use HTTP::Response;
use IO::All;
use Sub::Override;
use Test::Deep;
use Test::More;
use Test::Exception;

use WebService::OverheidIO;

sub _create_overheid_io_ok {
    my %options = @_;
    my $model   = WebService::OverheidIO->new(
        type        => 'foo',
        fieldnames  => [],
        queryfields => [],
        %options,
        $options{base_uri} ?
            (base_uri => URI->new($options{base_uri})) : (),
        key => $options{key} // 'testsuite',
    );
    isa_ok($model, "WebService::OverheidIO");
    return $model;
}

{
    my $model = _create_overheid_io_ok();

    my $answer = '{"some" : "json"}';

    my $override = Sub::Override->new(
        'LWP::UserAgent::request' => sub {
            return HTTP::Response->new(200, undef, undef, $answer);
        },
    );

    my $a = $model->search();
    cmp_deeply($a, { some => 'json' }, "JSON decoding works fine");

    is($model->type, 'foo', "Has correct type");
    is($model->base_uri->as_string, 'https://overheid.io/api/foo', "Base URI has type");

    _test_overheid_io_uri_query("Simple search", $model, "foo");
    _test_overheid_io_uri_query("Filter search", $model, "foo", filter => { foo => 'bar' });


    $override->replace(
        'LWP::UserAgent::request' => sub {
            return HTTP::Response->new(401, undef, undef, 'Eek a mouse!');
        },
    );

    throws_ok(
        sub {
            my $a = $model->search();
        },
        qr/Eek a mouse\!/,
        "OverheidIO did not return a 200 OK"
    );

}

sub _test_overheid_io_uri_query {
    my ($test_name, $model, $search, %params) = @_;

    my $uri;
    my $override = Sub::Override->new('WebService::OverheidIO::_call_overheid_io' => sub { shift; $uri = shift });
    $model->search($search, %params);

    my @query = $uri->query_form;
    my @expected_query = ("size" => 30,);

    foreach (keys %{ $params{filter} }) {
        push(@expected_query, "filters[$_]" => $params{filter}{$_});
    }

    foreach (@{ $model->fieldnames }) {
        push(@expected_query, 'fields[]' => $_);
    }

    foreach (@{ $model->queryfields }) {
        push(@expected_query, 'queryfields[]' => $_);
    }
    push(@expected_query, query => "foo");

    @query          = sort { $a cmp $b } @query;
    @expected_query = sort { $a cmp $b } @expected_query;

    cmp_deeply(\@query, \@expected_query, "Correct query params: $test_name");
    is($uri->path, "/api/foo", "API path is correct: $test_name");
}

done_testing;
