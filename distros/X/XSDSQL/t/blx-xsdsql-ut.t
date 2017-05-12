#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 14;
BEGIN { use_ok 'blx::xsdsql::version'};
BEGIN { use_ok 'XML::Parser','1.21' };
BEGIN { use_ok 'XML::Writer','0.600' };
BEGIN { use_ok 'DBI','1.58' };
BEGIN { use_ok 'DBD::DBM','0.06' };
BEGIN { use_ok 'MLDBM','2.05' };
BEGIN { use_ok 'SQL::Statement','1.33' };
BEGIN { use_ok 'Carp::Assert','0.20' }
BEGIN { use_ok 'Attribute::Constant','0.06' }
BEGIN { use_ok 'Filter::Include','1.6' }
BEGIN { use_ok 'Modern::Perl','1.20121103' }
BEGIN { system('which xmllint > /dev/null'); my $rc=$?;  print STDERR "xmllint not found in PATH\n"  if $rc; ok($rc == 0);  };
BEGIN { system('which xmldiff > /dev/null'); my $rc=$?;  print STDERR "xmldiff not found in PATH\n"  if $rc; ok($rc == 0);  };
BEGIN {
	use File::Spec;
	my $dir=undef;
	for my $startdir( File::Spec->curdir,$ENV{TMP},File::Spec->tmpdir()) {
		next unless defined $startdir;
		$dir=File::Spec->catdir($startdir,'tmp');
		mkdir($dir);
		if (-d $dir) {
			my $tmpfile=File::Spec->catfile($dir,$$);
			if (open(my $fd,'>',$tmpfile)) {
				close $fd;
				unlink $tmpfile;
			}
			else {
				$dir=undef;
			}
		}
		else { 
			$dir=undef;
		}
		last if defined $dir;
	}

	die "cannot determine tmp directory" unless defined $dir;
	$dir = File::Spec->rel2abs($dir);
	print STDERR "use temporary directory '$dir'\n";
    chdir('t') || die "cannot change directory 't' $!";
 	$ENV{DB_CONNECT_STRING}="sql::DBM:dbm_mldbm=Storable;RaiseError => 1,f_dir=> '$dir'";
	my $perl=$ENV{PERL} // 'perl';
	system($perl.' ./test.pl'); 
	ok($? == 0)
};
