package DBIx::dbMan::Extension::SQLOutputCube;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::FormatTable;

our $VERSION = '0.02';

1;

sub IDENTIFICATION { return "000001-000082-000002"; }

sub preference { return 0; }

sub known_actions { return [ qw/SQL_OUTPUT/ ]; }

sub init {
	my $obj = shift;
	$obj->{-mempool}->register('output_format','cube');
}

sub done {
	my $obj = shift;
	$obj->{-mempool}->deregister('output_format','cube');
	if ($obj->{-mempool}->get('output_format') eq 'cube') {
		my @all_formats = $obj->{-mempool}->get_register('output_format');
		$obj->{-mempool}->set('output_format',$all_formats[0]) if @all_formats;
	}
}
	
sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_OUTPUT') {	# table is standard fallback
                if ($obj->{-mempool}->get('output_format') eq 'cube') {
			my %cube = ();
			my %fields = ();
			for (@{$action{result}}) {
				my $x = ($_->[0] eq 'NULL') ? chr(255).'total' : $_->[0]; 
				my $y = ($_->[1] eq 'NULL') ? chr(255).'total' : $_->[1]; 
				my $value = $_->[2] || 0;
				++$fields{$x};
				$cube{$y}->{$x} = $value;
			}

			$action{result} = [];
			for my $y (sort keys %cube) {
				my @temporary = ($y eq chr(255).'total' ? 'Total' : $y);
				for my $x (sort keys %fields) {
					push @temporary,($cube{$y}->{$x} || 0);
				}
				push @{$action{result}},\@temporary;
			}
			$action{fieldnames} = [ 'y\x', map { $_ eq chr(255).'total' ? 'Total' : $_ } sort keys %fields ] ;

			# $action{fieldtypes} - formatting ?
			my $table = new Text::FormatTable ('|'.( 'l|' x scalar @{$action{fieldnames}} ));
			$table->rule;
			$table->head(@{$action{fieldnames}});
			$table->rule;
			for (@{$action{result}}) {
				$table->row(@$_);
			}
			$table->rule;
			$action{action} = 'OUTPUT';
			$action{output} = $table->render($obj->{-interface}->render_size);
			delete $action{processed};
		}
	}

	return %action;
}
