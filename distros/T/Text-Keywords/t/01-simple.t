use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::Text::Keywords::Standard;

Test::Text::Keywords::Standard->new(
	name => 'Simple',
	setup => [{
		lists => [
			['Perl','YAPC::(\w\w) (\d\d\d\d)|YAPC'],
			['Linux','Microsoft','Par'],
		],
	},{
		lists => [
			['London','Ice'],
			['Beer','Peter Parker'],
		],
	}],
	tests => [
		[
			'Perl YAPC Linux London Ice Beer Par',
			'YAPC YAPC::EU 2010 YAPC::EU 2009',

			'Perl','Perl',[],1,0,0,0,
			'Linux','Linux',[],1,0,0,1,
			'YAPC','YAPC::(\w\w) (\d\d\d\d)|YAPC',[undef,undef],1,0,0,0,
			'YAPC::EU 2010','YAPC::(\w\w) (\d\d\d\d)|YAPC',['EU','2010'],0,1,0,0,
			'YAPC::EU 2009','YAPC::(\w\w) (\d\d\d\d)|YAPC',['EU','2009'],0,1,0,0,
			'Par','Par',[],1,0,0,1,
			'London','London',[],1,0,1,0,
			'Beer','Beer',[],1,0,1,1,
			'Ice','Ice',[],1,0,1,0,
		],[
			'Peter Parker uses Perl on London at YAPC::EU 2010',
			'Lalala More Beer on Ice',

			'Perl','Perl',[],1,0,0,0,
			'YAPC::EU 2010','YAPC::(\w\w) (\d\d\d\d)|YAPC',['EU','2010'],1,0,0,0,
			'London','London',[],1,0,1,0,
			'Beer','Beer',[],0,1,1,1,
			'Ice','Ice',[],0,1,1,0,
			'Peter Parker','Peter Parker',[],1,0,1,1,
		],[
			'Peter# #Parker !uses% %__Perl# (((on(( ()London #at #YAPC::EU 2010',
			'Lalala!! ""More____Beer# !"!"§on ###Ice',

			'Perl','Perl',[],1,0,0,0,
			'YAPC::EU 2010','YAPC::(\w\w) (\d\d\d\d)|YAPC',['EU','2010'],1,0,0,0,
			'London','London',[],1,0,1,0,
			'Beer','Beer',[],0,1,1,1,
			'Ice','Ice',[],0,1,1,0,
			'Peter Parker','Peter Parker',[],1,0,1,1,
		],[
			'Perl Perl Perl Perl Perl',
			'Lalala More Beer!!!',

			'Perl','Perl',[],1,0,0,0,
			'Beer','Beer',[],0,1,1,1,
		],
	],
);

done_testing;
