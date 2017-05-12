use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

BEGIN {
    $ENV{CATALYST_DEBUG} = 0;
    $ENV{CATTY_DEBUG}    = 0;
}
use Test::WWW::Mechanize::Catalyst::WithContext 'Catty';

my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new;
$mech->get_ok('/');

is ref( $mech->_get_context ), 'CODE', '_get_context is there';

dies_ok { $mech->get_context } 'url is required';

my $old_c;
{
    my ( $res, $c ) = $mech->get_context('/');
    isa_ok $res, 'HTTP::Response', '$res';
    is $res->code, 200, '... and request was successful';

    isa_ok $c, 'Catalyst', '$c';
    isa_ok $c, 'Catty',    '$c';
    is $c->stash->{foo}, '1', '... and the current stash is accessible';

    my $model = $c->model('Foo');
    isa_ok $model, 'Catty::Model::Foo', '$c->model';
    is $model->general,          'general', 'general model attribute works';
    is $model->context_specific, '1',     'attribute set by ACCEPT_CONTEXT works';

    $old_c = $c;
}

$mech->get_ok('/set_session/hello/world');

is $old_c->session->{hello}, undef, 'old context does not know about session after new request';
{
    my ( $res, $c ) = $mech->get_context('/');
    is $c->session->{hello}, 'world', '... but new context does';
    is $c->stash->{foo}, '2', 'new context has a new stash';
    isnt "$c", "$old_c", 'old context and new context are different refs';
    isnt $old_c->session->{hello}, $c->session->{hello}, 'session info is different before and after';
}


done_testing;
