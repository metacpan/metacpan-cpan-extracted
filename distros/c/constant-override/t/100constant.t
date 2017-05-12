use warnings;
use strict;

use Test::More tests => 20;

BEGIN {
    use constant::override;
    use constant::override ignore => [ 'asdf' ];
    use constant;
    use constant asdf => 'QWER';
    use constant unaffected => 'ASDF';

    eval { asdf() };
    ok($@, 'Died on calling ignored constant');
    like($@, qr/Undefined subroutine.*asdf/,
        'Got correct error message');

    is(unaffected(), 'ASDF', 'Other constant use is not affected');

    my $i = 0;
    use constant::override substitute => { 'qwer' => 123,
                                           'zxcv' => sub { $i++ } };
    use constant qwer => 100;
    use constant zxcv => 'QWERQWERQWER';
    is(qwer(), 123, 'Constant overridden with scalar value');
    is(zxcv(), 0,   'Constant overridden by normal function');
    is(zxcv(), 1,   'Constant overridden by normal function (2)');

    package MyConstantTesting;

    use warnings;
    use strict;

    use Test::More;

    my $j = 0;

    use constant::override ignore     => [ 'asdf',
                                           'MyConstantTesting::fdsa' ],
                           substitute => { 'MyConstantTesting::qwer' => 321,
                                           'zxcv' => sub { $j++ } };
    use constant asdf => 'ZXCV';
    use constant fdsa => 'ZXCV';
    use constant qwer => 200;
    use constant zxcv => 'ZXCVZXCVZXCV';
    use constant unaffected => 4321;
    use constant myarray => 1,2,3,4;

    eval { asdf(); };
    ok($@, 'Died on calling ignored constant (in package)');
    like($@, qr/Undefined subroutine.*MyConstantTesting::asdf/,
        'Got correct error message');
    eval { fdsa(); };
    ok($@, 'Died on calling ignored constant (in package) (2)');
    like($@, qr/Undefined subroutine.*MyConstantTesting::fdsa/,
        'Got correct error message');

    is(qwer(), 321, 'Constant overridden with scalar value (in package)');
    is(zxcv(), 0,   'Constant overridden by normal function (in package)');
    is(zxcv(), 1,   'Constant overridden by normal function (in package) (2)');

    is(unaffected(), 4321, 'Other constant use is not affected');
    my $val = (myarray())[1];
    is($val, 2, 'Array constant use is not affected');
    myarray();

    eval "use constant [1,2,3,4]";
    ok($@, 'Died trying to pass arrayref to constant');
    like($@, qr/Invalid reference type/,
        'Got correct error message');

    eval "use constant { 'one' => 'two', 'three' => 'four' }";
    ok(($@ eq ''), 'No error passing hashref to constant');
    is(one(), 'two',   'Constant value is correct (1)');
    is(three(), 'four', 'Constant value is correct (2)');
}

1;

__END__

Copyright 2013 APNIC Pty Ltd.

This library is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The full text of the license can be found in the LICENSE file included
with this module.

