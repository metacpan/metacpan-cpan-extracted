#!/usr/bin/perl -w
use strict;
use Tie::Locked ':all';
use Test;
BEGIN { plan tests => 41 };

# debugging tools
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# test tied hash
#
do {
	my (%hash, $dummy);
	
	# tie hash
	tie %hash, 'Tie::Locked::Tied', x=>1;
	
	eval { print $hash{'y'} };
	ok ($@);
	
	eval { $hash{'y'} = 'yyyyy' };
	ok ($@);
	
	eval { $dummy = $hash{'x'} };
	ok (! $@);
	
	eval { $hash{'x'} = 'yyyyy' };
	ok ($@);
};
#
# test tied hash
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# test hashref
#
do {
	my $ref = locked_hashref('x'=>1);
	my ($dummy);
	
	eval { print $ref->{'y'} };
	ok ($@);
	
	eval { $ref->{'y'} = 'yyyyy' };
	ok ($@);
	
	eval { $dummy = $ref->{'x'} };
	ok (! $@);
	
	eval { $ref->{'x'} = 'yyyyy' };
	ok ($@);
	
	eval { if (exists $ref->{'x'}) {} };
	ok (! $@);
	
	eval { if (exists $ref->{'y'}) {} };
	ok (! $@);
};
#
# test hashref
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# test unlock: hashref
#
do {
	my $ref = locked_hashref('x'=>1);
	my ($dummy);
	
	# test unlocked
	$ref->unlock;
	$ref->{'x'} = 'yyyyy';
	$ref->{'z'} = 'yyyyy';
	
	# relock
	$ref->lock;
	
	eval { print $ref->{'y'} };
	ok ($@);
	
	eval { $ref->{'y'} = 'yyyyy' };
	ok($@);
	
	eval { $dummy = $ref->{'x'} };
	ok(! $@);
	
	eval { $ref->{'x'} = 'yyyyy' };
	ok($@);
};
#
# test unlock: hashref
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# test unlocked_hashref
#
do {
	my ($ref, $dummy);
	$ref = unlocked_hashref('x'=>1);
	
	ok (! $ref->locked());
	ok ($ref->unlocked());
	
	eval { $dummy = defined $ref->{'y'} };
	ok (! $@);
	
	eval { $ref->{'y'} = 'yyyyy' };
	ok (! $@);
	
	eval { $dummy = $ref->{'x'} };
	ok(! $@);
	
	eval { $ref->{'x'} = 'yyyyy' };
	ok (! $@);
	
	$ref->lock();
	
	eval { print $ref->{'z'} };
	ok ($@);
	
	eval { $ref->{'y'} = 'yyyyy' };
	ok($@);
	
	eval { $dummy = $ref->{'x'} };
	ok(! $@);
	
	eval { $ref->{'x'} = 'yyyyy' };
	ok($@);
};
#
# test unlocked_hashref
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# test locker
#
do {
	my ($ref);
	$ref = locked_hashref('x'=>1);
	
	ok($ref->locked());
	ok (! $ref->unlocked());
	
	do {
		my $locker = $ref->autolocker();
		ok (! $ref->locked());
		ok ($ref->unlocked());
	};
	
	ok ($ref->locked());
	ok (! $ref->unlocked());
};
#
# test locker
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# unlock_fields
#
do {
	my ($ref, @fields);
	$ref = locked_hashref('page_pk'=>1, 'pc_pk'=>'article');
	
	# unlock fields
	$ref->unlock_fields(qw{title body});
	
	# attempt to set non-existent field
	eval { $ref->{'x'} = 10 };
	ok ($@);
	
	# attempt to set existent but locked field
	eval { $ref->{'page_pk'} = 10 };
	ok ($@);
	
	# attempt to read existent and unlocked field
	eval { my $var = $ref->{'title'} };
	ok (! $@);
	
	# attempt to set existent and unlocked field
	eval { $ref->{'title'} = 10 };
	ok (! $@);
	
	# attempt to delete existent and unlocked field
	eval { delete $ref->{'title'} };
	ok (! $@);
	
	# unlocked_fields
	@fields = $ref->unlocked_fields();
	@fields = sort(@fields);
	ok(@fields == 2);
	ok($fields[0] eq 'body');
	ok($fields[1] eq 'title');
	
	# lock_fields
	$ref->lock_fields('body');
	@fields = $ref->unlocked_fields();
	@fields = sort(@fields);
	ok(@fields == 1);
	ok($fields[0] eq 'title');
	
	# lock_all_fields
	$ref->lock_all_fields();
	@fields = $ref->unlocked_fields();
	ok(@fields == 0);
};
#
# unlock_fields
#------------------------------------------------------------------------------
