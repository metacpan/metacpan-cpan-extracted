
# $Id: Prefs.pm,v 1.5 2001/03/12 11:15:19 joern Exp $

package NewSpirit::Prefs;

@ISA = qw( NewSpirit::Widget );
$VERSION = "0.01";

use strict;
use NewSpirit::LKFile;
use NewSpirit::Widget;
use Carp;

my %WIDGET_TYPE_LEN = (
	'c' => 7,
	'f' => 40,
	'i' => 10,
	'b' => 1,
	'fr' => 20
);

sub new {
	my $type = shift;
	
	my ($q) = @_;
	
	my $self = {
		q => $q,
		data => {},
		widget_fields => [],
		filename => undef
	};
	
	return bless $self, $type;
}

sub read {
	my $self = shift;
	
	my ($username) = @_;

	my $user_conf_file = "$CFG::user_conf_dir/$username.conf";
	my $default_conf_file = $CFG::default_user_conf_file;
	
	# first read default config file to build the structure

	my $lkfile = new NewSpirit::LKFile ($default_conf_file);
	my $data = $lkfile->read;
	$lkfile = undef;
	
	$$data =~ m/^(.*?#--do-not-remove-this--\n)(.*?)(#--do-not-remove-this--\n.*)$/s;

	my $header = $1;
	my $footer = $3;
	$data = $2;
	
	my %data;
	my %widget_definition;
	my @widget_order;

	my $nr = 0;
	while ( $data =~ m/(.*)/mg ) {
		my $line = $1;
		next if $line eq '';
		
		if ( $line =~ m,^#!/\s+(.*), ) {
			++$nr;
			$widget_definition{"title$nr"} = {
				description => $1,
				type => 'title'
			};
			push @widget_order, "title$nr";

		} elsif ( $line =~ m/^#!-/ ) {
			++$nr;
			$widget_definition{"space$nr"} = {
				type => 'space'
			};
			push @widget_order, "space$nr";

		} elsif ( $line =~ m/\$(\w+)\s*=\s*"?(.*?)"?;\s*#!([^\s]+)\s*(.*)/ ) {
			my $len = $WIDGET_TYPE_LEN{$3};
			$widget_definition{$1} = {
				description => $4,
				type => "text $len"
			};
			push @widget_order, $1;
			$data{$1} = $2;
		}
	}
	
	# now read user config file to get user specific values,
	# if the user files exists

	if ( -f $user_conf_file ) {
		$lkfile = new NewSpirit::LKFile ($user_conf_file);
		$data = $lkfile->read;
		$lkfile = undef;
	
		$$data =~ m/^(.*?#--do-not-remove-this--\n)(.*?)(#--do-not-remove-this--\n.*)$/s;

		$data = $2;
	
		while ( $data =~ m/(.*)/mg ) {
			my $line = $1;
			next if $line eq '';
			
			if ( $line =~ m/\$(\w+)\s*=\s*"?(.*?)"?;\s*#!([^\s]+)\s*(.*)/ ) {
				$data{$1} = $2;
			}
		}
	}


	$self->{widget_definition} = \%widget_definition;
	$self->{widget_order}      = \@widget_order;
	$self->{data}		   = \%data;

#	NewSpirit::dump (\%widget_definition, \@widget_order, \%data);

	1;
}

sub save {
	my $self = shift;
	
	my ($username) = @_;

	my $user_conf_file = "$CFG::user_conf_dir/$username.conf";
	my $default_conf_file = $CFG::default_user_conf_file;

	my $q = $self->{q};
	
	# read default config file as a template for the
	# user configuration file

	my $lkfile = new NewSpirit::LKFile ($default_conf_file);
	my $data = $lkfile->read;
	$lkfile = undef;
	
	# parse configuration template
	
	$$data =~ m/^(.*?#--do-not-remove-this--\n)(.*?)(#--do-not-remove-this--\n.*)$/s;

	my $header = $1;
	my $footer = $3;
	$data = $2;
	
	my $new_data = '';
	
	# build new configuration file body.
	# scan configuration template and replace values with
	# the new values taken from the CGI query object
	
	while ( $data =~ m/(.*)/mg ) {
		my $line = $1;
		$new_data .= "\n", next if $line eq '';
		
		if ( $line =~ m/\$(\w+)(\s*)=(\s*)("?)(.*?)("?);(\s*)#!([^\s]+)\s*(.*)/ ) {
			$new_data .= "\$$1$2=$3$4".$q->param($1)."$6;$7#!$8 $9";
		} else {
			$new_data .= "$line";
		}
	}
	
	$data = $header.$new_data.$footer;

	my $lkfile = new NewSpirit::LKFile ($user_conf_file);
	$lkfile->write (\$data) ;
	$lkfile = undef;
	
	1;
}

# CGI Stuff

sub event_edit {
	my $self = shift;

	my ($message) = @_;
	
	$message ||= '&nbsp;';
	
	my $q = $self->{q};
	my $username = $q->param('username');
	my $ticket = $q->param('ticket');

	$self->read ($username);

	NewSpirit::std_header (
		page_title => "Edit Preferences"
	);
	
	print <<__HTML;
<form name="usr" action="$CFG::admin_url" method="POST">
<input type="HIDDEN" name=ticket value="$ticket">
<input type="HIDDEN" name=e value="pref_save">
__HTML
	
	my $buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td>
  $CFG::FONT<FONT COLOR="green">
  <b>$message</b>
  </FONT></FONT>
</td><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Save "
         onClick="this.form.submit()">
  </FONT>
</td></tr>
</table>
__HTML

	$self->input_widget_factory (
		names_lref => $self->{widget_order},
		info_href  => $self->{widget_definition},
		data_href  => $self->{data},
		buttons    => $buttons
	);


	print "</form>\n";
	
	$self->back_to_main;
	
	NewSpirit::end_page();
}

sub event_save {
	my $self = shift;
	
	my $q = $self->{q};
	my $username = $q->param('username');

	$self->save ($username);

	NewSpirit::read_user_config($username);

	$self->event_edit ('User preferences saved');
}

sub back_to_main {
	my $self = shift;
	
	my $ticket = $self->{q}->param('ticket');

	print <<__HTML;
<p>
$CFG::FONT
<a href="$CFG::admin_url?ticket=$ticket&e=menu"><b>[ Go Back ]</b></a>
</font>
__HTML
}

1;
