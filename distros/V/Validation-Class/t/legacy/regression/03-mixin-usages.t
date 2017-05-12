use Test::More tests => 9;

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
    max_length => 255,
    filters    => [qw/trim strip/]
};

mixin UTEXT => {
    required   => 1,
    min_length => 1,
    max_length => 255,
    filters    => 'uppercase'
};

field id => {
    mixin => 'ID',
    label => 'Object ID',
    error => 'Object ID error'
};

field name => {
    mixin   => 'TEXT',
    label   => 'Object Name',
    error   => 'Object Name error',
    filters => ['uppercase']
};

field handle => {
    mixin   => 'UTEXT',
    label   => 'Object Handle',
    error   => 'Object Handle error',
    filters => [qw/trim strip/]
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

my $v = MyVal->new(params => {name => ' p3rlc0dr    '});
ok $v, 'initialization successful';
ok $v->fields->{email}->{max_length} == 500,
  'email max_length mixin overridden';

ok $v->fields->{email_confirm}->{required}, 'email_confirm required ok';
ok $v->fields->{email_confirm}->{min_length} == 5,
  'email_confirm min_length ok';
ok $v->fields->{email_confirm}->{max_length} == 500,
  'email_confirm max_length ok';
ok $v->fields->{email_confirm}->{label} eq 'Object Email Confirm',
  'email_confirm label ok';
ok $v->fields->{email_confirm}->{error} eq 'Object Email confirmation error',
  'email_confirm error ok';
ok $v->params->{name} =~ /^P3RLC0DR$/,
  'trim, strip and uppercase filters all applied';

my $w = MyVal->new(params => {name => ' p3rlc0dr    '});
ok $w->params->{name} =~ /^P3RLC0DR$/,
  'trim, strip and uppercase filters all applied';
