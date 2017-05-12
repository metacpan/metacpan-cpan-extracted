package MyVal::Temp;

use Validation::Class;

load {
    base => [
        'MyVal::Person'
    ]
};

field login => {
    mixin => 'TMP',
    label => 'Staff login'
};

field password => {
    mixin => 'TMP',
    label => 'Staff password'
};

1;