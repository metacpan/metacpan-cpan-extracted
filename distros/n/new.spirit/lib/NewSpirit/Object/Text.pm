# $Id: Text.pm,v 1.12 2000/12/02 12:02:17 joern Exp $

package NewSpirit::Object::Text;

$VERSION = "0.01";
@ISA = qw( NewSpirit::Object );

use strict;
use Carp;
use NewSpirit::Object;
use NewSpirit;
use FileHandle;

sub get_install_filename {
	my $self = shift;
	
	my $rel_path = "$self->{object_rel_dir}/$self->{object_basename}";
	
	$rel_path =~ s/\.[^\.]+$//;
	
	my $ext = $self->{object_ext};
	my $path = "$self->{project_htdocs_dir}/$rel_path.$ext";
	$path =~ s!/+!/!g;
	
	return $path;
}

sub edit_ctrl {
	my $self = shift;

	$self->editor_header ('edit');

	my $wrap = $CFG::TEXTAREA_WRAP ? 'virtual' : 'off';

	print <<__HTML;
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr><td>
__HTML
	print qq{<textarea name=cipp_text rows="$CFG::TEXTAREA_ROWS" }.
	      qq{cols="$CFG::TEXTAREA_COLS" WRAP="$wrap" }.
	      qq{onChange="if ( object_was_modified ) object_was_modified()">};

	$self->print_escaped;
	     
	print qq{</textarea>\n};
	print <<__HTML;
</td></tr>
</table>
</td></tr></table>
__HTML
	$self->editor_footer;
}

sub save_file {
	my $self = shift;

	my $q = $self->{q};
	my $object_file = $self->{object_file};
	
	my $fh = new FileHandle;
	open ($fh, "> $object_file") or croak "can't write $object_file";
	
	# Netscape adds \r to the end of each line. We remove
	# them here, so win32 will have CR LF as eol (
	# because \n is translated to CR LF already due to the
	# non-binmode of the filehandle) and Unix has LF.

	my $text = $q->param('cipp_text');
	$text =~ s/\r//g;

	print $fh $text;
	close $fh;

	return 0;	# no project file browser update needed
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

	$self->print_escaped;

	print <<__HTML;
</pre></FONT>
</td></tr>
</table>
</td></tr></table>
__HTML
	
	$self->view_footer;
}

1;
