package My::Module6;

use later 'My::Module1';

sub module6_test1 {
    use later 'My::Module3';
    return My::Module3::foo();
}

sub module6_test2 {
    return My::Module1::say();
}

1;
