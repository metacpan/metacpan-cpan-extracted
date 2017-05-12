# $Id: PO.pm,v 1.2 2006/05/17 10:55:48 joern Exp $

package NewSpirit::CIPP::PO;

$VERSION = "0.01";
@ISA = qw( NewSpirit::Object );

use strict;
use Carp;
use NewSpirit::Object;
use NewSpirit;
use FileHandle;
use File::Basename;

sub create {
        my $self = shift;
        
        my $object_file = $self->{object_file};
        
        if ( dirname($object_file) !~ m!/po$! ) {
            return "Object MUST be placed in a folder called 'po'";
        }

        my $domain_qm = quotemeta ( eval { $self->get_text_domain } );

        if ( $@ ) {
            return "Create a text-domain object first";
        }
        
        if ( basename($object_file) !~ /^$domain_qm-[^-]+\.po$/ ) {
            return "Object MUST be named TEXTDOMAIN-LANG";
        }

        return $self->SUPER::create();
}

sub install_file {
        my $self = shift;
        
        my $mo_file = $self->get_install_filename;
        
        my $cmd    = "msgfmt -c -o $mo_file $self->{object_file} && echo SUCCESS";

        my $output = qx[($cmd) 2>&1];
        
        if ( $output !~ /SUCCESS/ ) {
            push @{$self->{install_errors}},
                "Error compiling .mo file.\nCommand: $cmd\nOutput:\n$output\n";
            return 0;
        }
        else {
            return 1;
        }
}

sub get_install_filename {
	my $self = shift;
	
        my $domain = $self->get_text_domain;
        my ($lang) = $self->{object_file} =~ /([^-]+)\.po$/;

        return "$self->{project_prod_dir}/l10n/$lang/LC_MESSAGES/$domain.mo";
}

sub get_text_domain {
        my $self = shift;
        
        my $object_dir  = $self->{object_dir};
        my $domain_file = "$object_dir/domain.text-domain";
        
        open (my $fh, $domain_file) or die "can't read $domain_file";
        my $domain = <$fh>;
        chomp $domain;
        close $fh;

        return $domain;
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
