use strict;
use warnings;

use Test::More;
use Test::Deep;

my $token = $ENV{TOKEN};
plan skip_all => 'Works only if API token provided in he TOKEN environment variable'
	if not $token;

plan tests => 4;

use WWW::SmartSheet;
my $w = WWW::SmartSheet->new( token => $token );
isa_ok($w, 'WWW::SmartSheet');

my $sheet_name = 'test_' . int(rand(10000)) . '_' . time;
my $s = $w->create_sheet(
    name    => $sheet_name,
	columns =>  [
        { title => "First Col",  type => 'TEXT_NUMBER', primary => JSON::true },
    	{ title => "Second Col", type => 'CONTACT_LIST' },
        { title => 'Third Col',  type => 'TEXT_NUMBER' },
        { title => "Fourth Col", type => 'CHECKBOX', symbol => 'FLAG' },
        { title => 'Status',     type => 'PICKLIST', options => ['Started', 'Finished' , 'Delivered'] }
	],
);


#isa_ok($s, 'WWW::SmartSheet::Sheet';
#diag explain $s;
diag "id: $s->{result}{id}";
my $sheet = $w->get_sheet_by_id($s->{result}{id});
isa_ok($sheet, 'WWW::SmartSheet::Sheet');
cmp_deeply($sheet, bless({
	accessLevel => 'OWNER',
	columns     => ignore(),
	id          => re('\d{10}'),
	name        => $sheet_name,
	permalink   => re('^https://app.smartsheet.com/b/home\?lx=[\w-]+$'),
}, 'WWW::SmartSheet::Sheet'), 'sheet');

#my $c = $w->add_column($s->{result}{id}, { title => 'Delivered', type => 'DATE', index => 5 });

#diag explain $c;

#$w->insert_rows($s->{result}{id},

cmp_deeply($w->delete_sheet($s->{result}{id}),
	{
		'message' => 'SUCCESS',
		'resultCode' => 0
	});





