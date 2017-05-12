package MyVal::Person;

use Validation::Class;

mixin TMP => {
    required => 1,
    between => '1-255'
};

field name => {
    mixin => 'TMP',
    label => 'Person\'s name'
};

field email => {
    mixin => 'TMP',
    label => 'Person\'s email'
};

1;