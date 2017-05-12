use Test::More tests => 4;

package MyApp::Test;

use Validation::Class;

field 'field01' => {
    required   => 1,
    min_length => 1,
    max_length => 255,
};

field 'field02' => {
    required   => 1,
    min_length => 1,
    max_length => 255,
};

package main;

my $v = MyApp::Test->new;

# check attributes
ok ref $v, 'class initialized';
ok $v->fields->{field01}, 'field01 inheritence ok';
ok $v->fields->{field02}, 'field02 inheritence ok';
ok !$v->error_count, 'no errors yet';
