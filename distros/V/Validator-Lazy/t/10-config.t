#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 18;

use Validator::Lazy;

describe 'config' => sub {

    it 'empty' => sub {
        my $v = Validator::Lazy->new();
        is_deeply( [ { 'Validator::Lazy::Role::Check::Test' => {} } ], [ $v->get_field_roles( 'Test'         ) ], 'field not found fallback to default role' );
        is_deeply( [                                                ], [ $v->get_field_roles( 'Test', 'Test' ) ], 'should skip field if it is in 2nd param'  );
        is_deeply( [ { 'My::Role' => {}                           } ], [ $v->get_field_roles( 'My::Role'     ) ], 'should skip field if it is in 2nd param'  );

    };

    it 'definition' => sub {
        my $v1 = Validator::Lazy->new( config => { x => 'y' } );
        is_deeply( { x => 'y' }, $v1->config, 'config applied' );

        my $v2 = Validator::Lazy->new( { x => 'y' } );
        is_deeply( { x => 'y' }, $v2->config, 'config applied directly' );
    };

    it 'yaml' => sub {

        my $config = q/
            x: y
        /;

        my $v1 = Validator::Lazy->new( config => $config );
        is_deeply( { x => 'y' }, $v1->config, 'config applied' );

        my $v2 = Validator::Lazy->new( $config );
        is_deeply( { x => 'y' }, $v2->config, 'config applied directly' );
    };

    it 'json' => sub {

        my $config = q/
            {
                "x": "y"
            }
        /;

        my $v1 = Validator::Lazy->new( config => $config );
        is_deeply( { x => 'y' }, $v1->config, 'config applied' );

        my $v2 = Validator::Lazy->new( $config );
        is_deeply( { x => 'y' }, $v2->config, 'config applied directly' );
    };

    it 'role matching' => sub {
        my $v1 = Validator::Lazy->new( { test => 'Test' } );
        is_deeply( [ { 'Validator::Lazy::Role::Check::Test' => {} } ], [ $v1->get_field_roles( 'test' ) ], 'direct native role'  );

        my $v2 = Validator::Lazy->new( { test => 'My::Test' } );
        is_deeply( [ { 'My::Test' => {} } ], [ $v2->get_field_roles( 'test' ) ], 'direct external role'  );

        my $v3 = Validator::Lazy->new( { '/es/' => 'My::Test' } );
        is_deeply( [ { 'My::Test' => {} } ], [ $v3->get_field_roles( 'test' ) ], 'regexp role matching'  );

        my $v4 = Validator::Lazy->new( { '/ES/' => 'My::Test' } );
        is_deeply( [ { 'Validator::Lazy::Role::Check::test' => {} } ], [ $v4->get_field_roles( 'test' ) ], 'regexp role NOT match'  );

        my $v5 = Validator::Lazy->new( { '[test|check]' => 'My::Test' } );
        is_deeply( [ { 'My::Test' => {} } ], [ $v5->get_field_roles( 'test'  ) ], 'regexp role in list 1'  );
        is_deeply( [ { 'My::Test' => {} } ], [ $v5->get_field_roles( 'check' ) ], 'regexp role in list 2'  );

        my $v6 = Validator::Lazy->new( {
            '[test|check]' => 'My::Test::Ok1',
            '/es/'         => 'My::Test::Ok2',
            'es'           => 'My::Test::NO3',
            'test'         => 'My::Test::Ok4',
            'test2'        => 'My::Test::NO5',
        } );

        is_deeply(
            [
                { 'My::Test::Ok1' => {} },
                { 'My::Test::Ok2' => {} },
                { 'My::Test::Ok4' => {} },
            ],
            [
                sort { [keys %$a]->[0] cmp [keys %$b]->[0] } $v6->get_field_roles( 'test'  )
            ],
            'regexp role in list multi'
        );

        my $v7 = Validator::Lazy->new( {
            '[test|check]' => 'alias1',
            '/alias/'      => 'My::Alias::Class1',
            '[alias1]'     => 'My::Alias::Class2',
        } );

        is_deeply(
            [
                { 'My::Alias::Class1' => {} },
                { 'My::Alias::Class2' => {} },
            ],
            [
                sort { [keys %$a]->[0] cmp [keys %$b]->[0] } $v7->get_field_roles( 'test'  )
            ],
            'role from alias'
        );

        my $v8 = Validator::Lazy->new( {
            '[test|check]' => [ { 'MinMax' => { min => 10, max => 100 } }, 'TrimLR', { 'Someth' => [ 1, 2, 3 ] }, 'Int' ],
        } );

        is_deeply(
            [
                { 'Validator::Lazy::Role::Check::MinMax' => { min => 10, max => 100 } },
                { 'Validator::Lazy::Role::Check::TrimLR' => {} },
                { 'Validator::Lazy::Role::Check::Someth' => [ 1, 2, 3 ] },
                { 'Validator::Lazy::Role::Check::Int'    => {} },
            ],
            [
                $v8->get_field_roles( 'test'  )
            ],
            'list of classes: not REsorted, all types of params are allowed'
        );
    };

    # Class lists x => []
};

runtests unless caller;
