package DBIx::dbMan::Extension::SQLOutputTable;

use strict;
use base 'DBIx::dbMan::Extension';
use utf8;
use Text::FormatTable;
use Term::ANSIColor;

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000026-000005"; }

sub preference { return -25; }

sub known_actions { return [ qw/SQL_OUTPUT/ ]; }

sub init {
	my $obj = shift;
	$obj->{-mempool}->register('output_format','table');
	$obj->{-mempool}->register('output_format','colortable');
	$obj->{-mempool}->set('output_format',$obj->{-config}->output_format || 'table') unless $obj->{-mempool}->get('output_format');
}

sub done {
	my $obj = shift;
	$obj->{-mempool}->deregister('output_format','table');
	$obj->{-mempool}->deregister('output_format','colortable');

    if ( $obj->{-mempool}->get('output_format') =~ /^(color)?table$/ ) {
        my @all_formats = $obj->{-mempool}->get_register('output_format');
        $obj->{-mempool}->set('output_format',scalar @all_formats ? $all_formats[0] : '');
    }
}
	
sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_OUTPUT') {	# table is standard fallback
        my $colorized = $obj->{-mempool}->get('output_format') eq 'colortable';

		# $action{fieldtypes} - formatting ?
		my $table = new Text::FormatTable ('|'.( 'l|' x scalar @{$action{fieldnames}} ));
		$table->rule;
		$table->head( map { $colorized ? color( $obj->{-config}->tablecolor_head || 'bright_yellow' ) . $_ . color( $obj->{-config}->tablecolor_lines || 'reset' ) : $_; } @{$action{fieldnames}} );
		$table->rule;
        use Data::Dumper;
		for (@{$action{result}}) {
			$table->row( map {
                my $r = $_;
                $r =~ s/(\S+)/color( $obj->{-config}->tablecolor_content || 'bright_white' ) . $1 . color( $obj->{-config}->tablecolor_lines || 'reset' )/seg if $colorized;
                $r; 
            } @$_ );
		}
		$table->rule;
		$action{action} = 'OUTPUT';
		$action{output} = ( $colorized ? color( $obj->{-config}->tablecolor_lines || 'reset' ) : '' ) 
            . $table->render( $obj->{-interface}->render_size ) . ( $colorized ? color( 'reset' ) : '' );
		delete $action{processed};
	}

	return %action;
}
