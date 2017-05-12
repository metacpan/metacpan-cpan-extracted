package Tie::REHash;

use 5.006; 

use strict qw[vars subs];
$Tie::REHash::VERSION = '1.05'; 

no warnings; 

sub CDUP () { 0 } 
sub CMIS () { 1 } 
sub CHIT () { 1 } 
sub OFFSET () { 0 } 
our (%Global_options, %AD);
our $qr_fragment = qr{(subcall[\w\d]+)(?:\(\))?}; 

$AD{croak} = 'use Carp;';

$AD{import} = <<'SUBCODE';
sub import {
	my $self = shift;
	%Global_options = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

	$Global_options{precompile}
	and $self->precompile;

	exists $Global_options{stringref_bug_is_fixed}
	and $self->stringref_bug_is_fixed;
}
SUBCODE

*tiehash = \&new;
*TIEHASH = \&new;
*STORE = \&store;
*FETCH = \&fetch;
*EXISTS = \&exists;
*DELETE = \&delete;
*FIRSTKEY = \&firstkey;
*NEXTKEY = \&nextkey;
*SCALAR = \&scalar;
*CLEAR = \&clear;

$AD{new} = <<'SUBCODE';
sub new {
	return $_[0] 
	if ref $_[0];

	my $self = bless {}, $_[0]; 

	if (ref $_[1]) {
		$_[1] =~ /HASH/
		or croak("Wrong $_[1] argument to tie()");

		$self->{REGX} = [ $_[1] ]; 
		$self->{DELIM} = $_[2] if @_ == 3;
	}
	else {
		shift @_;

		$self->{DELIM} = pop @_
		if @_ - 2*int(@_/2);

		$self->{REGX} = [ {@_} ];
	}

	$self->{ESC} = {};

	$self->{DELIM} = $Global_options{autodelete_limit} 
	if exists $Global_options{autodelete_limit};

	$self->{OFFSET2} = $Global_options{_offset2} 
	if exists $Global_options{_offset2};

	$self->{REMOD} 
	= exists $Global_options{remove_dups}
	? $Global_options{remove_dups} 
	: 1;

	$self->{CACH} 
	= ref $Global_options{do_cache} eq 'HASH' 
	? $Global_options{do_cache} : {} 
	if exists $Global_options{do_cache};

	$self->{CMIS2} 
	= exists $Global_options{do_cache_miss}
	? $Global_options{do_cache_miss}
	: 1;

	$self->{CHIT2} 
	= exists $Global_options{do_cache_hit}
	? $Global_options{do_cache_hit}
	: 1;

	return $self
}
SUBCODE

$AD{store} = <<'SUBCODE';
sub store { 
	my $self = $_[0];

	$self->{IS_NORMALIZED} = undef;

	my $cach = $self->{CACH} if !CDUP; 

	my ($k, $esc, $dyn);

	!ref $_[1] ? $k = $_[1] 
	: do{ 
		($k, $esc, $dyn) 
		= (ref $_[1] eq 'REF' 
		or ref $_[1] eq 'SCALAR') 
		? ref $_[2] eq 'CODE' 
		? ( ${$_[1]}, undef, 1 ) 
		: ( ${$_[1]}, 1 ) 
		: ( $_[1] ); 

		if (ref $k eq 'Regexp') {
			$dyn 
			? $self->{DYN2}{$k} = 1 
			: delete $self->{DYN2}{$k};
			$esc 
			? $self->{ESC2}{$k} = 1 
			: delete $self->{ESC2}{$k};

			if (exists $self->{REGX2}{$k}) { 
				my $regx = $self->{REGX};

				$k eq $regx->[$_] 
				and splice(@$regx, $_, 1) 
				foreach reverse 0..$#$regx;
			} 

			my (@upfront, $element); 
			while (@{$self->{REGX}}) { 
				$element = $self->{REGX}[0]; 

				last 
				if ref $element eq 'Regexp' 
				or $self->{DELIM}
				and $self->{DELIM} <= keys %$element; 

				shift @{$self->{REGX}};

				$_ =~ $k 
				and delete $element->{$_}
				foreach keys %$element;

				push @upfront, $element;
			} 
			unshift @{$self->{REGX}}, @upfront, $k; 

			if (!CDUP and $cach) { 
				$_ =~ $k 
				and delete $cach->{$_}
				foreach keys %$cach;
			}

			return $self->{REGX2}{$k} = $esc ? undef : $_[2] 
		} 

		_examine($self) 
		if @{$self->{REGX}} > 1; 
	};

	!CDUP 
	and $cach 
	and delete $cach->{$k}; 

	$esc
	and @{$self->{REGX}} == 1
	and ref $self->{REGX}[0] eq 'HASH'
	and delete $self->{REGX}[0]{$k}
	, delete $self->{ESC}{$k}
	, delete $self->{DYN}{$k}
	, return undef; 

	$dyn 
	? $self->{DYN}{$k} = 1 
	: delete $self->{DYN}{$k};
	$esc 
	? $self->{ESC}{$k} = 1 
	: delete $self->{ESC}{$k};

	my $offset;
	foreach (@{$self->{REGX}}) { 
		last 
		if ref $_ eq 'Regexp' 
		and $k =~ $_; 

		return $_->{$k} = $esc ? undef : $_[2] 
		if ref $_ eq 'HASH'; 

		last if OFFSET
		and $self->{OFFSET2} 
		and $self->{OFFSET2} <= ++$offset; 
	} 

	unshift @{$self->{REGX}}, {$k => $esc ? undef : $_[2] };

	return $esc ? undef : $_[2] 
}
SUBCODE

$AD{subcall_match} = <<'SUBCODE';
SUBCODE
$AD{subcall_match2} = <<'SUBCODE';
	!$cach2
	? $self->{REGX2}{ $_}
	: ( CDUP 
	? $self->{REGX}[0]{$k}
	: ${ $cach2->{$k}
	 = \$self->{REGX2}{ $_} } )
SUBCODE
$AD{subcall_match0} = <<'SUBCODE';
	!$cach2
	? undef
	: ( CDUP 
	? $self->{REGX}[0]{$k}
	: $cach2->{$k} = undef
	, $self->{ESC}{$k} = 1 )[0] 
SUBCODE

$AD{subcall_fetch} = <<'SUBCODE';
	($_ eq $cach ? ${$_->{$k}} 
	 : $_->{$k})
SUBCODE
$AD{subcall_fetch2} = <<'SUBCODE';
	!$cach2
	? $_ eq $cach ? ${$_->{$k}} 
	 : $_->{$k}
	: ( CDUP 
	? $self->{REGX}[0]{$k}
	: ${ $cach2->{$k}
	 = \$_->{$k} } ) 
SUBCODE
$AD{subcall_fetch0} = <<'SUBCODE';
	!$cach2
	? undef
	: ( CDUP 
	? $self->{REGX}[0]{$k}
	: $cach2->{$k}
	 = undef )
SUBCODE

$AD{fetch} = <<'SUBCODE';
sub fetch { 
	my $self = $_[0];
	my $type = $_[2];

	my ($k, $esc);

	!ref $_[1] ? $k = $_[1] 
	: do{ 
		($k, $esc) 
		= (ref $_[1] eq 'REF' 
		or ref $_[1] eq 'SCALAR') 
		? ( ${$_[1]}, 1 ) 
		: ( $_[1] ); 

		if (ref $k eq 'Regexp') {
			return 
			 exists $self->{ESC2}{$k}
			? undef
			: $type eq 'ex'
			? 1
			: exists $self->{DYN2}{$k} && !$esc 
			? $type eq 'sr' 
			? \$self->{REGX2}{$k}($self, $k, @_[2..$#_]) 
			: $self->{REGX2}{$k}($self, $k, @_[2..$#_])
			: $type eq 'sr' 
			? \$self->{REGX2}{$k}
			: $self->{REGX2}{$k} 
			if exists $self->{REGX2}{$k};

			return undef;
		}
	}; 

	my $cach = $self->{CACH}; 

	my $first_element2;
	ref ($first_element2 = $self->{REGX}[0]) eq 'HASH'
	or $first_element2 = undef ; 
	foreach (CDUP || !$cach ? () : $cach, @{$self->{REGX}}) { 
		my $cach2 = $cach 
		if $_ ne $cach
		and $_ ne $first_element2; 

		if (ref $_ eq 'Regexp') { 
			next if $k !~ $_; 

			if ( CHIT 
			and $self->{CHIT2}
			) {
				CDUP
				and ref $self->{REGX}[0] eq 'HASH'
				|| unshift @{$self->{REGX}}, {};

				return 
				 exists $self->{ESC2}{$_}
				? subcall_match0()
				: $type eq 'ex'
				? 1
				: exists $self->{DYN2}{$_} && !$esc 
				? $type eq 'sr' 
				? \(subcall_match2()->($self, $k, @_[2..$#_])) 
				: subcall_match2()->($self, $k, @_[2..$#_])
				: $type eq 'sr' 
				? \(subcall_match2())
				: subcall_match2();
			}
			else {
				return 
				 exists $self->{ESC2}{$_}
				? undef
				: $type eq 'ex'
				? 1
				: exists $self->{DYN2}{$_} && !$esc 
				? $type eq 'sr' 
				? \$self->{REGX2}{ $_}($self, $k, @_[2..$#_]) 
				: $self->{REGX2}{ $_}($self, $k, @_[2..$#_])
				: $type eq 'sr' 
				? \$self->{REGX2}{ $_}
				: $self->{REGX2}{ $_};
			}
		} 
		else { 
			next if !exists $_->{$k}; 

			if ( CHIT 
			and $self->{CHIT2}
			) {
				CDUP
				and ref $self->{REGX}[0] eq 'HASH'
				|| unshift @{$self->{REGX}}, {};

				return 
				 exists $self->{ESC}{$k}
				? subcall_fetch0() 
				: $type eq 'ex'
				? 1
				: exists $self->{DYN}{$k} && !$esc 
				? $type eq 'sr' 
				? \(subcall_fetch2()->($self, $k, @_[2..$#_])) 
				: subcall_fetch2()->($self, $k, @_[2..$#_]) 
				: $type eq 'sr' 
				? \(subcall_fetch2()) 
				: subcall_fetch2(); 
			}
			else {	
				return 
				 exists $self->{ESC}{$k}
				? undef
				: $type eq 'ex'
				? 1
				: exists $self->{DYN}{$k} && !$esc 
				? $type eq 'sr' 
				? \(subcall_fetch()->($self, $k, @_[2..$#_])) 
				: subcall_fetch()->($self, $k, @_[2..$#_]) 
				: $type eq 'sr' 
				? \subcall_fetch()
				: subcall_fetch();

			}
		} 
	} 

	!CDUP
	? ( $cach 
	 and $self->{ESC}{$k} = 1 
	 and $cach->{$k} = undef ) 
	: ( ref $self->{REGX}[0] eq 'HASH'
	? $self->{REGX}[0]{$k} = undef
	: unshift(@{$self->{REGX}}, {$k => undef})
	, $self->{ESC}{$k} = 1 )
	if CMIS 
	and $self->{CMIS2} 
	and $self->{CMIS2} < @{$self->{REGX}};

	return undef 
}
SUBCODE

$AD{_examine} = <<'SUBCODE';
sub _examine { 
	my $self = $_[0];

	my $element;
	while (1) { 
		last 
		unless 
		exists $self->{ESC2}{$element = 
		 $self->{REGX}[-1]}; 

		pop @{$self->{REGX}};
		delete $self->{REGX2}{ $element};
		delete $self->{ESC2}{$element};
		delete $self->{DYN2}{$element};
	}
}
SUBCODE

$AD{exists} = <<'SUBCODE';
sub exists { 
	$_[2] = 'ex'; 
	goto &FETCH 
}
SUBCODE

$AD{delete} = <<'SUBCODE';
sub delete {
	my ($k, $esc, $dyn); 

	!ref $_[1] ? $k = $_[1] 
	: do{ 
		($k, $esc, $dyn) 
		= (ref $_[1] eq 'REF' 
		or ref $_[1] eq 'SCALAR') 
		? ref $_[2] eq 'CODE' 
		? ( ${$_[1]}, undef, 1 ) 
		: ( ${$_[1]}, 1 ) 
		: ( $_[1] ); 

		if (ref $k eq 'Regexp') {
			return( ( $_[0]->FETCH( $k)
			 , $_[0]->STORE(\$k) )[0] )
		}
	};

	return undef 
	unless my $value = $_[0]->FETCH( $k, 'sr'); 
	$value = $$value; 
	$_[0]->STORE(\$k);
	return $value 
}
SUBCODE

$AD{normalize} = <<'SUBCODE';
sub normalize { 
	my $self = $_[0];

	my ($element, $element2); 

	my $regx = \@{$self->{REGX}};
	my $esc = \%{$self->{ESC}};
	my $esc2 = \%{$self->{ESC2}};
	my $regx2 = \%{$self->{REGX2}};

	my $rem_esc_2;
	my $rem_all_2;
	my $rem_2 = $self->{REMOD};
	 $rem_2 == 3
	? $rem_all_2 = 1
	: $rem_2 == 2
	? $rem_esc_2 = 1
	: $rem_2 && !($self)->SCALAR() 
	? $rem_esc_2 = 1 
	: ();

	foreach $element2 (@$regx) { 
		next unless ref $element2 eq 'HASH'; 

		foreach my $k (keys %$element2) { 
			my $in_over;
			if ($rem_all_2
			or $rem_esc_2 and my $esc_key = $esc->{$k} 
			) {
				my $over_element2;
				my $element2_k_is_2; 
				foreach $element (@$regx) { 
					$in_over
					and ref $element eq 'HASH' 
					? delete $element->{$k} 
					:( !defined $element2_k_is_2 
					and $over_element2
					and exists $element2->{$k} 
					and $k =~ $element
					and $element2_k_is_2 
					= $esc_key 
					? exists $esc2->{$element} ? 1 : 0 
					: $element2->{$k} eq $regx2->{$element} )
					, next;

					$over_element2 = 1 if $element eq $element2;

					$in_over = 1 
					if ref $element eq 'Regexp' 
					? $k =~ $element 
					: $over_element2; 
				} 

				!defined $element2_k_is_2 
				and $esc_key
				and exists $element2->{$k}
				and $element2_k_is_2 = 1; 

				delete $element2->{$k} 
				if $element2_k_is_2; 
			}
			else {
				foreach $element (@$regx) { 
					$in_over
					and ( ref $element eq 'HASH' 
					and delete $element->{$k} )
					, next;

					$in_over = 1 
					if ref $element eq 'Regexp' 
					? $k =~ $element 
					: $element eq $element2;
				} 
			}

		}
	}

	@$regx = ( 
		{ map ref $_ eq 'HASH' ? %$_ : (), @$regx },
		( map ref $_ ne 'HASH' ? $_ : (), @$regx ),
	);

	_examine($self) 
	if @$regx > 1;

	$self->{IS_NORMALIZED} = 1;
}
SUBCODE

$AD{firstkey} = <<'SUBCODE';
sub firstkey { 
	my $self = $_[0];

	($self)->normalize unless $self->{IS_NORMALIZED};

	$self->{EACH} = [	0, [reverse @{$self->{REGX}}] ]; 

	return( ($self)->NEXTKEY) 
}
SUBCODE

$AD{nextkey} = <<'SUBCODE';
sub nextkey { 
	my $self = $_[0];

	return( ($self)->firstkey)
	if !$self->{EACH};

	NEXT: {

	delete $self->{EACH}
	, return wantarray ? () : undef
	if $#{$self->{EACH}[1]} 
	< $self->{EACH}[0]; 

	my $element = $self->{EACH}[1]->[$self->{EACH}[0]]; 

	if (ref $element eq 'Regexp') {
		++$self->{EACH}[0];

		return( ( exists $self->{DYN2}{$element}
		 || exists $self->{ESC2}{$element} ? \$element : $element
		, wantarray ? $self->{REGX2}{ $element} : () 
		)[0, wantarray ? 1 : ()] ) 
	}
	else {
		my ($k, $value);
		wantarray ? ($k, $value) = each %$element 
		: ($k = each %$element);

		++$self->{EACH}[0]
		, redo NEXT
		if !defined $k;

		return(	( exists $self->{DYN}{$k}
		 || exists $self->{ESC}{$k} ? \$k : $k
		, wantarray ? $value : ()
		)[0, wantarray ? 1 : ()] ) 
	}

	} 

}
SUBCODE

$AD{keys} = <<'SUBCODE';
sub keys {
	(my $self, my $as_arrayref) = @_;

	($self)->normalize unless $self->{IS_NORMALIZED};

	my (@list, $count);

	if (wantarray or $as_arrayref) {
		my $element;
		foreach $element (reverse @{$self->{REGX}}) { 
			if (ref $element eq 'Regexp') { 
				push @list
				, exists $self->{DYN2}{$element}
				|| exists $self->{ESC2}{$element} ? \$element : $element;
			}
			else { 
				push @list
				, map exists $self->{DYN}{$_}
				 || exists $self->{ESC}{$_} ? \$_ : $_
				, keys %$element;
			}
		}
	}
	else {
		ref $_ eq 'Regexp' ? $count++ : ($count += keys %$_)
		foreach @{$self->{REGX}};
	}

	wantarray ? @list : $as_arrayref ? \@list : $count
}
SUBCODE

$AD{values} = <<'SUBCODE';
sub values {
	(my $self, my $as_arrayref) = @_;

	($self)->normalize unless $self->{IS_NORMALIZED};

	my (@list, $count);

	if (wantarray or $as_arrayref) {
		my $element;
		foreach $element (reverse @{$self->{REGX}}) { 
			if (ref $element eq 'Regexp') { 
				push @list, $self->{REGX2}{$element}; 
			}
			else { 
				push @list, values %$element; 
			}
		}
	}
	else {
		ref $_ eq 'Regexp' ? $count++ : ($count += keys %$_)
		foreach @{$self->{REGX}};
	}

	wantarray ? @list : $as_arrayref ? \@list : $count
} 
SUBCODE

$AD{list} = <<'SUBCODE';
sub list {
	my $as_arrayref = $_[1];

	my $ks = $_[0]->keys( 'as_arrayref'); 
	my $values = $_[0]->values('as_arrayref'); 
	my @list = map +($ks->[$_], $values->[$_]), 0..$#$ks;

	wantarray ? @list : $as_arrayref ? \@list : @list
}
SUBCODE

$AD{scalar} = <<'SUBCODE';
sub scalar { 
	my $self = $_[0];

	return scalar %{$self->{REGX}[0]}
	if @{$self->{REGX}} == 1
	and ref $self->{REGX}[0] eq 'HASH'
	and !%{$self->{ESC}}; 

	ref $_ eq 'Regexp' 
	and !exists $self->{ESC2}{$_}
	and return 1 
	foreach @{$self->{REGX}};

	my $cach = $self->{CACH} if !CDUP; 

	my ($element, $element2, $k);
	foreach $element2 ($cach||(), @{$self->{REGX}}) { 
		next if ref $element2 eq 'Regexp'; 

		KEY: foreach $k (keys %$element2) { 
			next if exists $self->{ESC}{$k};

			foreach $element ($cach||(), @{$self->{REGX}}) { 
				$element eq $element2
				and return 1;

				ref $element eq 'Regexp' 
				? $k =~ $element 
					? !exists $self->{ESC2}{$element} 
						? return 1 
						: next KEY 
					: next 
				: exists $element->{$k} 
					? !exists $self->{ESC}{$k} 
						? return 1 
						: next KEY 
					: next;
			}

			return 1
		}
	} 

	return 0
}
SUBCODE

$AD{clear} = <<'SUBCODE';
sub clear { 
	my $self = $_[0];

	@{$self->{REGX}} = ();
	%{$self->{ESC}} = ();
	%{$self->{DYN}} = ();
	%{$self->{ESC2}} = ();
	%{$self->{DYN2}} = ();
	%{$self->{REGX2}} = ();
	%{$self->{CACH}} = () if $self->{CACH}; 
}
SUBCODE

sub DESTROY {
	%{$_[0]} = ();
}

*storable = \&freeze;
$AD{freeze} = <<'SUBCODE';
sub freeze { 
	my $what = $_[1];
	my $selffreeze = ( $what =~ /self/i );
	my $self = $selffreeze ? $_[0] : {%{$_[0]}}; 
	if (!$selffreeze) { 
		$self->{REGX} = [@{$self->{REGX}}];
		$self->{REGX2} = {%{$self->{REGX2}}};
		$self->{ESC2} = {%{$self->{ESC2}}};
		$self->{DYN2} = {%{$self->{DYN2}}};

		bless $self, ref($_[0])||$_[0]
		if $what =~ /clone/i;
	}

	my ($wraps_removed, $old);
	ref $_ eq 'Regexp' 
	and $old = $_ , $_ = "$_"
	#,( $wraps_removed = ($_ =~ s/(\(\?[a-z\-]+:)(?=\1)//g) 
	,( $wraps_removed = ($_ =~ s/(\(\?(?:\^|[a-z\-]+):)(?=\1)//g) # perl 5.14 switches to (?^:) wrap 
	 and $_ =~ s/\){$wraps_removed}$// ) 
	,( exists $self->{REGX2}{$old}
	 and $self->{REGX2}{$_} 
	 = delete $self->{REGX2}{$old} )
	,( exists $self->{ESC2}{$old}
	 and $self->{ESC2}{$_} 
	 = delete $self->{ESC2}{$old} )
	,( exists $self->{DYN2}{$old}
	 and $self->{DYN2}{$_} 
	 = delete $self->{DYN2}{$old} )
	foreach @{$self->{REGX}}; 

	return $self
}
SUBCODE

*thaw = \&unfreeze;
*restore = \&unfreeze;
$AD{unfreeze} = <<'SUBCODE';
sub unfreeze {
	my $do_not_bless = $_[2];
	my $self = ref $_[1] ? $_[1] : ref $_[0] ? $_[0] : return undef;

	bless $self, ref($_[0])||$_[0]
	unless $self =~ /=/ 
	or $do_not_bless; 

	my $old;
	!ref $_ 
	and $old = $_ , $_ = qr{$_}
	,( exists $self->{REGX2}{$old}
	 and $self->{REGX2}{$_} 
	 = delete $self->{REGX2}{$old} )
	,( exists $self->{ESC2}{$old}
	 and $self->{ESC2}{$_} 
	 = delete $self->{ESC2}{$old} )
	,( exists $self->{DYN2}{$old}
	 and $self->{DYN2}{$_} 
	 = delete $self->{DYN2}{$old} )
	foreach @{$self->{REGX}};

	return $self
}
SUBCODE

$AD{STORABLE_freeze} = <<'SUBCODE';
sub STORABLE_freeze { 
	return (undef, $_[0]->freeze)
}
SUBCODE

$AD{STORABLE_thaw} = <<'SUBCODE';
sub STORABLE_thaw { 
	my $self = $_[3];
 $_[0]->unfreeze($self);
 %{$_[0]} = %$self;
}
SUBCODE

$AD{autodelete_limit} = <<'SUBCODE';
sub autodelete_limit {
	my $self = $_[0];

	return $self->{DELIM} = $_[1] if @_ > 1;
	return $self->{DELIM}
}
SUBCODE

$AD{_offset2} = <<'SUBCODE';
sub _offset2 {
	my $self = $_[0];

	return $self->{OFFSET2} = $_[1] if @_ > 1;
	return $self->{OFFSET2}
}
SUBCODE

$AD{do_cache} = <<'SUBCODE';
sub do_cache {
	my $self = $_[0];

	return $self->{CACH} ||= ref $_[1] eq 'HASH' ? $_[1] : {} if $_[1]; 
	return delete $self->{CACH}
}
SUBCODE

$AD{do_cache_miss} = <<'SUBCODE';
sub do_cache_miss {
	my $self = $_[0];

	return $self->{CMIS2} = $_[1] if @_ > 1;
	return $self->{CMIS2}
}
SUBCODE

$AD{do_cache_hit} = <<'SUBCODE';
sub do_cache_hit {
	my $self = $_[0];

	return $self->{CHIT2} = $_[1] if @_ > 1;
	return $self->{CHIT2}
}
SUBCODE

$AD{flush_cache} = <<'SUBCODE';
sub flush_cache {
	 my $self = $_[0];

	%{ $self->{CACH}} = () 
	if $self->{CACH}; 
}
SUBCODE

$AD{remove_dups} = <<'SUBCODE';
sub remove_dups {
	my $self = $_[0];

	return $self->{REMOD} = $_[1] if @_ > 1;
	return $self->{REMOD}
}
SUBCODE

$AD{die_on_stringref_bug} = $AD{stringref_bug_is_fixed} = <<'SUBCODE';
sub die_on_stringref_bug {
	my $bugtxt = 'Due to bug (rt.perl.org ticket 79178) in your instance of perl, storing/fetching to/from the rehash should avoid escaped literal keys (as well as stringified scalarref keys), like $hash{\"foo"} (or in one statement: $regx2{$k = \"foo"}), or fatal error will result. The workaround: $k = \"foo"; $hash{$k}.';
	#warn("BUG WARNING: $bugtxt"); 

	*FETCH2 = \&FETCH;
	*STORE2 = \&STORE;

	my $qr_scalaref = qr{^SCALAR\(0x[\dabcdef]+\)$};
	my $errmess = "Tie::REHash: Aborting due to Perl bug - escaped literal (or stringified scalarref) key has been used. $bugtxt";

	*FETCH = sub{
		!ref $_[1] 
		and $_[1] =~ $qr_scalaref
		and croak($errmess);

		goto &FETCH2;
	};
	*STORE = sub{
		!ref $_[1] 
		and $_[1] =~ $qr_scalaref
		and croak($errmess);

		goto &STORE2;
	};
}

sub stringref_bug_is_fixed {
	*FETCH = \&FETCH2;
	*STORE = \&STORE2;
}
SUBCODE

$AD{precompile} = <<'SUBCODE';
sub precompile {
	foreach (keys %AD) {
		next 
		if $_ =~ $qr_fragment; 
		 $AD{$_} =~ s/$qr_fragment/($AD{$1})/g;
		eval $AD{$_};
		!$@ or croak( "Compilation error: $@ in code: $AD{$_}")
	}

	return 1
}
SUBCODE

eval join '', map "sub $_;", keys %AD; 

sub is_precompiled { 0 }
$AD{is_precompiled} = <<'SUBCODE';
sub is_precompiled { 1 }
SUBCODE

sub AUTOLOAD {
	my $code = \( $AD{$Tie::REHash::AUTOLOAD}
	 || scalar( $Tie::REHash::AUTOLOAD =~ /::(\w+)$/, $AD{$1} ) );
	eval{ $$code =~ s/$qr_fragment/($AD{$1})/g; }; 
	eval $$code; 
	!$@ or die("$@ evaluating $$code");

	goto &$Tie::REHash::AUTOLOAD 
	if defined &$Tie::REHash::AUTOLOAD;
}

{
	package Tie::REHash::StringrefBug;
	sub TIEHASH { bless {}, $_[0] }
	sub STORE { ref $_[1] }
	sub FETCH { ref $_[1] }
}
tie my %detector, 'Tie::REHash::StringrefBug';
( $detector{\'foo'} = 1 ) eq 'SCALAR'
and $detector{\'foo'} eq 'SCALAR'
#$] >= 5.012 
or die_on_stringref_bug();

1

__END__

=head1 NAME

Tie::REHash - the tie()d implementation of hash that allows using regular expression "keys" along with plain keys (plus some more). 

=head1 SYNOPSIS

	use            Tie::REHash;
	tie  %rehash, 'Tie::REHash';
	#... %rehash is now almost standard hash, except for the following...

	# Regexp keys:...

	# basics that you might expect...
	$rehash{qr{car|auto|automobile}} =  'vehicle on wheels'; # note qr{}
	$rehash{qr{car|auto|automobile}} eq 'vehicle on wheels'; # true
	$rehash{car}                     eq 'vehicle on wheels'; # true
	$rehash{auto}                    eq 'vehicle on wheels'; # true
	$rehash{automobile}              eq 'vehicle on wheels'; # true
	exists $rehash{car};                                     # true
	exists $rehash{auto};                                    # true
	exists $rehash{automobile};                              # true
	exists $rehash{qr{car|auto|automobile}};                 # true

	#... and a bit more advanced manipulations:

	# then deleting one of matching keys...
	delete     $rehash{car}; # results in...
	not exists $rehash{car};                                 # true
	exists     $rehash{auto};                                # true
	exists     $rehash{automobile};                          # true
	exists     $rehash{qr{car|auto|automobile}};             # true

	# then altering value of another matching key...
	$rehash{auto}                    =  'automatic';
	$rehash{auto}                    eq 'automatic';         # true
	$rehash{car}                     eq undef;               # true (deleted above)
	$rehash{automobile}              eq 'vehicle on wheels'; # true
	$rehash{qr{car|auto|automobile}} eq 'vehicle on wheels'; # true

	# then overwriting two matching keys at once...
	$rehash{qr{car|automobile}}      =  'not a luxury';
	$rehash{qr{car|automobile}}      eq 'not a luxury';      # true
	$rehash{car}                     eq 'not a luxury';      # true
	$rehash{automobile}              eq 'not a luxury';      # true
	$rehash{auto}                    eq 'automatic';         # still true
	$rehash{qr{car|auto|automobile}} eq 'vehicle on wheels'; # still true

	#... and so on. 

	# Dynamic (calculated) values:...

	$hash{\qr{(car|automobile)}} = sub { "$_[1] is a vehicle on wheels" }; 
	$hash{car} eq                          "car is a vehicle on wheels"; # true

	#... if necessary, see Hash Interface section for more details

=head1 DESCRIPTION

Tie::REHash is a tie()d implementation of hash that allows using regexp "keys" along with plain keys.

Storing (assigning value to, deleting) regexp key in a hash tie()d to Tie::REHash is almost equivalent to storing (assigning value to, deleting) set of (plain) keys that regexp matches, called "matching keys". For example:

	$rehash{qr{foo|bar}} = 'baz';  # is almost same as... 
	$rehash{foo}         = 'baz';  # 'foo' is a matching key for qr{foo|bar} regexp key
	$rehash{bar}         = 'baz';  # 'bar' is a matching key for qr{foo|bar} regexp key

Each of matching keys (as well as regexp key that created it) exists(), can be delete()ed, its value can be overwritten.

However, differences between matching keys and plain keys are: 

1. Regexp key and all its matching keys share same value. If we take dictionary view of a hash, then regexp key effectively defines set of synonymous matching keys (alias keys). When value of individual matching key is overwritten, aliasing of that specific key to shared value is discontinued and it gets its own new value (copy-on-write approach).

2. Matching keys set may be infinite, while set of plain keys in the hash is always finite. This dictates different behavior of keys(), values(), each() and list context in case of matching keys: the only way to make, say, keys() return infinite set of matching keys in finite (and very short) time is to make keys() return underlying regexp instead of its matching keys.

To make matters worse, Tie::REHash also supports notion of "dynamic value" (this feature can safely be ignored, unless it is necessary). As a result, Tie::REHash allows, for example, creating hash with infinite sets of key/value pairs.

=head1 Stop reading now (or How to use this documentation).

Usually, there is absolutely no need to read any of the following bulky documentation to use Tie::REHash - you can stop reading at this point. What you have read so far, or even just self-explanatory short SYNOPSIS, is enough in most cases.

The following documentation covers many additional features (e.g. dynamic values, performance tuning, serialization, etc.) that you do NOT need to learn for using Tie::REHash in most usual case (e.g. occasionally). Thus, the following documentation can safely be either ignored or read selectively, skipping most of it. You may read only those sections that concern your usage. This way you can easily avoid learning features that you do not need.

Moreover, initially you may read only code examples, skipping text, and read text only if necessary (as a last resort). This way allows to avoid excessive verbosity of this documentation (unless verbosity is what you need). 

=head1 Terms: "REHash" vs "rehash"

In this documentation name "REHash" is often used as short reference to Tie::REHash class or object, while lowercased "rehash" term is used to refer to hash tie()d to Tie::REHash, to distinguish it from standard hash (however, since rehash behaves almost like standard hash, rehash may also be referred to as simply "hash" in the standard hash context).

=head1 Rehash construction

	use Tie::REHash;
	tie %rehash, 'Tie::REHash';

Alternatively, %rehash can be tie()d to already existing Tie::REHash instance (in this case rest of tie() arguments are ignored) - this way multiple hashes can be tie()d as aliases to same back-end instance of Tie::REHash:

	tie %rehash, 'Tie::REHash';
	tie %rehash2, tied %rehash; # %rehash2 is now alias for %rehash

Newly tie()d hash can be initialized from existing plain hash. For large hashes this way can be much faster than copying hash to rehash: 

	tie %rehash, 'Tie::REHash', \%init_hash; 

The %init_hash is then used internally by rehash, so its state may implicitly change (at a distance) due to %rehash manipulation. Moreover, the %init_hash may itself be a tie()d hash, a rehash, and even the same %rehash:

	# tie %rehash, 'Tie::REHash', \%rehash;      # NOT!

Later is not blocked and will blow up in complex, potentially infinite recursion, so don't (though it can be used for interesting recursion research and smoke experiments).

To avoid these dangerous effects, %init_hash can be copied by passing it as arguments list instead of by reference:

	tie %rehash, 'Tie::REHash', %init_hash; 

This will have same effect as above (except slower), but %init_hash is now copied.

Also, the autodelete_limit() attribute (see autodelete_limit() attribute) can be set upon tie()ing:

	tie %rehash, 'Tie::REHash',  $autodelete_limit;  # or, combining...
	tie %rehash, 'Tie::REHash', \%init_hash, $autodelete_limit; # or...
	tie %rehash, 'Tie::REHash',  %init_hash, $autodelete_limit;

=head1 use Tie::REHash

The default values of attributes (see below) of every new Tie::REHash instance can be changed upon loading Tie::REHash, as follows:

	use Tie::REHash  attribute => $value, attribute2 => $value2;

Attributes that can be set this way are: autodelete_limit, do_cache, do_cache_miss, do_cache_hit, remove_dups.

=head1 Hash Interface

The rehash interface is very similar to that of standard (plain) hash with differences that arise only when you try to use rehash's unique, non-standard features. Even then the differences are quite intuitive. 

In particular, if rehash is used only as standard hash, it behaves exactly like standard hash, except lvalue keys() (and being slower).

In general case, rehash behaves same as standard hash, except for the following:

=head2 Regexp Keys

Storing (assigning value to, deleting) regexp key in rehash effectively stores (assigns value to, deletes) a set of keys that regexp matches - called "matching keys"; matching key, if fetched, returns value of last stored regexp key that matches it:

	$rehash{qr{car|automobile}} =  'vehicle on wheels'; # note qr{}
	$rehash{car}                eq 'vehicle on wheels'; # true
	$rehash{automobile}         eq 'vehicle on wheels'; # true
	$rehash{qr{car|automobile}} eq 'vehicle on wheels'; # true
	exists $rehash{car};                                # true
	exists $rehash{automobile};                         # true
	exists $rehash{qr{car|automobile}};                 # true

Thus, keys of rehash are divided into two main classes: string keys and regexp keys. Since storing regexp key creates corresponding string keys - matching keys, string keys are in turn can be sub-divided into matching keys and plain keys classes. Keys of different classes, however, behave the same way, except matching keys are not returned by keys(), values(), each() and when evaluating hash in list context (see corresponding section below). 

Value of specific matching key created by one regexp key can be overridden by storing later either same plain key or other regexp key that also matches that same key:

	$rehash{  qr{car|automobile}} = 'vehicle on wheels';
	$rehash{    'car'}            = 'not a luxury'; 
	$rehash{    'car'}           eq 'not a luxury';            # true
	$rehash{qr{automobile|truck}} = 'means of transportation'; 
	$rehash{  'automobile'}      eq 'means of transportation'; # true
	# but still...
	exists $rehash{qr{car|automobile}}                         # true
	and    $rehash{qr{car|automobile}} eq 'vehicle on wheels'; # true

Each individual matching key exists() and can be delete()d, but it is not returned by keys() and each() (see below). Later is the difference between matching key and plain key.

Accordingly, in case of rehash each() key returned by keys() exists(), but, unlike in case of standard hash, the reverse is not true - matching key exists(), but is not returned by keys() and each(). (For more details refer to section "keys(), values(), each() and List Context" below.) 

Another difference between matching key and plain key is that regexp key and all its matching keys share (alias for) same value.

If some or even all matching keys of given regexp key have been either delete()d (except delete()ing the very regexp key) or overwritten (see above example), the regexp key still exists(), as well as remaining (not deleted, if any) matching keys of that regexp key still exist and their value can be fetched. However, delete()ing of regexp key removes it and also delete()s all its matching keys (including overwritten ones). For example:

	$rehash{qr{car|automobile}} = 'vehicle on wheels';
	delete $rehash{car};
	delete $rehash{automobile};
	# but still...
	exists $rehash{qr{car|automobile}};                        # true
	and    $rehash{qr{car|automobile}} eq 'vehicle on wheels'; # true

	$rehash{automobile} = 'not a luxury';
	delete  $rehash{qr{car|automobile}};
	!exists $rehash{qr{car|automobile}}; # true, but also...
	!exists $rehash{automobile};         # true

Also note that delete()ing regexp key that do not exist in rehash still has effect - all matching keys of that regexp key get deleted from the hash:

	$rehash{foo}         = 2;
	$rehash{qr{bar|buz}} = 3;
	delete $rehash{qr{foo|bar}}; # deletes 'foo' and 'bar'
	!exists $rehash{foo};        # true
	!exists $rehash{bar};        # true, but 'buz' still remains...
	$rehash{buz} eq 3;           # true

Different qr{} instances of exactly same regexp are interpreted as same regexp key: 

	$rehash{qr{foo|bar}} eq $rehash{qr{foo|bar}}; # always true (identity) 

Regexps that are equivalent in terms of what they match, but written differently, are interpreted as different regexp keys. However, since equivalent regexps create identical sets of matching keys, the value of matching keys will be value of the one of equivalent regexp keys that was stored last: 

	$rehash{qr{car|automobile}} =  'vehicle on wheels';
	$rehash{qr{automobile|car}} =  'not a luxury';
	$rehash{qr{automobile|car}} ne $rehash{qr{car|automobile}}; # true, but...
	$rehash{automobile}         eq 'not a luxury';              # true

=head2 Dynamic Values

Dynamic values feature of rehash can safely be ignored skipping this documentation section entirely, if you do not plan to use it.

Dynamic value of the key is simply reference to subroutine, referred to as "accessor", that is called when key's value is fetched, with corresponding tied() Tie::REHash instance, accessed key, and rest of fetch() arguments (in case fetch() is called explicitly with extra arguments) propagated as arguments to accessor in that order (so that accessor can be seen as method of Tie::REHash instance); the value returned by accessor, referred to as "calculated value", is then returned as key's value. To store accessor for key, "escape" key as follows (see Escaped Keys section):

	$rehash{\qr{(car|truck)}} = sub { 
		my  ($self, $key, @rest_of_fetch_args) = @_;
		return     "$key is a vehicle on wheels" 
	}; 
	$rehash{car} eq "car is a vehicle on wheels";   # true

Both plain and regexp/matching keys may have dynamic values. In contrast to dynamic (calculated) values, plain values are often called "static".

After being stored, accessor is revealed instead of its calculated values only in the following cases: 

1) reference to accessor is returned by values() and each(), together with corresponding key reference (i.e. "escaped" key returned by keys() corresponding to values(), see Escaped Keys); 
2) reference to accessor is fetched using key reference (i.e. "escaped" key - both key and value are same that were stored, see Escaped Keys). 

In all other cases dynamic value is represented by its calculated value and indistinguishable from static value (except calculated value may change). 

	$sub =  sub{ "calculated value" };
	$rehash{\'zoo'} =  $sub;
	$rehash{\'zoo'} eq $sub;               # true
	$rehash{ 'zoo'} eq "calculated value"; # true

	$rehash{\qr{foo|bar}} =  $sub;
	$rehash{\qr{foo|bar}} eq $sub;               # true
	$rehash{  \'foo'}     eq $sub;               # true
	$rehash{ qr{foo|bar}} eq "calculated value"; # true
	$rehash{   'foo'}     eq "calculated value"; # true

	each %rehash; # returns list (\'zoo',       $sub)
	each %rehash; # returns list (\qr{foo|bar}, $sub) 

Since dynamic value of the key gets calculated, it can vary. In particular, if regexp key has dynamic value, the values of different matching keys of that regexp key are not necessarily same. 

Moreover, using regexp key one may not only create infinite set of keys, but also use dynamic value to create corresponding infinite set of different values. For example, the following rehash has an infinite set of key/value pairs:

	$rehash{\qr{.*}} = sub { $_[1] }; 

In case of regexp/matching key, the code of accessor will find $1, $2, etc. being those of regexp match, UNLESS caching is enabled (see Caching section):

	$rehash{\qr{(car|truck)}} = sub {    "$1 is a vehicle on wheels" }; 
	$rehash{    'car'}        eq        "car is a vehicle on wheels";   # true, UNLESS caching is enabled 

If caching is enabled, $1, $2, etc. will be available only upon cache miss, i.e. typically upon first call of accessor, and will not be available upon cache hits. The reason for this is that $1, $2, etc. are available to accessor as a by-product of immediately preceding key matching, but in case of cache hit the matching is not attempted, so providing $1, $2, etc. in case of cache hit would require incurring extra cost that would penalize performance in case accessor do not need them. Thus, if caching is enabled and accessor needs to know $1, $2, etc. of corresponding match, accessor itself should be designed to capture and remember them:

	my %match;
	$rehash{\qr{(car|truck)}} = sub { 
		!exists $match{$_[1]} 
		and     $match{$_[1]} = $1;
		return "$match{$_[1]} is a vehicle on wheels" 
	};

In the above example, if rehash happens to be restored (deserialized) from its image, then cache is also restored, but value of %match lexical may or may not be restored depending on serializer's level of sophistication, so you may need to flush cache to force repopulating of %match, or design accessor a bit differently:

	$rehash{\qr{(car|truck)}} = sub { 
		!exists $_[0]->{my_match}{$_[1]} 
		and     $_[0]->{my_match}{$_[1]} = $1;
		return "$_[0]->{my_match}{$_[1]} is a vehicle on wheels" 
	};

=head2 Escaped Keys

Tie::REHash supports "escaped" key syntax - extra reference applied to either plain key or regexp key. Such escape matters only for storing, fetching, keys(), values(), each() as well as evaluating hash in list context - in all other hash operations escape is ignored as if there is none.

Semantics of assigning to escaped key depends on value assigned. If assigned value is subroutine reference, that subroutine is used as dynamic value accessor (see Dynamic Values section). Assigned value other then subroutine reference is ignored and assignment is equivalent to delete()ing that (dereferenced, unescaped) key, except undef is always returned instead of deleted value - later makes it a cheaper form of delete().

Fetching value of escaped key is equivalent to fetching value of unescaped key, except in case of dynamic value the accessor subroutine reference is returned instead of calculated value.

Thus, the same value assigned to escaped key is fetched using that same escaped key. (This is true for any same key - escaped or not, plain or regexp.)

In addition, keys stored escaped are returned escaped together with corresponding stored values by keys(), values(), each() and list context of the rehash.

In hash operations other than storing, fetching, keys(), values(), each() and list context evaluation, i.e. in case of exists(), delete(), etc., escape of the key is simply ignored as if there is no escape i.e. dereferenced (unescaped) key is always used. 

Examples:

	$sub = sub{ 'calculated value' }; # see also Dynamic Values section
	$rehash{\'zoo'}       =  $sub;
	$rehash{\'zoo'}       eq $sub;               # true
	$rehash{ 'zoo'}       eq 'calculated value'; # true
	$rehash{\qr{foo|bar}} =  $sub;
	$rehash{\qr{foo|bar}} eq $sub;               # true
	$rehash{  \'foo'}     eq $sub;               # true
	$rehash{ qr{foo|bar}} eq 'calculated value'; # true
	$rehash{   'foo'}     eq 'calculated value'; # true
	exists $rehash{ 'zoo'};       # true
	exists $rehash{\'zoo'};       # same
	exists $rehash{ qr{foo|bar}}; # true
	exists $rehash{\qr{foo|bar}}; # same

	keys   %rehash; # returns list (\'zoo',       \qr{foo|bar})
	values %rehash; # returns list ( $sub,        $sub)
	each   %rehash; # returns list (\'zoo',       $sub)
	each   %rehash; # returns list (\qr{foo|bar}, $sub)

	!defined($rehash{\'zoo'}       = 'ignored value'); # true, deleting
	!defined($rehash{\qr{foo|bar}} = 'ignored value'); # true, deleting
	!exists  $rehash{ 'zoo'};                          # true
	!exists  $rehash{\'zoo'};                          # same
	!exists  $rehash{ qr{foo|bar}};                    # true
	!exists  $rehash{\qr{foo|bar}};                    # same

=head2 keys(), values(), each() and List Context

No assumptions should be made about order of elements returned by evaluating %rehash in list context, as well as by keys(), values() and each() except: 1) ordering of keys() list matches ordering of values() list (this is same as for standard hash); and 2) they all return key/value pairs in order necessary to create copy of the %rehash:

	tie %copy, 'Tie::REHash';
	@copy{keys %rehash} = values %rehash; # makes a copy of %rehash
	%copy  =   %rehash;                   # same

Later means that plain keys (!ref $key), regexp keys (ref $key eq 'Regexp') as well as escaped keys (ref $key eq 'SCALAR' or ref $key eq 'REF') and their corresponding values can be returned by keys(), values(), each() as well as by %rehash in list context.

Matching keys are never returned neither by keys(), values(), each() nor evaluating %rehash in list context.

In scalar context keys() and values() return number of elements that each of them would otherwise return in list context (same behavior as in case of standard hash).

Unlike in case of standard hash, pre-extending hash by assigning to keys(%rehash) has no effect. 

Like in case of standard hash, if you add or delete elements of a rehash while you're iterating over it with each(), you may get entries skipped or duplicated, so don't. Exceptions: It is always safe to delete the item most recently returned by each(); also, any regexp key is always safe to delete. In particular, the following code will work:

	while (($key, $value) = each %rehash) {
		print $key, "\n";
		delete $rehash{$key};   # This is safe
	}

If you add/delete regexp key to/from the rehash while iterating over it, the change will not be reflected in currently iterated sequence (only next one).

The value of tied(%rehash)->remove_dupes() attribute controls whether duplicate keys (see remove_dupes() attribute below) can be returned by keys(), each() and evaluating %rehash in a list context. 

In case of rehash with many plain/regexp keys or in tight loops, to increase performance the tied(%rehash)->keys(), tied(%rehash)->values() or tied(%rehash)->list() are better used instead of, respectively, keys(%rehash), values(%rehash) or evaluating %rehash in list context - see "keys(), values() and list() methods" section below.

=head2 Scalar Context

Evaluating rehash in scalar context (as in case of standard hash) returns true if any key exits() in that hash, or false, if hash is empty. Note that hash may have no string keys at all, but have regexp keys, and, thus, be not empty i.e. evaluate true.

If, and only if, regexp and escaped keys were never stored in rehash, evaluating it in scalar contest renders usual used/allocated buckets semantics as in case of standard hash.

If scalar(keys(%rehash)) returns false, then scalar(%rehash) is false too. The reverse, however, is true only if tied(%rehash)->remove_dups() is set true (later is the the default value). This means that by default evaluating %rehash in scalar/boolean context is equivalent to scalar/boolean context of keys(%rehash), but in general case this is not necessarily true. 

=cut

=head1 Performance

Rehash accesses can be many times slower than that of a plain hash, so performance issues may be important.

Simple rules for rehash performance optimization are: if possible, 1) store regexps before plain keys; 2) store slowest regexp keys first, while most often hit regexp keys - last; 3) optimize regexps for performance (but, of course, do not get too obsessed with it - avoid micro-tunning).

There are two classes of hash fetches: hits (key exists) and misses (key does not exist). In general case, misses and matching key hits slow down with every new regexp key added to the hash, and misses are likely to be slowest, since miss means every regexp key of the hash was tried.

Performance of plain key hits usually do not depend on number of regexp keys in the hash (unless number of plain keys is higher than autodelete_limit() - see autodelete_limit() attribute below).

Unlike string keys, fetching regexp keys is always fast (but those are unlikely to be fetched often).

Calling keys(), values(), first call of each() or evaluating rehash in list context all may be relatively costly in case of rehash with large number of plain/regexp keys. In this case or in case of tight loop, the tied(%rehash)->keys(), tied(%rehash)->values() or tied(%rehash)->list() are better used instead of, respectively, keys(%rehash), values(%rehash) or evaluating %rehash in list context, since these methods can be times (5-6 in some benchmarks) faster. See "keys(), values() and list() methods" section below. 

Note also that mere use()/require()ing of Tie::REHash is relatively inexpensive. For comparison, it is about twice as costly as use Carp (faster CPU make this ratio even closer to 1), so that in most cases there is no need to be concerned about use()/require()ing it unnecessarily (like in case of Carp itself), e.g. when rehashes are used conditionally.

=head2 Caching 

Rehash has built-in cache to improve performance of repeated same key hits and misses.

Caching pays off only if repeated fetches of same key happen often enough; otherwise caching just adds (though quite small) overhead without actually using the cache very much. Moreover, caching is useless if rehash has no regexp keys (and the more regexp keys are in the rehash, the more efficiency benefits caching can bring). For that reason, caching is off by default and should be turned on manually only for those rehashes that need it by setting do_cache() attribute true: 

	tied(%rehash)->do_cache(1) 

Alternatively, caching can be turned on by default for all rehashes upon Tie::REHash loading:

	use Tie::REHash do_cache => 1;

The true value of do_cache() attribute can be used not only to turn caching on, but also to specify reference to hash (a true value) to be used as cache. This provides an interesting opportunity to use some tie()d hash for persistent caching, e.g. SDBM_File hash. (Note that turning cache on is idempotent, so it may need to be turned off before different cache hash can be specified.)

If do_cache() attribute is true, additional attributes do_cache_hit() and do_cache_miss() control caching of hits and misses, as follows: 

The approximate rule is: if number of regexp keys in the hash is equal or higher than the value of do_cache_miss() attribute (i.e. the miss is costly enough), the caching of misses is on - repeated same key misses are fast. False do_cache_miss() turns caching of misses off. The default is true do_cache_miss(1).

If do_cache_hit() attribute is set true, string key hits are cached - repeated same key hits are fast. False do_cache_hit() turns caching of hits off. The default is true do_cache_hit(1).

Performance of repeated fetching of dynamic value also improves with caching (same way as that of plain value), but accessor is still called every time, i.e. dynamic value may change upon repeated fetch.

Use of caching may dramatically improve performance of repeated fetches. For example, hash with 100 simple regexp keys may get up to 30 times boost in speed of repeated fetches. Also note that caching do not copy rehash values, so the memory footprint do not escalate as a result of caching.

To empty cache of specific hash, call tied(%rehash)->flush_cache().

=head1 Serialization

The generic rehash serialization/deserialization sequence that works for most serializers is as follows:

	$data = serialize(tied(%rehash)->freeze);
	tie %clone, Tie::REHash->unfreeze(deserialize($data));

where serialize() and deserialize() stand for corresponding routines provided by a serializer module.

In particular, for Data::Dumper:

	use Data::Dumper;
	$data = Data::Dumper::Dumper(tied(%rehash)->freeze);
	tie %clone, Tie::REHash->unfreeze(eval($data));

Direct serialization with Data::Dumper - Data::Dumper::Dumper(\%rehash) or Data::Dumper::Dumper(tied(%rehash)) - will not work.

For Storable:

	use Storable;
	$data = Storable::freeze(tied(%rehash)->freeze);
	tie %clone, Tie::REHash->unfreeze(Storable::thaw($data));

With Storable direct serialization is possible:

	use Storable;
	$data = Storable::freeze(tied(%rehash));
	tie %clone, Storable::thaw($data);

or even:

	use Storable;
	$data = Storable::freeze(\%rehash);
	$clone = Storable::thaw($data);

Only freeze('data') - the default flavor of freezing (see freeze()) - should be used in case of Storable (or nasty things may happen).

NOTE: freeze() do not attempt to handle internal CODE references (including dynamic value accessors, if any) - handling them is entirely up to serializer (Storable and Data::Dumper can serialize coderefs, if properly asked to).

See also documentation for freeze() and unfreeze() methods.

=head1 METHODS

The Tie::REHash object provides new() constructor and lowercase aliases of all hash tie API methods, so that Tie::REHash object can be manipulated via its own OO interface same way as via tie()d hash interface (see perltie for hashes). A number of other methods are also supported.

Tie::REHash object provides the following methods:

=head2 new()

Object instance constructor

	$REHash = Tie::REHash->new()

=head2  keys(), values() and list() methods

In case rehash has large number of plain/regexp keys or in case of tight loops, to increase performance the corresponding Tie::REHash methods are better used instead of keys(), values() or evaluating rehash in list context:

	tied(%rehash)->keys;   # instead of keys(%rehash)
	tied(%rehash)->values; # instead of values(%rehash)
	tied(%rehash)->list;   # instead of @list = %rehash;

These Tie::REHash methods can be times (5-6 in some benchmarks) faster than built-in keys(), values() or evaluating rehash in list context.

If called in scalar context, all these methods return number of elements that they otherwise return in list context.

	$count = tied(%rehash)->keys;
	$count = tied(%rehash)->values;
	$count = tied(%rehash)->list;

However, if called in scalar context with true argument, the return value is reference to array containing elements otherwise returned in list context. This can be used in case of rehash with large number of plain/regexp keys to avoid costs of copying large return lists:

	$array_keys   = tied(%rehash)->keys(  'wantref');
	$array_values = tied(%rehash)->values('wantref');
	$array_list   = tied(%rehash)->list(  'wantref');

=head2 freeze() (alias: storable())

	$data   = tied(%rehash)->freeze();       # same as freeze('data')
	$data   = tied(%rehash)->freeze('data'); # same as freeze()
	$object = tied(%rehash)->freeze('clone');
	$object = tied(%rehash)->freeze('itself');

The freeze() method always returns serializable (frozen) data structure that is a "snapshot" of Tie::REHash object instance that freeze() was called on. The returned snapshot data structure can then be serialized using some serializer. The type of data structure depends on argument, as follows:

'data'   - (default assumed if not argument is specified) unblessed data structure copied from Tie::REHash instance (later is not altered);
'clone'  - blessed copy of Tie::REHash instance (later is not altered);
'itself' - the very Tie::REHash instance that freeze() was called on is converted into serializable, but non-operational (so rehash becomes non-operational!) state and returned.

If no or some other argument is specified, freeze() defaults to 'data' mode. With both 'data' and 'clone' arguments freeze() returns shallow copies that share most of its data with Tie::REHash instance - those data structures should be used as read-only.

See also Serialization section.

=head2 unfreeze() (aliases: restore(), thaw())

	$REHash_obj = Tie::REHash->unfreeze($frozen);
	$REHash_obj->unfreeze();

Calling unfreeze() with serializable data structure (that probably have been serialized and deserialized back) produced by freeze() passed as argument, will return fully operational instance of Tie::REHash object restored from that data structure.

Without argument or with non-reference argument unfreeze() will try to unfreeze the Tie::REHash instance it was called on and will do nothing, if that instance is not frozen, or if called on class.

When unfreeze()ing the unblessed data structure produced by freeze('data'), the resulting instance is by default bless()ed into the class that unfreeze() was called on (already blessed references are never re-blessed). This blessing, however, can be avoided by specifying true second argument. 

	Tie::REHash->unfreeze($frozen, 'do not bless');

See also Serialization section.

=head1 ATTRIBUTES

The Tie::REHash object tied() to rehash supports the following attributes:

=head2 do_cache(), do_cache_hit(), do_cache_miss()

See Caching section above.

=head2 remove_dups()

The value of tied(%rehash)->remove_dupes() attribute controls whether duplicate keys are returned by keys(), values(), each() and %rehash in list context (referred to as "keys(), etc." below). 

Duplicate key is the redundant key/value pair that is identical to that already in the hash. For example, duplicate keys may be returned by keys(), etc. when matching key overrides plain key with same value and vice versa:

	$rehash{   foo}      = 1;
	$rehash{qr{foo|bar}} = 1; # 'foo' already has value 1
	$rehash{   foo}      = 1; # 'foo' already has value 1

False remove_dupes() value means that keys are returned "as is", i.e. duplicates, if any, are returned by keys(), etc.

The remove_dupes(1), or any true value except 2 and 3, means that duplicate keys can be returned only if hash is not empty - no duplicate keys are returned if hash is empty. This is the default.

The remove_dupes(2) value means that duplicate delete (escaped) keys are never returned by keys(), etc.

The remove_dupes(3) value means that duplicate keys are never returned by keys(), etc.

In general, any true value of remove_dupes() means that scalar(%rehash) and scalar(keys %rehash) are boolean equivalents.

=head2 autodelete_limit()

This section can safely be skipped entirely, unless you need to squeeze every bit of performance out of rehashes.

	(tied %rehash)->autodelete_limit($value)
	$value = (tied %rehash)->autodelete_limit;

When regexp key is stored in the rehash, the sort of internal housekeeping operation called "autodeleting" is automatically performed on rehash. Autodeleting may improve performance of plain key hits, but is not at all required for correct rehash operation. On the other hand, if there are many plain keys in the rehash, autodeleting itself becomes costly operation, so that its expected performance benefits for plain keys should be weighted against costs of autodeleting. 

The autodelete_limit() attribute of Tie::REHash object allows to control autodeleting. The autodelete_limit() == 0 - default value - means autodeleting is unlimited, i.e. always performed (equivalent to infinitely large autodelete_limit()). No autodeleting takes place in case autodelete_limit() == 1. Otherwise autodeleting is performed if there are less than autodelete_limit() plain keys at the moment of storing regexp key.

The autodelete_limit() different from default value can be set for all rehashes upon use Tie::REHash, of for specific rehash upon its tie()ing:

	use Tie::REHash autodelete_limit => $autodelete_limit_new_default;
	tie my %rehash, 'Tie::REHash',      $autodelete_limit;
	tied(  %rehash)->autodelete_limit(  $autodelete_limit);

The optimal value of autodelete_limit() is approximated by the number of plain key hits expected to happen after regexp key is assigned. The more plain key hits are expected to happen, the higher optimal autodelete_limit() value is. For optimal performance it may be necessary to adjust autodelete_limit() before storing new regexp key to hash with large number of plain keys.

=head1 Usage and Applications

Since Tie::REHash allows easily defining synonymous (aliased) keys, it is potentially useful for various dictionary and linguistic applications to define synonyms and patterns of word formation (morphology). However, its use for natural language processing is limited by relatively high cost of sequential regexp matching during rehash lookup in case many regexps are stored in rehash, and for natural languages number of regexps may be measured by 10000s. However, use of cache can improve performance, especially if rehash is made persistent using serialization or otherwise (since filling cache is costly, cache should be reused as much as possible).

Tie::REHash is ideal for processing artificial technical mini-languages, like those used in configuration files, etc. In particular, rehash is often used to categorize various file extensions, and a like simple tasks.

Occasional use of rehash competes with using this (or a like) simple routine:

	sub hash {
			my ($key) = @_;
			return 'foo_value' if $key =~ /foo/;
			return 'bar_value' if $key =~ /bar/;
			return undef
	}

or with plain keys and cache:

	my %hash;
	sub hash {
			my (         $key,   $value) = @_;
			return $hash{$key} = $value if @_ > 1;

			return    $hash{$key} 
			if exists $hash{$key};

			return $hash{$key} = 'foo_value' if $key =~ /foo/;
			return $hash{$key} = 'bar_value' if $key =~ /bar/;
			return undef
	}

The advantages of subroutine solution vs. using Tie::REHash are:

1) No extra module dependency
2) Faster to compile (at least if single hash is needed) and execute

The Tie::REHash alternative to above subroutines is:

	use              Tie::REHash do_cache => 1;
	tie my %rehash, 'Tie::REHash';
	%rehash = (
		qr/foo/ => 'foo_value',
		qr/bar/ => 'bar_value',
	);

Advantages of Tie::REHash are:

1) Full-blown standard hash API: exists(), delete(), keys(), etc. (far beyond what simple routine can provide).
2) Allows to freely add/manipulate regexps at run time (i.e. dynamic object vs static subroutine).
3) Ergonomics: No need to remember and type lots of (error prone and boring) same code again and again. 
4) Constructed hash can be serialized, dumped and restored.
5) Scales better in case many rehashes are required.

=head1 BUGS

Due to bug (rt.perl.org ticket 79178) in some perls (not bound to specific versions range), storing/fetching to/from the rehash should avoid escaped literal keys (as well as stringified scalarref keys), like $rehash{\"foo"}, or fatal error will result. The workaround: $key = \"foo"; $rehash{$key} (or in one statement: $rehash{$key = \"foo"}). If your perl is affected, you will see BUG WARNING during module installation. 

Due to incomplete implementation of hash tie()ing in perls prior to v5.8.3, evaluating hash (tie()d to Tie::REHash) in scalar context will not work as expected - use tied(%hash)->scalar instead.

=head1 TODO

Benchmarking of keys(%rehash) vs. tied(%rehash)->keys shows that perltie hash API needs separate KEYS(), VALUES() and LIST() methods to allow tie()d implementation authors to write those methods directly instead of inefficiently emulating them via FIRSTKEY()/NEXTKEY(). Also, lvalue keys(%rehash) should be supported.

=head1 SUPPORT

Send bug reports, patches, ideas, suggestions, feature requests or any module-related information to F<parsels@mail.ru>. They are welcome and each carefully considered.

In particular, if you find certain portions of this documentation either unclear, complicated or incomplete, please let me know, so that I can try to make it better. 

If you have examples of a neat usage of Tie::REHash, drop a line too.

=head1 AUTHOR

Alexandr Kononoff (F<parsels@mail.ru>)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Alexandr Kononoff (F<parsels@mail.ru>). All rights reserved.

This program is free software; you can use, redistribute and/or modify it either under the same terms as Perl itself or, at your discretion, under following Simplified (2-clause) BSD License terms:

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

