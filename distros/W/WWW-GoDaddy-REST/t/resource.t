#!perl

use strict;
use warnings;

use Carp qw/cluck/;

use File::Slurp qw(slurp);
use FindBin;
use Test::MockObject::Extends;
use Test::More;
use Test::Exception;
use WWW::GoDaddy::REST;
use WWW::GoDaddy::REST::Resource;
use WWW::GoDaddy::REST::Util qw(json_decode);

my $URL_BASE    = 'http://example.com/v1';
my $SCHEMA_FILE = "$FindBin::Bin/schema.json";
my $SCHEMA_JSON = slurp($SCHEMA_FILE);

my $schema_struct = json_decode($SCHEMA_JSON);

my $c = WWW::GoDaddy::REST->new( { url => $URL_BASE, schemas_file => $SCHEMA_FILE } );

subtest 'constructor' => sub {
    lives_ok { WWW::GoDaddy::REST::Resource->new( { client => $c, fields => {} } ) }
    'required params';
    dies_ok { WWW::GoDaddy::REST::Resource->new( { fields => {} } ) } 'client is required';
    dies_ok { WWW::GoDaddy::REST::Resource->new( { client => $c, fields => undef } ) }
    'fields is required';
    dies_ok { WWW::GoDaddy::REST::Resource->new( { client => $c } ) } 'fields is required';
    dies_ok { WWW::GoDaddy::REST::Resource->new( { client => $c, fields => [] } ) }
    'fields must be hashref';
};

subtest 'fields' => sub {
    my $r = WWW::GoDaddy::REST::Resource->new( { fields => $schema_struct, client => $c } );
    subtest 'get' => sub {
        subtest 'basic' => sub {
            is( $r->f('type'),     'collection', 'getting a field works' );
            is( $r->field('type'), 'collection', 'getting a field works' );
        };
        subtest 'converting to Resource objects' => sub {
            my $data_plain = $r->f('data');
            my $data_res   = $r->f_as_resources('data');
            isnt( $data_plain->[0], 'WWW::GoDaddy::REST::Schema', 'get - no transformation' );
            isa_ok( $data_res->[0], 'WWW::GoDaddy::REST::Schema', 'get - with transformation' );

            my $not_a_res = $r->f_as_resources('type');
            is( $not_a_res, 'collection', 'get - with transformation, but not transformed' );

            # missing a type field
            my $schema_res = WWW::GoDaddy::REST::Resource->new(
                {   client => $c,
                    fields => {
                        id              => 'magic',
                        type            => 'schema',
                        resourceActions => {
                            'cast' => {
                                'input'  => 'string',
                                'output' => 'bool'
                            }
                        }
                    }
                }
            );
            my $actions_res = $schema_res->f_as_resources('resourceActions');

            isa_ok(
                $actions_res->{cast},
                'WWW::GoDaddy::REST::Resource',
                'get - with transformation'
            );
            is( $actions_res->{cast}->type, 'apiaction', 'type was filled in' );

        };
    };
    subtest 'set' => sub {
        my $orig = $r->f('type');
        is( $r->f( 'type', 'asdf' ), 'asdf', 'setting a field returns new value' );
        is( $r->f('type'), 'asdf', 'field was indeed set' );
        is( $r->field( 'type', 'asdf2' ), 'asdf2', 'setting a field returns new value' );
        is( $r->field('type'), 'asdf2', 'field was indeed set' );
        $r->f( 'type', $orig );
    };
};

subtest 'find_implementation' => sub {
    is( WWW::GoDaddy::REST::Resource->find_implementation('schema'),
        'WWW::GoDaddy::REST::Schema', 'schema handler is present' );
    is( WWW::GoDaddy::REST::Resource->find_implementation('collection'),
        'WWW::GoDaddy::REST::Collection',
        'collection handler is present'
    );
    is( WWW::GoDaddy::REST::Resource->find_implementation('asfasdfadsf'),
        undef, 'unknown handler should return undef' );
};

subtest 'register_implementation' => sub {
    WWW::GoDaddy::REST::Resource->register_implementation( 'foo' => 'Bar::Baz' );
    is( WWW::GoDaddy::REST::Resource->find_implementation('foo'),
        'Bar::Baz', 'registering subclasses works' );
    WWW::GoDaddy::REST::Resource->register_implementation(
        'foo2' => 'Bar2::Baz2',
        'bar2' => 'Biz2::Buzz2'
    );
    is( WWW::GoDaddy::REST::Resource->find_implementation('foo2'),
        'Bar2::Baz2', 'registering multiple subclasses works 1' );
    is( WWW::GoDaddy::REST::Resource->find_implementation('bar2'),
        'Biz2::Buzz2', 'registering multiple subclasses works 2' );

    dies_ok { WWW::GoDaddy::REST::Resource->register_implementation( 1, 2, 3 ) }
    'odd number of elements dies';
};

subtest 'to_string' => sub {

    my $r = Test::MockObject::Extends->new(
        WWW::GoDaddy::REST::Resource->new( { fields => $schema_struct, client => $c } ) );
    $r->mock(
        'fields' => sub {
            return undef;
        }
    );
    lives_ok { $r->to_string } 'fields undef emulation - should live';
    $r->unmock('fields');
    lives_ok { $r->to_string } 'fields defined emulation - should live';
};

done_testing();
