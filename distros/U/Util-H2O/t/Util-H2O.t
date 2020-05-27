#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module L<Util::H2O>.

=head1 Author, Copyright, and License

Copyright (c) 2020 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use Test::More tests => 100;
use Scalar::Util qw/blessed/;

sub exception (&) { eval { shift->(); 1 } ? undef : ($@ || die) }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn, RequireCarping)
sub warns (&) { my @w; { local $SIG{__WARN__} = sub { push @w, shift }; shift->() } @w }  ## no critic (ProhibitSubroutinePrototypes, RequireFinalReturn)

## no critic (RequireTestLabels)

diag "This is Perl $] at $^X on $^O";
BEGIN { use_ok 'Util::H2O' }
is $Util::H2O::VERSION, '0.08';

my $PACKRE = qr/\AUtil::H2O::_[0-9A-Fa-f]+\z/;

{
	my $hash = { foo => "bar", x => "y" };
	my $o1 = h2o $hash, qw/ more keys /;
	is $o1, $hash;
	like blessed($o1), $PACKRE;
	is $o1->foo, 'bar';
	is $o1->x, 'y';
	ok exception { $o1->blah };
	is $o1->x("z"), 'z';
	is $o1->x, 'z';
	is $o1->more, undef;
	is $o1->keys, undef;
	is $o1->more("quz"), 'quz';
	is $o1->more, 'quz';
	is_deeply $hash, { foo=>'bar', x=>'z', more=>'quz' };
	is $o1->keys(undef), undef;
	is_deeply $hash, { foo=>'bar', x=>'z', more=>'quz', keys=>undef };
}
{
	my $o2 = { hello => { perl => "world!" }, x=>{y=>{z=>"foo"}} };
	h2o -recurse, $o2;
	is $o2->hello->perl, "world!";
	is $o2->x->y->z, "foo";
	like blessed($o2->x), $PACKRE;
	like blessed($o2->x->y), $PACKRE;
	note explain $o2;
}

# -recurse
{
	my $o3 = h2o -recurse, { foo => { bar => "quz" } }, 'xyz';
	is $o3->xyz, undef;
	is $o3->foo->bar, 'quz';
	ok exception { $o3->foo->xyz };
}
{
	my $code = sub {};
	my $o4 = h2o { a=>[], h=>{}, c=>$code };
	is ref $o4->a, 'ARRAY';
	is ref $o4->h, 'HASH';
	is ref $o4->c, 'CODE';
	is $o4->c, $code;
}

# -meth
{
	my $o5 = h2o -meth, { abc => 123, def => sub { $_[0]->abc(789); 456 } };
	is $o5->abc, 123;
	is $o5->def, 456;
	is $o5->abc, 789;
}
{
	my $o6 = h2o -meth, -recurse, { a => { b=>"c", d=>sub{"e"} }, f=>sub{"g"} };
	is $o6->a->b, 'c';
	is ref $o6->a->d, 'CODE';
	is $o6->f, 'g';
}
{
	my $o = h2o -meth, { x=>111, y=>sub{222} };
	is $o->x, 111;
	is $o->y, 222;
	is_deeply [sort keys %$o], [qw/ x /];
	is $o->{x}, 111;
	SKIP: {
		skip "Won't work on old Perls", 1 if $] lt '5.008009';
		ok exception { my $x = $o->{y} };
	}
}
{
	my $o = h2o -meth, { x=>111, y=>sub{222} }, qw/y/;
	is $o->x, 111;
	is $o->y, 222;
	is_deeply [sort keys %$o], [qw/ x /];
	$o->{y} = 333;
	is_deeply $o, { x=>111, y=>333 };
	is $o->y, 222;
}

# -class
{
	my $dest=0;
	my $o7 = h2o -class=>'Foo::Bar', -meth,
		{ ijk=>'nop', rst => sub { $_[0]->ijk('wxy'); 'efg' },
			DESTROY=>sub{$dest++} };
	isa_ok $o7, 'Foo::Bar';
	is $o7->ijk, 'nop';
	is $o7->rst, 'efg';
	is $o7->ijk, 'wxy';
	is $dest, 0;
	$o7 = undef;
	is $dest, 1;
	my $o7a = bless {}, 'Foo::Bar';
	is $o7a->ijk, undef;
	is $o7a->rst, 'efg';
	is $o7a->ijk, 'wxy';
}

# -clean
sub checksym {
	my $s = shift;
	my ($p,$n) = $s=~/\A(.+::)?(\w+)\z/ or die $s;  ## no critic (RequireCarping)
	my $t = defined $p ? do { no strict 'refs'; \%{$p} } : \%::;  ## no critic (ProhibitNoStrict)
	return exists $t->{$n.'::'};
}
{
	my $o = h2o {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok !checksym $c;
}
{
	my $o = h2o -clean=>0, {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok checksym $c;
}
{
	my $o = h2o -class=>'TestClean1', {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok checksym $c;
}
{
	my $o = h2o -class=>'TestClean2', -clean=>1, {};
	my $c = ref $o;
	ok checksym $c;
	$o = undef;
	ok !checksym $c;
}

# -new
{
	my $o = h2o -new, {};
	my $on = $o->new;
	isa_ok $on, ref $o;
}
{
	my $n = h2o -class=>'Quz', -new, {}, qw/ abc /;
	isa_ok $n, 'Quz';
	my $n2 = new_ok 'Quz';
	is $n2->abc, undef;
	$n2->{new} = sub{die};  ## no critic (RequireCarping)
	my $n3 = $n2->new(abc=>444);
	is $n3->abc, 444;
	like exception { Quz->new(abc=>4,5) }, qr/\bOdd\b/;
	like exception { Quz->new(def=>4) }, qr/\bUnknown argument\b/i;
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { my $x = $n->{new} };
		ok exception { my $x = $n->{DESTROY} };
	}
}

# -lock
{
	my $o = h2o { foo=>123 }, qw/ bar /;
	is $o->{foo}, 123;
	is $o->{bar}, undef;
	is_deeply [sort keys %$o], [qw/ foo /];
	$o->{bar} = 456;
	is $o->{bar}, 456;
	is_deeply [sort keys %$o], [qw/ bar foo /];
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { my $x = $o->{quz} };
		ok exception { $o->{quz} = 789 };
	}
}
{
	my $o = h2o -lock=>1, { foo=>123 }, qw/ bar /;
	SKIP: {
		skip "Won't work on old Perls", 2 if $] lt '5.008009';
		ok exception { my $x = $o->{quz} };
		ok exception { $o->{quz} = 789 };
	}
}
{
	my $o = h2o -lock=>0, { foo=>123 }, qw/ bar /;
	is $o->{foo}, 123;
	is $o->{bar}, undef;
	is_deeply [sort keys %$o], [qw/ foo /];
	$o->{bar} = 456;
	is $o->{quz}, undef;
	is $o->{bar}, 456;
	is_deeply [sort keys %$o], [qw/ bar foo /];
	$o->{quz} = 789;
	is $o->{quz}, 789;
	is_deeply [sort keys %$o], [qw/ bar foo quz /];
	ok exception { my $x = $o->quz };
}
{
	h2o -class=>'Baz', -new, {}, qw/ abc /;
	my $n = Baz->new(abc=>123);
	$n->{def} = 456;
	is_deeply [sort keys %$n], [qw/ abc def /];
}

ok !grep { /redefined/i } warns {
	h2o { abc => "def" }, qw/ abc /;
	h2o {}, qw/ abc abc /;
};

ok exception { h2o() };
ok exception { h2o("blah") };
ok exception { h2o(undef) };
ok exception { h2o([]) };
ok exception { h2o(-meth,-recurse) };
ok exception { h2o(bless {}, "SomeClass") };
ok exception { h2o({DESTROY=>'foo'}) };
ok exception { h2o(-new, { new=>5 }) };
ok exception { h2o(-class) };
ok exception { h2o(-class=>'') };
ok exception { h2o(-class=>[]) };

done_testing;
