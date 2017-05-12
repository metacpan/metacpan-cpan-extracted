package DBIx::dbMan::Extension::SQLHelp;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000059-000003"; }

sub preference { return 0; }

sub known_actions { return [ qw/HELP/ ]; }

sub init {
	my $obj = shift;

	$obj->{help_texts} = <<EOF;
***select
Command: select
Description: retrieve tuples
Syntax:
select [distinct on <attr>] <expr1> [as <attr1>], ... <exprN> [as <attrN>]
	[into [table] <class_name>]
	[from <from_list>]
	[where <qual>]
	[group by <group_list>]
	[having <having_clause>]
	[order by <attr1> [ASC | DESC] [using <op1>], ... <attrN> ]
	[union [all] select ...]
***insert
Command: insert
Description: insert tuples
Syntax:
insert into <class_name> [(<attr1>...<attrN>)]
	values (<expr1>...<exprN>); |
        select [distinct]
        <expr1>,...<exprN>
        [from <from_clause>]
        [where <qual>]
        [group by <group_list>]
        [having <having_clause>]
        [union [all] select ...]
***delete
Command: delete
Description: delete tuples
Syntax:
delete from <class_name> [where <qual>]
***update
Command: update
Description: update tuples
Syntax:
update <class_name> set <attr1>=<expr1>,...<attrN>=<exprN> [from <from_clause>]
	[where <qual>]
***create
create function
create index
create sequence
create table
create trigger
create view
***create table
Command: create table
Description: create a new table
Syntax:
create table <class_name>
        (<attr1> <type1> [default <expression>] [not null] [,...])
	[inherits (<class_name1>,...<class_nameN>)
	[[constraint <name>] check <condition> [,...] ]
***create view
Command: create view
Description: create a view
Syntax:
create view <view_name> as
	select
        <expr1>[as <attr1>][,... <exprN>[as <attrN>]]
        [from <from_list>]
        [where <qual>]
        [group by <group_list>]
***alter table
Command: alter table
Description: add/rename attributes, rename tables
Syntax:
        alter table <class_name> [*] add column <attr> <type>;
        alter table <class_name> [*] rename [column] <attr1> to <attr2>;
        alter table <class_name1> rename to <class_name2>
***create function
Command: create function
Description: create a user-defined function
Syntax:
create function <function_name> ([<type1>,...<typeN>]) returns <return_type>
	as '<object_filename>'|'<sql-queries>'
        language 'c'|'sql'|'internal'
***create sequence
Command: create sequence
Description: create a new sequence number generator
Syntax:
create sequence <sequence_name>
        [increment <NUMBER>]
        [start <NUMBER>]
        [minvalue <NUMBER>]
        [maxvalue <NUMBER>]
        [cache <NUMBER>]
        [cycle]
***create trigger
Command: create trigger
Description: create a new trigger
Syntax:
create trigger <trigger_name> after|before event1 [or event2 [or event3] ]
        on <class_name> for each row|statement
        execute procedure <func_name> ([arguments])
		
        eventX is one of INSERT, DELETE, UPDATE
***drop
drop function
drop index
drop sequence
drop table
drop trigger
drop view
***drop function
Command: drop function
Description: remove a user-defined function
Syntax:
drop function <funcname> ([<type1>,....<typeN>])
***drop index
Command: drop index
Description: remove an existing index
Syntax:
drop index <indexname>
***drop sequence
Command: drop sequence
Description: remove a sequence number generator
Syntax:
drop sequence <sequence_name>[,...<sequence_nameN]
***drop table
Command: drop table
Description: remove a table
Syntax:
drop table <class_name>[,...<class_nameN]
***drop trigger
Command: drop trigger
Description: remove a trigger
Syntax:
drop trigger <trigger_name> on <class_name>
***drop view
Command: drop view
Description: remove a view
Syntax:
drop view <view_name>
***create index
Command: create index
Description: construct an index
Syntax:
create [unique] index <indexname> on <class_name> [using <access_method>]
	( <attr1> [<type_class1>] [,...] | 
	  <funcname>(<attr1>,...) [<type_class>] )
***grant
Command: grant
Description: grant access control to a user or group
Syntax:
grant <privilege[,privilege,...]> on <rel1>[,...<reln>] to 
	[public | group <group> | <username>]
privilege is {ALL | SELECT | INSERT | UPDATE | DELETE | RULE}
***revoke
Command: revoke
Description: revoke access control from a user or group
Syntax:
revoke <privilege[,privilege,...]> on <rel1>[,...<reln>] from 
	[public | group <group> | <username>]
privilege is {ALL | SELECT | INSERT | UPDATE | DELETE | RULE}
***fetch
Command: fetch
Description: retrieve tuples from a cursor
Syntax:
fetch [forward|backward] [<number>|all] [in <cursorname>]
***lock
Command: lock
Description: exclusive lock a table inside a transaction
Syntax:
lock [table] <class_name>
***move
Command: move
Description: move an cursor position
Syntax:
move [forward|backward] [<number>|all] [in <cursorname>]
***vacuum
Command: vacuum
Description: vacuum the database, i.e. cleans out deleted records, updates statistics
Syntax:
vacuum [verbose] [analyze] [table]
        or
vacuum [verbose]  analyze  [table [(attr1, ... attrN)]]
***declare
Command: declare
Description: set up a cursor
Syntax:
declare <cursorname> [binary] cursor for
        select [distinct]
        <expr1> [as <attr1>],...<exprN> [as <attrN>]
        [from <from_list>]
        [where <qual>]
        [group by <group_list>]
        [having <having_clause>]
        [order by <attr1> [using <op1>],... <attrN> [using <opN>]]
        [union [all] select ...]
EOF
	my $now = '';
	my %line = ();
	for (split /\n/,$obj->{help_texts}) {
		if (/^\*\*\*(.*)/) { $now = $1;  next; }
		next unless $now;
		s/\s+$//;
		$line{$now} .= $_."\n";
	}
	$obj->{lines} = \%line;
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'HELP') {
		if ($action{type} eq 'sql') {
			my $out = '';
			for (sort keys %{$obj->{lines}}) { 
				$out .= $obj->{lines}->{$_} if /^\Q$action{what}/;
			}
			$action{action} = 'OUTPUT';
			$action{output} = $out;
		}
	}

	$action{processed} = 1;
	return %action;
}

sub cmdcomplete {
	my ($obj,$text,$line,$start) = @_;
	return sort keys %{$obj->{lines}} if $line =~ /^\s*\\h\s+[A-Z]*$/i;
	return ();
	# tady by to chtelo zlepsit - ty vracene klice jsou i vice retezcove a museji se vracet prubezne znovu
}
