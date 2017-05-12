# $Id: Generic.pm,v 1.1 2001/07/24 15:35:26 joern Exp $

package NewSpirit::Object::Generic;

$VERSION = "0.01";
@ISA = qw( NewSpirit::CIPP::Prep );

use strict;
use Carp;
use NewSpirit::CIPP::Prep;
use NewSpirit;
use FileHandle;

sub get_install_filename {
	my $self = shift;
	
	my $meta = $self->get_meta_data;
	my $install_dir = $meta->{install_target_dir};
	return if not $install_dir;

	my $path = "$self->{project_prod_dir}/$install_dir/$self->{project}/$self->{object_rel_dir}/$meta->{_original_filename}";
	$path =~ s!/+!/!g;
	
	return $path;
}

sub edit_ctrl {
	my $self = shift;

	$self->editor_header ('edit');

	my $properties = $self->get_meta_data;
	my $orig_filename = $properties->{_original_filename} ||
			    '&lt;currently no file uploaded&gt;';
	print <<__HTML;
<p>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr>
  <td>
    $CFG::FONT
    This is an object with an unknown file type. The original filename is:<br>
    <b>$orig_filename</b>
    </font>
  </td>
</tr>
</table>
</td></tr></table>
__HTML

	if ( $properties->{show_as_text} and -s $self->{object_file} ) {
		print <<__HTML;
<p>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr>
  <td>
__HTML
		$self->print_escaped;
		print <<__HTML;
</td>
</tr>
</table>
</td></tr></table>
__HTML
	} elsif ( $properties->{_original_filename} ) {
		print <<__HTML;
<p>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr>
  <td>
    $CFG::FONT
    If the content of the file is viewable as text in your browser you<br>
    can switch on displaying it here in the <b>PROPERTIES</b> dialog.<br>
    Also you can decide, where this file should be installed.
    <p>
    Anyway you can download the file using the object name link in the<br>
    head of this page.
    </font>
  </td>
</tr>
</table>
</td></tr></table>
__HTML
	}

	print <<__HTML;
<p>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr><td valign="center">
  $CFG::FONT
  <b>Generic File Upload</b>
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

sub save_file {
	my $self = shift;

	my $q = $self->{q};
	my $image_fh = $q->param('cipp_file_upload');
	return if not $image_fh;

	# save the uploaded file to the object file

	my $object_file = $self->{object_file};

	binmode $image_fh;
	
	my $fh = new FileHandle;
	open ($fh, "> $object_file")
		or croak "can't write $object_file";
	binmode $fh;
	
	while (<$image_fh>) {
		print $fh $_;
	}
	
	close $image_fh;
	close $fh;

	# now save the original filename into the meta data hash
	my $meta_data = $self->get_meta_data;
	$meta_data->{_original_filename} = "$image_fh";
	$self->save_meta_data ($meta_data);

	return;

	# check if the extension of the file has changed
	my ($new_ext) = $image_fh =~ m!([^\.]+)$!;
	$new_ext =~ tr/A-Z/a-z/;

	my ($old_ext) = $self->{object_ext};
	$old_ext =~ tr/A-Z/a-z/;

	if ( $new_ext ne $old_ext ) {
		# uh oh, file extension has changed, we must rename
		# the object
		
		my $new_object_basename = $self->{object_basename};
		$new_object_basename =~ s![^\.]+$!!;
		$new_object_basename .= $new_ext;
		
		$self->rename ($new_object_basename);
	}

	# return true if the extension has changed, so the
	# project browser will be reloaded by $self->save_ctrl

	$old_ext ne $new_ext;
}

sub download_filename {
	my $self = shift;
	
	# now save the original filename into the meta data hash
	my $meta_data = $self->get_meta_data;
	return $meta_data->{_original_filename};
}

sub print_escaped {
	my $self = shift;

	my $fh = new FileHandle;
	binmode $fh;

	if ( open ($fh, $self->{object_file} ) ) {
		while ( <$fh> ) {
			s/&/&amp;/g;
			s/</&lt;/g;
			s/>/&gt;/g;
			s/\"/&quot;/g;
			print;
		}
		close $fh;
	}
}

sub view_ctrl {
	my $self = shift;
	
	$self->view_header;
	
	print <<__HTML;
<table $CFG::BG_TABLE_OPTS width="100%"><tr><td>
<table cellpadding=5 $CFG::TABLE_OPTS width="100%">
<tr><td>
$CFG::FONT_FIXED<pre>
__HTML

	my $properties = $self->get_meta_data;
	if ( $properties->{show_as_text} and -s $self->{object_file} ) {
		$self->print_escaped;
	} else {
		print "It is not possible to display the content of this file in the browser.\n";
	}

	print <<__HTML;
</pre></FONT>
</td></tr>
</table>
</td></tr></table>
__HTML
	
	$self->view_footer;
}

1;
