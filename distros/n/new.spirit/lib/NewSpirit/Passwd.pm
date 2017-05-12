# $Id: Passwd.pm,v 1.18 2004/09/14 09:08:40 joern Exp $

package NewSpirit::Passwd;

@ISA = qw( NewSpirit::Widget );
$VERSION = "0.01";

use strict;
use NewSpirit;
use NewSpirit::LKDB;
use NewSpirit::Widget;
use NewSpirit::Project;
use Carp;

sub new {
	my $type = shift;
	my ($q, $filename) = @_;

	$filename ||= $CFG::passwd_file;

	my $lkdb = new NewSpirit::LKDB ($filename);
	
	my $self = {
		lkdb => $lkdb,
		hash => $lkdb->{hash},
		q    => $q
	};

	return bless $self, $type;
} 

sub check_user {
	my $self = shift;
	my ($username) = @_;
	
	if ( not exists $self->{hash}->{$username} ) {
		confess "user '$username' is unknown";
	}
	
	1;
}

sub add {
	my $self = shift;
	my ($username, $password, $flags, $projects) = @_;

	if ( exists $self->{hash}->{$username} ) {
		croak "user '$username' already exists";
	}

	$self->put($username, $password, $flags, $projects);

	1;
}

sub update {
	my $self = shift;
	my ($username, $password, $flags, $projects) = @_;

	$self->check_user ($username);

	$self->put($username, $password, $flags, $projects);

	1;
}

sub delete {
	my $self = shift;
	
	my ($username) = @_;

	$self->check_user ($username);

	delete $self->{hash}->{$username};

	return;
}

sub check_project_access {
	my $self = shift;
	my ($username, $project) = @_;

	$self->check_user ($username);

	return 1 if $username eq 'spirit';

	my ($projects);
	(undef, undef, $projects) = $self->get($username);

	defined $projects->{$project};
}

sub get_access_rights {
	my $self = shift;
	my ($username) = @_;

	$self->check_user ($username);

	my ($flags, $projects);
	(undef, $flags, $projects) = $self->get($username);

	return ($projects, $flags);
}

sub check_flag {
	my $self = shift;
	my ($username, $flag) = @_;

	$self->check_user ($username);

	my ($flags);
	(undef, $flags) = $self->get($username);

	defined $flags->{$flag};
}

sub check_password {
	my $self = shift;
	my ($username, $check_password) = @_;

	return if $username eq '' or $check_password eq '';

	return $self->ldap_check_password ($username, $check_password)
		if $username ne 'spirit' and
		   $CFG::ldap_enabled;

	$check_password = $self->crypt($check_password, $username);

	my ($password) = $self->get($username);

	$password eq $check_password;
}

sub ldap_check_password {
	my $self = shift;
	my ($username, $password) = @_;
	
	require "Net/LDAP.pm";

	my $ldap;
	eval {
		# anonymous connect
        	$ldap = Net::LDAP->new (
			$CFG::ldap_server,
			onerror => 'die',
			version => $CFG::ldap_version,
		) or die "$@";

        	$ldap->bind;

		# search uid (we need the dn)
        	my $result = $ldap->search (
			base   => $CFG::ldap_base,
			filter => "$CFG::ldap_uid=$username"
		);

		die "username ambigious" if $result->count > 1;

		# catch dn
		my $entry = $result->shift_entry;
		my $dn = $entry->dn;

        	$ldap->unbind;

		# now try to connect with this dn and the
		# given password to validate the account
		$ldap = Net::LDAP->new (
			$CFG::ldap_server,
			onerror => 'die',
			version => $CFG::ldap_version,
		) or die "$@";

		$ldap->bind (
        	     dn       => $dn,
        	     password => $password,
		);
	};

	my $error = $@;

	$ldap->unbind if defined $ldap;

	return if $error;
	
	# if this is a new user to new.spirit,
	# create the corresponding account
	eval { $self->check_user ( $username ) };
	$self->add ($username, "*", {}, {}) if $@;
	
	return 1;	
}

sub crypt {
	my $self = shift;
	
	my ($crypt, $salt) = @_;

	$crypt = crypt $crypt, substr($salt,0,2)
		if $CFG::OS_has_crypt;

	return $crypt;
}

sub get {
	my $self = shift;
	my ($username) = @_;

	return if not defined $self->{hash}{$username};

	my ($password, $flags_txt, $projects_txt) = 
		split( "\t", $self->{hash}->{$username});

	my @flag_list = split (",", $flags_txt);
	my %flag_hash;
	@flag_hash{@flag_list} = (1) x @flag_list;

	my @project_list = split (",", $projects_txt);
	my %project_hash;
	@project_hash{@project_list} = (1) x @project_list;
		
	return ($password, \%flag_hash, \%project_hash);
}

sub put {
	my $self = shift;
	
	my ($username, $password, $flag_href, $project_href) = @_;

	if ( $password ne '' ) {
		$password = $self->crypt ($password, $username);
	} else {
		($password) = $self->get ($username);
	}

	$password = '*' if $CFG::ldap_enabled and
			   $username ne 'spirit';

	$self->{hash}->{$username} = join ("\t",
		$password,
		join (",", keys %{$flag_href}),
		join (",", keys %{$project_href})
	);
	
	1;
}

sub grant_project_access {
	my $self = shift;
	
	my %par = @_;
	
	my $username      = $par{username};
	my $project_lref  = $par{project_lref};
	my $revoke_others = $par{revoke_others};
	
	my ($password, $flags, $projects) = $self->get($username);

	if ( $revoke_others ) {
		%{$projects} = ();
	}

	foreach my $project ( @{$project_lref} ) {	
		$projects->{$project} = 1;
	}

	$self->put ($username, undef, $flags, $projects);

	1;
}

sub get_user_list {
	my $self = shift;
	
	my @list = keys %{$self->{hash}};
	
	return \@list;
}

# CGI stuff

sub main_menu {
	my $self = shift;
	my ($q, $project_href, $flags) = @_;

	my $ticket = $q->param('ticket');

	print <<__HTML;
<script>
  function usr_submit (f, event) {
    if ( (event == 'edit' || event == 'delete') &&
         f.edit_username.selectedIndex == -1 ) {
      alert ('Please select a entry!');
      return;
    }
    
    if ( event == 'delete' ) {
      if ( f.edit_username.options[f.edit_username.selectedIndex].text == 'spirit' ) {
      	alert ('You cannot delete the user spirit!');
	return;
      }
      var ok = confirm (
      	'Please confirm deletion of user '+
	f.edit_username.options[f.edit_username.selectedIndex].text
      );
      if ( ! ok ) {
        return;
      }
    } 
    
    f.e.value = 'user_'+event;
    f.submit();
  }
</script>

<form name="users" action="$CFG::admin_url" method="POST">
<input type="HIDDEN" name=ticket value="$ticket">
<input type="HIDDEN" name=e value="">

$CFG::FONT_BIG<b>User Administration</b></FONT>
<table $CFG::BG_TABLE_OPTS width="100%">
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td>
    $CFG::FONT
    <select name="edit_username" size=10 width=200>
__HTML
	my $selected = "SELECTED";
	foreach my $username ( sort keys %{$self->{hash}} ) {
		print "<option value=$username $selected>$username\n";
		$selected = '';
	}
	print <<__HTML;
    </select>
    <br>
    <a href="javascript:usr_submit(document.users, 'edit')"><b>EDIT USER</b></a>
    <br>
    <a href="javascript:usr_submit(document.users, 'new_ask')"><b>NEW USER</b></a>
    <br>
    <a href="javascript:usr_submit(document.users, 'delete')"><b>DELETE USER</b></a>
    </FONT>
  </td></tr>
  </table>
  </td></tr>
</table>
</form>
__HTML

}

sub account_menu {
	my $self = shift;
	my ($q, $project_href, $flags) = @_;

	my $ticket = $q->param('ticket');
	my $project = $q->param('project');

	print <<__HTML;
<script>
  function logout () {
    if ( parent.name != 'NEWSPIRIT' ) {
      parent.document.location.href=
      	'$CFG::admin_url?ticket=$ticket&e=logout&project=$project&close=1';
    } else {
      parent.document.location.href=
      	'$CFG::admin_url?ticket=$ticket&e=logout&project=$project';
    }
  }
</script>

<form name="usr" action="$CFG::admin_url" method="POST">
<input type="HIDDEN" name=ticket value="$ticket">
<input type="HIDDEN" name=e value="">

$CFG::FONT_BIG<b>Account</b></FONT>
<table $CFG::BG_TABLE_OPTS width="100%">
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
  <tr><td>
    $CFG::FONT
    <a href="$CFG::admin_url?ticket=$ticket&e=pref_edit"><b>EDIT PREFERENCES</b></a>
    <br>
    <a href="$CFG::admin_url?ticket=$ticket&e=user_chpasswd_ask"><b>CHANGE PASSWORD</b></a>
    <p>
    <a href="javascript:logout()"><b>LOGOUT</b></a>
    </FONT>
  </td></tr>
  </table>
  </td></tr>
</table>
</form>
__HTML

}

#--------------------------------------------------------
# user data structure and methods for formular generation
#--------------------------------------------------------

my %FIELD_DEFINITION = (
	edit_username => {
		description => 'Username',
		type => 'text',
	},
	password => {
		description => 'Password',
		type => 'password',
	},
	password2 => {
		description => 'Password (repeated)',
		type => 'password',
	},
	rights => {
		description => 'Functions',
		type => 'type_method'
	},
	projects => {
		description => 'Project Access',
		type => 'type_method'
	}
);

my @FIELD_ORDER = (
	'edit_username', 'password', 'password2',
	'rights', 'projects'
);

my @FIELD_ORDER_LDAP = (
	'edit_username',
	'rights', 'projects'
);

sub widget_type_projects {
	my $self = shift;
	
	my $q = $self->{q};
	my $username = $q->param('edit_username');
	
	my ($projects, $rights);
	
	if ( not $self->{widget_no_default_values} ) {
		($projects, $rights) = $self->get_access_rights ($username);
	} else {
		$projects = {};
		$rights = {};
	}

	my $ph = new NewSpirit::Project ($self->{q});
	my $projects_href = $ph->get_project_list ( name2desc => 1 );
	$ph = undef;
	
	my @items;
	foreach my $prj (sort {lc($a) cmp lc($b)} keys %{$projects_href} ) {
		push @items, [ $prj, "$prj: $projects_href->{$prj}" ];
	}

	return {
		type => 'list',
		items => \@items,
		selected => $projects,
		multiple => 1,
	};
}

sub widget_type_rights {
	my $self = shift;
	
	my $q = $self->{q};
	my $username = $q->param('edit_username');

	my ($projects, $rights);
	
	if ( not $self->{widget_no_default_values} ) {
		($projects, $rights) = $self->get_access_rights ($username);
	} else {
		$projects = {};
		$rights = {};
	}

	return {
		type => 'list',
		items => [ ['PROJECT', 'Project Manager'],
			   ['USER', 'User Manager'], ],
		selected => $rights,
		multiple => 1,
	};
}

#--------------------------------------------------------

sub event_edit {
	my $self = shift;
	
	my ($message) = @_;

	my $q = $self->{q};

	my $username = $q->param('edit_username');
	my $ticket = $q->param('ticket');

	NewSpirit::std_header (
		page_title => "Edit User '$username'"
	);
	
	print <<__HTML;
<form name="usr" action="$CFG::admin_url" method="POST">
<input type="HIDDEN" name=ticket value="$ticket">
<input type="HIDDEN" name=e value="user_save">
__HTML
	
	$self->print_user_form (
		username => $username,
		check_password => 0,
		message => $message
	);
	
	print "</form>\n";
	
	$self->back_to_main;
	
	NewSpirit::end_page();
}

sub event_new_ask {
	my $self = shift;
	
	my $q = $self->{q};

	my $ticket = $q->param('ticket');

	NewSpirit::std_header (
		page_title => "Add A New User"
	);
	
	print <<__HTML;
<form name="usr" action="$CFG::admin_url" method="POST">
<input type="HIDDEN" name=ticket value="$ticket">
<input type="HIDDEN" name=e value="user_new">
__HTML
	
	# this flag advises the widget callback methods
	# to produce widget without default values
	$self->{widget_no_default_values} = 1;

	$self->print_user_form (
		blank => 1,
		check_password => 1
	);

	$self->{widget_no_default_values} = 0;
	
	print "</form>\n";
	
	$self->back_to_main;
	
	NewSpirit::end_page();
}

sub print_user_form {
	my $self = shift;

	my %par = @_;
	
	my $username       = $par{username};
	my $check_password = $par{check_password};
	my $message        = $par{message} || '&nbsp;';
	my $blank          = $par{blank};

	my $js_check_password;
	if ( $check_password ) {
		$js_check_password =
			"&& ".
			"this.form.password.value != '' && ".
			"this.form.password.value == ".
			"this.form.password2.value";
	} else {
		$js_check_password =
			"&& ".
			"this.form.password.value == ".
			"this.form.password2.value";
	}
	
	if ( $CFG::ldap_enabled and $username ne 'spirit' ) {
		$js_check_password = '';
	}
	
	my $q = $self->{q};
	
	my $button_text = $blank ? 'Create User' : 'Save User';

	my $buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td>
  $CFG::FONT<FONT COLOR="green">
  <b>$message</b>
  </FONT></FONT>
</td><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" $button_text "
         onClick="if (this.form.edit_username.value != ''
	              $js_check_password ) {
	            this.form.submit();
		  } else {
		    alert ('Please provide username and two identical passwords.');
		  }">
  </FONT>
</td></tr>
</table>
__HTML

	my %read_only;
	if ( not $blank ) {
		%read_only = (
			edit_username => 1,
		);
	}

	my $names_lref = \@FIELD_ORDER;
	$names_lref = \@FIELD_ORDER_LDAP if $CFG::ldap_enabled and
				  	    $username ne 'spirit';

	$self->input_widget_factory (
		read_only_href => \%read_only,
		names_lref     => $names_lref,
		info_href      => \%FIELD_DEFINITION,
		data_href      => {
			edit_username => $username
		},
		buttons        => $buttons
	);
}

sub event_save {
	my $self = shift;
	
	my $q = $self->{q};
	
	my ($username, @rights_list,   %rights_hash,
	    $password, @projects_list, %projects_hash);

	$username      = $q->param('edit_username');
	$password      = $q->param('password');
	@rights_list   = $q->param('rights');
	@projects_list = $q->param('projects');
	
	@rights_hash{@rights_list} = (1) x @rights_list;
	@projects_hash{@projects_list} = (1) x @projects_list;

	$self->update ($username, $password, \%rights_hash, \%projects_hash);
	
	$q->param('password', '');
	$q->param('password2', '');
	
	$self->event_edit ("User saved successfully!");
}

sub event_new {
	my $self = shift;
	
	my $q = $self->{q};
	
	my ($username, @rights_list,   %rights_hash,
	    $password, @projects_list, %projects_hash);

	$username      = $q->param('edit_username');
	$password      = $q->param('password');
	@rights_list   = $q->param('rights');
	@projects_list = $q->param('projects');
	
	@rights_hash{@rights_list} = (1) x @rights_list;
	@projects_hash{@projects_list} = (1) x @projects_list;

	$self->add ($username, $password, \%rights_hash, \%projects_hash);
	
	$q->param('password', '');
	$q->param('password2', '');
	
	$self->event_edit ("User created successfully!");
}

sub event_delete {
	my $self = shift;
	
	my $q = $self->{q};

	my $username = $q->param('edit_username');

	$self->delete ($username);

	my $file_lref = NewSpirit::filename_glob (
		dir   => $CFG::user_conf_dir,
		regex => "^$username".'\..*'
	);

	unlink @{$file_lref};
	
	NewSpirit::std_header (
		page_title => "User '$username' deleted"
	);
	
	print <<__HTML;
$CFG::FONT
The user '$username' has been successfully deleted.
</font>
__HTML
	
	$self->back_to_main;
	
	NewSpirit::end_page();
}

sub event_chpasswd_ask {
	my $self = shift;
	
	my ($message) = @_;

	$message ||= '&nbsp';
	
	my $q = $self->{q};
	
	my $ticket = $q->param('ticket');
	my $username = $q->param('username');
	
	NewSpirit::std_header (
		page_title => "Change Password Of User '$username'"
	);
	
	if ( $CFG::ldap_enabled ) {
		print <<__HTML;
$CFG::FONT
This new.spirit server is configured to use a LDAP database<br>
for account validiation. Please change your password<br>
in the LDAP server.
</font>
__HTML
		$self->back_to_main;
		NewSpirit::end_page();
		return;
	}

	print <<__HTML;
<form name="usr" action="$CFG::admin_url" method="POST">
<input type="HIDDEN" name=ticket value="$ticket">
<input type="HIDDEN" name=e value="user_chpasswd">
__HTML

	my $buttons = <<__HTML;
<table $CFG::TABLE_OPTS width="100%">
<tr><td>
  $CFG::FONT<FONT COLOR="red">
  <b>$message</b>
  </FONT></FONT>
</td><td align="right">
  $CFG::FONT
  <INPUT TYPE=BUTTON VALUE=" Save "
         onClick="if ( this.form.old_password.value != '' &&
		       this.form.new_password1.value != '' &&
	  	       this.form.new_password1.value == this.form.new_password2.value) {
	            this.form.submit();
		  } else {
		    alert ('Please provide old password and two identical new passwords.');
		  }">
  </FONT>
</td></tr>
</table>
__HTML

	$self->input_widget_factory (
		names_lref => [ 'old_password', 'new_password1',
		                'new_password2' ],
		info_href  => {
			old_password => {
				type => 'password',
				description => 'Old password'
			},
			new_password1 => {
				type => 'password',
				description => 'New password'
			},
			new_password2 => {
				type => 'password',
				description => 'New password (confirmation)'
			}
		},
		buttons    => $buttons
	);
	
	print "</form>\n";
	
	$self->back_to_main;
	
	NewSpirit::end_page();
}

sub event_chpasswd {
	my $self = shift;
	
	my $q = $self->{q};
	
	my $ticket = $q->param('ticket');
	my $username = $q->param('username');

	my $old_password = $q->param('old_password');

	if ( 1 and not $self->check_password ($username, $old_password) ) {
		$q->param('old_password', '');
		return $self->event_chpasswd_ask (
			'Your old password is incorrect!'
		);
	}
	
	my ($password, @stuff) = $self->get ($username);
	$self->put ($username, $q->param('new_password1'), @stuff);

	NewSpirit::std_header (
		page_title => "Change Password Of User '$username'"
	);

	if ( $CFG::ldap_enabled ) {
		print <<__HTML;
$CFG::FONT
This new.spirit server is configured to use a LDAP database<br>
for account validiation. Please change your password<br>
in the LDAP server.
</font>
__HTML
		$self->back_to_main;
		NewSpirit::end_page();
		return;
	}
	
	print <<__HTML;
$CFG::FONT
Password of user '$username' successful changed!
</font>
__HTML
	$self->back_to_main;
	
	NewSpirit::end_page();
	
	
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
