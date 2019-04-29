use strict;
use warnings;

use Test2::V0 -target => 'WebService::Pixela::Graph';

use JSON;
use WebService::Pixela;

my $username = 'testuser';
my $token    = 'thisistoken';

my $pixela = WebService::Pixela->new(username => $username, token => $token);
my $graph  = $pixela->graph;

subtest 'use_methods' => sub {
    can_ok($CLASS,qw/new client id create get get_svg update delete html pixels _color_validate/);
};

subtest 'new' => sub {
    ok( my $obj = $CLASS->new($pixela),'create instance');
    isa_ok($obj->{client}, [qw/'WebService::Pixela/], 'client is WebService::Pixela instance');
};

subtest 'use_methods_by_instance' => sub {
    can_ok($graph ,qw/new client id create get get_svg update delete/);
};

subtest 'client_method' => sub {
    isa_ok($graph->client, [qw/'WebService::Pixela/], 'client is WebService::Pixela instance');
};

subtest 'id_method' => sub {
    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $graph  = $pixela->graph;
    my $test_id = 'testid';

    $graph->{id} = $test_id;
    is ($graph->id,$test_id, 'no input argument return id value');
    is ($graph->id(),$test_id, 'no input argument return id value');

    isa_ok($graph->id('update'), [$CLASS], 'The WebService::Pixela::Graph instance returns as a return value');
    like($graph->id('update2'),
         object {
             call  id => 'update2';
             field id => 'update2';
         },
         'id method set id at instance');
    like($graph->id(undef),
         object {
             call  id => undef;
             field id => undef;
         },
         'id method set undef id at instance');
};

#subtest '_color_validate' => sub {
#    my @colors = (qw/shibafu momiji sora ichou ajisai kuro/);
#};

subtest 'no_args_and_invalid_create_method_croak' => sub {
    like( dies {$graph->create()}, qr/require id/, "no input id");
    like( dies {$graph->create(id => 'testid')}, qr/require name/, "no input name");
    like( dies {$graph->create(id => 'testid', name => 'testname')}, qr/require unit/, "no input unit");
    like( dies {$graph->create(id => 'testid', name => 'testname', unit => 1, )}, qr/require type/, "no input type");
    like( dies {$graph->create(id => 'testid', name => 'testname', unit => 1, type => 'invalid')}, qr/invalid type/, "invalid type");
    like( dies {$graph->create(id => 'testid', name => 'testname', unit => 1, type => 'int')}, qr/require color/, "no input color");
    like( dies {$graph->create(id => 'testid', name => 'testname', unit => 1, type => 'int', color => 'invalid')}, qr/invalid color/, "invalid color");
};

subtest 'create_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header => sub {shift @_; return [@_]; }],
    );

    isnt($graph->id,'testid');

    my %params = (
        id    => 'testid',
        name  => 'testname',
        unit  => 'testunit',
        type  => 'int',
        color => 'ichou',
    );

    my $path = 'users/'.$username.'/graphs';

    is(
        $graph->create(%params),
        [   'POST',
            $path,
            \%params,
        ],
        'input params call create method'
    );

    is($graph->id,'testid');
};

subtest 'get_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header => sub {shift @_; return { graphs => [@_] }; }],
    );

    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $graph  = $pixela->graph;

    my $path = 'users/'.$username.'/graphs';

    $pixela->decode(1);
    is(
        $graph->get(),
        [   'GET',
            $path,
        ],
        'call get method'
    );

    $pixela->decode(0);
    is(
        $graph->get(),
        {
            graphs =>
                [   'GET',
                    $path,
                ],
        },
        'call get method at decode(0)'
    );
};

subtest 'get_svg_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [query_request => sub {shift @_; return [@_]; }],
    );

    my $graph = WebService::Pixela->new(username => $username, token => $token)->graph;

    my $id = "testid";
    my $path = 'users/'.$username.'/graphs/'.$id;

    $graph->id($id);

    my %params = (
        date  => "date_test",
        mode  => "mode_test",
        dummy => "not_include_return",
    );

    is(
        $graph->get_svg(%params),
        [   'GET',
            $path,
            {
                date  => "date_test",
                mode  => "mode_test",
            },
        ],
        'input args call get svg method'
    );

    is(
        $graph->get_svg(),
        [   'GET',
            $path,
            {},
        ],
        'not input args call get svg method'
    );
    $graph->id(undef);

    like(dies {$graph->get_svg(%params)} ,qr/require graph id/, 'input args call get svg method' );

    $params{id} = $id;

    is(
        $graph->get_svg(%params),
        [   'GET',
            $path,
            {
                date  => "date_test",
                mode  => "mode_test",
            },
        ],
        'input args call get svg method'
    );


};


subtest 'input_arg_call_update_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header => sub {shift @_; return [@_]; }],
    );

    my $graph = WebService::Pixela->new(username => $username, token => $token)->graph;

    my %params = (
        id               => 'input_id',
        name             => 'graphname',
        unit             => 'testunit',
        color            => 'momiji',
        purge_cache_urls => [qw/test_cache hoge/],
        self_sufficient  => 'test_sufficient',
    );
    my $path = 'users/'.$username.'/graphs/input_id';

    is(
        $graph->update(%params),
        [   'PUT',
            $path,
            {
                name             => 'graphname',
                unit             => 'testunit',
                color            => 'momiji',
                purgeCacheURLs   => [qw/test_cache hoge/],
                selfSufficient   => 'test_sufficient',
            },
        ],
        'input args call get svg method'
    );
};

subtest 'input_arg_call_update_method' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header => sub {shift @_; return [@_]; }],
    );

    my $graph = WebService::Pixela->new(username => $username, token => $token)->graph;
    like (dies {$graph->update()}, qr/require graph id/, 'no input graph id');
};

subtest 'html' => sub {
    my $mock = mock 'WebService::Pixela' => (
        override => [request_with_xuser_in_header => sub {shift @_; return [@_]; }],
    );

    my $graph = WebService::Pixela->new(username => $username, token => $token)->graph;
    my %param = ( id => 'testid');
    $graph->id($param{id});
    is($graph->html,'https://pixe.la/v1/users/testuser/graphs/testid.html');

    $graph->id(undef);
    is($graph->html(%param),'https://pixe.la/v1/users/testuser/graphs/testid.html');
    $param{line} = 1;
    is($graph->html(%param),'https://pixe.la/v1/users/testuser/graphs/testid.html?mode=line');
};

subtest 'pixels' => sub {
my $mock = mock 'WebService::Pixela' => (
    override => [request_with_xuser_in_header =>
        sub {
            shift @_;
            return { pixels => [@_]};
        }],
    );


    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $graph  = $pixela->graph;

    my $id = 'input_id';

    my %params = (
        id   => $id,
        from => '20180101',
        to   => '20180202',
    );

    my $path = 'users/'.$username.'/graphs/'. $id . '/pixels';
    $pixela->decode(1);
    is(
        $graph->pixels(%params),
        [   'GET',
            $path,
            {
                from => '20180101',
                to   => '20180202',
            },
        ],
        'input args call get pixels method'
    );

    $pixela->decode(0);
    is(
        $graph->pixels(%params),
        {
            pixels =>
                [   'GET',
                    $path,
                    {
                        from => '20180101',
                        to   => '20180202',
                    },
                ],
        },
        'decode 0 is dumpping original json'
    );
};

subtest 'stats' => sub {
my $mock = mock 'WebService::Pixela' => (
    override => [request =>
        sub {
            shift @_;
            return [@_] ;
        }],
    );


    my $pixela = WebService::Pixela->new(username => $username, token => $token);
    my $graph  = $pixela->graph;

    my $id = 'input_id';

    my $path = 'users/'.$username.'/graphs/'. $id . '/stats';
    is(
        $graph->stats($id),
        [   'GET',
            $path,
        ],
        'input args call get stats method'
    );
};

done_testing;
