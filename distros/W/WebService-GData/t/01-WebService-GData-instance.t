use Test::More tests => 7;
use WebService::GData;

my $gdata = new WebService::GData(firstname=>'doe',lastname=>'john');

ok(ref($gdata) eq 'WebService::GData','$gdata is a WebService::GData instance.');
ok($gdata->{firstname} eq 'doe','$gdata->{firstname} is properly set.');
ok($gdata->{lastname} eq 'john','$gdata->{lastname} is properly set.');
ok($gdata->equal($gdata),'$gdata equal return true for the same object.');
ok($gdata==$gdata,'$gdata == return true for the same object.');
ok(!($gdata==new WebService::GData(firstname=>'doe',lastname=>'john')),'$gdata == return true for the same object.');

$gdata->trying(5)->trying2(1,2,3)->trying3(bonjour=>'hi',aurevoir=>'good bye');

ok($gdata->trying2->[2]==3,'$gdata __set methods register the data as an array reference if several parameters are passed');
