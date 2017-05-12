#!/usr/local/bin/perl
#
#	@(#)dbtext.pl	1.3	10/17/95
#
# Example code showing the Sybperl usage of dbwritetext().
#
#       create table text_table (t_index int, the_text text)
#

use Sybase::DBlib;

### Add appropriate passwords...
#
$d = Sybase::DBlib->dblogin;
$d2 = Sybase::DBlib->dbopen;

### I've got this test database that I use...
$d->dbuse('mp_test');
$d2->dbuse('mp_test');

$d->sql ('delete from text_table');
$d->sql ('insert into text_table (t_index, the_text) values (5,"")');


$d->dbcmd('select the_text, t_index from text_table where t_index = 5');
$d->dbsqlexec;                         # execute sql

$d->dbresults;
@data = $d->dbnextrow;

$d2->dbwritetext ("text_table.the_text", $d, 1, "This is text which was added with Sybperl");

$d->sql('select t_index, the_text from text_table where t_index = 5',
	sub { print @_, "\n";});

$d->dbclose;
