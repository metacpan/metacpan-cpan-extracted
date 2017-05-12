# $Id: Image.pm,v 1.7 2001/01/29 11:09:35 joern Exp $

package NewSpirit::Object::Image;

$VERSION = "0.01";
@ISA = qw( NewSpirit::Object );

use strict;
use Carp;
use NewSpirit::Object;
use NewSpirit;
use File::Copy;

sub init {
	my $self = shift;
	
	# this module depends on the correct definition of
	# the _image_filename meta data field. If actually
	# no meta data exists for this object, we define
	# this field with a convenient default value.
	
	my $meta_data = $self->get_meta_data;
	my $image_filename = $meta_data->{_image_filename};

	# maybe the object has no properties, so no _image_filename
	# is available. Instead we take the object_basename assuming
	# that it has the correct extension and save the meta data,
	# so this object has a well defined state.

	if ( not $image_filename ) {
		$image_filename = $self->{object_basename};
		$meta_data->{_image_filename} = $image_filename;
		$self->save_meta_data ($meta_data);
	}

	1;
}	

sub convert_data_from_spirit1 {
	my $self = shift;
	
	1;
}

sub edit_ctrl {
	my $self = shift;

	$self->editor_header ('edit');

	my $img_html_code = $self->gen_img_html_code;


	print <<__HTML;
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr>
  <td>$img_html_code</td>
</tr>
</table>
</td></tr></table>
<p>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr><td valign="center">
  $CFG::FONT
  <b>Image File Upload</b>
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

sub download_ctrl {
	my $self = shift;
	
	my $mime_type = 'image/'.$self->{object_ext};
	$self->SUPER::download_ctrl ($mime_type);
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
	$meta_data->{_image_filename} = "$image_fh";
	$self->save_meta_data ($meta_data);

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

sub view_ctrl {
	my $self = shift;
	
	$self->view_header;
	
	my $version = $self->{q}->param('version');
	my $img_html_code = $self->gen_img_html_code ($version);


	print <<__HTML;
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr>
  <td>$img_html_code</td>
</tr>
</table>
</td></tr></table>
<p>
__HTML

	$self->view_footer;
}

sub restore {
	my $self = shift;
	
	# we overload the NewSpirit::Object::restore method to
	# check if the file extension changes due to the restore

	my ($version) = @_;

	# store actual extension
	my $old_ext = $self->{object_ext};
	$old_ext =~ tr/A-Z/a-z/;

	# first we do the restore and then check file extensions
	# and eventually rename the object
	$self->SUPER::restore ($version);
	
	my $meta_data = $self->get_meta_data;
	my $image_filename = $meta_data->{_image_filename};

	my ($new_ext) = $image_filename =~ m!([^\.]+)$!;
	$new_ext =~ tr/A-Z/a-z/;

	if ( $old_ext ne $new_ext ) {
		# uh oh, file extension has changed, we must rename
		# the object
		
		my $new_object_basename = $self->{object_basename};
		$new_object_basename =~ s![^\.]+$!!;
		$new_object_basename .= $new_ext;
		
		$self->rename ($new_object_basename);
	}
	
	# return true if the extension has changed, so the
	# project browser will be reloaded by $self->restore_ctrl

	$old_ext ne $new_ext;
}

sub get_install_filename {
	my $self = shift;
	
	return $self->{project_htdocs_dir}.'/'.
	       $self->{object};
}

sub gen_img_html_code {
	my $self = shift;
	
	my ($version) = @_;
	
	my $download_url;
	my $basename = $self->{object_basename};
	my $random = int(rand(10000000));

	my $filename = $self->{object_file};
	if ( $version ) {
		$filename = "$self->{object_history_dir}/$version";
	}

	if ( -z $filename ) {
		return qq{$CFG::FONT<b>Image file is empty</b></FONT>};
	}

	if ( $version ) {
		$download_url = $self->{object_url}.
			'&e=download&no_http_header=1'.
			'&history_warp=1&version='.$version.
			'&RANDOM='.(int(rand(10000000)));
		$download_url =~ s!\?!/$random/$basename?!;
	} else {
		$download_url = $self->{object_url}.
			'&e=download&no_http_header=1'.
			'&RANDOM='.(int(rand(10000000)));
		$download_url =~ s!\?!/$random/$basename?!;
	}


	return qq{<img src="$download_url">};
}

1;
