package testcases::fields;
use strict;
use XAO::Utils;
use XAO::Objects;
use Error qw(:try);

use base qw(testcases::base);

##
# MySQL is noisy about mistakes that we expect. So we hide DBD
# messages.
#
use vars qw(*SE);
sub stderr_stop {
    open(SE,">&STDERR");
    open(STDERR,">/dev/null");
}
sub stderr_restore {
    open(STDERR,">&SE");
    close(SE);
}

sub test_update_field {
    my $self=shift;

    my $odb=$self->get_odb();

    my $global=$odb->fetch('/');
    $self->assert(ref($global), "Failure getting / reference");

    ##
    # Spaces at the end of string are chopped off at least by
    # MySQL. Documented bug.
    #
    foreach my $text (q('"~!@#$%^&*_+=[]{}),
                      '()æù÷áÊÃÕË',
                      '  Spaces  .' ,
                      'Test Project') {
        $global->put(project => $text);
        my $got=$global->get('project');
        $self->assert($got eq $text,
                      "Field update ('$text' != '$got')");
    }
}

sub test_delete_field {
    my $self=shift;

    my $odb=$self->get_odb();

    my $global=$odb->fetch('/');
    $self->assert(ref($global), "Failure getting / reference");

    $global->put(project => '123abc');
    $global->delete('project');

    my $got=$global->get('project');
    $self->assert(defined($got) && $got eq '',
                  "Field is incorrect after delete");

}

sub test_fetch {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    my $custlist=$odb->fetch('/Customers');
    $self->assert($cust, 'List object fetch failed');
}

sub test_container_key {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    my $ckey=$cust->container_key();
    $self->assert($ckey eq 'c1',
                  "container_key() returned bad value ('$ckey'!='c1')");
}

sub test_defined {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    $cust->put(name => 'aaaa');

    $self->assert($cust->defined('name'),
                  "Method defined('name') returned false instead of true");
}

sub test_exists {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    $self->assert($cust->exists('name'),
                  "Method exists('name') returned false instead of true");

    $self->assert(!$cust->exists('nonexistent'),
                  "Method exists('nonexistent') returned true instead of false");

    $self->assert($cust->exists('unique_id'),
                  "Method exists('unique_id') returned false instead of true");
}

sub test_keys {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    my $keys=join(',',sort $cust->keys());
    $self->assert($keys eq 'customer_id,name',
                  "Keys are wrong for customer ('$keys'!='customer_id,name')");
}

sub test_is_attached {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    $self->assert($cust->is_attached(),
                  "Is_attached() returned false on attached object");

    my $newcust=$odb->fetch('/Customers')->get_new();
    $self->assert(! $newcust->is_attached(),
                  "Is_attached() returned true on detached object");
}

sub test_values {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    $cust->add_placeholder(name => 'xxx',
                           type => 'text'
                          );

    $cust->put(name => 'foo');
    $cust->put(xxx  => '123');

    my %v;
    @v{$cust->keys()}=$cust->values();
    my $v=join(",",map { $v{$_} } sort keys %v);

    $self->assert($v eq 'c1,foo,123',
                  "Values() returned wrong list ('$v'!='c1,foo,123')");
}

sub test_describe {
    my $self=shift;
    my $odb=$self->get_odb();
    my $cust=$odb->fetch('/Customers/c1');

    $cust->add_placeholder(name => 'xxx',
                           type => 'text',
                           maxlength => 123,
                          );

    my $desc=$cust->describe('xxx');
    $self->assert(ref($desc),
                  "Describe() did not return field description");
    $self->assert($desc->{name} eq 'xxx',
                  "Describe() returned wrong name ($desc->{name}!='xxx')");
    $self->assert($desc->{type} eq 'text',
                  "Describe() returned wrong type ($desc->{type}!='text')");
    $self->assert($desc->{maxlength} eq 123,
                  "Describe() returned wrong maxlength ($desc->{maxlength}!='123')");
    $self->assert($desc->{default} eq '',
                  "Describe() returned wrong default ($desc->{default})");
}

sub test_integer {
    my $self=shift;
    my $odb=$self->get_odb();
    my $cust=$odb->fetch('/Customers/c1');

    foreach my $max (100, 100000, 100000000) {

        $cust->add_placeholder(name => 'int',
                           type => 'integer',
                           minvalue => 20,
                           maxvalue => $max);

        my $value=int($max/2);
        $cust->put(int => $value);
        my $got=$cust->get('int');
        $self->assert($got == $value,
                      "Got not what was stored ($got!=$value)");

        my $stored=1;
        try {
            $cust->put(int => $max+1);
        }
        otherwise {
            $stored=0;
        };
        $self->assert(!$stored,
                      "Allowed to store value bigger then maxvalue (max=$max)");
        $self->assert($cust->get('int') == $value,
                      "Value was corrupted by unsuccessful store (max=$max)");

        $stored=1;
        try {
            $cust->put(int => $max);
        }
        otherwise {
            $stored=0;
        };
        $self->assert($stored,
                      "Does not allow to store value equal to maxvalue (max=$max)");

        $stored=1;
        try {
            $cust->put(int => 10);
        }
        otherwise {
            $stored=0;
        };
        $self->assert(!$stored,
                      "Allowed to store value less then minvalue (max=$max)");
        $self->assert($cust->get('int') == $max,
                      "Value was corrupted by unsuccessful store (max=$max)");

        $cust->drop_placeholder('int');
    }
}

sub test_real {
    my $self=shift;
    my $odb=$self->get_odb();
    my $cust=$odb->fetch('/Customers/c1');

    foreach my $max (100, 1e20) {

        $cust->add_placeholder(name => 'real',
                           type => 'real',
                           minvalue => 20,
                           maxvalue => $max);

        my $value=$max/2;
        $cust->put(real => $value);
        my $got=$cust->get('real');
        $self->assert($got == $value,
                      "Got not what was stored ($got!=$value)");

        my $stored=1;
        try {
            $cust->put(real => $max*1.1);
        }
        otherwise {
            $stored=0;
        };
        $self->assert(!$stored,
                      "Allowed to store value bigger then maxvalue (max=$max)");
        $self->assert($cust->get('real') == $value,
                      "Value was corrupted by unsuccessful store (max=$max)");

        $stored=1;
        try {
            $cust->put(real => $max);
        }
        otherwise {
            $stored=0;
        };
        $self->assert($stored,
                      "Does not allow to store value equal to maxvalue (max=$max)");

        $stored=1;
        try {
            $cust->put(real => 10);
        }
        otherwise {
            $stored=0;
        };
        $self->assert(!$stored,
                      "Allowed to store value less then minvalue (max=$max)");
        $self->assert($cust->get('real') == $max,
                      "Value was corrupted by unsuccessful store (max=$max)");

        $cust->drop_placeholder('real');
    }

    my $clist=$odb->fetch('/Customers');
    my $nc=$clist->get_new();
    $nc->add_placeholder(name => 'real',
                         type => 'real');

    $nc->put(real => 123.45);
    $clist->put('new' => $nc);
    $nc=$clist->get('new');

    $self->assert(ref($nc),
                  "Can't get stored object with real field");
    my $got=$nc->get('real');
    $self->assert($got == 123.45,
                  "Got wrong real value ($got!=123.45)");
}

sub test_unique {
    my $self=shift;
    my $odb=$self->get_odb();

    my $list=$odb->fetch('/Customers');
    $list->destroy();

    foreach my $type (qw(text integer real)) {

        my $c=$list->get_new();

        $c->add_placeholder(name => 'uf',
                            type => $type,
                            unique => 1);

        $c->put(uf => 1);

        $list->put(u1 => $c);
        my $c1=$list->get('u1');
        $self->assert(ref($c1),
                      "Can't get stored object");
        $self->assert($c1->get('uf') == 1,
                      "Wrong value in the unique field of the first object (1)");
        my $mistake;
        stderr_stop();
        try {
            $list->put(u2 => $c);
            $mistake=1;
        } otherwise {
            $mistake=0;
        };
        stderr_restore();
        $self->assert(! $mistake,
                "Succeded in putting the same object twice, 'unique' does not work");

        $c->put(uf => 2);
        $list->put(u2 => $c);
        my $c2=$list->get('u2');
        $self->assert(ref($c2),
                      "Can't get stored object");
        $self->assert($c2->get('uf') == 2,
                      "Wrong value in the unique field of the first object (2)");

        $c2->put(uf => 3);
        $self->assert($c2->get('uf') == 3,
                      "Wrong value in the unique field of the first object (3)");

        stderr_stop();
        try {
            $c1->put(uf => 3);
            $mistake=1;
        } otherwise {
            $mistake=0;
        };
        stderr_restore();
        $self->assert(! $mistake,
                      "Succeded in storing two equal values into unique field");
        $self->assert($c1->get('uf') == 1,
                      "Unique field produced error and still stored second value");

        $c->drop_placeholder('uf');
        $list->destroy();
    }
}

=pod

##
# Checking how 'unique' works for second level objects. The trick with
# them is that the field should be unique in the space of an enclosing
# container, but two containers can have identical properties.
#
sub test_unique_2 {
    my $self=shift;
    my $odb=$self->get_odb();

    my $list=$odb->fetch('/Customers');
    my $c1=$list->get('c1');
    my $c2=$list->get('c2');

    $c1->add_placeholder(
        name    => 'Orders',
        type    => 'list',
        class   => 'Data::Order',
        key     => 'order_id',
    );

    my $c1list=$c1->get('Orders');
    my $c2list=$c2->get('Orders');

    my $order=$c1->get('Orders')->get_new;

    foreach my $type (qw(text integer real)) {
        $order->add_placeholder(
            name    => 'foo',
            type    => $type,
            unique  => 1,
        );

        $order->put(foo => 1);

        my $mistake;
        stderr_stop();
        try {
            $c1list->put(o1 => $order);
            $c2list->put(o1 => $order);
            $mistake=0;
        }
        otherwise {
            $mistake=1;
        };
        stderr_restore();
        $self->assert(! $mistake,
            "Can't put the same object into two different parents' lists");

        stderr_stop();
        try {
            $c1list->put(o2 => $order);
            $mistake=1;
        }
        otherwise {
            $mistake=0;
        };
        stderr_restore();
        $self->assert(! $mistake,
            "Put the same object twice (type=$type), 'unique' does not work on the second level");

        $order->put(foo => 2);
        $c2list->put(o2 => $order);

        stderr_stop();
        try {
            $c2list->put(o1 => $order);
            $mistake=1;
        } otherwise {
            $mistake=0;
        };
        stderr_restore();
        $self->assert(! $mistake,
            "Put the same object twice (type=$type), replacement");

        $self->assert(! $c1list->exists('o2'),
            "Got o2 from the c1list");

        $self->assert($c1list->get('o1')->get('foo') eq '1',
            "Got wrong value from c1list");
        $self->assert($c2list->get('o1')->get('foo') eq '1',
            "Got wrong value from c2list/o2");
        $self->assert($c2list->get('o2')->get('foo') eq '2',
            "Got wrong value from c2list/o2");

        $order->drop_placeholder('foo');
    }
}

=cut

sub test_get_multi {
    my $self=shift;

    my $odb=$self->get_odb();

    my $cust=$odb->fetch('/Customers/c1');
    $self->assert($cust, 'Hash object fetch failed');

    $cust->add_placeholder(name => 'xxx',
                           type => 'text'
                          );

    $cust->put(name => 'foo');
    $cust->put(xxx  => '123');

    my ($name_1,$xxx_1)=$cust->get(qw(name xxx));
    my ($xxx_2,$name_2)=$cust->get(qw(xxx name));

    $self->assert($name_1 eq 'foo',
                  "test_get_multi: Got wrong name_1");
    $self->assert($xxx_1 eq '123',
                  "test_get_multi: Got wrong xxx_1");
    $self->assert($xxx_1 eq $xxx_2 && $name_1 eq $name_2,
                  "test_get_multi: Order of stuff is wrong on second call");

    my $global=$odb->fetch('/');
    my @val=$global->get(sort $global->keys);
    $self->assert(@val == 2,
                  "test_get_multi: Global returned wrong number of values");
    $self->assert(ref($val[0]) && $val[0]->objtype eq 'List',
                  "test_get_multi: Global did not return list reference");


    my $nc=$odb->fetch('/Customers')->get_new();
    $nc->put(name => 'abc');
    $nc->put(xxx => 'zzz');
    my ($xxx,$name)=$nc->get(qw(xxx name));
    $self->assert($name eq 'abc',
                  "test_get_multi: Got wrong name");
    $self->assert($xxx eq 'zzz',
                  "test_get_multi: Got wrong xxx");
}

##
# Checks how translation from undef to default values work. Undefs are
# not supported by XAO::FS and therefore are never returned.
#
sub test_null {
    my $self=shift;

    my $odb=$self->get_odb();

    my $clist=$odb->fetch('/Customers');
    $self->assert($clist, 'List object fetch failed');
    my $cust=$clist->get('c1');
    $self->assert($cust, 'Hash object fetch failed');

    $cust->add_placeholder(name     => 'text',
                           type     => 'text',
                          );
    $cust->add_placeholder(name     => 'text2',
                           type     => 'text',
                           default  => 'test',
                          );
    $cust->add_placeholder(name     => 'integer',
                           type     => 'integer',
                          );
    $cust->add_placeholder(name     => 'real',
                           type     => 'real',
                          );
    $cust->add_placeholder(name     => 'int1',
                           type     => 'integer',
                           default  => 10000,
                          );
    $cust->add_placeholder(name     => 'int2',
                           type     => 'integer',
                           minvalue => 1000,
                          );
    $cust->add_placeholder(name     => 'real2',
                           type     => 'real',
                           minvalue => 256,
                          );

    my %matrix=(
        t1  => {
            name    => 'text',
            default => '',
        },
        t2  => {
            name    => 'integer',
            default => 0,
        },
        t3  => {
            name    => 'int1',
            default => 10000,
        },
        t4  => {
            name    => 'int2',
            default => 1000,
        },
        t5  => {
            name    => 'real',
            default => 0,
        },
        t6  => {
            name    => 'real2',
            default => 256,
        },
        t7  => {
            name    => 'text2',
            default => 'test',
        },
    );

    foreach my $test (map { $matrix{$_} } sort keys %matrix) {
        my $name=$test->{name};
        my $expect=$test->{default};

        my $c=$clist->get('c2');

        my $desc=$c->describe($name);
        $self->assert(defined($desc->{default}),
                      "Default value not set in describe() for $name");
        $self->assert($desc->{default} eq $expect,
                      "Default value is wrong for $name (got '$desc->{default}', expected '$expect')");

        my $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (initial)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (initial)");

        $c->put($name => 12345);

        $c=$clist->get('c2');

        $c->delete($name);

        $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (deleted)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (deleted)");

        $c->put($name => undef);

        $c=$clist->get('c2');

        $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (put undef)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (put undef)");

        $c->put($name => $expect);

        $c=$clist->get('c2');

        $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (put default)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (put default)");

        ##
        # Now the same on detached object
        #
        $c=$clist->get_new;

        $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (initial, detached)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (initial, detached)");

        $c->put($name => 12345);
        $c->delete($name);

        $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (deleted, detached)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (deleted, detached)");

        $c->put($name => undef);

        $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (put undef, detached)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (put undef, detached)");

        $c->put($name => $expect);

        $got=$c->get($name);
        $self->assert(defined($got),
                      "Got 'undef' for name=$name (put default, detached)");
        $self->assert($got eq $expect,
                      "Expect $expect, got $got for name=$name (put default, detached)");

    }
}

1;
