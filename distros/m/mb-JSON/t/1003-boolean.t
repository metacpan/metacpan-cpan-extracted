######################################################################
#
# 1003-boolean.t - mb::JSON::Boolean object tests
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use mb::JSON;

my ($T_RUN, $T_FAIL) = (0, 0);
sub ok   {
    my ($ok,$n) = @_;
    $T_RUN++; $T_FAIL++ unless $ok;
    print +($ok?'':'not ') . "ok $T_RUN" . ($n?" - $n":'') . "\n"; $ok
}
sub is   {
    my ($got,$exp,$n) = @_;
    my $ok = defined $got && defined $exp && "$got" eq "$exp";
    ok($ok, $n) or print "# got: '$got'  expected: '$exp'\n";
}
# Assigning to $? sets the exit status; calling exit() from an END block
# aborts perl 5.6 and earlier with "Callback called exit."
END { $? = 1 if $T_FAIL }

my @tests;

# type check
push @tests, sub { ok(ref(mb::JSON::true)  eq 'mb::JSON::Boolean', 'true is mb::JSON::Boolean')  };
push @tests, sub { ok(ref(mb::JSON::false) eq 'mb::JSON::Boolean', 'false is mb::JSON::Boolean') };

# singleton identity
push @tests, sub { ok(mb::JSON::true  == mb::JSON::true,  'true is singleton')  };
push @tests, sub { ok(mb::JSON::false == mb::JSON::false, 'false is singleton') };

# numification
push @tests, sub { ok(mb::JSON::true  == 1, 'true numifies to 1')  };
push @tests, sub { ok(mb::JSON::false == 0, 'false numifies to 0') };

# stringification
push @tests, sub { is("" . mb::JSON::true,  'true',  'true stringifies to "true"')   };
push @tests, sub { is("" . mb::JSON::false, 'false', 'false stringifies to "false"') };

# boolean context
push @tests, sub { ok(mb::JSON::true  == 1, 'true  is true  in boolean context') };
push @tests, sub { ok(mb::JSON::false == 0, 'false is false in boolean context') };

# encode produces true/false (not 1/0)
push @tests, sub { is( mb::JSON::encode(mb::JSON::true),  'true',  'encode(true)  -> "true"')  };
push @tests, sub { is( mb::JSON::encode(mb::JSON::false), 'false', 'encode(false) -> "false"') };

# plain 1/0 are NOT boolean
push @tests, sub { is( mb::JSON::encode(1), '1', 'encode(1) -> "1" not "true"')  };
push @tests, sub { is( mb::JSON::encode(0), '0', 'encode(0) -> "0" not "false"') };

# decode returns Boolean objects
push @tests, sub { my $t = mb::JSON::decode('true');  ok(ref($t) eq 'mb::JSON::Boolean', 'decode true  -> Boolean object') };
push @tests, sub { my $f = mb::JSON::decode('false'); ok(ref($f) eq 'mb::JSON::Boolean', 'decode false -> Boolean object') };

# decoded booleans re-encode correctly
push @tests, sub { my $t = mb::JSON::decode('true');  is( mb::JSON::encode($t), 'true',  'decoded true  re-encodes as true')  };
push @tests, sub { my $f = mb::JSON::decode('false'); is( mb::JSON::encode($f), 'false', 'decoded false re-encodes as false') };

# $VERSION defined
push @tests, sub { ok(defined $mb::JSON::Boolean::VERSION, 'mb::JSON::Boolean has VERSION') };

# stringify() also encodes booleans correctly
push @tests, sub { is( mb::JSON::stringify(mb::JSON::true),  'true',  'stringify(true)  -> "true"')  };
push @tests, sub { is( mb::JSON::stringify(mb::JSON::false), 'false', 'stringify(false) -> "false"') };

# true != false
push @tests, sub { ok(mb::JSON::true != mb::JSON::false, 'true != false') };

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
