# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::TestFixture;

use base qw(Exporter);
use fields qw(class debug numtested obj tests);
use strict;
use warnings;

use Test qw();

use constant SCALARARG => qw(foo);
use constant ARRAYARGS => [qw(item1 item2 item3)];
use constant HASHARGS => { key1 => qw(val1), key2 => qw(val2) };
use constant TABLEARGS => { key1 => [qw(val1 val2)], key2 => [qw(val3)] };

our @EXPORT;
push @EXPORT, qw(test_require test_constructor test_isa);
push @EXPORT, qw(test_result_isa test_result_exception);
push @EXPORT, qw(test_scalar_get test_scalar_set);
push @EXPORT, qw(test_bool_get_true test_bool_get_false);
push @EXPORT, qw(test_bool_set_true test_bool_set_false);
push @EXPORT, qw(test_array_add test_array_get test_array_getall);
push @EXPORT, qw(test_array_clear);
push @EXPORT, qw(test_hash_set test_hash_get test_hash_getnames);
push @EXPORT, qw(test_hash_remove);
push @EXPORT, qw(test_table_add test_table_get test_table_getnames);
push @EXPORT, qw(test_table_getvalues test_table_clear);

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{class} = undef;
    $self->{debug} = undef;
    $self->{numtested} = 0;
    $self->{obj} = undef;
    $self->{tests} = [];

    return $self;
}

sub getObj {
    my $self = shift;

    return $self->{obj};
}

sub setup {
    my $self = shift;
    my $class = shift;
    my %args = @_;

    $self->{class} = $class or
        die "no class specified for tests\n";

    $self->addTest('require', \&test_require);
    $self->addTest('constructor', \&test_constructor);

    $self->{debug} = $args{debug};

    if ($args{isa}) {
        for (@{ $args{isa} }) {
            $self->addTest("isa/$_", $_, \&test_isa);
        }
    }

    if ($args{scalar}) {
        for (@{ $args{scalar} }) {
            $self->addTest("scalar_get/$_", $_, \&test_scalar_get);
            $self->addTest("scalar_set/$_", $_, \&test_scalar_set);
        }
    }

    if ($args{bool}) {
        for (@{ $args{bool} }) {
            $self->addTest("bool_get_true/$_", $_, \&test_bool_get_true);
            $self->addTest("bool_get_false/$_", $_, \&test_bool_get_false);
            $self->addTest("bool_set_true/$_", $_, \&test_bool_set_true);
            $self->addTest("bool_set_false/$_", $_, \&test_bool_set_false);
        }
    }

    if ($args{array}) {
        for (@{ $args{array} }) {
            $self->addTest("array_add/$_", $_, \&test_array_add);
            $self->addTest("array_get/$_", $_, \&test_array_get);
            $self->addTest("array_getall/$_", $_, \&test_array_getall);
            $self->addTest("array_clear/$_", $_, \&test_array_clear);
        }
    }

    if ($args{hash}) {
        for (@{ $args{hash} }) {
            $self->addTest("hash_set/$_", $_, \&test_hash_set);
            $self->addTest("hash_get/$_", $_, \&test_hash_get);
            $self->addTest("hash_getnames/$_", $_, \&test_hash_getnames);
            $self->addTest("hash_remove/$_", $_, \&test_hash_remove);
        }
    }

    if ($args{table}) {
        for (@{ $args{table} }) {
            $self->addTest("table_add/$_", $_, \&test_table_add);
            $self->addTest("table_get/$_", $_, \&test_table_get);
            $self->addTest("table_getnames/$_", $_, \&test_table_getnames);
            $self->addTest("table_getvalues/$_", $_, \&test_table_getvalues);
            $self->addTest("table_clear/$_", $_, \&test_table_clear);
        }
    }

    return 1;
}

sub addTest {
    my $self = shift;
    my $name = shift;

    my ($data, $test);
    if (@_ > 1) {
        ($data, $test) = @_;
    } else {
        $test = shift;
    }

    push @{ $self->{tests} }, [$name, $data, $test];

    return 1;
}

sub run {
    my $self = shift;

    Test::plan tests => scalar @{ $self->{tests} };

    for (@{ $self->{tests} }) {
        my ($name, $data, $test) = @$_;
        &{$test}($self, $name, $self->{obj}, $data);
        $self->{obj}->recycle() if
            $self->{obj} && $self->{obj}->can('recycle');
    }

    return 1;
}

sub ok {
    my $self = shift;
    my $meth = shift;
    my $result = shift;

    $self->{numtested}++;

    warn "\n\t$self->{numtested}: $meth\n" if $self->{debug};

    Test::ok $result;
}

# individual test routines

sub test_require {
    my $self = shift;
    my $name = shift;

    $self->ok($name, eval "require $self->{class}");

    return 1;
}

sub test_constructor {
    my $self = shift;
    my $name = shift;

    $self->ok($name, $self->{obj} = $self->{class}->new());

    return 1;
}

sub test_isa {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $class = shift;

    $self->ok($name, $self->{obj}->isa($class));

    return 1;
}

sub test_result_isa {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $data = shift;

    my $method = $data->{method};
    my $args = $data->{args} || [];
    my $class = $data->{class};

    my $result = eval { $obj->$method(@$args) };
    $self->ok($name, $result->isa($class));

    return 1;
}

sub test_result_exception {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $data = shift;

    my $prereq = $data->{prereq};
    my $method = $data->{method};
    my $args = $data->{args} || [];

    &$prereq($obj) if $prereq;
    my $result = eval { $obj->$method(@$args) };
    $self->ok($name, $@);

    return 1;
}

sub test_scalar_get {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;

    my $orig = $obj->{$field};
    if (not $orig) {
        $self->ok($name, not $obj->$meth());
    } else {
        $self->ok($name, $obj->$meth() eq $orig);
    }

    return 1;
}

sub test_scalar_set {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'set' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->$meth(SCALARARG);
    $self->ok($name, $obj->{$field} eq SCALARARG);

    $obj->{$field} = $orig;

    return 1;
}

sub test_bool_get_true {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'is' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->{$field} = 1;
    $self->ok($name, $obj->$meth());

    $obj->{$field} = $orig;

    return 1;
}

sub test_bool_get_false {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'is' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->{$field} = undef;
    $self->ok($name, not $obj->$meth());

    $obj->{$field} = $orig;

    return 1;
}

sub test_bool_set_true {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'set' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->$meth(1);
    $self->ok($name, $obj->{$field});

    $obj->{$field} = $orig;

    return 1;
}

sub test_bool_set_false {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'set' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->$meth(undef);
    $self->ok($name, not $obj->{$field});

    $obj->{$field} = $orig;

    return 1;
}

sub test_array_add {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'add' . ucfirst $field;
    $meth =~ s/s$//;

    my $orig = $obj->{$field};

    for my $item (@{ ARRAYARGS() }) {
        $obj->$meth($item);
    }

    my $ok = 1;
    for my $val (@{ ARRAYARGS() }) {
        $ok-- unless $val eq ARRAYARGS->[0];
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_array_get {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;
    $meth =~ s/s$//;

    my $orig = $obj->{$field};

    $obj->{$field} = ARRAYARGS;
    $self->ok($name, $obj->$meth() eq ARRAYARGS->[0]);

    $obj->{$field} = $orig;

    return 1;
}

sub test_array_getall {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->{$field} = ARRAYARGS;

    my @items = $obj->$meth();
    my $ok = 1;
    for (my $i=0; $i < @{ ARRAYARGS() }; $i++) {
        $ok-- unless $items[$i] eq ARRAYARGS->[$i];
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_array_clear {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'clear' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->{$field} = ARRAYARGS;

    $obj->$meth();
    $self->ok($name, not @{ $obj->{$field} });

    $obj->{$field} = $orig;

    return 1;
}

sub test_hash_set {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'set' . ucfirst $field;
    $meth =~ s/s$//;

    my $orig = $obj->{$field};

    for my $key (keys %{ HASHARGS() }) {
        $obj->$meth($key, HASHARGS->{$key});
    }

    my $ok = 1;
    for my $key (keys %{ HASHARGS() }) {
        $ok-- unless $obj->{$field}->{$key} eq HASHARGS->{$key};
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_hash_get {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;
    $meth =~ s/s$//;

    my $orig = $obj->{$field};

    $obj->{$field} = HASHARGS;

    my $ok = 1;
    for my $key (keys %{ HASHARGS() }) {
        $ok-- unless $obj->$meth($key) eq HASHARGS->{$key};
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_hash_getnames {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;
    $meth =~ s/s$//;
    $meth.= 'Names';

    my $orig = $obj->{$field};

    $obj->{$field} = HASHARGS;

    my @items = sort $obj->$meth();
    my @vals = sort keys %{ HASHARGS() };
    my $ok = 1;
    for (my $i=0; $i < @vals; $i++) {
        $ok-- unless $items[$i] eq $vals[$i];
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_hash_remove {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'remove' . ucfirst $field;
    $meth =~ s/s$//;

    my $orig = $obj->{$field};

    $obj->{$field} = HASHARGS;

    my $ok = 1;
    for my $key (keys %{ HASHARGS() }) {
        $obj->$meth($key);
        $ok-- unless not $obj->{$field}->{$key};
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_table_add {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'add' . ucfirst $field;
    $meth =~ s/s$//;

    my $orig = $obj->{$field};

    for my $key (keys %{ TABLEARGS() }) {
        $obj->$meth($key, @{ TABLEARGS->{$key} });
    }

    my $ok = 1;
    for my $key (keys %{ TABLEARGS() }) {
        for (my $i=0; $i < @{ TABLEARGS->{$key} }; $i++) {
            $ok-- unless
                $obj->{$field}->{$key}->[$i] eq TABLEARGS->{$key}->[$i];
        }
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_table_get {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;
    $meth =~ s/s$//;

    my $orig = $obj->{$field};

    $obj->{$field} = TABLEARGS;

    my $ok = 1;
    for my $key (keys %{ TABLEARGS() }) {
        $ok-- unless $obj->$meth($key) eq TABLEARGS->{$key}->[0];
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_table_getnames {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;
    $meth =~ s/s$//;
    $meth.= 'Names';

    my $orig = $obj->{$field};

    $obj->{$field} = TABLEARGS;

    my @items = sort $obj->$meth();
    my @vals = sort keys %{ TABLEARGS() };
    my $ok = 1;
    for (my $i=0; $i < @vals; $i++) {
        $ok-- unless $items[$i] eq $vals[$i];
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_table_getvalues {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'get' . ucfirst $field;
    $meth =~ s/s$//;
    $meth.= 'Values';

    my $orig = $obj->{$field};

    $obj->{$field} = TABLEARGS;

    my $ok = 1;
    for my $key (keys %{ TABLEARGS() }) {
        my @items = sort $obj->$meth($key);
        my @vals = @{ TABLEARGS->{$key} };
        for (my $i=0; $i < @vals; $i++) {
            $ok-- unless $items[$i] eq $vals[$i];
        }
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

sub test_table_clear {
    my $self = shift;
    my $name = shift;
    my $obj = shift;
    my $field = shift;

    my $meth = 'clear' . ucfirst $field;

    my $orig = $obj->{$field};

    $obj->{$field} = TABLEARGS;

    $obj->$meth();

    my $ok = 1;
    for my $key (keys %{ TABLEARGS() }) {
        $ok-- unless not $obj->{$field}->{$key};
    }

    $self->ok($name, $ok);

    $obj->{$field} = $orig;

    return 1;
}

1;
__END__
