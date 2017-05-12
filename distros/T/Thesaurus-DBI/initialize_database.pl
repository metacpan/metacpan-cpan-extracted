#!/usr/bin/perl
# small script to fill database
# input file: text, all synonyms on one line, speperated by ;

use lib '../lib';
use Thesaurus::DBI;

# parameters
my ($filename, $dbname, $dbuser, $dbpassword, $dbhost) = @ARGV;
if (!$filename || !-f $filename || !$dbname || !$dbuser || !$dbpassword) {
	die "usage: $0 filename dbname dbuser dbpassword dbhost";
}
$dbhost ||= 'localhost';

# create thesaurus object -> connect to db
my $th = new Thesaurus::DBI(dbhost=> $dbhost, dbname=>$dbname,dbuser=>$dbuser,dbpassword=>$dbpassword);

# create database
$th->create_tables();

# fill database
open (FILE, $filename) || die "file $filename not found";

while (my $line = <FILE>) {
	next if ($line =~ /^#/);
	$line =~ s/[\r\n]//g;
	
	my @words = split(';', $line);
	$th->add(\@words);
}

close(FILE);


