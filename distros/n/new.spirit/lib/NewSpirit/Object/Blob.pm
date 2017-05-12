# $Id: Blob.pm,v 1.2 2002/04/08 12:17:35 joern Exp $

package NewSpirit::Object::Blob;

$VERSION = "0.01";
@ISA = qw( NewSpirit::Object::Generic );

use strict;
use Carp;
use NewSpirit::Object::Generic;
use NewSpirit;
use FileHandle;

sub get_install_filename {
	my $self = shift;
	
	my $meta = $self->get_meta_data;
	my $install_dir = $meta->{install_target_dir};
	return if not $install_dir;

	my $path = "$self->{project_prod_dir}/$install_dir/$self->{project}/$self->{object}";
	$path =~ s!/+!/!g;
	
	return $path;
}

sub install_dependant_objects {
	my $self = shift;
	
	if ( $self->{event} =~ /proper|restore/ ) {
		# dependenc installation only if properties are saved
		# (maybe installation target has changed => URL changes too)
		return $self->SUPER::install_dependant_objects;
	}
	
	# otherwise no dependency installation necessary
	print "No dependency installation necessary<p>\n"
		if not $self->{dependency_installation};
	
	1;
}

sub edit_ctrl {
	my $self = shift;

	$self->editor_header ('edit');

	my $no_file_uploaded = " <b>(Currently empty. Please upload a file)</b>"
		if -s $self->{object_file} == 0;

	print <<__HTML;
<p>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr>
  <td>
    $CFG::FONT
    Filename: <b>$self->{object_basename}</b>$no_file_uploaded
    <p>
    This file type is handled through the new.spirit Blob handler.
    </font>
  </td>
</tr>
</table>
</td></tr></table>
<p>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr><td valign="center">
  $CFG::FONT
  <b>Blob File Upload</b>
  </FONT>
</td><td>
  $CFG::FONT
  <input type=file name=cipp_file_upload size=60>
  </FONT>
</td></tr>
</table>
</td></tr></table>

__HTML

	$self->editor_footer;
}

1;
