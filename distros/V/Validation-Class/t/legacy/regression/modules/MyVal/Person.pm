package MyVal::Person;

use Validation::Class;

mixin TMP => {
    required => 1,
    min_length => 1,
    max_length => 255,
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