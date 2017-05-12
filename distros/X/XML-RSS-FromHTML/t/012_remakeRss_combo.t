use Test::More tests => 55;
use strict;
use FindBin;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}

# 1 new item
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01',     link => 'http://link/01.html' },
		{ title => 'new link 02', link => 'http://link/02.html' },
		{ title => 'link 03',     link => 'http://link/03.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	# without maxItemCount
	{
		my $expect = [
			{ title => 'new link 02', link => 'http://link/02.html' },
			{ title => 'oldrss 01', link => 'http://oldrss/01.html' },
			{ title => 'oldrss 02', link => 'http://oldrss/02.html' },
			{ title => 'oldrss 03', link => 'http://oldrss/03.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,1);
		is(scalar @{$new->{items}},4);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
	# with maxItemCount
	{
		my $expect = [
			{ title => 'new link 02', link => 'http://link/02.html' },
			{ title => 'oldrss 01', link => 'http://oldrss/01.html' },
		];
		$rss->maxItemCount(2);
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,1);
		is(scalar @{$new->{items}},2);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# some new item
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01',     link => 'http://link/01.html' },
		{ title => 'new link 02', link => 'http://link/02.html' },
		{ title => 'new link 03', link => 'http://link/03.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'new link 02', link => 'http://link/02.html' },
			{ title => 'new link 03', link => 'http://link/03.html' },
			{ title => 'oldrss 01', link => 'http://oldrss/01.html' },
			{ title => 'oldrss 02', link => 'http://oldrss/02.html' },
			{ title => 'oldrss 03', link => 'http://oldrss/03.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,2);
		is(scalar @{$new->{items}},5);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# no new item
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'oldrss 01', link => 'http://oldrss/01.html' },
			{ title => 'oldrss 02', link => 'http://oldrss/02.html' },
			{ title => 'oldrss 03', link => 'http://oldrss/03.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,0);
		is(scalar @{$new->{items}},3);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# 1 updated item
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01',       link => 'http://link/01.html' },
		{ title => 'oldrss 02 upd', link => 'http://oldrss/02.html' },
		{ title => 'link 03',       link => 'http://link/03.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'oldrss 02 upd', link => 'http://oldrss/02.html' },
			{ title => 'oldrss 01',     link => 'http://oldrss/01.html' },
			{ title => 'oldrss 03',     link => 'http://oldrss/03.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,1);
		is(scalar @{$new->{items}},3);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# 2 updated item
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01',       link => 'http://link/01.html' },
		{ title => 'oldrss 02 upd', link => 'http://oldrss/02.html' },
		{ title => 'oldrss 03 upd', link => 'http://oldrss/03.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'oldrss 02 upd', link => 'http://oldrss/02.html' },
			{ title => 'oldrss 03 upd', link => 'http://oldrss/03.html' },
			{ title => 'oldrss 01',     link => 'http://oldrss/01.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,2);
		is(scalar @{$new->{items}},3);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# 2 update + 1 new item
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01',       link => 'http://link/01.html' },
		{ title => 'oldrss 02 upd', link => 'http://oldrss/02.html' },
		{ title => 'oldrss 03 upd', link => 'http://oldrss/03.html' },
		{ title => 'link 04',       link => 'http://link/04.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'oldrss 02 upd', link => 'http://oldrss/02.html' },
			{ title => 'oldrss 03 upd', link => 'http://oldrss/03.html' },
			{ title => 'link 04',       link => 'http://link/04.html' },
			{ title => 'oldrss 01',     link => 'http://oldrss/01.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,3);
		is(scalar @{$new->{items}},4);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# irregular pattern - will delete old rss item correctly
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 99', link => 'http://link/99.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'link 01', link => 'http://link/01.html');
	$old_rss->add_item(title => 'link 02', link => 'http://link/02.html');
	$old_rss->add_item(title => 'link 99', link => 'http://link/99.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'link 99', link => 'http://link/99.html' },
			{ title => 'link 01', link => 'http://link/01.html' },
			{ title => 'link 02', link => 'http://link/02.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,1);
		is(scalar @{$new->{items}},3);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
	# with maxItemCount
	{
		my $expect = [
			{ title => 'link 99', link => 'http://link/99.html' },
			{ title => 'link 01', link => 'http://link/01.html' },
		];
		$rss->maxItemCount(2);
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,1);
		is(scalar @{$new->{items}},2);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# different link url is counted as new item
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02xxxx.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'link 02', link => 'http://link/02xxxx.html' },
			{ title => 'oldrss 01', link => 'http://oldrss/01.html' },
			{ title => 'oldrss 02', link => 'http://oldrss/02.html' },
			{ title => 'oldrss 03', link => 'http://oldrss/03.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,1);
		is(scalar @{$new->{items}},4);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# different link url is counted as new item - against old rss
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02xxxx.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_list = [
		{ title => 'link 01', link => 'http://link/01.html' },
		{ title => 'link 02', link => 'http://link/02.html' },
		{ title => 'link 03', link => 'http://link/03.html' },
	];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'link 01', link => 'http://link/01.html');
	$old_rss->add_item(title => 'link 02', link => 'http://link/02.html');
	$old_rss->add_item(title => 'link 03', link => 'http://link/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my $expect = [
			{ title => 'link 02', link => 'http://link/02xxxx.html' },
			{ title => 'link 01', link => 'http://link/01.html' },
			{ title => 'link 02', link => 'http://link/02.html' },
			{ title => 'link 03', link => 'http://link/03.html' },
		];
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,1);
		is(scalar @{$new->{items}},4);
		is_deeply( deleteUnwantedKeys($new->{items}) ,$expect);
		unlink $rss->_getFeedFilePath;
	}
}

# adding more than 30 items
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [];
	for my $i (1 .. 28){
		push(@{ $list },{
			title => "newitem$i", link => "http://link/$i"
		});
	}
	my $old_list = [];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,28);
		is(scalar @{$new->{items}},30);
		is($new->{items}[0]{title},'newitem1');
		is($new->{items}[29]{title},'oldrss 02');
		unlink $rss->_getFeedFilePath;
	}
}

# setting maxItemCount to undef + adding 100 items
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [];
	for my $i (1 .. 100){
		push(@{ $list },{
			title => "newitem$i", link => "http://link/$i"
		});
	}
	my $old_list = [];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		$rss->maxItemCount(undef);
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,100);
		is(scalar @{$new->{items}},103);
		is($new->{items}[0]{title},'newitem1');
		is($new->{items}[29]{title},'newitem30');
		unlink $rss->_getFeedFilePath;
	}
}

# setting maxItemCount to 0 + adding 100 items
{
	my $rss = XML::RSS::FromHTML::Test->new;
	my $list = [];
	for my $i (1 .. 100){
		push(@{ $list },{
			title => "newitem$i", link => "http://link/$i"
		});
	}
	my $old_list = [];
	my $old_rss = XML::RSS->new;
	$old_rss->add_item(title => 'oldrss 01', link => 'http://oldrss/01.html');
	$old_rss->add_item(title => 'oldrss 02', link => 'http://oldrss/02.html');
	$old_rss->add_item(title => 'oldrss 03', link => 'http://oldrss/03.html');
	is(scalar @{ $old_rss->{items} },3);
	{
		$rss->maxItemCount(0);
		my ($new,$cnt) = $rss->remakeRSS($list,$old_list,$old_rss);
		is($cnt,0);
		is(scalar @{$new->{items}},0);
		unlink $rss->_getFeedFilePath;
	}
}



sub deleteUnwantedKeys {
	my $tgt = shift;
	my $new = [];
	foreach my $itr (@{$tgt}){
		push(@{$new},{
			title => $itr->{title},
			link  => $itr->{link},
		});
	}
	return $new;
}