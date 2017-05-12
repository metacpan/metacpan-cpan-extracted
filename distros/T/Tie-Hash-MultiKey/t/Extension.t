
# Extension.t

BEGIN { $| = 1; print "1..32\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Data::Dumper::Sorted;

$package = 'Tie::Hash::MultiKey::ExtensionPrototype';
eval "require $package";

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

my $dd = new Data::Dumper::Sorted;

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my %h;

# test 2	check accessor
my $th = tie %h, $package;

my $exp = q|6	= bless([{
	},
{
	},
{
	},
0,0,undef,], '|. $package .q|');
|;
my $got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 3	recheck accessor
$th = tied %h;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

my(@rv,@exidx);
my $var = 100;
my $ic = 0;	# one time iteration counter

# $sub_tie->($self)
my $subtie = sub {
  @rv = @_;
# $rv[0] is $self
  $rv[0]->[7]->{DATA} = {};
};

# $sub_fetch->($self,$key,$valueindex)
my $subfetch = sub {
  my($self,$key,$vi) = @rv = @_;
  @{$self->[7]->{DATA}->{$vi}}{qw( touch track )} = ('fch' . $var++, $key);
};

# $sub_store->($self,\@keys,$valueindex)
my $substore = sub {
  my($self,$kp,$vi) = @rv = @_;
  $self->[7]->{DATA}->{$vi} = {
	touch	=> 'sto' . $var++,
	track	=> $kp
  };
};

# $sub_delete->($self,$kp,$vp)
my $subdelete = sub {
  my($self,$kp,$vp) = @rv = @_;
  @exidx = delete @{$self->[7]->{DATA}}{@{$vp}};
};

# $sub_exists->($self,$key,$valueindex)
my $subexists = sub {
  my($self,$key) = @rv = @_;
  my $vi = $self->[0]->{$key};
  $self->[7]->{DATA}->{$vi} = {
	touch	=> 'exs' . $var++,
	track	=> $key
  };
};

# $sub___next->($self,$key)
my $subnext = sub {
  my($self,$key,$vi) = @rv = @_;
  $ic++;				# bump iteration counter
# do nothing, goes to a FETCH
};

# $sub_copy->($self,$copy,\@valueindex)
my $subcopy = sub {
  my($self,$copy,$vi) = @rv = @_;
  foreach (keys %{$self->[7]}) {
    next if $_ eq 'DATA';
    $copy->[7]->{$_} = $self->[7]->{$_};
  }
  foreach (@$vi) {
#    @{$copy->[7]->{DATA}->{$_}}{qw( touch track )} = @{$self->[7]->{DATA}->{$_}}{qw( touch track )};
    $copy->[7]->{DATA}->{$_}->{touch} = $self->[7]->{DATA}->{$_}->{touch};
    if (ref $self->[7]->{DATA}->{$_}->{track}) {
      if (ref $self->[7]->{DATA}->{$_}->{track} eq 'ARRAY') {
	foreach my $track (@{$self->[7]->{DATA}->{$_}->{track}}) {
	  push @{$copy->[7]->{DATA}->{$_}->{track}}, $self->[7]->{DATA}->{$_}->{track}->{$track};
	}
      } else {
	foreach my $track (keys %{$self->[7]->{DATA}->{$_}->{track}}) {
	  $copy->[7]->{DATA}->{$_}->{track}->{$track} = $self->[7]->{DATA}->{$_}->{track}->{$track};
	}
      }
    } else {
      $copy->[7]->{DATA}->{$_}->{track} = $self->[7]->{DATA}->{$_}->{track};
    }
  }
};

# $sub_clear->($self)
my $subclear = sub {
  my($self) = @rv = @_;
  $self->[7]->{DATA} = {};
};

# $sub_addkey->($self,$key,$valueindex,\@newkeys)
my $subaddkey = sub {
  my($self,$key,$vi,$nk) = @rv = @_;
  $self->[7]->{DATA}->{$vi}->{touch} = 'ak'. $var++;
  $self->[7]->{DATA}->{$vi}->{track} = [$key,@$nk];
};

# $sub_delkey->($self,$key,$vi)
my $subdelkey = sub {
  my($self,$key,$vi,$lastkey) = @rv = @_;
  $self->[7]->{DATA}->{$vi}->{touch} = 'dk'. $var++;
  $self->[7]->{DATA}->{$vi}->{track} = $key;
};

# $sub_Korder->{$self,\$reordermap)
my $subKorder = sub {
  @rv = @_;
};

# $sub_Vorder->($self,\%kmap
my $subVorder = sub {
  my($self,$kmap) = @rv = @_;
  my %newdata = map { $kmap->{$_}, $self->[7]->{DATA}->{$_} } keys %$kmap;
  $self->[7]->{DATA} = \%newdata;
};

# $sub_consolidate->($self,\%kbv,\$ko)
my $subconsol = sub {
  my($self,$kbv,$ko) = @rv = @_;
  my @vi = keys %{$self->[7]->{DATA}};
  foreach (@vi) {
    delete $self->[7]->{DATA}->{$_} unless exists $self->[1]->{$_};
  }
};

undef $th;
untie %h;

# test 4	tie extension
$exp = q|22	= bless([{
	},
{
	},
{
	},
0,0,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype');
|;
$th = tie %h, $package,
	TIE		=> $subtie,
	FETCH		=> $subfetch,
	STORE		=> $substore,
	DELETE		=> $subdelete,
	EXISTS		=> $subexists,
	NEXT		=> $subnext,
	CLEAR		=> $subclear,
	ADDKEY		=> $subaddkey,
	DELKEY		=> $subdelkey,
	COPY		=> $subcopy,
	REORDERK	=> $subKorder,
	REORDERV	=> $subVorder,
	CONSOLD		=> $subconsol;

$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 5	check subtie rv
$exp = q|23	= [bless([{
	},
{
	},
{
	},
0,0,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
];
|;
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 6	store value set
$exp = q|42	= [bless([{
		'a'	=> 0,
		'b'	=> 0,
		'c'	=> 0,
	},
{
		'0'	=> 'store1',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
	},
1,3,'abc',undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['a','b','c',],
0,];
|;
$h{qw(a b c)} = 'store1';
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 7	store value set 2
$exp = q|87	= [bless([{
		'a'	=> 0,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'over'	=> 1,
		'quick'	=> 1,
		'the'	=> 1,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
	},
2,12,['the','quick','brown','fox','jumped','over','the','lazy','dog',],
undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
			'1'	=> {
				'touch'	=> 'sto101',
				'track'	=> ['the','quick','brown','fox','jumped','over','the','lazy','dog',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['the','quick','brown','fox','jumped','over','the','lazy','dog',],
1,];
|;
$h{[qw(the quick brown fox jumped over the lazy dog)]} = 'store2';
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 8	store value set 3
$exp = q|82	= [bless([{
		'a'	=> 0,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'over'	=> 1,
		'quick'	=> 1,
		'the'	=> 1,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
	},
3,14,'xy',undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
			'1'	=> {
				'touch'	=> 'sto101',
				'track'	=> ['the','quick','brown','fox','jumped','over','the','lazy','dog',],
			},
			'2'	=> {
				'touch'	=> 'sto102',
				'track'	=> ['x','y',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['x','y',],
2,];
|;
$h{qw( x y )} = 'store3';
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 9	store value set 4
$exp = q|109	= [bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'quick'	=> 1,
		'the'	=> 1,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
4,20,'inmemoryofneelandprey',undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
			'1'	=> {
				'touch'	=> 'sto101',
				'track'	=> ['the','quick','brown','fox','jumped','over','the','lazy','dog',],
			},
			'2'	=> {
				'touch'	=> 'sto102',
				'track'	=> ['x','y',],
			},
			'3'	=> {
				'touch'	=> 'sto103',
				'track'	=> ['in','memory','of','neel','and','prey',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['in','memory','of','neel','and','prey',],
3,];
|;
$h{qw(in memory of neel and prey)} = 'store4';
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 10	fetch a value
$exp = q|94	= [bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'quick'	=> 1,
		'the'	=> 1,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
4,20,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
			'1'	=> {
				'touch'	=> 'fch104',
				'track'	=> 'fox',
			},
			'2'	=> {
				'touch'	=> 'sto102',
				'track'	=> ['x','y',],
			},
			'3'	=> {
				'touch'	=> 'sto103',
				'track'	=> ['in','memory','of','neel','and','prey',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
'fox',1,];
|;
$got = $h{'fox'};
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

############## plan, add several more keysets or individual keys, delete @{$h}{@keys} and  delete $h[@keys] to track effect

# test 11	add several more key sets
$exp = q|139	= [bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fat'	=> 5,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lady'	=> 5,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'one'	=> 4,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		'sings'	=> 5,
		'the'	=> 1,
		'two'	=> 4,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
		'4'	=> 'store5',
		'5'	=> 'store6',
		'6'	=> 'store7',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'4'	=> {
			'one'	=> 20,
			'two'	=> 21,
		},
		'5'	=> {
			'fat'	=> 22,
			'lady'	=> 23,
			'sings'	=> 24,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
	},
7,28,['q','r','s',],
undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
			'1'	=> {
				'touch'	=> 'fch104',
				'track'	=> 'fox',
			},
			'2'	=> {
				'touch'	=> 'sto102',
				'track'	=> ['x','y',],
			},
			'3'	=> {
				'touch'	=> 'sto103',
				'track'	=> ['in','memory','of','neel','and','prey',],
			},
			'4'	=> {
				'touch'	=> 'sto105',
				'track'	=> ['one','two',],
			},
			'5'	=> {
				'touch'	=> 'sto106',
				'track'	=> ['fat','lady','sings',],
			},
			'6'	=> {
				'touch'	=> 'sto107',
				'track'	=> ['q','r','s',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['q','r','s',],
6,];
|;
$h{['one','two']} = 'store5';
$h{[qw(fat lady sings)]} = 'store6';
$h{[qw( q r s )]} = 'store7';
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 12	test delete @keys
$exp = q|115	= [bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'brown'	=> 1,
		'c'	=> 0,
		'dog'	=> 1,
		'fox'	=> 1,
		'in'	=> 3,
		'jumped'	=> 1,
		'lazy'	=> 1,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'over'	=> 1,
		'prey'	=> 3,
		'q'	=> 6,
		'quick'	=> 1,
		'r'	=> 6,
		's'	=> 6,
		'the'	=> 1,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store2',
		'2'	=> 'store3',
		'3'	=> 'store4',
		'6'	=> 'store7',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'1'	=> {
			'brown'	=> 5,
			'dog'	=> 11,
			'fox'	=> 6,
			'jumped'	=> 7,
			'lazy'	=> 10,
			'over'	=> 8,
			'quick'	=> 4,
			'the'	=> 9,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
		'6'	=> {
			'q'	=> 25,
			'r'	=> 26,
			's'	=> 27,
		},
	},
7,28,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
			'1'	=> {
				'touch'	=> 'fch104',
				'track'	=> 'fox',
			},
			'2'	=> {
				'touch'	=> 'sto102',
				'track'	=> ['x','y',],
			},
			'3'	=> {
				'touch'	=> 'sto103',
				'track'	=> ['in','memory','of','neel','and','prey',],
			},
			'6'	=> {
				'touch'	=> 'sto107',
				'track'	=> ['q','r','s',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['fat','lady','sings','one','two',],
[5,4,],
];
|;
delete $h{'fat','two'};
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 13	check deleted extension pointers
$exp = q|11	= [{
		'touch'	=> 'sto106',
		'track'	=> ['fat','lady','sings',],
	},
{
		'touch'	=> 'sto105',
		'track'	=> ['one','two',],
	},
];
|;
$got = $dd->DumperA(\@exidx);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 14	test delete \@keys
$exp = q|86	= [bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'in'	=> 3,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
7,28,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'sto100',
				'track'	=> ['a','b','c',],
			},
			'2'	=> {
				'touch'	=> 'sto102',
				'track'	=> ['x','y',],
			},
			'3'	=> {
				'touch'	=> 'sto103',
				'track'	=> ['in','memory','of','neel','and','prey',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['q','r','s','quick','brown','fox','jumped','over','the','lazy','dog',],
[6,1,],
];
|;
delete $h{['q','jumped']};
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 15	check deleted extension pointers
$exp = q|9	= [{
		'touch'	=> 'sto107',
		'track'	=> ['q','r','s',],
	},
{
		'touch'	=> 'fch104',
		'track'	=> 'fox',
	},
];
|;
$got = $dd->DumperA(\@exidx);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 16	test iteration and NEXT function
my @capturekeys;
my %capture;
while (my($k,$v) = each %h) {
  $capture{$k} = $v;
  push @capturekeys, $rv[1];
}
$exp = q|11	= {
	'a'	=> 'store1',
	'and'	=> 'store4',
	'b'	=> 'store1',
	'c'	=> 'store1',
	'in'	=> 'store4',
	'memory'	=> 'store4',
	'neel'	=> 'store4',
	'of'	=> 'store4',
	'prey'	=> 'store4',
	'x'	=> 'store3',
	'y'	=> 'store3',
};
|;
$got = $dd->DumperA(\%capture);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 17	check captured keys
$exp = q|11	= ['a','and','b','c','in','memory','neel','of','prey','x','y',];
|;
@capturekeys = sort @capturekeys;
$got = $dd->DumperA(\@capturekeys);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 18	check iteration capture
$exp = 11;
print "got: $ic, exp: $exp\nnot "
	unless $ic == $exp;
&ok;

# test 19 - 21	test exists and sycronize $var tracking cross platform
foreach(qw( b x memory )) {
  print "failed to detect key '$_'\nnot "
	unless exists $h{$_};
  &ok;
}

# test 22	check sub_exists and sycronize $var tracking cross platform
$exp = q|61	= [bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'in'	=> 3,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
7,28,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'exs119',
				'track'	=> 'b',
			},
			'2'	=> {
				'touch'	=> 'exs120',
				'track'	=> 'x',
			},
			'3'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
'memory',];
|;
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

########### copy next

# test 23	check copy matches original
my %new;
tie %new, 'Tie::Hash::MultiKey::ExtensionPrototype';
my $thy = $th->copy(\%new);
my $gself = $dd->DumperA($rv[0]);
my $gcopy = $dd->DumperA($rv[1]);
print "COPY does not match ORIGINAL\n$gcopy\n$gself\nnot "
	unless $gself eq $gcopy;
&ok;

# test 24	check copy contents
my $cexp = q|59	= bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'in'	=> 3,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		'x'	=> 2,
		'y'	=> 2,
	},
{
		'0'	=> 'store1',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'2'	=> {
			'x'	=> 12,
			'y'	=> 13,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
7,28,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'exs119',
				'track'	=> 'b',
			},
			'2'	=> {
				'touch'	=> 'exs120',
				'track'	=> 'x',
			},
			'3'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype');
|;
print "got: $gcopy\nexp: $cexp\nnot "
	unless $gcopy eq $cexp;
&ok;

# test 25	add key
$exp = q|72	= [bless([{
		'a'	=> 0,
		'and'	=> 3,
		'b'	=> 0,
		'c'	=> 0,
		'in'	=> 3,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		'w'	=> 2,
		'x'	=> 2,
		'y'	=> 2,
		'z'	=> 2,
	},
{
		'0'	=> 'store1',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'a'	=> 0,
			'b'	=> 1,
			'c'	=> 2,
		},
		'2'	=> {
			'w'	=> 28,
			'x'	=> 12,
			'y'	=> 13,
			'z'	=> 29,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
7,30,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'exs119',
				'track'	=> 'b',
			},
			'2'	=> {
				'touch'	=> 'ak122',
				'track'	=> ['x','w','z',],
			},
			'3'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
'x',2,['w','z',],
];
|;
$th->addkey([qw(w z)] => 'x');
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 26	delete key
$exp = q|65	= [bless([{
		'and'	=> 3,
		'b'	=> 0,
		'in'	=> 3,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		'w'	=> 2,
		'x'	=> 2,
		'y'	=> 2,
		'z'	=> 2,
	},
{
		'0'	=> 'store1',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'b'	=> 1,
		},
		'2'	=> {
			'w'	=> 28,
			'x'	=> 12,
			'y'	=> 13,
			'z'	=> 29,
		},
		'3'	=> {
			'and'	=> 18,
			'in'	=> 14,
			'memory'	=> 15,
			'neel'	=> 17,
			'of'	=> 16,
			'prey'	=> 19,
		},
	},
7,30,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'dk124',
				'track'	=> 'c',
			},
			'2'	=> {
				'touch'	=> 'ak122',
				'track'	=> ['x','w','z',],
			},
			'3'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
'c',0,];
|;
$th->delkey('a','c');
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 27	reorder keys
$exp = q|75	= [bless([{
		'and'	=> 3,
		'b'	=> 0,
		'in'	=> 3,
		'memory'	=> 3,
		'neel'	=> 3,
		'of'	=> 3,
		'prey'	=> 3,
		'w'	=> 2,
		'x'	=> 2,
		'y'	=> 2,
		'z'	=> 2,
	},
{
		'0'	=> 'store1',
		'2'	=> 'store3',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'b'	=> 0,
		},
		'2'	=> {
			'w'	=> 9,
			'x'	=> 1,
			'y'	=> 2,
			'z'	=> 10,
		},
		'3'	=> {
			'and'	=> 7,
			'in'	=> 3,
			'memory'	=> 4,
			'neel'	=> 6,
			'of'	=> 5,
			'prey'	=> 8,
		},
	},
7,11,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'dk124',
				'track'	=> 'c',
			},
			'2'	=> {
				'touch'	=> 'ak122',
				'track'	=> ['x','w','z',],
			},
			'3'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
{
		'and'	=> 7,
		'b'	=> 0,
		'in'	=> 3,
		'memory'	=> 4,
		'neel'	=> 6,
		'of'	=> 5,
		'prey'	=> 8,
		'w'	=> 9,
		'x'	=> 1,
		'y'	=> 2,
		'z'	=> 10,
	},
];
|;
$th->_rordkeys;
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 28	reorder vals
$exp = q|67	= [bless([{
		'and'	=> 2,
		'b'	=> 0,
		'in'	=> 2,
		'memory'	=> 2,
		'neel'	=> 2,
		'of'	=> 2,
		'prey'	=> 2,
		'w'	=> 1,
		'x'	=> 1,
		'y'	=> 1,
		'z'	=> 1,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store3',
		'2'	=> 'store4',
	},
{
		'0'	=> {
			'b'	=> 0,
		},
		'1'	=> {
			'w'	=> 9,
			'x'	=> 1,
			'y'	=> 2,
			'z'	=> 10,
		},
		'2'	=> {
			'and'	=> 7,
			'in'	=> 3,
			'memory'	=> 4,
			'neel'	=> 6,
			'of'	=> 5,
			'prey'	=> 8,
		},
	},
3,11,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'dk124',
				'track'	=> 'c',
			},
			'1'	=> {
				'touch'	=> 'ak122',
				'track'	=> ['x','w','z',],
			},
			'2'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
{
		'0'	=> 0,
		'2'	=> 1,
		'3'	=> 2,
	},
];
|;
$th->_rordvals;
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 29	set up for consolidation test
$exp = q|78	= [bless([{
		'and'	=> 2,
		'b'	=> 0,
		'in'	=> 2,
		'memory'	=> 2,
		'neel'	=> 2,
		'not'	=> 3,
		'of'	=> 2,
		'prey'	=> 2,
		'store4'	=> 3,
		'w'	=> 1,
		'x'	=> 1,
		'y'	=> 1,
		'z'	=> 1,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store3',
		'2'	=> 'store4',
		'3'	=> 'store4',
	},
{
		'0'	=> {
			'b'	=> 0,
		},
		'1'	=> {
			'w'	=> 9,
			'x'	=> 1,
			'y'	=> 2,
			'z'	=> 10,
		},
		'2'	=> {
			'and'	=> 7,
			'in'	=> 3,
			'memory'	=> 4,
			'neel'	=> 6,
			'of'	=> 5,
			'prey'	=> 8,
		},
		'3'	=> {
			'not'	=> 11,
			'store4'	=> 12,
		},
	},
4,13,'notstore4',undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'dk124',
				'track'	=> 'c',
			},
			'1'	=> {
				'touch'	=> 'ak122',
				'track'	=> ['x','w','z',],
			},
			'2'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
			'3'	=> {
				'touch'	=> 'sto125',
				'track'	=> ['not','store4',],
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
['not','store4',],
3,];
|;
$h{qw( not store4 )} = 'store4';
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 30	consolidate
$exp = q|106	= [bless([{
		'and'	=> 2,
		'b'	=> 0,
		'in'	=> 2,
		'memory'	=> 2,
		'neel'	=> 2,
		'not'	=> 2,
		'of'	=> 2,
		'prey'	=> 2,
		'store4'	=> 2,
		'w'	=> 1,
		'x'	=> 1,
		'y'	=> 1,
		'z'	=> 1,
	},
{
		'0'	=> 'store1',
		'1'	=> 'store3',
		'2'	=> 'store4',
	},
{
		'0'	=> {
			'b'	=> 0,
		},
		'1'	=> {
			'w'	=> 9,
			'x'	=> 1,
			'y'	=> 2,
			'z'	=> 10,
		},
		'2'	=> {
			'and'	=> 7,
			'in'	=> 3,
			'memory'	=> 4,
			'neel'	=> 6,
			'not'	=> 11,
			'of'	=> 5,
			'prey'	=> 8,
			'store4'	=> 12,
		},
	},
3,13,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
			'0'	=> {
				'touch'	=> 'dk124',
				'track'	=> 'c',
			},
			'1'	=> {
				'touch'	=> 'ak122',
				'track'	=> ['x','w','z',],
			},
			'2'	=> {
				'touch'	=> 'exs121',
				'track'	=> 'memory',
			},
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
{
		'store1'	=> ['b',],
		'store3'	=> ['w','x','y','z',],
		'store4'	=> ['and','in','memory','neel','of','prey','not','store4',],
	},
{
		'and'	=> 7,
		'b'	=> 0,
		'in'	=> 3,
		'memory'	=> 4,
		'neel'	=> 6,
		'not'	=> 11,
		'of'	=> 5,
		'prey'	=> 8,
		'store4'	=> 12,
		'w'	=> 9,
		'x'	=> 1,
		'y'	=> 2,
		'z'	=> 10,
	},
{
		'0'	=> [0,],
		'1'	=> [1,],
		'2'	=> [2,3,],
	},
];
|;
$th->consolidate;
$got = $dd->DumperA(\@rv);
#if ($got eq $exp) {
#  &ok;
#} else {	# not all platforms sort hashes the same way
#  print "ok $test	# Skipped\n";
#  $test++;
#}
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 31	clear
$exp = q|23	= [bless([{
	},
{
	},
{
	},
0,0,undef,undef,{
		'ADDKEY'	=> sub {'DUMMY'},
		'CLEAR'	=> sub {'DUMMY'},
		'CONSOLD'	=> sub {'DUMMY'},
		'COPY'	=> sub {'DUMMY'},
		'DATA'	=> {
		},
		'DELETE'	=> sub {'DUMMY'},
		'DELKEY'	=> sub {'DUMMY'},
		'EXISTS'	=> sub {'DUMMY'},
		'FETCH'	=> sub {'DUMMY'},
		'NEXT'	=> sub {'DUMMY'},
		'REORDERK'	=> sub {'DUMMY'},
		'REORDERV'	=> sub {'DUMMY'},
		'STORE'	=> sub {'DUMMY'},
		'TIE'	=> sub {'DUMMY'},
	},
], 'Tie::Hash::MultiKey::ExtensionPrototype'),
];
|;
%h = ();
$got = $dd->DumperA(\@rv);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 32	verify that copied hash is untouched
$got = $dd->DumperA($thy);
print "got: $got\nexp: $gcopy\nnot "
	unless $got eq $gcopy;
&ok;

