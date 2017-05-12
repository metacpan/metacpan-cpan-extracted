#!/usr/bin/perl
use v5.14;
use warnings;

use Cwd qw/getcwd/;
use File::Find;
use File::Spec::Functions qw/abs2rel/;
use Zeal::Docset;

sub mkindex {
	my ($root) = @_;
	my $oldwd = getcwd;
	unlink "$root/Contents/Resources/docSet.dsidx";

	my $ds = Zeal::Docset->new($root);
	$ds->dbh->do('CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)');
	$ds->dbh->do('CREATE UNIQUE INDEX anchor on searchIndex (name, type, path)');

	chdir "$root/Contents/Resources/Documents";

	find +{
		no_chdir => 1,
		wanted => sub {
			return unless -f;
			my ($name) = m/(\w+)\.html/;
			my $path = abs2rel $_;
			say STDERR "Adding document $name at $path";
			$ds->dbh->do('INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, \'Word\', ?)', {}, $name, $path);
		}
	}, '.';
	chdir $oldwd;
}

mkindex $_ for <ds/*>
