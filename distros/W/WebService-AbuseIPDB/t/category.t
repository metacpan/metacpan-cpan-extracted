#
#===============================================================================
#
#         FILE: category.t
#
#  DESCRIPTION: Test of categories
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 16/08/19 17:21:24
#===============================================================================

use strict;
use warnings;

use Test::More tests => 3 + 23 * 11;

use WebService::AbuseIPDB::Category;
use WebService::AbuseIPDB::Response;

for my $cid (1 .. 23) {
	my @cat = WebService::AbuseIPDB::Category->new ($cid);
	ok ($cat[0], "Category for id $cid defined");
	isa_ok ($cat[0], 'WebService::AbuseIPDB::Category', 'Class matches');
	is ($cat[0]->id, $cid, "Returned id is $cid");
	ok ($cat[0]->name, "Name is true");
	push @cat, WebService::AbuseIPDB::Category->new ($cat[0]->name);
	ok ($cat[1], 'Category for same name defined');
	isa_ok ($cat[1], 'WebService::AbuseIPDB::Category', 'Class matches');
	is ($cat[1]->id,   $cid,          "Returned id is $cid");
	is ($cat[1]->name, $cat[0]->name, "Name is the same");
	isnt ($cat[1], $cat[0], 'Different object');
	push @cat, WebService::AbuseIPDB::Category->new ($cat[0]);
	ok ($cat[2], 'Category for same object defined');
	is ($cat[2], $cat[0], 'Same object');
}

my $cat = WebService::AbuseIPDB::Category->new ();
is ($cat, undef, 'Undef cat returns undef');
$cat = WebService::AbuseIPDB::Category->new ('Not a cat');
is ($cat, undef, 'Unrecognised cat returns undef');
$cat = WebService::AbuseIPDB::Category->new
	(WebService::AbuseIPDB::Response->new);
is ($cat, undef, 'Arg of wrong class returns undef');
