use strict;
use FileHandle;
use Carp 'confess';

# debugging
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;


#------------------------------------------------------------------------------
# comp
#
sub comp {
	my ($test_name, $is, $shouldbe) = @_;
	
	# TESTING
	# println subname(); ##i
	# showvar $is;
	# showvar $shouldbe;
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	if(! equndef($is, $shouldbe)) {
		if ($ENV{'IDOCSDEV'}) {
			print STDERR 
				"\n",
				"\tis:         ", (defined($is) ?       $is       : '[undef]'), "\n",
				"\tshould be : ", (defined($shouldbe) ? $shouldbe : '[undef]'), "\n\n";
		}
		
		rtok("(rt) $test_name: values do not match", 0);
		return 0;
	}
	
	else {
		rtok("(rt) $test_name: values match", 1);
		return 1;
	}
}
#
# comp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# slurp
#
sub slurp {
	my ($path) = @_;
	my $in = FileHandle->new($path);
	$in or die $!;
	return join('', <$in>);
}
#
# slurp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# arr_comp
#
sub arr_comp {
	my ($alpha_sent, $beta_sent, $test_name, %opts) = @_;
	my (@alpha, @beta);
	
	# TESTING
	# println subname(); ##i
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# both must be array references
	unless (
		UNIVERSAL::isa($alpha_sent, 'ARRAY') &&
		UNIVERSAL::isa($beta_sent, 'ARRAY')
		)
		{ die 'both params must be array references' }
	
	# if they have different lengths, they're different
	if (@$alpha_sent != @$beta_sent)
		{ rtok("(rt) $test_name", 0) }
	
	# get arrays to use for comparison
	@alpha = @$alpha_sent;
	@beta = @$beta_sent;
	
	# if order insensitive
	if ($opts{'order_insensitive'}) {
		@alpha = sort @alpha;
		@beta = sort @beta;
	}
	
	# if case insensitive
	if ($opts{'case_insensitive'}) {
		grep {$_ = lc($_)} @alpha;
		grep {$_ = lc($_)} @beta;
	}
	
	# loop through array elements
	for (my $i=0; $i<=$#alpha; $i++) { ##i
		# if one is undef but other isn't
		if (
			( (  defined $alpha[$i]) && (! defined $beta[$i]) ) ||
			( (! defined $alpha[$i]) && (  defined $beta[$i]) )
			) {
			rtok("(rt) $test_name", 0);
		}
		
		# if $alpha[$i] is undef then both must be, so they're the same
		elsif (! defined $alpha[$i]) {
		}
		
		# both are defined
		else {
			unless ($alpha[$i] eq $beta[$i])
				{ rtok("(rt) $test_name", 0) }
		}
	}
	
	# if we get this far, they're the same
	rtok("(rt) $test_name", 1);
}
#
# arr_comp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# file_exists
#
sub file_exists {
	my ($test_name, $path, $should) = @_;
	my ($e);
	
	# TESTING
	# println subname(); ##i
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# test if the file exists
	$e = -e($path);
	
	# if not should, reverse sense of test
	if (! $should)
		{ $e = ! $e }
	
	rtok("(rt) $test_name", $e);
}
#
# file_exists
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# equndef
#
sub equndef {
	my ($str1, $str2) = @_;
	
	# if both defined
	if ( defined($str1) && defined($str2) )
		{return $str1 eq $str2}
	
	# if neither are defined 
	if ( (! defined($str1)) && (! defined($str2)) )
		{return 1}
	
	# only one is defined, so return false
	return 0;
}
#
# equndef
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# stringify_tokens
#
sub stringify_tokens {
	my (@orgs) = @_;
	my (@rv);
	
	# loop through original tokens and build array of string versions
	foreach my $org (@orgs) {
		if (UNIVERSAL::isa $org, 'JSON::Relaxed::Parser::Token::String') {
			push @rv, $org->{'raw'};
		}
		else {
			push @rv, $org;
		}
	}
	
	# return new array
	return @rv;
}
#
# stringify_tokens
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# key_count
#
sub key_count {
	my ($hash, $count, $test_name) = @_;
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	unless (scalar(keys %$hash) == $count) {
		rtok(
			"(rt) $test_name",
			0,
			
			'hash should have ' .
			$count . ' ' .
			'element' .
			( ($count == 1) ? '' : 's' ) . ' ' .
			'but actually has ' .
			scalar(keys %$hash),
		);
	}
	
	rtok("(rt) $test_name", 1);
}
#
# key_count
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# bool_check
#
sub bool_check {
	my ($test_name, $is_got, $should_got) = @_;
	my ($is_norm, $should_norm);
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# normalize boolean values
	$is_norm = $is_got ? 1 : 0;
	$should_norm = $should_got ? 1 : 0;
	
	if ($is_norm ne $should_norm) {
		print STDERR 
			"\n",
			"\tis:         ", (defined($is_got)     ? $is_got     : '[undef]'), "\n",
			"\tshould be : ", (defined($should_got) ? $should_got : '[undef]'), "\n\n";
		rtok("(rt) $test_name", 0);
		
		# return false
		return 0;
	}
	
	# ok
	rtok("(rt) $test_name", 1);
	
	# return true
	return 1;
}
#
# bool_check
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# el_count
#
sub el_count {
	my ($arr, $count, $test_name) = @_;
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	unless (scalar(@$arr) == $count) {
		rtok(
			"(rt) $test_name",
			0,
			
			'array should have ' .
			$count . ' ' .
			'element' .
			( ($count == 1) ? '' : 's' ) . ' ' .
			'but actually has ' .
			scalar(@$arr),
		);
	}
	
	rtok("(rt) $test_name", 1);
}
#
# el_count
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# compact
#
sub compact {
	my ($val) = @_;
	
	if (defined $val) {
		$val =~ s|^\s+||s;
		$val =~ s|\s+$||s;
		$val =~ s|\s+| |sg;
	}
	
	# return
	return $val;
}
#
# compact
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# error_id_check
#
sub error_id_check {
	my ($test_name, $is, $should) = @_;
	
	# TESTING
	# println subname(); ##i
	# showvar $is;
	# showvar $should;
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# get id of $is
	if (defined $is)
		{ $is =~ s|\:.*||s }
	
	# get id of $should or set it to empty string
	if (defined $should)
		{ $should =~ s|\:.*||s }
	else
		{ $should = '' }
	
	# compare
	comp($test_name, $is, $should);
}
#
# error_id_check
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# randstring
#
sub randstring {
	my ($rv, $count, @chars);
	$rv = '';
	$count = 5;
	
	# set of characters to choose from
	# Only using alphas because numbers often cause problems as names for
	# various objects like database tables.
	@chars = ('a' .. 'z', 'A' .. 'Z');
	
	while (length($rv) < $count) {
		my $char = rand();
		$char = int( $char * ($#chars + 1) );
		$char = $chars[$char];
		$rv .= $char;
	}
	
	# return
	return $rv;
}
#
# randstring
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# taint
#
sub taint {
	my ($val) = @_;
	
	# add tainted empty string to value
	if (defined $val) {
		my $tainted = <*>;
		$tainted =~ s|.*||g;
		$val .= $tainted;
	}
	
	# return
	return $val;
}
#
# taint
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# rtok
#
sub rtok {
	my ($test_name, $ok) = @_;
	ok($ok, $test_name);
}
#
# rtok
#------------------------------------------------------------------------------


# return true
1;
