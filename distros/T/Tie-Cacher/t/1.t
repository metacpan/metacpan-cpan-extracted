# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use strict;
use warnings;
#########################

use Test::More tests => 3112;
BEGIN { $^W = 1 };
BEGIN { use_ok('Tie::Cacher') };

my @save;

sub say {
    # print STDERR "\n", @_, "\n";
}

sub empty_test {
    my $data = shift;

    @save = ();
    is($data->count, 0, "count 0 on empty");

    is($data->keys, 0,  "keys 0 on empty");
    is_deeply([$data->keys], [],  "keys gives empty list on empty set");

    is($data->recent_keys, 0,  "recent_keys 0 on empty");
    is_deeply([$data->recent_keys], [],  "recent_keys gives empty list on empty set");

    is($data->old_keys, 0,  "old_keys 0 on empty");
    is_deeply([$data->old_keys], [],  "old_keys gives empty list on empty set");

    ok(!$data->exists("foo"), "No key foo on empty set");
    # is_deeply([$data->exists("foo")], [""], "No key foo on empty set");

    is($data->most_recent_key, undef, "No most recent key on empty set");
    is($data->oldest_key, undef, "No oldest key on empty set");

    my $first = $data->first_key;
    is($first, undef, "scalar context first_key gives undef on empty set");
    my @first = $data->first_key;
    is(@first, 0, "list context first_key empty list on empty set");

    my $next = $data->next_key;
    is($next, undef, "scalar context next_key gives undef on empty set");
    my @next = $data->next_key;
    is(@next, 0, "list context next_key empty list on empty set");
    is(@save, 0, "pure queries don't save anything");
}

sub basic_run {
    my ($data, $max_count, $append) = @_;
    $append = "" unless $append;
    my $load = $data->load;
    my $save = $data->save;
    # Compensate for the fact that tied "each" in list context does a fetch
    my $tie = $data->isa("MapTie") ? $append : "";

    empty_test($data);
    is($data->missed,	0, "missed 0 on start");
    is($data->hit,	0, "hit 0 on start");
    @save = ();
    my $get = $data->fetch("foo");
    if ($load) {
        is($get, "a", "fetch non-existing element");
        is($data->count, 1, "count 1 after failed fetch and implied load");
        if ($save) {
            is_deeply(\@save, ["foo", "a"], "save value autocreated by fetch");
        } else {
            is(@save, 0, "Nothing gets saved if there is no save function");
        }
    } else {
        is($get, undef, "fetch non-existing element");
        is($data->count, 0, "count unchanged after failed fetch");
        is(@save, 0, "Nothing gets saved by a plain fetch");
    }
    is($data->missed,  1, "missed +1 after failed fetch");
    is($data->hit,   0, "hit unchanged after failed fetch");

    @save = ();
    $data->store("foo", "bar");
    if ($save) {
        is_deeply(\@save, ["foo", "bar"], "save value set by store");
    } else {
        is(@save, 0, "store doesn't save if there is no save method");
    }
    is($data->count, 1, "count 1 after store");
    is($data->missed,  1, "missed unchanged by store");
    is($data->hit,   0, "hit unchanged by store");
    ok($data->exists("foo"), "stored element exists");
    $get = $data->fetch("foo");
    if ($max_count) {
        is($get, "bar$append", "fetch existing element");
    } else {
        is($get, undef, "fetch non-existing element");
    }
    is($data->missed,  1, "missed unchanged by good fetch");
    is($data->hit,   1, "hit +1 after good fetch");

    $data->store("foo", undef);
    is($data->count, 1, "count still 1 after restore");
    is($data->missed,  1, "missed unchanged by store");
    is($data->hit,   1, "hit unchanged by store");
    ok($data->exists("foo"), "stored element exists");
    @save = ();
    $get = $data->fetch("foo");
    is($get, $append || undef, "refetch existing element");
    is($data->missed,  1, "missed unchanged by good fetch");
    is($data->hit,   2, "hit +1 after good fetch");
    is(@save, 0, "Nothing happens");

    $data->store("foo", "baz");
    is($data->count, 1, "count still 1 after restore");
    is($data->missed,  1, "missed unchanged by store");
    is($data->hit,   2, "hit unchanged by store");
    ok($data->exists("foo"), "stored element exists");
    $get = $data->fetch("foo");
    if ($max_count) {
        is($get, "baz$append", "refetch existing element");
    } else {
        is($get, undef, "fetch non-existing element");
    }
    is($data->missed,  1, "missed unchanged by good fetch");
    is($data->hit,   3, "hit +1 after good fetch");

    $data->delete("foo");
    empty_test($data);
    is($data->missed,  1, "missed unchanged by delete");
    is($data->hit,   3, "hit unchanged by delete");
    $get = $data->fetch("foo");
    if ($load) {
        is($get, "a", "fetch non-existing element after delete and implied load");
        $data->delete("foo");
    } else {
        is($get, undef, "fetch non-existing element after delete");
    }
    is($data->missed,  2, "missed +1 after failed fetch");
    is($data->hit,   3, "hit unchanged after failed fetch");

    $data->store("foo1", "bar1");
    $data->store("foo2", "bar2");
    $data->store("foo3", "bar3");
    $data->store("foo4", "bar4");
    my @validates = ("") x 5;
    is($data->count, $max_count || 4, "count $max_count after adding some");
    is($data->keys,  $max_count || 4, "testing keys in scalar context");
    is($data->recent_keys, $max_count || 4,
       "testing recent_keys in scalar context");
    is($data->old_keys, $max_count || 4, "testing old_keys in scalar context");
    my @foo1 = $max_count == 3 ? () : "foo1";
    is_deeply([sort $data->keys], [@foo1, qw(foo2 foo3 foo4)],
              "testing keys in list context");

    is_deeply([my @recent = $data->recent_keys], [qw(foo4 foo3 foo2), @foo1],
              "testing recent_ list context");
    is_deeply([my @old = $data->old_keys], [@foo1, qw(foo2 foo3 foo4)],
              "testing recent_ list context");
    is_deeply(\@old, [reverse @recent], "recent/old in reverse order");
    is($recent[0], $data->most_recent_key, "most recent in front");
    is($recent[-1], $data->oldest_key, "least recent at the back");

    $get = $data->fetch("foo2");
    my @foo2 = $max_count ? "foo2" : ();
    $validates[2] .= $append if @foo2;
    is_deeply([@recent = $data->recent_keys], [@foo2, qw(foo4 foo3), @foo1],
              "testing recent_ list context");
    is_deeply([@old = $data->old_keys], [@foo1, qw(foo3 foo4), @foo2],
              "testing recent_ list context");
    is_deeply(\@old, [reverse @recent], "recent/old in reverse order");
    is($recent[0], $data->most_recent_key, "most recent in front");
    is($recent[-1], $data->oldest_key, "least recent at the back");

    my $f = my $first = $data->first_key;
    $f =~ s/foo//;
    is(grep($_ eq $first, @foo1, qw(foo3 foo4), @foo2), 1, "scalar first key is one of the keys");
    my @first = $data->first_key;
    $validates[$f] .= $tie;
    is (@first, 2, "list context first_key returns 2 values");
    is($first[0], $first, "list first_key refers the same entry as scalar first key");
    return unless $max_count;

    is($first[1], "bar$f$validates[$f]",
       "list context first_key implies right value");
    $get = $data->fetch($first);
    $validates[$f] .= $append;
    is($get, "bar$f$validates[$f]", "fetch the right value");
    my $second = $data->next_key;
    my @third  = $data->next_key;
    $f = $third[0];
    $f =~ s/foo//;
    $validates[$f] .= $tie;
    my ($k, @rest);
    while ($k = $data->next_key) {
        push(@rest, $k);
    }
    is($k, undef, "next_key should finish on undef");
    is(grep($_ eq $second, $data->keys), 1,
       "scalar context first key is one of the keys");
    is(grep($_ eq $third[0], $data->keys), 1,
       "list context first key is one of the keys");
    push(@rest, $first[0], $second, $third[0]);
    is_deeply([sort @rest], [@foo1, qw(foo2 foo3 foo4)],
              "first/next key repeated should get all keys");
    @first = $data->first_key;
    @rest = ($first[0]);
    while (@first = $data->next_key) {
        is(@first, 2, "next_key fetches 2 values");
        $get = $data->fetch($first[0]);
        my $f = $first[0];
        $f =~ s/foo//;
        $validates[$f] .= $append;
        is($get, $first[1].$append,
           "list context next_key fetches right value");
        push(@rest, $first[0]);
    }
    is_deeply([sort @rest], [@foo1, qw(foo2 foo3 foo4)],
              "first/next key (list) repeated should get all keys");

    $get = $data->delete("foo4");
    is($get, "bar4$validates[4]$tie", "deleted value was bar4");
    is($data->count, $max_count-1, "one less element after delete");
    ok(!$data->exists("foo4"), "deleted value does not exist anymore");
    $data->store("foo4", "baz4");
    is($data->count, $max_count, "one more element after store");

    $get = $data->delete("foo5");
    is($get, undef, "non deleted value gives undef");
    is($data->count, $max_count, "one less element after delete");
    ok(!$data->exists("foo5"), "deleting must not create value");

    $get = $data->delete("foo4", "foo3");
    is($get, "bar3$validates[3]$tie", "deleted value was bar3");
    is($data->count, $max_count-2, "two less elements after delete");
    ok(!$data->exists("foo4"), "deleted value does not exist anymore");
    ok(!$data->exists("foo3"), "deleted value does not exist anymore");
    $data->store("foo4", "baz4");
    $data->store("foo3", "baz3");
    is($data->count, $max_count, "one more element after store");

    my @get = $data->delete("foo4", "foo5", "foo3");
    is_deeply(\@get, ["baz4", undef, "baz3"], "deleted value match");
    is($data->count, $max_count-2, "two less elements after delete");
    ok(!$data->exists("foo4"), "deleted value does not exist anymore");
    ok(!$data->exists("foo3"), "deleted value does not exist anymore");
    $data->store("foo4", "baz4");
    $data->store("foo3", "baz3");
    is($data->count, $max_count, "one more element after store");

    # test void context
    $data->delete("foo4", "foo5", "foo3");
    is($data->count, $max_count-2, "two less elements after delete");
    ok(!$data->exists("foo4"), "deleted value does not exist anymore");
    ok(!$data->exists("foo3"), "deleted value does not exist anymore");
    $data->store("foo4", "baz4");
    $data->store("foo3", "baz3");
    is($data->count, $max_count, "one more element after store");

    $data->clear;
    empty_test($data);

    @save = ();
    $get = $data->fetch_node("foo");
    if ($load) {
        is($get->[0], "a", "fetch non-existing element");
        is($data->count, 1, "count 1 after failed fetch and implied load");
        if ($save) {
            is_deeply(\@save, ["foo", "a"], "save value autocreated by fetch");
        } else {
            is(@save, 0, "Nothing gets saved if there is no save function");
        }
    } else {
        is($get, undef, "fetch non-existing element");
        is($data->count, 0, "count unchanged after failed fetch");
        is(@save, 0, "Nothing gets saved by a plain fetch");
    }

    @save = ();
    $data->store("foo", "bar");
    if ($save) {
        is_deeply(\@save, ["foo", "bar"], "save value set by store");
    } else {
        is(@save, 0, "store doesn't save if there is no save method");
    }
    is($data->count, 1, "count 1 after store");
    ok($data->exists("foo"), "stored element exists");
    $get = $data->fetch_node("foo");
    if ($max_count) {
        is($get->[0], "bar$append", "fetch existing element");
    } else {
        is($get, undef, "fetch non-existing element");
    }

    $data->store("foo", undef);
    is($data->count, 1, "count still 1 after restore");
    ok($data->exists("foo"), "stored element exists");
    @save = ();
    $get = $data->fetch_node("foo");
    is($get->[0], $append || undef, "refetch existing element");
    is(@save, 0, "Nothing happens");

    $data->CLEAR;
    empty_test($data);
    @save = ();
    $get = $data->FETCH("foo");
    if ($load) {
        is($get, "a", "fetch non-existing element");
        is($data->count, 1, "count 1 after failed fetch and implied load");
        if ($save) {
            is_deeply(\@save, ["foo", "a"], "save value autocreated by fetch");
        } else {
            is(@save, 0, "Nothing gets saved if there is no save function");
        }
    } else {
        is($get, undef, "fetch non-existing element");
        is($data->count, 0, "count unchanged after failed fetch");
        is(@save, 0, "Nothing gets saved by a plain fetch");
    }

    @save = ();
    $data->STORE("foo", "bar");
    if ($save) {
        is_deeply(\@save, ["foo", "bar"], "save value set by store");
    } else {
        is(@save, 0, "store doesn't save if there is no save method");
    }
    is($data->count, 1, "count 1 after store");
    ok($data->EXISTS("foo"), "stored element exists");
    $get = $data->FETCH("foo");
    if ($max_count) {
        is($get, "bar$append", "fetch existing element");
    } else {
        is($get, undef, "fetch non-existing element");
    }

    $data->STORE("foo", undef);
    is($data->count, 1, "count still 1 after restore");
    ok($data->EXISTS("foo"), "stored element exists");
    @save = ();
    $get = $data->FETCH("foo");
    is($get, $append || undef, "refetch existing element");
    is(@save, 0, "Nothing happens");
}

{
    # A fake package mapping OO style back to tied hash style
    package MapTie;

    sub new {
        my $class = shift;
        my $tie = tie my %cache, "Tie::Cacher", @_;
        return bless [\%cache, $tie], $class;
    }

    for my $name (qw(load save validate max_count user_data
                     fetch_node TIEHASH
                     FETCH STORE CLEAR DELETE FIRSTKEY NEXTKEY EXISTS
                     count hit missed
                     recent_keys old_keys most_recent_key oldest_key)) {
        eval "sub $name { shift->[1]->$name(\@_) }";
        die $@ if $@;
    }

    sub keys : method {
        return keys %{shift->[0]};
    }

    sub exists : method {
        my ($self, $key) = @_;
        return exists $self->[0]{$key};
    }

    sub first_key {
        my $self = shift;
        keys %{$self->[0]};
        each %{$self->[0]};
    }

    sub next_key {
        each %{shift->[0]};
    }

    sub fetch {
        my ($self, $key) = @_;
        $self->[0]{$key};
    }

    sub store {
        my ($self, $key, $val) = @_;
        $self->[0]{$key} = $val;
    }

    sub delete : method {
        my $self = shift;
        delete @{$self->[0]}{@_};
    }

    sub clear {
        %{shift->[0]} = ();
    }
}

sub nop {}

my $refcount;
for my $class (qw(Tie::Cacher MapTie)) {
    my %options = (validate => \&nop,
                   load => \&nop,
                   save => \&nop,
                   max_count => 3,
                   user_data => 5);

    my $data = eval { $class->new; };
    is($@, "", "new croaked");
    can_ok($data, qw(new TIEHASH store STORE fetch FETCH fetch_node
                     delete DELETE clear CLEAR first_key FIRSTKEY
                     next_key NEXTKEY exists EXISTS
                     keys recent_keys old_keys most_recent_key oldest_key
                     count missed hit), keys %options);
    for (keys %options) {
        is($data->$_, undef, "default option $_ is undef");
    }

    say("$class: plain call with options");
    my $data1 = eval { $class->new(%options); };
    is($@, "", "new croaked");
    for (keys %options) {
        is($data1->$_, $options{$_}, "Option $_ fetchable after set");
    }

    say("$class: plain call with options reference");
    $data1 = eval { $class->new(\%options); };
    is($@, "", "new croaked");
    for (keys %options) {
        is($data1->$_, $options{$_}, "Option $_ fetchable after set");
    }

    say("$class: Testing invalid option");
    $data1 = eval { $class->new(foo => "bar"); };
    ok($@, "new croaked");

    $data1 = eval { $class->new(4); };
    is($@, "", "new croaked");
    is($data1->max_count, 4, "simple max_count interface works");

    # attribute getting/setting
    my $i = 123;
    for (keys %options, qw(hit missed)) {
        $data1->$_(++$i);
        is($data1->$_, $i, "get what you set");
        is($data1->$_(undef), $i, "set returns old value");
        is($data1->$_, undef, "get what you set");
    }

    say("$class: Basic usage");
    basic_run($data, 4);

    $refcount = 1;
    {
        package Refcount;

        DESTROY {
            $refcount--;
        }
    }
    $data->store("foo", bless [], "Refcount");
    is($refcount, 1, "before cleanup releases all elements");
    undef $data;
    is($refcount, 0, "cleanup releases all elements");

    say("$class: Restricted size");
    $data = eval { $class->new(max_count => 3); };
    is($@, "", "new croaked");
    basic_run($data, 3);

    say("$class: Always valid");
    # validate that always succeeds is essentially a noop
    $data = eval { $class->new(validate => sub { 1; }); };
    is($@, "", "new croaked");
    basic_run($data, 4);

    say("$class: Never valid");
    # validate that always fails is basically "evaporate on fetch"
    $data = eval { $class->new(validate => sub { 0; }); };
    is($@, "", "new croaked");
    basic_run($data, 0);

    say("$class: Morphing validate");
    # validate that appends "a" on fetch
    $data = eval { $class->new(validate => sub {
        my ($self, $key, $node) = @_;
        $node->[0] .= "a";
        return 1;
    }); };
    is($@, "", "new croaked");
    basic_run($data, 4, "a");

    say("$class: Load on demand");
    # Just load: autocreate non-existing elements to "a"
    $data = eval { $class->new(load => sub {
        my ($self, $key, $node) = @_;
        $node->[0] .= "a";
    }); };
    is($@, "", "new croaked");
    basic_run($data, 4);

    say("$class: plain save");
    # Save what gets stored
    $data = eval { $class->new(save => sub {
        my ($self, $key, $node) = @_;
        push(@save, $key, $node->[0]);
    });};
    is($@, "", "new croaked");
    basic_run($data, 4);

    say("$class: Load on demand and save");
    # Just load and save: autocreate non-existing elements to "a"
    $data = eval { $class->new(user_data => "waf",
                               load => sub {
                                   my ($self, $key, $node) = @_;
                                   $node->[0] .= "a";
                               },
                               save => sub {
                                   my ($self, $key, $node) = @_;
                                   push(@save, $key, $node->[0]);
                               },
                               ); };
    is($@, "", "new croaked");
    is($data->user_data, "waf", "Userdata set");
    is($data->user_data("foo"), "waf", "Get old userdata");
    is($data->user_data("baz"), "foo", "Get old userdata");
    is($data->user_data, "baz", "Most recent userdata set");
    is($data->user_data, "baz", "Most recent userdata remains set");
    basic_run($data, 4);

    say("$class: Always load");
    # invalidate and load: autoextend on EVERY fetch
    $data = eval { $class->new(validate => sub { 0; },
                               load => sub {
                                   my ($self, $key, $node) = @_;
                                   $node->[0] .= "a";
                               }); };
    is($@, "", "new croaked");
    is($data->user_data, undef, "No userdata set");
    is($data->user_data("foo"), undef, "Get old userdata");
    is($data->user_data("baz"), "foo", "Get old userdata");
    is($data->user_data, "baz", "Most recent userdata set");
    is($data->user_data, "baz", "Most recent userdata remains set");
    basic_run($data, 4, "a");

    # Check load exception
    $data = $class->new(load => sub { die "\n"; },
                        validate => sub { 0 },
                        save => sub {
                            my ($self, $key, $node) = @_;
                            push(@save, $key, $node->[0]);
                        });
    for (1..2) {
        $data->store("foo", 5) if $_ == 2;
        @save = ();
        eval { $data->fetch("foo"); };
        ok($@, "load exception");
        is(@save, 0, "save doesn't get called");
        ok(!$data->exists("foo"), "failing load doesn't create value");
    }
    empty_test($data);

    # Check save exception
    $data = $class->new(load => sub {
        my ($self, $key, $node) = @_;
        $node->[0] = $key x 2;
    },
                        save => sub {
                            die "\n";
                        });
    eval { $data->store("foo", 5) };
    ok($@, "Failing save dies");
    ok(!$data->exists("foo"), "failing save doesn't create value");
    eval { $data->fetch("bar") };
    ok($@, "Failing save dies");
    ok(!$data->exists("bar"), "failing save doesn't create value");
    empty_test($data);

    # Check validate exception
    $data = $class->new(validate => sub { die "\n" });
    $data->store("foo", "bar");
    eval { $data->fetch("foo") };
    ok($@, "failed validate exception passed on");
    ok($data->exists("foo"), "failing validate does not delete");

    # Check all ways of deleting elements
    for ([], ["b"], ["b", "c"]) {
        # Void context
        $data = $class->new(validate => sub { die "\n" });
        $data->store($_ => "bar$_") for "a".."z";
        $data->delete(@$_);
        is($data->count, 26 - @$_, "Correct number of elements removed");

        # Scalar context
        $data = $class->new(user_data => "waf", validate => sub { die "\n" });
        $data->store($_ => "bar$_") for "a".."z";
        my $out = $data->delete(@$_);
        is($data->count, 26 - @$_, "Correct number of elements removed");
        is($out, $_->[-1] && "bar" . $_->[-1], "Correct value returned") unless
            @$_ == 0 && $data->isa("MapTie");

        # List context
        $data = $class->new(validate => sub { die "\n" });
        $data->store($_ => "bar$_") for "a".."z";
        my @out = $data->delete(@$_);
        is($data->count, 26 - @$_, "Correct number of elements removed");
        is(@out, @$_, "Return as many values as deleted");
        for my $n (0..$#out) {
            is($out[$n], "bar" . $_->[$n], "Correct value returned");
        }
    }
}
