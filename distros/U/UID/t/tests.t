#!perl -T

#################################################################################################################################################################
#
#	TESTS for UID.pm
#
#################################################################################################################################################################

	use strict; use warnings; use Carp;
	use Test::More 'no_plan';
	use utf8; #because of our «,»

#—————————————————————————————————————————————————————————————————————————————————————————————
#hm, "is_deeply" actually seems to compare just the overloaded representation, so make our own
sub deeper($$;$)	{	return Test::More->builder->ok( deepcomp(@_), $_[2]);	}	# same?
sub deepless($$;$)	{	return Test::More->builder->ok(!deepcomp(@_), $_[2]);	}	# different?

#Hey, shouldn't these be functions in UID.pm, perhaps??  =)
sub deepcomp($$)
# compare actual structure to see whether two UIDs are the same
# Note that we are depending on knowing how UIDs work inside to check this!
{
	my $tb=Test::More->builder;		# to get an "OK" object
	my ($foo, $bar)=@_;
	return ref $foo eq ref $bar unless ref $foo eq "UID" and ref $bar eq "UID";	
		#unless both are UIDs, merely compare the ref-types
	
	my @foo, my @bar;
	eval { @foo=@$foo; @bar=@$bar; };	                    	# UIDs should really be array-refs
	my $same=overload::StrVal($foo) eq overload::StrVal($bar);	# compare the refs' memory addresses
	croak "ERROR!  fake UID: $@" if $@=~/Can't use.*as ARRAY/	# if we can't de-array-ref them, they're not real UIDs!
									or @foo!=2 or @bar!=2    	# 	...or if they don't both have exactly 2 elements each
									or $same != ($foo[1] eq $bar[1]);	#...or if the refs are the same and the full-names aren't, or vice versa
	return $same;
}

#—————————————————————————————————————————————————————————————————————————————————————————————
	
BEGIN { use_ok "UID" }

	diag( "Testing UID $UID::VERSION, Perl $], $^X" );


# Basic testing

	BEGIN { use_ok "UID", 'foo'; }				# define a UID
		
	is foo, "«foo»", "Name";					# evaluates as string, so gets the name from foo
	ok foo."" eq "«foo»", "Name again";	 		# force foo-as-string since "eq" is overloaded
	is ${+foo}, "«main::foo»", "Full name";		# deref to get full name
	isa_ok foo(), "UID", "Class";
	is foo->[1], "main::foo", "Array deref";
	is foo()?"Y":"N", "Y", "Bool context";
	
	ok foo == foo, "Self-identity (==)";		#hm, won't work with cmp_ok, "==" -- will numify first
	ok foo eq foo, "Self-identity (eq)";
	deeper foo, foo, "Deep identity";
	
	isn't foo, "foo", "Non-identity";			# again, compares string-overloaded value
	ok foo ne "foo", "Non-identity too";
	ok foo ne "«foo»", "Non-identity still";
	
	my $f=foo;
	is $f, foo, "Copy";
	is $f, "«foo»", "Copy's name";
	ok $f==foo, "Copy's identity";
	is ref $f, "UID", "Class ref";
	
	
	BEGIN { use_ok "UID", BAR=>BAZ=>QUX=>; }	# define some more
	deeper BAR, BAR, "Deep identity, bar none";
	deepless foo, BAR, "Deep misidentity";
	
	is BAR, "«BAR»", "String name";
	is BAR, BAR, "String-val identity";
	isn't foo, BAR, "Different UIDs";			# meh, as strings!
	isn't BAR, BAZ, "Other different UIDs";		# meh, as strings!
	ok BAR eq BAR,  "Matching UIDs";
	ok foo ne BAR,  "Different UIDs";
	cmp_ok BAR, ne=> BAZ,  "Other different UIDs";
	ok QUX==QUX, "Other other match";
	ok foo!=QUX, "Other other difference";
	
#	#hm, test for errors?
#	use UID foo;		# Can't create a UID called &foo!
#	use UID "foo";		# can't redefine existing foo()
	
		

package Other;		# Repeat intro stuff for new namespace:
	use strict; use warnings;
	use Test::More;	# no plan because we already specified one in this file
	use utf8; #because of our «,»

	BEGIN { use_ok "UID", 'foo'; }			# new foo in new namespace
	is ${foo()}, "«Other::foo»", "Other package name";
	is foo, main::foo(), "Compare package names";
	main::deepless foo, main::foo(), "Compare package objects";
	
	
	
# Test contexts
	my $either; 	#use this to save the results, then test them -- otherwise "is" itself will impose list-context all the time!
	sub either { $either=wantarray?"LIST":"SCALAR" }	# reacts differently in list vs scalar context	
	
	        either;    			is $either, "SCALAR", "Plain scalar";
	(undef)=either;     		is $either,  "LIST",  "Plain list";
	
	        foo, either;   			is $either, "SCALAR", "comma-scalar";
	(undef)=foo  either;      		is $either,  "LIST",  "call-list";
	       (foo, scalar either);	is $either, "SCALAR", "Explicit scalar";
	(undef)=foo  scalar either;  	is $either, "SCALAR", "Explicit scalar too";
	(undef)=foo (either); 			is $either,  "LIST",  "Explicit list";
	
	
	#also with prototypes($)
	sub one($) {@_}		# forces a single scalar arg
		#use []'s and then is_deeply to compare multiple values together
	is_deeply [one foo],     [foo],     '$-prototype alone';
	is_deeply [one foo, 42], [foo, 42], '$-prototype w/comma';
#test for error:	is_deeply [one foo 42], <ERROR!>, '$-prototype w/arg';
	
	
# Test that passing args through a UID doesn't inadvertently evaluate them
	use overload fallback=>1; use overload q(""), sub {$_->[0]++};
	my $o=bless \my $x;		# an object that increments everytime we evaluate it (as a string, anyway)
	
	is $o, 0, "Incrementer";
	is $o, 1, "Incremented";
	(undef)=foo(foo $o, $o); 	# run it though «foo»
	is $o, 2, "Passed through";
	
	
__END__	
