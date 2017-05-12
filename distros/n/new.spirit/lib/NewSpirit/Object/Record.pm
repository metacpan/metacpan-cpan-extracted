# $Id: Record.pm,v 1.6 2000/07/12 15:03:09 joern Exp $

package NewSpirit::Object::Record;

$VERSION = "0.01";
@ISA = qw( NewSpirit::Object );

use strict;
use Carp;
use NewSpirit::Object;
use NewSpirit::Param1x;
use NewSpirit::DataFile;
use FileHandle;
use Carp;

sub get_data {
	my $self = shift;
	
	my $df = new NewSpirit::DataFile ($self->{object_file});
	my $data = $df->read;
	$df = undef;

	return $data;	
}

sub edit_ctrl {
	my $self = shift;

	$self->editor_header ('edit');

	print <<__HTML;
<table $CFG::BG_TABLE_OPTS width="100%"><tr><td>
<table $CFG::TABLE_OPTS width="100%">
__HTML

	my $data = $self->get_data;

	my $field_order      = $self->{record_field_order};
	my $field_definition = $self->{record_field_definition};
	
	foreach my $key ( @{$field_order} ) {
		$self->input_widget (
			name      => $key,
			info_href => $field_definition->{$key},
			data_href => $data
		);
	}

	print <<__HTML;
</table>
</td></tr></table>
__HTML
	$self->editor_footer;
}

sub view_ctrl {
	my $self = shift;

	$self->view_header;

	print <<__HTML;
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
__HTML

	my $df = new NewSpirit::DataFile ($self->{object_file});
	my $data = $df->read;
	$df = undef;

	my $field_order      = $self->{record_field_order};
	my $field_definition = $self->{record_field_definition};
	
	foreach my $key ( @{$field_order} ) {
		$self->input_widget (
			read_only => 1,
			name      => $key,
			info_href => $field_definition->{$key},
			data_href => $data
		);
	}

	print <<__HTML;
</table>
</td></tr></table>
__HTML
	$self->view_footer;
}

sub save_file {
	my $self = shift;
	
	my $q = $self->{q};
	
	# build the data hash
	my $field_order      = $self->{record_field_order};
	my %data;
	foreach my $key ( @{$field_order} ) {
		$data{$key} = $q->param($key);
		$data{$key} =~ s/\r//g;
	}

	# store the hash
	my $df = new NewSpirit::DataFile ($self->{object_file});
	$df->write ( \%data );
	$df = undef;
	
	return 0;	# no project file browser update needed
}


1;
