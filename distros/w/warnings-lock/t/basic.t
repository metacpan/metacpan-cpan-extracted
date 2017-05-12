use strict;
use warnings;
use Test::More;
use Test::Warnings ':all';

{
    use warnings;
    no warnings 'void';
    use warnings::lock;

    use warnings;

    is_deeply warning { eval 'sub { 42; return }' }, [];

    {
        no warnings::lock;
        use warnings;

        like warning { eval 'sub { 42; return }' },
            qr/void context/;
    }

    is_deeply warning { eval 'sub { 42; return }' }, [];
}

{
    use warnings;
    no warnings 'void';

    use warnings;

    like warning { eval 'sub { 42; return }' },
        qr/void context/;
}

done_testing;