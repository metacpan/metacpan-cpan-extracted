package MyVal::Staff;

use Validation::Class;

field login => {
    mixin => 'TMP',
    label => 'Staff login'
};

field password => {
    mixin => 'TMP',
    label => 'Staff password'
};

1;