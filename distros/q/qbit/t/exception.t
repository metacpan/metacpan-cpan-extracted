package Exception::Test;
use base qw(Exception);

package Exception::Test_2;
use base qw(Exception::Test);

package main;

use qbit;

use Test::More tests => 23;

sub t1 {
    my $res = '';
    try {
        throw 'Error';
    }
    catch {
        $res .= 'catch';
    };
    return $res;
}

ok(t1() eq 'catch', 'check catch');

sub t2 {
    my $res = '';
    try {
        throw 'Error';
    }
    catch {
        $res .= 'catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t2() eq 'catch+finally', 'check exception');

sub t3 {
    my $res = '';
    try {
        throw Exception::Test 'Error';
    }
    catch Exception::Test with {
        $res .= 'catch_Test';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t3() eq 'catch_Test+finally', 'catch Exception::Test (base Exception)');

sub t4 {
    my $res = '';
    try {
        throw Exception::Test_2 'Error';
    }
    catch Exception::Test_2 with {
        $res .= 'catch_Test_2';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t4() eq 'catch_Test_2+finally', 'catch Exception::Test_2 (base Exception::Test)');

sub t5 {
    my $res = '';
    try {
        throw Exception::Test_2 'Error';
    }
    catch Exception::Test with {
        $res .= 'catch_Test';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t5() eq 'catch_Test+finally', 'catch Exception::Test (throw Exception::Test_2)');

sub t6 {
    my $res = '';
    eval {
        try {
            throw Exception::Test_2 'Error';
        }
        catch Exception::Test_2 with {
            $res .= 'catch_Test_2';
            throw shift;
        }
        finally {
            $res .= '+finally';
        };
    };
    return $res;
}

is(t6(), "catch_Test_2+finally", 'throw in block "catch"');

sub t7 {
    my $res = 'start';
    try {
        throw 'Error';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t7() eq 'start+finally', 'finally');

sub t8 {
    my $res = 'start';
    try {
        throw 'Error';
    }
    catch Exception::Test with {
        $res .= '+catch Test';
    }
    catch {
        $res .= '+catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t8() eq 'start+catch+finally', 'check catch in multi catch(throw)');

sub t9 {
    my $res = 'start';
    try {
        throw Exception::Test 'Error';
    }
    catch Exception::Test with {
        $res .= '+catch_Test';
    }
    catch {
        $res .= '+catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t9() eq 'start+catch_Test+finally', 'check catch in multi catch(throw Exception::Test)');

sub t10 {
    my $res = 'start';
    try {
        throw Exception::Test 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch';
    };
    return $res;
}

ok(t10() eq 'start+catch', 'check catch in multi choice(throw Exception::Test)');

sub t11 {
    my $res = 'start';
    try {
        throw Exception::Test_2 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch';
    };
    return $res;
}

ok(t11() eq 'start+catch', 'check catch in multi choice(throw Exception::Test_2)');

sub t12 {
    my $res = 'start';
    try {
        throw Exception::Test 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t12() eq 'start+catch+finally', 'check catch and finally in multi choice(throw Exception::Test)');

sub t13 {
    my $res = 'start';
    try {
        throw Exception::Test_2 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t13() eq 'start+catch+finally', 'check catch and finally in multi choice(throw Exception::Test_2)');

sub t14 {
    my $res = 'start';
    try {
        throw Exception::Test 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch_Test(_2)';
    }
    catch {
        $res .= '+catch';
    };
    return $res;
}

ok(t14() eq 'start+catch_Test(_2)', 'check multi choice and catch(throw Exception::Test)');

sub t15 {
    my $res = 'start';
    try {
        throw Exception::Test_2 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch_Test(_2)';
    }
    catch {
        $res .= '+catch';
    };
    return $res;
}

ok(t15() eq 'start+catch_Test(_2)', 'check multi choice and catch(throw Exception::Test_2)');

sub t16 {
    my $res = 'start';
    try {
        throw 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch_Test(_2)';
    }
    catch {
        $res .= '+catch';
    };
    return $res;
}

ok(t16() eq 'start+catch', 'check multi choice and catch(throw)');

sub t17 {
    my $res = 'start';
    try {
        throw 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch_Test(_2)';
    }
    catch {
        $res .= '+catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t17() eq 'start+catch+finally', 'check multi choice, catch and finally(throw)');

sub t18 {
    my $res = 'start';
    try {
        throw Exception::Test 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch_Test(_2)';
    }
    catch {
        $res .= '+catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t18() eq 'start+catch_Test(_2)+finally', 'check multi choice, catch and finally(throw Exception::Test)');

sub t19 {
    my $res = 'start';
    try {
        throw Exception::Test_2 'Error';
    }
    catch Exception::Test catch Exception::Test_2 with {
        $res .= '+catch_Test(_2)';
    }
    catch {
        $res .= '+catch';
    }
    finally {
        $res .= '+finally';
    };
    return $res;
}

ok(t19() eq 'start+catch_Test(_2)+finally', 'check multi choice, catch and finally(throw Exception::Test_2)');

sub t20 {
    my $res = 'start';
    eval {
        try {
            throw Exception::Test 'Error Test';
        }
        catch Exception::Test with {
            $res .= '+catch_Test';
            throw Exception::Test_2 'Error Test_2';
        }
        catch {
            $res .= '+catch';
        }
        finally {
            $res .= '+' . ref($_[0]);
        };
    };

    $res .= '+' . ref($@) if $@;

    return $res;
}

ok(t20() eq 'start+catch_Test+Exception::Test+Exception::Test_2',
    'In catch and finally blocks you can access first $@');

sub t21 {
    my $result = '';
    try {
        throw 'Error';
    }
    catch Exception::Test with {
        $result .= '+catch_Test';
    }
    catch {
        $result .= $_[0]->message;
    };

    return $result;
}

ok(t21() eq 'Error', 'Error message right');

sub t22 {
    my $result = '';
    try {
        throw Exception::Test 'Error';
    }
    catch Exception::Test with {
        $result .= $_[0]->message;
    }
    catch {
        $result .= '+catch';
    };

    return $result;
}

ok(t22() eq 'Error', 'Error message right');

sub t23 {
    my $result = '';
    try {
        throw 'Error';
    }
    catch Exception::Test with {
        $result .= '+catch_Test';
    }
    catch {
        $result .= $_[0]->message;
    }
    finally {
        $result .= '+finally';
    };

    return $result;
}

ok(t23() eq 'Error+finally', 'Error message right');
