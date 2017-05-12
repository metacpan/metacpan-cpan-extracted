#!/usr/bin/perl
use WWW::Sucksub::Vostfree;
my $motif=shift;
my $foo=WWW::Sucksub::Vostfree->new(
				html =>'/home/timo/vostfree.html',
				logout=>'/home/timo/logvostfree.txt',
				dbfile=>'/home/timo/dbfilevostfree.db',
				debug=>1,
				tmpfile_vost=>'/home/timo/tmpfilevost.html',
				cookies_file=>'/home/timo/.cookies_vostfree',
				motif=>$motif,
				);
$foo->search(); ## see /home/timo/vostfree.html
$foo->searchdbm();## see /home/timo/vostfree.html
