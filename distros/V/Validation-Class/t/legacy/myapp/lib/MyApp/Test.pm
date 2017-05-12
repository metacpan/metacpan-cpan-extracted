package MyApp::Test;

use Validation::Class;

set {
    
    classes => [__PACKAGE__]
    
};

# rules mixin

mxn basic       => {
    required    => 1,
    max_length  => 255,
    filters     => [qw/trim strip/]
}; 
 
# attr(s) w/rules
 
fld id          => {
    mixin       => 'basic',
    max_length  => 11,
    required    => 0
};
 
fld name        => {
    mixin       => 'basic',
    min_length  => 5
};
 
fld email       => {
    mixin       => 'basic',
    min_length  => 3
};
 
fld login       => {
    mixin       => 'basic',
    min_length  => 5
};
 
fld password    => {
    mixin       => 'basic',
    min_length  => 5,
    min_symbols => 1
};
 
# just an attr
 
has attitude => 1; 
 
# self-validating method
 
mth create  => {
 
    input   => [qw/name email login password/],
    output  => ['+id'],
     
    using   => sub {
         
        my ($self, @args) = @_;
         
        # make sure to set id for output validation
         
    }
 
};

# build method, run automatically after new()

bld sub {
    
    shift->attitude(0)
    
};

1;