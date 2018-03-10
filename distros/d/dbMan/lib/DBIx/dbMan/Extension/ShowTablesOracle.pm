package DBIx::dbMan::Extension::ShowTablesOracle;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;
use Term::ANSIColor;

our $VERSION = '0.08';

1;

sub IDENTIFICATION { return "000001-000039-000008"; }

sub preference { return 50; }

sub known_actions { return [ qw/SHOW_TABLES/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'SHOW_TABLES' and $obj->{-dbi}->driver eq 'Oracle') {
        my $colorized = $obj->{-mempool}->get('output_format') eq 'colortable';
		my $table = new Text::FormatTable '| l | l |';
		$table->rule;
		$table->head( map { $colorized ? color( $obj->{-config}->tablecolor_head || 'bright_yellow' ) . $_ . color( $obj->{-config}->tablecolor_lines || 'reset' ) : $_; } 'NAME','TYPE');
		$table->rule;

		my $sth = $obj->{-dbi}->table_info( { TABLE_SCHEM => uc($obj->{-dbi}->login) } );
		if (defined $sth) {
			my $ret = $sth->fetchall_arrayref();
			study $action{mask};
			eval {
				if (defined $ret) {
					for (sort { $a->[2] cmp $b->[2] } @$ret) {
						if (($action{type} eq 'object'
						  or $action{type} eq lc $_->[3]) and
						  $action{mask} and $_->[2] =~ /$action{mask}/i) {
							$table->row(map { $colorized ? color( $obj->{-config}->tablecolor_content || 'bright_white' ) . $_ . color( $obj->{-config}->tablecolor_lines || 'reset' ) : $_; } $_->[2],$_->[3]);
						}
					}
				}
			};
			$sth->finish;
			$table->rule;
            if ( $@ ) {
                $obj->{ -interface }->error( "Invalid regular expression." );
            }
			$action{output} = $@ ? '' : ( $colorized ? color( $obj->{-config}->tablecolor_lines || 'reset' ) : '' ) . $table->render($obj->{-interface}->render_size) . ( $colorized ? color( 'reset' ) : '' );
		} else {
			$action{output} = '';
            $obj->{ -interface }->error( "Interrupted." ); 
		}
		$action{action} = 'OUTPUT';
	}

	$action{processed} = 1;
	return %action;
}
