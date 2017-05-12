package MyApp::Container;

use base 'MyApp::Test::Base';

use Validation::Class;

mxn other       => {
    required    => 1,
    max_length  => 255,
    filters     => [qw/trim strip/]
};

fld name        => {
    mixin       => 'basic',
    max_length  => 255,
    required    => 0
};

bld sub {
    
    my ($self) = @_;
    
    $self->name('Boy');
    
    return $self;
    
};

1;