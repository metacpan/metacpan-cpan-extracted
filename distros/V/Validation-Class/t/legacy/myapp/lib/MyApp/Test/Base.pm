package MyApp::Test::Base;

use base 'MyApp::Test::Base::Email';

use Validation::Class;

# rules mixin

mxn basic       => {
    required    => 1,
    max_length  => 255,
    filters     => [qw/trim strip/]
};

fld id          => {
    mixin       => 'basic',
    max_length  => 11,
    required    => 0
};

# build method, run automatically after new()

bld sub {
    
    shift->id(1)
    
};

1;