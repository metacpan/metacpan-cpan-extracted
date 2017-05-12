package Text::Placeholder::Appliance::SQL::Retrieval_n_Display;

use strict;
use warnings;
use Carp qw();
use parent qw(
	Object::By::Array);
use Text::Placeholder;

sub THIS() { 0 }

sub ATR_P1() { 0 }
sub ATR_RESULT() { 1 }
sub ATR_P2() { 2 }
sub ATR_GENERIC() { 3 }
sub ATR_STATEMENT() { 4 }

sub _init {
	my $this = shift;

	$this->[ATR_P1] = Text::Placeholder->new(
		$this->[ATR_RESULT] = '::SQL::Result');
	$this->[ATR_RESULT]->placeholder_re('^fld_(\w+)$');

	$this->[ATR_P2] = Text::Placeholder->new(
		$this->[ATR_GENERIC] = '::Generic',
		$this->[ATR_STATEMENT] = '::SQL::Statement');
	$this->[ATR_STATEMENT]->placeholder_re('^cond_(\w+)$');
	$this->[ATR_GENERIC]->add_placeholder('field_list',
		sub { return(join(', ', @{$this->[ATR_RESULT]->fields})) });

	return;
}

sub P_HTML() { 1 }
sub html_parameter {
	$_[THIS][ATR_P1]->compile($_[P_HTML]);
	return;
}

sub P_SQL() { 1 }
sub sql_parameter {
	my ($this) = @_;

	$this->[ATR_P2]->compile($_[P_SQL]);
	return($this->[ATR_P2]->execute,
		$this->[ATR_STATEMENT]->fields);
}

sub format {
	my ($this, $rows) = @_;

	foreach my $row (@$rows) {
		$this->[ATR_RESULT]->subject($row);
		$row = ${$this->[ATR_P1]->execute};
	}
	return;
}

1;
