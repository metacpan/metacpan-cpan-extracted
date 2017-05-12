# $Id: SQL.pm,v 1.20 2002/03/22 15:56:33 joern Exp $

package NewSpirit::CIPP::SQL;

$VERSION = "0.01";
@ISA = qw( NewSpirit::Object::Text );

use strict;
use Carp;
use NewSpirit::Object::Text;
use NewSpirit::SqlShell::HTML;
use DBI;

sub convert_meta_from_spirit1 {
	my $self = shift;
	
	my ($old_href, $new_href) = @_;
	
	my $db = $old_href->{SQL_DB};

	# convert spirit 1.x database property to the
	# new.spirit 2.x style (relative path name instead
	# of dotted object notation)

	$db =~ s!^[^\.]+\.!!;	# cut off project name
	$db =~ s!\.!/!g;	# .  ->  /
	$db .= '.cipp-db';	# add file extension
	
	$new_href->{sql_db} = $db;
	
	1;
}

sub property_widget_sql_db {
	my $self = shift;
	
	my %par = @_;
	
	my $name = $par{name};
	my $data = $par{data_href};
	
	my $q = $self->{q};

	my $db_files = $self->get_databases;

	my @db_files = ('', '__default');
	my %labels = ('' => 'none', '__default' => 'Default Database');

	foreach my $db (sort keys %{$db_files}) {
		my $tmp = $db;
		$tmp =~ s!/!.!g;
		$tmp =~ s!\.cipp-db$!!;
		push @db_files, $db;
		$labels{$db} = "$self->{project}.$tmp";
	}

	print $q->popup_menu (
		-name => $name,
		-values => [ @db_files ],
		-default => $data->{$name},
		-labels => \%labels
	);
	
	print qq{<a href="$self->{object_url}&e=refresh_db_popup&next_e=properties"><b>Refresh Database Popup</b></a>},
}

sub edit_ctrl {
	my $self = shift;
	
	$self->editor_header ('edit');

	my $q = $self->{q};
	my $object_url = $self->{object_url};
	my $ticket = $self->{ticket};

	my $rows_execute = 8;
	my $rows_editor = $CFG::TEXTAREA_ROWS - $rows_execute - 5;
	my $wrap = $CFG::TEXTAREA_WRAP ? 'virtual' : 'off';

	my $sql_window_name = "cipp_sqlwindow$ticket";

	print <<__HTML;
<script language="JavaScript">
  function open_sql_window (f) {
    document.cipp_object.e.value = 'function';
    document.cipp_object.f.value = f;
    document.cipp_object.target  = '$sql_window_name';

    if ( !top.$sql_window_name || top.$sql_window_name.closed ) {

      var exec_win = open_window (
      '', '$sql_window_name',
      $CFG::SQL_WIN_WIDTH, $CFG::SQL_WIN_HEIGHT,
      $CFG::SQL_WIN_POSX, $CFG::SQL_WIN_POSY,
      true
      );
      top.$sql_window_name = exec_win;
    }
    
    top.$sql_window_name.document.write(
      '<html><script>'+
      'window.opener.document.cipp_object.submit()'+
      '</'+'script></html>'
    );
    top.$sql_window_name.document.close();
    top.$sql_window_name.focus();
  }
</script>

<table $CFG::BG_TABLE_OPTS><tr><td>
<table $CFG::TABLE_OPTS>
<tr><td>
__HTML
	print qq{<textarea name=cipp_text rows="$rows_editor" }.
	      qq{cols="$CFG::TEXTAREA_COLS" wrap="$wrap"}.
	      qq{onChange="if ( object_was_modified ) object_was_modified()">};

	$self->print_escaped;

	print qq{</textarea>\n};
	
	print <<__HTML;
<table $CFG::INNER_TABLE_OPTS width="100%">
<tr><td>
  $CFG::FONT<b>SQL Quick Execute (data is not permanent)</b></FONT>
</td><td align="right">
  $CFG::FONT<a href="javascript:open_sql_window('execute')"><b>Save
  and execute above SQL code</b></a></FONT>
</td></tr>
</table>
__HTML

	print qq{<textarea name=cipp_sql_execute rows="$rows_execute" }.
	      qq{cols="$CFG::TEXTAREA_COLS" wrap="$wrap">};

	print $q->param('cipp_sql_execute');
	     
	print qq{</textarea>\n};

	print <<__HTML;
<table $CFG::INNER_TABLE_OPTS width="100%">
<tr><td align="right">
  $CFG::FONT<a href="javascript:open_sql_window('quick_execute')"><b>Save and
  execute quick SQL code</b></a></FONT>
</td></tr>
</table>

</td></tr>
</table>
</td></tr></table>
__HTML
	$self->editor_footer;
}

sub get_install_filename {
	my $self = shift;
	
	my $object_file = $self->{object_basename};
	$object_file =~ s/\.[^\.]+$//;	# strip off extension
	
	my $target_file =
	       $self->{project_sql_dir}.'/'.
	       $self->{object_rel_dir}.'/'.
	       $object_file.'.sql';
	
	$target_file =~ s!/+!/!g;
	
	return $target_file;
}

sub function_ctrl {
	my $self = shift;
	
	my $q = $self->{q};
	my $f = $q->param('f');
	
	if ( $f eq 'execute' ) {
		my $sql_code = $q->param('cipp_text');
		$self->exec_sql (\$sql_code, 'SQL Execute');
	} elsif ( $f eq 'quick_execute' ) {
		my $sql_code = $q->param('cipp_sql_execute');
		$self->exec_sql (\$sql_code, 'SQL Quick Execute');
	} else {
		print "f=$f\n";
	}
}

sub exec_sql {
	my $self = shift;
	
	my ($sql_sref, $title) = @_;

	return if $self->save_not_possible;

	$self->object_header ($title);

	# first, save the object
	$self->save;

	# determine database configuration

	my $meta_href = $self->get_meta_data;
	my $db_object = $meta_href->{sql_db};

	my $default_db_msg = '';

	if ( $db_object eq '__default' ) {
		$default_db_msg =
			"<p>You refer to the default database, but no default<br>".
			"database is defined yet!";
		$db_object = $self->get_default_database;
	}

	if ( $db_object eq '' ) {
		NewSpirit::SqlShell::HTML->error (
			"No database configuration found.",
			"Please refer to the properties menu and configure<br>".
			"a database for this SQL object.".$default_db_msg
		);
		return;
	}

	my $db_obj = new NewSpirit::Object (
		q => $self->{q},
		object => $db_object
	);

	my $db_data = $db_obj->get_data;
	my $db_name = $db_obj->{object_name};

	# set database environment

	my %OLD_ENV = %ENV;

	my @env = split (/\r?\n/, $db_data->{db_env});
	foreach my $env (@env) {
		my ($k,$v) = split (/\s+/, $env, 2);
		$ENV{$k} = $v;
	}

	# decode the password
	my $pass;
	{
		# strange workaround. without this block the
		# regex of NewSpirit::SqlShell::next_command
		# will result in this $1 if no match is found
		( $pass = $db_data->{db_pass} )=~
			s/%(..)/chr(ord(pack('C', hex($1)))^85)/eg;
	}
		
	my $shell = new NewSpirit::SqlShell::HTML (
		source     => $db_data->{db_source},
		username   => $db_data->{db_user},
		password   => $pass,
		autocommit => $db_data->{db_autocommit},
		sql        => $sql_sref,
		echo       => 1,
		preference_file => "$CFG::user_conf_dir/$self->{username}.sqlshell"
	);

	$shell->loop;
	
	$shell->error_summary if not $shell->{abort_mode} ;
	
	# restore environment
	%ENV = %OLD_ENV;
	
	NewSpirit::end_page();

	1;
}

sub install_file {
	my $self = shift;
	
	return 2 if $self->is_uptodate;

	# first install the .sql file via NewSpirit::Object
	$self->SUPER::install_file;
	
	# now install a .db file, which contains the name
	# of the database configuration file
	# (dbshell.pl needs this information to connect to
	#  a database on a production system)
	
	my $filename = $self->get_install_filename;
	
	$filename =~ s/sql$/db/;
	
	my $db = $self->get_meta_data->{sql_db};
	if ( $db eq '__default' ) {
		$db = 'default.db-conf' ;
	} else {
		$db =~ s!/!.!g;
		$db =~ s!cipp-db$!db-conf!;
	}

	my $prod_dir = $self->{project_prod_dir};
	my $back_prod = $filename;

	$back_prod =~ s!^$prod_dir/!!;
	$back_prod =~ s!/[^/]*?$!!;
	$back_prod =~ s![^/]+!..!g;
	
	open (OUT, ">$filename") or croak "can't write $filename";
	print OUT "$back_prod/config/$db\n";
	close OUT;
	
	1;
}

1;
