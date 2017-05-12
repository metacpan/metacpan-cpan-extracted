use strict;
use Test::More;
my $dummy = {
    foo  => 'ユー',
    bar  => 'ティー',
    baz  => 'エフ',
    qux  => 'エイト',
    quux => [
	'フラグ',
	'とやら',
	'僕は',
	'ぶっちゃけ',
	'あんま',
	'好きくない',
    ],
    corge => {
	grault => '日本人の',
	garply => '多くは',
	waldo  => '嫌い',
	fred   => 'なんじゃ',
	plugh  => [
	    'ない',
	    'の？',
	],
    },
};
eval {
    for my $key (qw(foo bar baz qux)) {
	utf8::upgrade($dummy->{$key});
    }
    for my $elem (@{$dummy->{quux}}) {
	utf8::upgrade($elem);
    }
    for my $key (qw(grault garply waldo fred)) {
	utf8::upgrade($dummy->{corge}{$key});
    }
    for my $elem (@{$dummy->{corge}{plugh}}) {
	utf8::upgrade($elem);
    }
};
if ($@) {
    plan skip_all => 'can not call utf8::upgrade';
}
else {
    plan tests => 85;
}
use_ok('Unicode::RecursiveDowngrade');
SKIP: {
    skip 'can not call utf8::is_utf8', 84 if $] < 5.008001;
    for my $key (qw(foo bar baz qux)) {
	ok(utf8::is_utf8($dummy->{$key}), "is flagged variable");
    }
    for my $elem (@{$dummy->{quux}}) {
	ok(utf8::is_utf8($elem), "is flagged variable");
    }
    for my $key (qw(grault garply waldo fred)) {
	ok(utf8::is_utf8($dummy->{corge}{$key}), "is flagged variable");
    }
    for my $elem (@{$dummy->{corge}{plugh}}) {
	ok(utf8::is_utf8($elem), "is flagged variable");
    }
    my $dummy_hashref = DummyClass::Hashref->new;
    $dummy_hashref->foo($dummy->{foo});
    $dummy_hashref->bar($dummy->{quux});
    $dummy_hashref->baz($dummy->{corge});
    my $dummy_arrayref = DummyClass::Arrayref->new;
    $dummy_arrayref->foo($dummy->{foo});
    $dummy_arrayref->bar($dummy->{quux});
    $dummy_arrayref->baz($dummy->{corge});
    for my $method (qw(foo bar baz)) {
    	if ($method eq 'foo') {
	    ok(utf8::is_utf8($dummy_hashref->$method()),
		"is flagged blessed reference");
	    ok(utf8::is_utf8($dummy_arrayref->$method()),
		"is flagged blessed reference");
	}
	elsif ($method eq 'bar') {
	    for my $elem (@{$dummy_hashref->$method()}) {
		ok(utf8::is_utf8($elem), "is flagged blessed reference");
	    }
	    for my $elem (@{$dummy_arrayref->$method()}) {
		ok(utf8::is_utf8($elem), "is flagged blessed reference");
	    }
	}
	elsif ($method eq 'baz') {
	    for my $key (qw(grault garply waldo fred)) {
		ok(utf8::is_utf8($dummy_hashref->$method()->{$key}),
		    "is flagged blessed reference");
		ok(utf8::is_utf8($dummy_arrayref->$method()->{$key}),
		    "is flagged blessed reference");
	    }
	    for my $elem (@{$dummy_hashref->$method()->{plugh}}) {
		ok(utf8::is_utf8($elem), "is flagged variable");
	    }
	    for my $elem (@{$dummy_arrayref->$method()->{plugh}}) {
		ok(utf8::is_utf8($elem), "is flagged variable");
	    }
	}
    }
    my $rd = Unicode::RecursiveDowngrade->new;
    $dummy = $rd->downgrade($dummy);
    for my $key (qw(foo bar baz qux)) {
	ok(! utf8::is_utf8($dummy->{$key}), "is unflagged variable");
    }
    for my $elem (@{$dummy->{quux}}) {
	ok(! utf8::is_utf8($elem), "is unflagged variable");
    }
    for my $key (qw(grault garply waldo fred)) {
	ok(! utf8::is_utf8($dummy->{corge}{$key}), "is unflagged variable");
    }
    for my $elem (@{$dummy->{corge}{plugh}}) {
	ok(! utf8::is_utf8($elem), "is unflagged variable");
    }
    $dummy_hashref  = $rd->downgrade($dummy_hashref);
    $dummy_arrayref = $rd->downgrade($dummy_arrayref);
    for my $method (qw(foo bar baz)) {
    	if ($method eq 'foo') {
	    ok(! utf8::is_utf8($dummy_hashref->$method()),
		"is unflagged blessed reference");
	    ok(! utf8::is_utf8($dummy_arrayref->$method()),
		"is unflagged blessed reference");
	}
	elsif ($method eq 'bar') {
	    for my $elem (@{$dummy_hashref->$method()}) {
		ok(! utf8::is_utf8($elem), "is unflagged blessed reference");
	    }
	    for my $elem (@{$dummy_arrayref->$method()}) {
		ok(! utf8::is_utf8($elem), "is unflagged blessed reference");
	    }
	}
	elsif ($method eq 'baz') {
	    for my $key (qw(grault garply waldo fred)) {
		ok(! utf8::is_utf8($dummy_hashref->$method()->{$key}),
		    "is unflagged blessed reference");
		ok(! utf8::is_utf8($dummy_arrayref->$method()->{$key}),
		    "is unflagged blessed reference");
	    }
	    for my $elem (@{$dummy_hashref->$method()->{plugh}}) {
		ok(! utf8::is_utf8($elem), "is unflagged variable");
	    }
	    for my $elem (@{$dummy_arrayref->$method()->{plugh}}) {
		ok(! utf8::is_utf8($elem), "is unflagged variable");
	    }
	}
    }
}

package DummyClass::Hashref;

sub new { bless {}, shift }

sub foo {
    my $self = shift;
    if (defined $_[0]) {
	$self->{foo} = shift;
    }
    return $self->{foo};
}

sub bar {
    my $self = shift;
    if (defined $_[0]) {
	$self->{bar} = shift;
    }
    return $self->{bar};
}

sub baz {
    my $self = shift;
    if (defined $_[0]) {
	$self->{baz} = shift;
    }
    return $self->{baz};
}

1;

package DummyClass::Arrayref;

sub new { bless [], shift }

sub foo {
    my $self = shift;
    if (defined $_[0]) {
	$self->[0] = shift;
    }
    return $self->[0];
}

sub bar {
    my $self = shift;
    if (defined $_[0]) {
	$self->[1] = shift;
    }
    return $self->[1];
}

sub baz {
    my $self = shift;
    if (defined $_[0]) {
	$self->[2] = shift;
    }
    return $self->[2];
}

1;
