use strict;
use warnings;

use Test2::V0 -target => 'WebService::Pixela::Pixel';

use WebService::Pixela;

my $username = 'testuser';
my $token    = 'thisistoken';

subtest 'use_methods' => sub {
    can_ok($CLASS,qw/new client post get update increment decrement delete _check_id _create_path/);
};

subtest 'new_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    ok( my $obj = $CLASS->new($pixela), 'create instance');
    isa_ok($obj->{client}, [qw/WebService::Pixela/], 'client is WebService::Pixela');
};

subtest 'client_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    isa_ok($pixela->pixel->client,[qw/WebService::Pixela/], 'cient is WebService::Pixela');
};

subtest '_check_id  method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $mock_id = 'mock_id';

    like( dies {$pixela->pixel->_check_id()}, qr/require graph_id/, 'require graph_id');
    $pixela->graph->id($mock_id);
    is($pixela->pixel->_check_id(), $mock_id, 'set instance id');
    is($pixela->pixel->_check_id('mock_id_2'), 'mock_id_2', 'set argument id');
};

subtest '_create_path method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $mock_id = 'mock_id';
    my $date    = '121101';

    my $url = 'users/testuser/graphs/mock_id';

    is($pixela->pixel->_create_path($mock_id), $url, 'not_insert_date');
    $url = 'users/testuser/graphs/mock_id/121101';
    is($pixela->pixel->_create_path($mock_id,$date), $url, 'insert_date');
};

subtest 'post_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);

    my $mock_id = 'mock_id';
    $pixela->graph->id($mock_id);

    like(dies {$pixela->pixel->post()}, qr/require date/, 'require date');

    my $mock_date = '20121211';

    like(dies {$pixela->pixel->post(date => $mock_date)}, qr/require quantity/, 'require quantity');

    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return [@_];
            }],
    );
    my $mock_path     = $pixela->pixel->_create_path($mock_id);
    my $mock_quantity = 9;

    my $mock_res = [
            'POST',
            $mock_path,
            {
                date     => $mock_date,
                quantity => $mock_quantity,
            },
    ];

    is($pixela->pixel->post(date => $mock_date, quantity => $mock_quantity),
        $mock_res,
        'call post (not use quantity)'
    );

    my $mock_optional_data = 'mock_optional_data';

    $mock_res->[2]->{optionalData} = $mock_optional_data;

    is($pixela->pixel->post(date => $mock_date, quantity => $mock_quantity, optional_data => $mock_optional_data),
        $mock_res,
        'call post (use quantity)'
    );
};


subtest 'get_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);

    my $mock_id = 'mock_id';
    $pixela->graph->id($mock_id);

    like(dies{$pixela->pixel->get();}, qr/require date/, 'no input date');

    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return [@_];
            }],
    );

    my $mock_date = '20121211';
    my $mock_path = $pixela->pixel->_create_path($mock_id,$mock_date);

    is($pixela->pixel->get(date => $mock_date),
        ['GET',$mock_path],
        'call get_method'
    );
};

subtest 'update_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $mock_id = 'mock_id';
    $pixela->graph->id($mock_id);

    like(dies{$pixela->pixel->update();}, qr/require date/, 'no input date');

    my $mock_date = '20121211';
    my $mock_path     = $pixela->pixel->_create_path($mock_id,$mock_date);
    my $mock_quantity = 9;
    my $mock_optional_data = 'mock_optional_data';

    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return [@_];
            }],
    );

    is($pixela->pixel->update(date => $mock_date),
        ['PUT',$mock_path,{}],
        'call update not input param'
    );

    is($pixela->pixel->update(date => $mock_date, quantity => $mock_quantity),
        ['PUT',$mock_path,{quantity => $mock_quantity}],
        'call update use quantity param'
    );

    is($pixela->pixel->update(date => $mock_date, quantity => $mock_quantity, optional_data => $mock_optional_data),
        ['PUT',$mock_path,{quantity => $mock_quantity, optionalData => $mock_optional_data}],
        'call update use all param'
    );

};


sub increment_decrement_helper {
    my $target = shift;
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $mock_id = 'mock_id';
    $pixela->graph->id($mock_id);

    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_dual_in_header =>
            sub {
                shift @_;
                return [@_];
            }],
    );

    my $mock_path = "users/testuser/graphs/mock_id/$target";

    is($pixela->pixel->$target(),
        ['PUT',$mock_path,0],
        "call $target not input param"
    );

    is($pixela->pixel->$target(length => 999),
        ['PUT',$mock_path,999],
        "call $target input param"
    );
}

subtest 'increment_method' => sub {
    increment_decrement_helper('increment');
};

subtest 'decrement_method' => sub {
    increment_decrement_helper('decrement');
};

subtest 'delete_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $mock_id = 'mock_id';
    $pixela->graph->id($mock_id);

    like(dies{$pixela->pixel->delete()}, qr/require date/, 'require dete');

    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header =>
            sub {
                shift @_;
                return [@_];
            }],

    );
    my $mock_date = '20121211';
    my $mock_url = $pixela->pixel->_create_path($mock_id,$mock_date);

    is($pixela->pixel->delete(date => $mock_date),
        ['DELETE', $mock_url],
        'delete method'
    );
};

done_testing;
