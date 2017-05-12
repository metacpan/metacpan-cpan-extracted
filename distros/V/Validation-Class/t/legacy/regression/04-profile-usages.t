BEGIN {
    use FindBin;
    use lib $FindBin::Bin. "/modules/";
}

use Test::More tests => 12;

package MyValAlt;

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

profile email_change => sub {

    my ($self, $hash) = @_;

    $self->validate('+email', '+email_confirm');

    return $self->error_count && keys %{$hash} ? 1 : 0;

};

package main;

use MyVal;

my $v1 = MyValAlt->new(params => {});

ok $v1, 'initialization successful';
ok !$v1->validate_profile('email_change'),
  'email_change profile did not validate';
ok $v1->error_count == 2, '2 errors encountered on failure';

$v1->params->{email}         = 'abc';
$v1->params->{email_confirm} = 'abc';

ok !$v1->validate_profile('email_change'),
  'email_change profile did not validate';
ok $v1->validate_profile('email_change', {this => 'that'}),
  'email_change profile validated OK';

my $v2 = MyVal->new(params => {});

ok !$v2->validate_profile('new_ticket'), 'new_ticket profile did not validate';
ok $v2->error_count == 2, '2 errors encountered on failure';

$v2->param(name => 'the dude');

ok !$v2->validate_profile('new_ticket'), 'new_ticket profile did not validate';
ok $v2->error_count == 1, '1 errors encountered on failure';

$v2->param(description => 'the bomb dot com');

ok $v2->validate_profile('new_ticket'), 'new_ticket profile validated OK';
ok $v2->error_count == 0, 'NO errors set';

my $v3 = MyVal->new(
    params => {
        'person.name'        => 'the dude',
        'ticket.description' => 'hot diggidy dog'
    }
);

ok $v3->validate_profile('new_ticket'), 'new_ticket profile validated OK';
