package DBIx::dbMan::Extension::SQLOutputPlain;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.07';

1;

sub IDENTIFICATION { return "000001-000027-000007"; }

sub preference { return 0; }

sub known_actions { return [ qw/SQL_OUTPUT/ ]; }

sub init {
	my $obj = shift;
	$obj->{-mempool}->register('output_format','plain');
}
 
sub done {
	my $obj = shift;
	$obj->{-mempool}->deregister('output_format','plain');
	if ($obj->{-mempool}->get('output_format') eq 'plain') {
		my @all_formats = $obj->{-mempool}->get_register('output_format');
		$obj->{-mempool}->set('output_format',$all_formats[0]) if @all_formats;
	}
}
	
sub handle_action {
	my ($obj,%action) = @_;

	$action{processed} = 1;
	if ($action{action} eq 'SQL_OUTPUT') {
		if ($obj->{-mempool}->get('output_format') eq 'plain') {
			my $output = join ',',@{$action{fieldnames}};
			$output .= "\n";
			my @litp = ();  my @lits = ();
                        for (@{$action{fieldtypes}}) {
				my %th = %{$obj->{-dbi}->type_info($_)};
				push @litp,$th{LITERAL_PREFIX}||'';
				push @lits,$th{LITERAL_SUFFIX}||'';
			}
			for (@{$action{result}}) {
				my @lp = @litp;  my @ls = @lits;
				$output .= join ',',map { my $lm = shift @lp;  my $rm = shift @ls;  defined($_)?"$lm$_$rm":"NULL" } @$_;
				$output .= "\n";
			}
			$action{action} = 'OUTPUT';
			$action{output} = $output;
			delete $action{processed};
		}
	}

	return %action;
}
