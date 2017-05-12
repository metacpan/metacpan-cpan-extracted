# $Id: TextDomain.pm,v 1.2 2006/05/17 12:55:18 joern Exp $

package NewSpirit::CIPP::TextDomain;

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
        
        if ( basename($object_file) ne "domain.text-domain" ) {
            return "Object MUST be named 'domain'";
        }
        
        if ( dirname($object_file) !~ m!/po$! ) {
            return "Object MUST be placed in a folder called 'po'";
        }

        return $self->SUPER::create();
}

sub install {
	my $self = shift;
	1;
}

sub get_install_filename {
        return;
}

sub edit_ctrl {
	my $self = shift;

        my ($domain, $lang_team_email, $msg_id_bug_email)
            = $self->load_file;

	$self->editor_header ('edit');

	my $wrap = $CFG::TEXTAREA_WRAP ? 'virtual' : 'off';

	print <<__HTML;
<br>
<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr><td>
  $CFG::FONT gettext text domain for the parent's subtree</font>
</td><td>
  <input type="text" name="text_domain" value="$domain" size="20"
         onChange="if ( object_was_modified ) object_was_modified()">
</td></tr>
<tr><td>
  $CFG::FONT Email address of the language team</font>
</td><td>
  <input type="text" name="lang_team_email" value="$lang_team_email"
         size="40"
         onChange="if ( object_was_modified ) object_was_modified()">
</td></tr>
<tr><td>
  $CFG::FONT Email address for message id bug reports</font>
</td><td>
  <input type="text" name="msg_id_bug_email" value="$msg_id_bug_email"
         size="40"
         onChange="if ( object_was_modified ) object_was_modified()">
</td></tr>
</table>
</td></tr></table>
__HTML
	$self->editor_footer;
}

sub load_file {
	my $self = shift;

	my $q = $self->{q};
	my $object_file = $self->{object_file};
	
	my $fh = new FileHandle;
	open ($fh, $object_file) or croak "can't read $object_file";
	my $domain = <$fh>;
        my $lang_team_email = <$fh>;
        my $msg_id_bug_email = <$fh>;
        close $fh;
        
        chomp $_ for ($domain, $lang_team_email, $msg_id_bug_email);

        return ($domain, $lang_team_email, $msg_id_bug_email);        
}

sub save_file {
	my $self = shift;

	my $q = $self->{q};
	my $object_file = $self->{object_file};
	
        if ( basename($object_file) ne "domain.text-domain" ) {
            die "Object MUST be named 'domain'";
        }
        
	my $fh = new FileHandle;
	open ($fh, "> $object_file") or croak "can't write $object_file";

        foreach my $par ( qw/text_domain lang_team_email msg_id_bug_email / ) {
    	    my $text = $q->param($par);
    	    chomp $text;
	    print $fh $text,"\n";
        }

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
