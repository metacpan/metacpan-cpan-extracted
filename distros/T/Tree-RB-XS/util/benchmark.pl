#! /usr/bin/env perl
use v5.20;
use warnings;
use Benchmark qw( :all :hireswallclock );
use List::Util 'shuffle';
use Time::HiRes 'time';
use Tree::RB::XS;
use Getopt::Long;

GetOptions(
	'nodecount|n=i'  => \(my $nodecount= 100_000),
	'outer-iterations|i=i' => \(my $iterations= 1),
	'inner-iterations|r=i' => \(my $inner_iterations= 1),
) or die "Usage: benchmark.pl [-i ITERCOUNT] [-r REPEATCOUNT] [-n NODECOUNT] [TYPES]\n";

sub make_script {
	my ($setup, $body, $use_benchmark)= @_;
	my $script= join "\n", <<END,
		use strict;
		use warnings;
		use Time::HiRes q|time|;
		use Benchmark qw| timeit :hireswallclock |;
		srand 42;
		my \$n= $nodecount;
		my \$min;
END
		$setup,
		$use_benchmark? (
			'my $t= timeit('.$inner_iterations.', sub{ '.$body.' });',
			'use Data::Dumper; print Dumper($t);',
			'use DDP; warn &np([$min])."\n";'
		) : (
			'my $t0= time;',
			$body,
			'my $t1= time; print(($t1-$t0).qq|\n|);'
		);
	$script =~ s/(^|\n)\s*//g;
	return $script;
}

my %setup= (
	int => <<'END',
		use List::Util q|shuffle|;
		my @collection= shuffle 1..$n;
END
	float => <<'END',
		my @collection;
		push @collection, rand()
			for 1..$n;
END
	shortstr => <<'END',
		my @collection;
		push @collection, join(q||, map chr(32+rand(128-32)), 1..8)
			for 1..$n;
END
	longstr => <<'END',
		my @collection;
		push @collection, join(q||, map chr(32+rand(128-32)), 1..800)
			for 1..$n;
END
	commonstr => <<'END',
		my @collection;
		push @collection, join(q||, rand, rand)
			for 1..$n;
END
	ustr => <<'END',
		my @collection;
		push @collection, join(q||, map chr(256+rand(100)), 1..20)
			for 1..$n;
END
	obj => <<'END',
		use List::Util q|shuffle|;
		my @collection;
		push @collection, { key => $_ }
			for shuffle 1..$n;
END
);
my %tests= (
	sort => {
		num       => '($min)= sort { $a <=> $b } @collection;',
		str       => '($min)= sort @collection;',
		obj       => '($min)= sort { $a->{key} <=> $b->{key} } @collection;',
	},
	sort_keys => {
		num       => 'my %hash; $hash{$_}= undef for @collection; ($min)= sort { $a <=> $b } keys %hash;',
		str       => 'my %hash; $hash{$_}= undef for @collection; ($min)= sort keys %hash;',
		# hash keys can't be objects.  The closest option would be to just put the key's inner string as the hash key,
		# but that would just be a repeat of the 'str' test.
		obj       => undef,
	},
	tree_rb   => {
		use       => 'use Tree::RB;',
		num       => 'my $tree= Tree::RB->new(sub{ $_[0] <=> $_[1] }); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
		str       => 'my $tree= Tree::RB->new; $tree->put($_,undef) for @collection; $min= $tree->min->key;',
		obj       => 'my $tree= Tree::RB->new(sub{ $_[0]{key} <=> $_[1]{key} }); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
	},
	tree_rb_xs => {
		use       => 'use Tree::RB::XS;',
		int       => 'my $tree= Tree::RB::XS->new(q|int|); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
		float     => 'my $tree= Tree::RB::XS->new(q|float|); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
		str       => 'my $tree= Tree::RB::XS->new(q|memcmp|); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
		ustr      => 'my $tree= Tree::RB::XS->new(q|utf8|); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
		#longstr   => 'my $tree= Tree::RB::XS->new(); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
		obj       => 'my $tree= Tree::RB::XS->new(sub{ $_[0]{key} <=> $_[1]{key} }); $tree->put($_,undef) for @collection; $min= $tree->min->key;',
	},		
	tree_avl => {
		use       => 'use Tree::AVL;',
		num       => 'my $tree= Tree::AVL->new(fcompare => sub{ $_[0] <=> $_[1] }); $tree->insert($_) for @collection; $min= $tree->smallest;',
		str       => 'my $tree= Tree::AVL->new(); $tree->insert($_) for @collection; $min= $tree->smallest;',
		obj       => 'my $tree= Tree::AVL->new(fcompare => sub{ $_[0]{key} <=> $_[1]{key} }); $tree->insert($_) for @collection; $min= $tree->smallest;',
	},
	avltree => {
		use       => 'use AVLTree;',
		num       => 'my $tree= AVLTree->new(sub{ $_[0] <=> $_[1] }); $tree->insert($_) for @collection; $min= $tree->first;',
		str       => 'my $tree= AVLTree->new(sub{ $_[0] cmp $_[1] }); $tree->insert($_) for @collection; $min= $tree->first;',
		obj       => 'my $tree= AVLTree->new(sub{ $_[0]{key} <=> $_[1]{key} }); $tree->insert($_) for @collection; $min= $tree->first;',
	},
);

$|= 1;
for my $type (@ARGV? @ARGV : qw( int float shortstr longstr commonstr ustr obj )) {
	my %result;
	for my $name (sort keys %tests) {
		my $t= $tests{$name};
		if ($t->{use} && !eval "$t->{use}; 1") {
			warn "$name is not available\n";
			next;
		}
		my $setup= ( $t->{use} || '' ) . ($setup{$type} // die "Unsupported type $type");
		next exists $t->{$type} && !defined $t->{$type};
		my $body= $t->{$type} || ($type =~ /str/? $t->{str} : $t->{num});
		my $script= make_script($setup, $body, 1);
		for (1..$iterations) {
			#printf"%s\n", $script;
			my $elapsed= `$^X -E '$script'`;
			if ($? == 0) {
				my $dt= eval 'no strict;'.$elapsed || die "$@";
				$dt= bless( [ $dt, 0, 0, 0, 0, 1 ], 'Benchmark' )
					unless ref $dt;
				$result{$name}= $result{$name}? timesum($result{$name}, $dt) : $dt;
			} else {
				die "Failed: $name:$type\n   $script\n";
			}
		}
	}
	printf "%s: %d data items, %d outer iterations, %d inner iterations\n",
		ucfirst($type), $nodecount, $iterations, $inner_iterations;
	cmpthese(\%result);
}

