use Test::More tests => 27;

package MyVal;

use Validation::Class;

mixin ID => {
    required   => 1,
    min_length => 1,
    max_length => 11
};

mixin TEXT => {
    required   => 1,
    min_length => 1,
    max_length => 255
};

field id => {
    mixin => 'ID',
    label => 'Object ID',
    error => 'Object ID error'
};

field name => {
    mixin => 'TEXT',
    label => 'Object Name',
    error => 'Object Name error'
};

field email => {
    mixin      => 'TEXT',
    label      => 'Object Email',
    error      => 'Object Email error',
    max_length => 500
};

field email_confirm => {
    mixin_field => 'email',
    label       => 'Object Email Confirm',
    error       => 'Object Email confirmation error',
    min_length  => 5
};

package main;

use strict;
use warnings;

my $p = {name => '', email => 'awncorp@cpan.org'};
my $v = MyVal->new(params => $p);

ok $v, 'initialization successful';
ok !$v->clear_queue, 'queue cleared, no errors';
ok $v->queue(qw/name email/), 'queued name and email';
ok !$v->validate, 'validation failed';
ok $v->error_count == 1, 'expected number of errors';
ok !$v->validate('id'), 'validation failed';
ok $v->error_count == 2, 'expected number of errors';
ok $v->param(qw/name AWNCORP/) eq 'AWNCORP', 'set parameter ok';
ok $v->param(qw/id 100/) == 100, 'set parameter ok';
ok $v->validate, 'validation succesful';
ok !$v->error_count, 'no errors';
ok $v->validate('id'), 'validation succesful';
ok !$v->error_count, 'no errors';

# ok $v->reset, 'reset ok'; - DEPRECATED
ok $v->proto->clear_queue, 'queue reset ok';
ok $v->proto->reset_fields(), 'fields reset ok';
ok !$v->validate(keys %{$v->fields}), 'validate all (not queued) failed';
ok $v->error_count == 1, 'error - email_confirm not set';

# advanced queue usage
$v->param($_ => '') for qw(id name);
ok $v->queue('+id'),   'queued id w/requirement';
ok $v->queue('+name'), 'queued name w/requirement';
ok $v->queue('email'), 'queued email';

# ok 3 == @{$v->queued}, '3 fields queued'; - DEPRECATED
ok 3 == @{$v->proto->queued}, '3 fields queued';
ok !$v->validate, 'error: both fields required, no input';
ok 2 == $v->error_count, '2 errors encoutered';
$v->param(id   => 123);
$v->param(name => 456);
ok 3 == $v->clear_queue(my ($id, $name)), 'rid the queue of 3 fields, 2 set';
ok $id == 123,   'local variable (id) set correctly';
ok $name == 456, 'local variable (name) set correctly';

# ok ! @{$v->queued}, 'no fields queued' - DEPRECATED;
ok !@{$v->proto->queued}, 'no fields queued';
