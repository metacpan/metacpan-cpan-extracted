package DBIx::dbMan::Extension::StandardSQL;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.13';

1;

sub IDENTIFICATION { return "000001-000014-000013"; }

sub preference { return 100; }

sub known_actions { return [ qw/SQL/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL') {
		if ($action{oper} eq 'complete') {
			$action{action} = 'CACHE';
			$action{type} = 'object' if lc $action{type} eq 'context';
			$action{cache_type} = 'sql_type_' . lc( $action{type} );

			if ($action{what} eq 'list') {
				# return in {list} list of {type}
				my $sth = $obj->{-dbi}->table_info();
				my $ret = $sth->fetchall_arrayref();
				my @all = ();
				if (defined $ret) {
					for (@$ret) {
						push @all,$_->[2] if lc $action{type} eq 'object' || lc $action{type} eq lc $_->[3];
					}
				}
				$sth->finish;
				$action{list} = \@all;
			}
		} elsif ($action{type} eq 'select' or $action{type} eq 'do') {
			$action{action} = 'NONE';
			unless ($obj->{-dbi}->current) {
				$obj->{-interface}->error("No current connection selected.");
				return %action;
			}
			
			my $explain_id = $$;
			if ($action{explain} and not $action{explain_2phase}) {
				$action{sql_save} = $action{sql};
				$action{sql} = qq!DELETE FROM plan_table WHERE statement_id = '$explain_id'!;
				$action{explain_2phase} = 1;
			} else {
				$action{sql} =~ s/explain\s+plan\s+for/explain plan set statement_id = '$explain_id' for/i;
				delete $action{explain_2phase};
			}

			$obj->{-interface}->status("Executing SQL...") unless $action{output_quiet};
			my $lr = $obj->{-dbi}->longreadlen();
			$obj->{-dbi}->longreadlen($action{longreadlen}) if $action{longreadlen};
			my $sth = $obj->{-dbi}->prepare($action{sql});
			if (exists $action{placeholders}) {
				my $i = 0;
				$sth->bind_param(++$i,$_) for @{$action{placeholders}};
			}
			unless (defined $sth) {
				$action{action} = 'OUTPUT';
				$action{output} = $obj->{-dbi}->errstr()."\n";
				$action{processed} = 1;
				$obj->{-dbi}->longreadlen($lr) if $action{longreadlen};
				$obj->{-interface}->nostatus unless $action{output_quiet};
				return %action;
			}
			my $res = $sth->execute();
			$obj->{-dbi}->longreadlen($lr) if $action{longreadlen};
			if (not defined $res) {
				my $errstr = $obj->{-dbi}->errstr();
				$errstr =~ s/^ERROR:\s*//;
				$obj->{-interface}->error($errstr);
			} else {
				if ($action{type} eq 'select' and not $action{explain}) {
					$action{fieldnames} = $sth->{NAME_uc};
					eval {
						$action{fieldtypes} = $sth->{TYPE};
					};
					if ($@) {
						$action{fieldtypes} = [ map { -9998 } @{$action{fieldnames}} ];
					}
					$res = $sth->fetchall_arrayref();
				}
				if ($action{explain}) {
					$action{action} = 'SQL';
					if ($action{explain_2phase}) {
						$action{sql} = $action{sql_save};
						$sth->finish;
						delete $action{processed};
						$obj->{-interface}->nostatus unless $action{output_quiet};
						return %action;
					}
					my $local_mempool = $obj->{-dbi}->mempool();
					if ( $local_mempool && $local_mempool->get( 'oracle_special_xplan' ) ) {
						$action{sql} = q!SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('plan_table',!.$explain_id.'))';
					} else {
						$action{sql} = q!SELECT '.' || LPAD(' ',2*LEVEL-1) || operation || ' ' || options || ' ' || object_name "Execution Plan" FROM plan_table WHERE statement_id = '!.$explain_id.q!' CONNECT BY PRIOR id = parent_id AND statement_id = '!.$explain_id.q!' START WITH id = 0 AND statement_id = '!.$explain_id.q!'!;
					}
					delete $action{explain};
				} else {
					$action{action} = 'SQL_RESULT';
					$action{result} = $res;
				}
			}
			$sth->finish;
			$obj->{-interface}->nostatus unless $action{output_quiet};
			$obj->{-dbi}->discard_profile_data;
			delete $action{processed};
		}
	}

	return %action;
}
