package testcases::Base::Utils;
use strict;

use base qw(testcases::Base::base);

sub test_utils_unicode_transparency {
    my $self=shift;

    use XAO::Utils;

    my @tests=(
        "qwerty",
        "smiley - \x{263a}",
        "\x90\x91\x92\x93",     # binary, non-unicode
    );

    foreach my $str (@tests) {
        my $got=XAO::Utils::t2hf($str);
        $self->assert($got eq $str,
                      "Got '$got' for '$str'");
    }
}

sub test_logprint_handler {
    my $self=shift;

    use XAO::Utils;

    my @log;
    XAO::Utils::set_logprint_handler(sub {
        push(@log,$_[0]);
    });
    my $olddebug=XAO::Utils::set_debug(1);
    dprint "Test1";
    eprint "Test2";
    dprint "Test3","Test4","Test5";

    $self->assert(@log == 3,
                  "Expected log to have 3 elements, has ".scalar(@log)." (".join(',',@log).")");
    $self->assert($log[0] =~ /Test1/,
                  "Expected first element to match /Test1/, got '$log[0]'");
    $self->assert($log[1] =~ /Test2/,
                  "Expected second element to match /Test2/, got '$log[1]'");
    $self->assert($log[2] =~ /Test3Test4Test5/,
                  "Expected third element to match /Test3Test4Test5/, got '$log[2]'");

    XAO::Utils::set_logprint_handler(undef);
    XAO::Utils::set_debug($olddebug);
}

sub test_fround {
    my $self=shift;

    use XAO::Utils qw(:math);

    my %matrix=(
        t1  => {
            num         => 33.415,
            prec        => 100,
            expect      => 33.42,
        },
        t2  => {
            num         => 33.41499,
            prec        => 100,
            expect      => 33.41,
        },
        t3  => {
            num         => 2.5,
            prec        => 1,
            expect      => 3,
        },
        t4  => {
            num         => 3.5,
            prec        => 1,
            expect      => 4,
        },
        t5  => {
            num         => 3.99999,
            prec        => 1,
            expect      => 4,
        },
        t6  => {
            num         => 3,
            prec        => 1,
            expect      => 3,
        },
        t7  => {
            num         => -900.00,
            prec        => 100,
            expect      => -900,
        },
        t8  => {
            num         => -1.456,
            prec        => 100,
            expect      => -1.46,
        },
        t9  => {
            num         => -1.456,
            prec        => 10,
            expect      => -1.5,
        },
        t10 => {
            num         => 12.345,
            prec        => 0.1,
            expect      => 10,
        },
        t11 => {
            num         => 18.345,
            prec        => 0.1,
            expect      => 20,
        },
    );

    foreach my $test_id (keys %matrix) {
        my $num=$matrix{$test_id}->{num};
        my $prec=$matrix{$test_id}->{prec};
        my $got=fround($num,$prec);
        my $expect=$matrix{$test_id}->{expect};
        $self->assert($got == $expect,
                      "Wrong result for test $test_id (num=$num, prec=$prec, expect=$expect, got=$got)");
    }
}

sub test_html {
    my $self=shift;

    use XAO::Utils qw(:html);

    my $str;
    my $got;
    $str='\'"!@#$%^&*()_-=[]\<>?';
    $got=t2ht($str);
    $self->assert($got eq '\'"!@#$%^&amp;*()_-=[]\&lt;&gt;?',
                  "Wrong value from t2ht ($got)");

    $got=t2hq($str);
    $self->assert($got eq '\'%22!@%23$%25^%26*()_-%3d[]\%3c%3e%3f',
                  "Wrong value from t2hq ($got)");

    $got=t2hf($str);
    $self->assert($got eq '\'&quot;!@#$%^&amp;*()_-=[]\&lt;&gt;?',
                  "Wrong value from t2hf ($got)");
}

sub test_t2hj {
    my $self=shift;

    use XAO::Utils qw(:html);

    my %matrix=(
        'plain'                     => 'plain',
        q(John's)                   => q(John\\'s),
        q(John "Bloody" Baron)      => q(John \\"Bloody\\" Baron),
        q(C:\\Foo - John's "Files") => q(C:\\\\Foo - John\\'s \\"Files\\"),
        qq(Two\nTabbed\tLines)      => q(Two\\012Tabbed\\011Lines),
        qq(smiley - \x{263a})       => qq(smiley - \x{263a}),
    );
    foreach my $t (keys %matrix) {
        my $j=t2hj($t);
        $self->assert($j eq $matrix{$t},
                      "t2hj: for '$t' expected '$matrix{$t}', got '$j'");
    }
}

sub test_t2hq {
    my $self=shift;

    use XAO::Utils qw(:html);
    use Encode;

    my %matrix=(
        'plain'                     => 'plain',
        q(John's)                   => q(John's),
        q(John "Bloody" Baron)      => q(John%20%22Bloody%22%20Baron),
        q(C:\\Foo - John's "Files") => q(C:\Foo%20-%20John's%20%22Files%22),
        qq(Two\nTabbed\tLines)      => q(Two%0aTabbed%09Lines),
        qq(smiley - \x{263a})       => q(smiley%20-%20%e2%98%ba),
        # binary
        Encode::encode('UTF-8',qq(smiley - \x{263a}))   => q(smiley%20-%20%e2%98%ba),
    );
    foreach my $t (keys %matrix) {
        my $j=t2hq($t);
        $self->assert($j eq $matrix{$t},
                      "t2hq: for '$t' expected '$matrix{$t}', got '$j'");
    }
}

sub test_args {
    my $self=shift;

    use XAO::Utils qw(:args);

    my $args;

    $args=get_args(a => 1, b => 2);
    $self->assert($args->{a} == 1 && $args->{b} == 2,
                  "get_args - can't parse a hash");

    $args=get_args([a => 2, b => 3]);
    $self->assert($args->{a} == 2 && $args->{b} == 3,
                  "get_args - can't parse an 'arrayed' hash");

    $args=get_args({a => 3, b => 4});
    $self->assert($args->{a} == 3 && $args->{b} == 4,
                  "get_args - can't parse a hash reference");

    my %a=(aa => 1, bb => '');
    my %b=(bb => 2, cc => undef);
    my %c=(cc => 3, dd => 3);
    my $r=merge_refs(\%a,\%b,\%c);
    $self->assert($a{aa} == 1 && $a{bb} eq '' &&
                  $b{bb} == 2 && !defined($b{cc}) &&
                  $c{cc} == 3 && $c{dd} == 3 &&
                  $r->{aa} == 1 && $r->{bb} == 2 &&
                  $r->{cc} == 3 && $r->{dd} == 3 &&
                  scalar(keys %$r) == 4,
                  "merge_refs doesn't work right");
}

sub test_keys {
    my $self=shift;

    use XAO::Utils qw(:keys);

    for(1..100000) {
        my $key=generate_key();
        ### dprint "key=$key";
        $self->assert(($key && $key =~ /^[A-Z][0-9A-Z]{7}$/ && $key !~ /^[0-9]+$/) ? 1 : 0,
                      "Wrong key generated ($key)");
    }

    my $key=repair_key('01V34567');
    $self->assert($key eq 'OIU3456I',
                  "repair_key returned wrong value for 01V34567 ($key)");
}

1;
