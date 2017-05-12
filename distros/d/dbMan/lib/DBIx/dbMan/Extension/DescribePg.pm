package DBIx::dbMan::Extension::DescribePg;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.03';

1;

sub IDENTIFICATION { return "000001-000033-000003"; }

sub preference { return 50; }

sub known_actions { return [ qw/DESCRIBE/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'DESCRIBE' and $obj->{-dbi}->driver eq 'Pg' and not $action{oper}) {
		$action{action} = 'NONE';
		unless ($obj->{-dbi}->current) {
			$obj->{-interface}->error("No current connection selected.");
			return %action;
		}	

		my $table = new Text::FormatTable '| r | l | l | r | l | l | l | l |';
		$table->rule;
		$table->head('ORDER','COLUMN','TYPE','SIZE','ALIGN','BY VAL','NULLABLE','DEFAULT');
		$table->rule;
		my $d = $obj->{-dbi}->selectall_arrayref(
			q!SELECT a.attnum, a.attname, t.typname, a.attlen, a.attalign, 
			         a.attbyval, a.attnotnull, a.atthasdef 
		          FROM pg_class c, pg_attribute a, pg_type t 
			  WHERE c.relname = ? AND a.attnum > 0 AND
				a.attrelid = c.oid AND a.atttypid = t.oid
    			  ORDER BY attnum!,{},$action{what});
		if (defined $d and @$d) {
			for (@$d) { $table->row($_->[0],$_->[1],$_->[2],
				($_->[3]>0)?$_->[3]:'',$_->[4],$_->[5]?'yes':'no',
				$_->[6]?'no':'yes',$_->[7]?'yes':'no'); }
		} else {
			$obj->{-interface}->error("Table $action{what} not found.");
			return %action;
		}
		$table->rule;
		$action{action} = 'OUTPUT';
		$action{output} = $table->render($obj->{-interface}->render_size);
	}

	$action{processed} = 1;
	return %action;
}
