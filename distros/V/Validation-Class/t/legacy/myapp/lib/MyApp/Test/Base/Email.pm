package MyApp::Test::Base::Email;

use Validation::Class;

# rules mixin

mxn email       => {
    required    => 1,
    max_length  => 255,
    filters     => [qw/trim strip/]
};

fld email       => {
    mixin       => 'basic',
    max_length  => 11,
    required    => 0
};

1;