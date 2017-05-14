package Tk::DBI::Form;
#------------------------------------------------
# automagically updated versioning variables -- CVS modifies these!
#------------------------------------------------
our $Revision           = '$Revision: 1.15 $';
our $CheckinDate        = '$Date: 2003/11/06 17:55:52 $';
our $CheckinUser        = '$Author: xpix $';
# we need to clean these up right here
$Revision               =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinDate            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
$CheckinUser            =~ s/^\$\S+:\s*(.*?)\s*\$$/$1/sx;
#-------------------------------------------------
#-- package Tk::DBInterface ----------------------
#-------------------------------------------------

use Tk::JBrowseEntry;
use Tk::XDialogBox;
use Tk::NumEntry;
use Tk::Date;
use Tk::LabFrame;
use Tk::FBox;
use Tk::ROText;
use Tk::Balloon;

use Date::Manip;

use base qw/Tk::Frame/;

use strict;

Construct Tk::Widget 'DBIForm';

my ($DELEIMG, $CHANGEIMG);

# Class initializer.

# ------------------------------------------
sub ClassInit {
# ------------------------------------------

    # ClassInit is called once per MainWindow, and serves to
    # perform tasks for the class as a whole.  Here we create
    # a Photo object used by all instances of the class.

    my ($class, $mw) = @_;

    $class->SUPER::ClassInit($mw);

} # end ClassInit

# Instance initializer.

# ------------------------------------------
sub Populate {
# ------------------------------------------
	my ($obj, $args) = @_;
	$obj->{dbh} 		= delete $args->{'-dbh'} 	|| warn "No DB-Handle!";
	$obj->{table} 		= delete $args->{'-table'} 	|| warn "No Table!";
	$obj->{alternateTypes}	= delete $args->{'-alternateTypes'};		# Alternate Fieldtypes
	$obj->{debug} 		= delete $args->{'-debug'}	|| 0;		# Debug Mode
	$obj->{lock} 		= delete $args->{'-lock'}	|| 0;		# Lock timeout in seconds
	$obj->{update} 		= delete $args->{'-update'};			# Update Fields
	$obj->{insert} 		= delete $args->{'-insert'};			# Insert Fields
	$obj->{link} 		= delete $args->{'-link'};			# Link Fields
	$obj->{required} 	= delete $args->{'-required'};			# Required Fields
	$obj->{images} 		= delete $args->{'-images'};			# display Images for Field
	$obj->{readonly}	= delete $args->{'-readonly'};			# Readonly Fields
	$obj->{default}		= delete $args->{'-default'};			# Default Fields
	$obj->{events}		= delete $args->{'-events'};			# Add Events
	$obj->{editId}		= delete $args->{'-editId'}	|| 0;		# Allow edit the ID
	$obj->{test_cb}		= delete $args->{'-test_cb'};			# Test Callbacks after dialog
	$obj->{validate_cb}	= delete $args->{'-validate_cb'};		# Validate Callbacks in dialog (after KeyEvents)
	$obj->{cancel_cb}	= delete $args->{'-cancel_cb'};			# Callback on Cancelbutton
	$obj->{noChange}	= delete $args->{'-noChange'}; 			# Functions no Change 'insert,update,delete' or 'all'
	$obj->{addButtons}	= delete $args->{'-addButtons'}; 		# add buttons to DialogBox
	$obj->{addFields}	= delete $args->{'-addFields'}; 		# add user defined fields to DialogBox
	$obj->{balloon}		= delete $args->{'-balloon'}; 			# add user defined fields to DialogBox

	$obj->{ status } = '';

	$obj->SUPER::Populate($args);

	$obj->ConfigSpecs(
        -editRecord   	=> [qw/METHOD  editRecord      EditRecord/,   undef ],
        -deleRecord	=> [qw/METHOD  deleRecord      DeleRecord/,   undef ],
        -newRecord	=> [qw/METHOD  newRecord       NewRecord/,    undef ],
        -dsplRecord	=> [qw/METHOD  dsplRecord      DsplRecord/,   undef ],
        -cancel		=> [qw/METHOD  cancel          Cancel/,       undef ],
        -Table_is_Change=> [qw/METHOD  Table_is_Change Table_IS_Change/,	undef ],
	);

	# Superoptions
	$obj->optionAdd("*tearOff", "false");

	# Bitmap Stuff
	$obj->load_pics;

	# Balloon
	$obj->{BAL} = $obj->Balloon();

	Tk::FBox->import('as_default');
} # end Populate


# Class private methods;
# ------------------------------------------
sub getFields {
# ------------------------------------------
	my $obj = shift or return warn("No object");
	my $table = $obj->{table};

	my $sth = $obj->{dbh}->prepare("select * from $table limit 0,0");
	$sth->execute();
	my $field_names = $sth->{'NAME'};

	return $field_names;
}


# ------------------------------------------
sub SaveToDB {
# ------------------------------------------
	my $obj 	= shift or return warn("No object");
	my $save	= shift or return warn("No Data!");
	my $id		= shift;
	my $opt		= shift;

	my $dbh 	= $obj->{dbh};
	my $table	= $obj->{table};
	my $fieldtypes = $obj->getFieldTypes()
		or return $obj->error('What!! No Fieldtypes???');
	my ($sql);

	my( @names, @values );
	foreach my $name (sort keys %$save) {
		next if($name eq 'TYPUSXPIX');
		next if(defined $obj->{addFields}->{$name});

		# Test auf Required
		if( ! $save->{$name} && $obj->{required}->{$name} ) {
			$obj->error("<${name}> is a required field!");
			return;
	        }


		# Tests vom User
		if(defined $obj->{test_cb}->{$name} and ref $obj->{test_cb}->{$name} eq 'CODE') {
			my $erg = &{$obj->{test_cb}->{$name}}($save, $name);
			if($erg && $erg eq 'NOMESSAGE') {
				return $erg;
			} elsif($erg) {
				return $obj->error($erg);
			}
		}

		if(defined $obj->{alternateTypes}->{$name}->{type} && $obj->{alternateTypes}->{$name}->{type} eq 'password') {
			push(@names, "$name = PASSWORD(?)") if( $save->{$name} );
			push(@values, $save->{$name}) 	    if( $save->{$name} );
		} elsif($name =~ /INET_NTOA\((.+?)\)/i) {
			push(@names, "$1 = INET_ATON(?)");
			push(@values, $save->{$name});
		} elsif($fieldtypes->{$name}->{Type} =~ /(date|time)/i) {
			push(@names, "$name = FROM_UNIXTIME(?)");
			push(@values, $save->{$name});
		} elsif($fieldtypes->{$name}->{Type} =~ /(\d+).+?zerofill/i) {
			push(@names, "$name = ?");
			my $val = sprintf("%0${1}d", ($save->{$name} || $id));
			push(@values, $val);
		} else {
			push(@names, "$name = ?");
			push(@values, $save->{$name});
		}
	}


	if(defined $save->{TYPUSXPIX} && $save->{TYPUSXPIX} eq 'update') {
		# keys?
		my $keys = $obj->get_keys();
		$id =~ s/\#/\\#/sig;
		my @ids	 = split(/[^0-9a-zA-Z\ ]/, $id);
		# select a record
		my $where = 'WHERE ';
		my $c = 0;
		foreach my $value (@ids) {
			$where .= sprintf("%s = '%s' ",
						$keys->[$c],
						$value);
			$c++;
			$where .= 'AND '
				if($c < scalar @ids);
		}

		$sql = sprintf('UPDATE %s SET %s %s',
				$table,
				join(',', @names),
				$where,
			);
	} elsif($save->{TYPUSXPIX} eq 'insert') {
		$sql = sprintf('REPLACE %s SET %s',
				$table,
				join(',', @names),
			);
	}



	my $erg;
	if(defined $opt->{NOSAVE}) {
		return 1;
	} else {
		$obj->debug($sql.' Fields: '.join(', ', @values));
		$erg = $dbh->do($sql, 0, @values);
	}

	unless($erg) {
		$obj->error($DBI::errstr);
		return;
	} else {
		$obj->{Last_Insert_Id} = $dbh->{'mysql_insertid'}
			if($save->{TYPUSXPIX} eq 'insert');
		$obj->{Last_Edit_Id} = $id
			if($save->{TYPUSXPIX} eq 'update');
		return $erg;
	}
}

# ------------------------------------------
sub getFieldTypes {
# ------------------------------------------
	my $obj 	= shift or return warn("No object");
	my $dbh 	= $obj->{dbh};
	my $table	= $obj->{table};

	return $obj->{$table}->{fieldtypes}
		if(defined $obj->{$table}->{fieldtypes});


	my $ret = $dbh->selectall_hashref("show fields from $table", 'Field')
		or return $obj->debug($dbh->errstr);

	$obj->{$table}->{fieldtypes} = $ret;
	return $ret;
}

# ------------------------------------------
sub Table_is_Change {
# ------------------------------------------
	my $obj 	= shift or return warn("No object");
	my $lasttime	= shift || 1;	# No last time, first request!
	my $table	= shift || $obj->{table};

	my $dbh 	= $obj->{dbh};
	my $ret = 0;

	my $data = $dbh->selectall_hashref(sprintf("SHOW TABLE STATUS LIKE '%s'", $table),'Name')
		or return $obj->debug($dbh->errstr);

	my $unixtime = $obj->getSqlArray(sprintf("select UNIX_TIMESTAMP('%s')", $data->{$table}->{Update_time}));

	if($unixtime->[0][0] > $lasttime) {
		return 1;
	}
}

# ------------------------------------------
sub _readonly_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save, $feldtyp) = @_;
	$save->{$name} = $obj->{readonly}->{$name} || $value;
	my $text = (defined $value && $save->{$name} ne $value
					?  sprintf('%s [%s]', $save->{$name}, (defined $value ? $value : '-'))
					:  $save->{$name});

	$text = localtime($save->{$name}) 
		if($feldtyp =~ /(time|date|timestamp)/i);

	if(length($text) > 50) {
		my $entry = $dialog->Scrolled(qw/ROText -wrap word -scrollbars osoe -width 50 -height 10/);
                $entry->insert("end", $text);
		return $entry;
	} else {
		my $entry = $dialog->Label(
				-text => $text
				);
		return $entry;
	}
}

# ------------------------------------------
sub _link_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;
	my ($n,$list);
	my $options;
	if( $obj->Table_is_Change($obj->{'link'}->{$name}->{last_refresh}, $obj->{'link'}->{$name}->{table}) ) {
		$obj->{'link'}->{$name}->{options} = $options = $obj->getSqlArray(
			sprintf("select (%s + 0), %s from %s %s order by %s",
				$obj->{'link'}->{$name}->{id},
				$obj->{'link'}->{$name}->{display},
				$obj->{'link'}->{$name}->{table},
				$obj->{'link'}->{$name}->{where} || '',
				$obj->{'link'}->{$name}->{display},
			)
		);
		$obj->{'link'}->{$name}->{last_refresh} = time;
	} else {
		$options = $obj->{'link'}->{$name}->{options}
	}
	my $entry = $dialog->JBrowseEntry(
		-width => 20,
		-variable  => \$n,
		-browsecmd => sub { $save->{$name} = (defined $n and exists $list->{$n} ? $list->{$n} : $n) },
	);

	$entry->insert( "end", '' );
	foreach my $z ( @$options ) {
		$list->{ $z->[1] } = $z->[0];
		$n = $z->[1]
		  if ( defined $value && $z->[0] == $value );
		$entry->insert( "end", $z->[1] );
	}

	if(defined $obj->{validate_cb}->{$name} and ref $obj->{validate_cb}->{$name} eq 'CODE') {
		$entry->Subwidget("entry")->configure(
			validate => 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}}, $entry, $save, $options ],
		);
	}elsif(defined $obj->{validate_cb}->{$name}->{'-callback'} ) {
		$entry->Subwidget("entry")->configure(
			validate => $obj->{validate_cb}->{$name}->{'-event'} || 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}->{'-callback'}}, $entry, $save ],
		);
	}

	$save->{$name} = (defined $n and defined $list->{$n} ? $list->{$n} : $n);
	$save->{$name} = $n = $value unless($n and $value);
	return $entry;
}

# ------------------------------------------
sub _time_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save, $feldtyp) = @_;

	if(uc($value) eq 'NOW' || uc($save->{$name}) eq 'NOW') {
		$save->{$name} = time;
	} elsif($value) {
		$value = $obj->{dbh}->quote($value);
		my $time = $obj->getSqlArray("select UNIX_TIMESTAMP($value)");
		$save->{$name} = $time->[0][0];
	}
	my $entry = $dialog->Date(
		-fields => ( $feldtyp eq 'date' ? 'date' : 'both' ),
		-variable => \$save->{$name},
	);
	$obj->debug("Time: ".$save->{$name});
	return $entry;
}

# ------------------------------------------
sub _choice_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save, $label) = @_;

	my $mode = $1;
	my $options = $2;

	$options =~ s/\'//sig;
	my @list = sort split ( ',', $options );
	my $z    = -1;
	my $entry;
	$save->{$name} = $value;
	if( $mode eq 'enum' ) {
		$entry = $dialog->JBrowseEntry(
			-width	   => 20,
			-state     => 'readonly',
			-variable  => \$save->{$name},
			-choices   => \@list,
		);

		return $entry;
	} elsif($mode eq 'set') {
		foreach my $e (@list) {
			$e =~ s/'//sig;
			push (
				@{ $save->{$name} },
				( defined $e && $value =~ /$e/ ? $e : undef )
			);
			$entry = $dialog->Checkbutton(
				variable => \$save->{$name}->[$z],
				text     => ucfirst($e),
				onvalue  => $e,
				offvalue => 0,
			);
			$label->grid( $entry, -sticky => 'nw' );
		}
	}
}

# ------------------------------------------
sub _decimal_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;

	$save->{$name} = $value;
	my $entry = $dialog->Entry(
		-textvariable => \$save->{$name},
	);

	if(defined $obj->{validate_cb}->{$name} and ref $obj->{validate_cb}->{$name} eq 'CODE') {
		$entry->configure(
			validate => 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}}, $entry, $save ], # Input is follow!
		);
	} elsif(defined $obj->{validate_cb}->{$name}->{'-callback'} ) {
		$entry->configure(
			validate => $obj->{validate_cb}->{$name}->{'-event'} || 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}->{'-callback'}}, $entry, $save ],
		);
	}

	return $entry;
}

# ------------------------------------------
sub _integer_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;

	$save->{$name} = $value;
	my $entry = $dialog->NumEntry(
		-textvariable => \$save->{$name},
	);

	if(defined $obj->{validate_cb}->{$name} and ref $obj->{validate_cb}->{$name} eq 'CODE') {
		$entry->configure(
			validate => 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}}, $entry, $save ], # Input is follow!
		);
	} elsif(defined $obj->{validate_cb}->{$name}->{'-callback'} ) {
		$entry->configure(
			validate => $obj->{validate_cb}->{$name}->{'-event'} || 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}->{'-callback'}}, $entry, $save ],
		);
	}


	return $entry;
}

# ------------------------------------------
sub _password_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;

	$save->{$name} = '';
	my $entry = $dialog->Entry(
		-textvariable => \$save->{$name},
		-show         => '*',
	);

	if(defined $obj->{validate_cb}->{$name} and ref $obj->{validate_cb}->{$name} eq 'CODE') {
		$entry->configure(
			validate => 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}}, $entry, $save ], # Input is follow!
		);
	} elsif(defined $obj->{validate_cb}->{$name}->{'-callback'} ) {
		$entry->configure(
			validate => $obj->{validate_cb}->{$name}->{'-event'} || 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}->{'-callback'}}, $entry, $save ],
		);
	}

	return $entry;
}


# ------------------------------------------
sub _file_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;

	$save->{$name} = $value;
	my $frame = $dialog->Frame(
	);
	my $entry = $frame->Entry(
		-textvariable => \$save->{$name},
		-state => 'disabled',
	)->pack(-side => 'left');
	my $button = $frame->Button(
		-image => $obj->{icons}->{icon_openfile},
		-command => sub{
			my $file;
			my $old_file = $save->{$name};
			$save->{$name} = $file if($file = $obj->getOpenFile(-initialdir => $obj->{alternateTypes}->{directory}));
			if(defined $obj->{validate_cb}->{$name} and ref $obj->{validate_cb}->{$name} eq 'CODE') {
				&{$obj->{validate_cb}->{$name}}($entry, $save, $old_file), # Input is follow!
			}
		},
	)->pack(-side => 'left');


	return $frame;
}

# ------------------------------------------
sub _mimetype_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;
	my $mimes = $obj->mimetypes();
	my @mime_names = sort keys %$mimes;

	$save->{$name} = $value;
	my $entry = $dialog->JBrowseEntry(
		-width	   => 20,
		-state     => 'readonly',
		-variable  => \$save->{$name},
		-choices   => \@mime_names,
	);

	return $entry;
}

# ------------------------------------------
sub _string_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;

	$save->{$name} = $value;
	my $entry = $dialog->Entry(
		-textvariable => \$save->{$name},
	);

	if(defined $obj->{validate_cb}->{$name} and ref $obj->{validate_cb}->{$name} eq 'CODE') {
		$entry->configure(
			validate => 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}}, $entry, $save ],
		);
	} elsif(defined $obj->{validate_cb}->{$name}->{'-callback'} ) {
		$entry->configure(
			validate => $obj->{validate_cb}->{$name}->{'-event'} || 'all',
			validatecommand => [ \&{$obj->{validate_cb}->{$name}->{'-callback'}}, $entry, $save ],
		);
	}

	return $entry;
}

# ------------------------------------------
sub _text_widget {
# ------------------------------------------
	my ( $obj, $dialog, $name, $value, $save) = @_;

	$save->{$name} = $value;
	my $entry = $dialog->Scrolled('Text',
		-scrollbars => 'osoe',
		-width => 20,
		-height => 5,
	);

	$entry->insert('end', $value);

	# Register no variables Widget
	$obj->{gets}->{$name} = sub {
			$save->{$name} = $entry->get('1.0', 'end');
			$save->{$name} =~ s/\n+$//s;
		};

	# Register Callback
	if(defined $obj->{validate_cb}->{$name} and ref $obj->{validate_cb}->{$name} eq 'CODE') {
		$entry->bind('<Any-KeyPress>',  sub{
			&{$obj->{gets}->{$name}};
			&{$obj->{validate_cb}->{$name}}($entry, $save);
		});
	} 
	

	return $entry;
}


# ------------------------------------------
sub makeForm {
# ------------------------------------------
	my ( $obj, $main, $erg, $typ, $opt ) = @_;
	my ( $save, $pic );
	my $rows   = $erg;
	$save->{TYPUSXPIX} = (grep(/\S+/, @$rows) ? 'update' : 'insert');
	my $fields = (defined $obj->{$save->{TYPUSXPIX}} ? $obj->{$save->{TYPUSXPIX}} : $obj->getFields);
	my $fieldtypes = $obj->getFieldTypes()
		or $obj->debug('What!! No Fieldtypes???');


	my $dialog = $main->Frame(
	)->pack( -fill => 'both', expand => 1 );

	if(defined $obj->{addFields}) {
		foreach my $name (sort keys %{$obj->{addFields}}) {
			push(@$fields, $name);
			$fieldtypes->{$name}->{Type} = $obj->{addFields}->{$name}->{type}
				or return error('I need a field type in addFields!');
			$fieldtypes->{$name}->{Default} = $obj->{addFields}->{$name}->{value}
				if(defined $obj->{addFields}->{$name}->{value});
		}
	}

	my $c = -1;
	my $required;
	foreach my $name (@$fields) {
		$c++;
		next if(! $c && ! $obj->{editId});

		my $namedisplay = $1 if($name =~ /AS\s+(\S+)/i);
		my $value = $rows->[0][$c] || $opt->{default}->{$name} || (defined $fieldtypes->{$name}->{Default} and $fieldtypes->{$name}->{Default} ne 'NULL' ? $fieldtypes->{$name}->{Default} : undef);
		my $feldtyp = $fieldtypes->{$name}->{Type};
		$feldtyp = $obj->{alternateTypes}->{$name}->{type}
			if(defined $obj->{alternateTypes}->{$name}->{type});
		my $NotNull = $name if($obj->{required}->{$name});
		$required = $NotNull unless($required);

		my $label = $dialog->Label(
			-fg 	 => ($NotNull ? 'red' : 'black'),
			-justify => 'left',
			-text    => ($namedisplay || $name).($NotNull ? '*' : ''),
		);

		my $image = $dialog->Label(
			-image	 => $obj->{images}->{$name},
		);


		if (defined $obj->{readonly}->{$name} || $opt->{all_readonly}) {
			$obj->{entrys}->{$name} = $obj->_readonly_widget($dialog, $name, $value, $save, $feldtyp);
		} elsif ( defined $obj->{'link'}->{$name} ) {
			$obj->{entrys}->{$name} = $obj->_link_widget($dialog, $name, $value, $save);
		} elsif ( $feldtyp =~ /(time|date|timestamp)/i ) {
			$obj->{entrys}->{$name} = $obj->_time_widget($dialog, $name, $value, $save, $feldtyp);
		} elsif ( $feldtyp =~ /^(enum|set)\((.+)\)/i ) {
			$obj->{entrys}->{$name} = $obj->_choice_widget($dialog, $name, $value, $save, $label);
		} elsif ( $feldtyp =~ /(int|float|double|real|numeric)/i ) {
			$obj->{entrys}->{$name} = $obj->_integer_widget($dialog, $name, $value, $save);
		} elsif ( $feldtyp =~ /decimal/i ) {
			$obj->{entrys}->{$name} = $obj->_decimal_widget($dialog, $name, $value, $save);
		} elsif ( $feldtyp =~ /text/i ) {
			$obj->{entrys}->{$name} = $obj->_text_widget($dialog, $name, $value, $save);
		} elsif ( $feldtyp eq 'file' ) { # SPEZIAL TYPES
			$obj->{entrys}->{$name} = $obj->_file_widget($dialog, $name, $value, $save);
		} elsif ( $feldtyp eq 'password' ) {
			$obj->{entrys}->{$name} = $obj->_password_widget($dialog, $name, $value, $save);
		} elsif ( $feldtyp eq 'mimetype' ) {
			$obj->{entrys}->{$name} = $obj->_mimetype_widget($dialog, $name, $value, $save);
		} else {
			$obj->{entrys}->{$name} = $obj->_string_widget($dialog, $name, $value, $save);
		}
		$obj->Advertise(sprintf('wi_%s', $name) => $obj->{entrys}->{$name});

		$obj->{BAL}->attach( 
			$obj->{entrys}->{$name}, 
			-balloonmsg => $obj->{balloon}->{$name} 
		) if(defined $obj->{balloon}->{$name}); 

		$label->grid( $image, $obj->{entrys}->{$name}, -sticky => 'nw' );
	}

	$dialog->Label(
		-fg 	 	=> 'red',
		-justify 	=> 'left',
		-textvariable   => \$obj->{ status },
	)->grid(-sticky => 'nw', -columnspan => 2);

	return $save;
}

# ------------------------------------------
sub cancel {
# ------------------------------------------
	my $obj = shift || warn "Kein Objekt!";

	$obj->{dialog}->Subwidget('B_Cancel')->invoke
		if(defined $obj->{dialog} && defined $obj->{dialog}->Subwidget('B_Cancel'));
	$obj->{dialog}->Subwidget('B_Ok')->invoke
		if(defined $obj->{dialog} && defined $obj->{dialog}->Subwidget('B_Ok'));
}


# ------------------------------------------
sub deleRecord {
# ------------------------------------------
	my $obj = shift || warn "Kein Objekt!";
	my $id = shift;
	my $nowarn = shift || 0;
	my $idx = $obj->{update}->[0] || $obj->{insert}->[0];
	my $table = $obj->{table};

	return "Sorry, no id to delete"
		unless($id);

	my $answer = $obj->messageBox(
		-message => 'Are you sure?',
		-title => "Delete Row from ".$table,
		-type => 'okcancel',
		-default => 'cancel')
			unless($nowarn);

	$obj->type('delete');

	if ( (defined $answer and $answer =~ /ok/i) || $nowarn) {
		my $info;
		my $sql = sprintf("DELETE FROM %s WHERE %s = '%s'",
					$table,
					$idx,
					$id);
		$obj->debug($sql);
		$info = $obj->{dbh}->do($sql)
			or return $obj->{dbh}->error();
	}
	1;
}

# ------------------------------------------
sub newRecord {
# ------------------------------------------
	my $obj = shift || warn "Kein Objekt!";
	my $options = shift;
	delete $obj->{Last_Insert_Id};
	$obj->editRecord(0, $options);
}

# ------------------------------------------
sub dsplRecord {
# ------------------------------------------
	my $obj = shift || warn "Kein Objekt!";
	my $id = shift;
	my $options =
	$obj->editRecord($id, {
		all_readonly => 1,
		} );
}


# ------------------------------------------
sub editRecord {
# ------------------------------------------
	my $obj = shift || warn "Kein Objekt!";
	my $id = shift;
	my $opt = shift;
	$obj->Busy;
	delete $obj->{Last_Edit_Id};
	
	$obj->type( $id ? 'update' : 'insert');

	my $key;
	if($id and $obj->type() eq 'update') {
		$key = sprintf('xpix_%s_%s', $obj->{table}, $id);
		if(defined $obj->{windows}->{$key}) {
			$obj->{windows}->{$key}->raise();
			return;
		}
		$obj->get_lock($key)
			|| return $obj->messageBox(
				-message => sprintf("Sorry, but this id <%s> is locked! Please try again later.", $id),
				-type => 'Ok');
	}

	my $sql = $obj->makeSql($id);
	my $erg = $obj->getSqlArray($sql);
	my $save = {};


	my @buttons;
	if($opt->{all_readonly}) {
		push(@buttons, 'Ok');
	} else {
                push(@buttons, ($id ? 'Save' : 'Insert'));
	}
	if(defined $obj->{addButtons}) {
		foreach my $bname (sort keys %{$obj->{addButtons}}) {
			push(@buttons, $bname)
				if(ref $obj->{addButtons}->{$bname} eq 'CODE' or grep(/$obj->{TYPE}/i, @{$obj->{addButtons}->{$bname}->{'-type'}}));
		}
	}
	push(@buttons, 'Cancel')
		unless($opt->{all_readonly});

	my $title = ($opt->{all_readonly} ? 'Display' : ($id ? 'Save' : 'Insert'))." Record ".$obj->{table};
	$title = sprintf("Insert Range from %s to %s", $opt->{range_from}, $opt->{range_until})
		if(defined $opt->{range_until} && $opt->{range_until});

	my $dialog;
	$dialog = $obj->XDialogBox(
		-title          => $title,
		-buttons        => \@buttons,
		-default_button => ($opt->{all_readonly} ? 'Ok' : ($id ? 'Save' : 'Insert')),
		-cancel_callback => sub{
				if($key) {
					$obj->release_lock($key);
					delete $obj->{windows}->{$key} if($key);;
				}
			},
		-check_callback => sub {
			my $answer = shift;
			if ( $answer eq 'Save' or $answer eq 'Insert') {
				foreach my $sub (keys %{$obj->{gets}}) {
					&{$obj->{gets}->{$sub}};
				}

				# Range
				if(defined $opt->{range_until} && $opt->{range_until}) {
					foreach my $nummer (($opt->{range_from}..$opt->{range_until})) {
						$obj->{info} = $obj->SaveToDB( $save, $nummer, $opt );
					}
				} elsif(defined $opt->{list} && scalar @{$opt->{list}}) {
					foreach my $nummer (@{$opt->{list}}) {
						$obj->{info} = $obj->SaveToDB( $save, $nummer, $opt );
					}
				} else {
					$obj->{info} = $obj->SaveToDB( $save, $id, $opt );
				}

				if(defined $obj->{info} and $obj->{info} eq 'NOMESSAGE') {
					return undef;		# Zurueck ohne Fehlermeldung
				} elsif($obj->{info}) {
					return $obj->{info};	# Zurueck
				} else {	   # Zurueck mit Fehlermeldung
					$obj->{status} = sprintf("Error: %s", $obj->error);
					return undef;
				}
			} elsif($answer eq 'Cancel' and defined $obj->{cancel_cb} and ref $obj->{cancel_cb} eq 'CODE') {
				&{$obj->{cancel_cb}}($save);
				return 'CANCEL';
			}
			return 1;
		},
	);
	$obj->{windows}->{$key} = $dialog if($key);
	$obj->{dialog} = $dialog;
	$dialog->resizable(0,0);

	$obj->{SAVE} = $save = $obj->makeForm( $dialog, $erg, 'edit', $opt );

	foreach my $button (@buttons) {
		if(ref $obj->{addButtons}->{$button} eq 'CODE') {
			$dialog->Subwidget(sprintf('B_%s', $button))->configure(
				-command => [\&{$obj->{addButtons}->{$button}}, $save, $id],
				);
		} elsif(defined $obj->{addButtons}->{$button}->{'-callback'} and ref $obj->{addButtons}->{$button}->{'-callback'} eq 'CODE') {
			$dialog->Subwidget(sprintf('B_%s', $button))->configure(
				-command => [\&{$obj->{addButtons}->{$button}->{'-callback'} }, $save, $id],
				);
		}
	}

	$dialog->Focus( $obj->{entrys}->{$opt->{FOCUS}} )
		if (defined $opt->{FOCUS} and defined $obj->{entrys}->{$opt->{FOCUS}});

	foreach my $event ( keys %{$obj->{events}} ) {
		$dialog->bind( $event => $obj->{events}->{$event} )
			if(ref $obj->{events}->{$event} eq 'CODE');
	}
	$dialog->bind('<Return>' => sub{});
	$dialog->update();
	$obj->Unbusy;

	my $answer = $dialog->Show(-nograb);

	if($key) {
		$obj->release_lock($key);
		delete $obj->{windows}->{$key} if($key);
	}
	return $answer;
}

# ------------------------------------------
sub type {
# ------------------------------------------
	my $obj = shift;
	my $typ = shift;
	if(defined $typ) {
		$obj->{TYPE} = $typ;
	}
	return $obj->{TYPE};
}


# ------------------------------------------
sub makeSql {
# ------------------------------------------
	my $obj = shift or warn("No object");
	my $id = shift;
	my $table = $obj->{table};
	my $fields = (defined $id && $id ? ( $obj->{update} || $obj->{insert} || $obj->getFields) : ($obj->{insert} || $obj->getFields) );
	my ($where, $limit, $order, $whereid);

	unless($id) {
	        # Limit
	        if ($obj->{limit}) {
			$limit = sprintf("LIMIT %d, %d", $obj->{offset}, $obj->{limit} + 1);
		}

	        # Order
	        if ($obj->{order}) {
			$order = sprintf("ORDER BY %s %s",
					join(',', @{$obj->{order}}),
					$obj->{order_right});
		}

		# Where
	        if ($obj->{where}) {
			$where .= sprintf("WHERE %s %s",
					join(' AND ', @{$obj->{where}}));
		}

		# Statement für insert
		if(defined $id && $id == 0) {
			$where .= sprintf("%s (1 = 0)",
					($obj->{where} ? ' AND ' : ' WHERE ')
					);
		}

		# Search
	        if ($obj->{search_txt}) {
			$where .= sprintf("%s %s LIKE '%%%s%%'",
					($obj->{where} ? ' AND ' : ' WHERE '),
					($obj->{search_row} eq 'AssignedAddr' ? 'INET_NTOA(AssignedAddr)' : $obj->{search_row}), #XXX hier noch was einfallen lassen
					$obj->{search_txt},
					);
		}

		# Timerange
	        if ($obj->{search_time_to} && $obj->{search_time_from} && $obj->{search_with_time}) {
			my @timerange;
			foreach my $timefield (@{$obj->{timefields}}) {
				push(@timerange, sprintf(
						'(%s BETWEEN FROM_UNIXTIME(%d) AND FROM_UNIXTIME(%d))',
						$timefield,
						$obj->{search_time_from},
						$obj->{search_time_to}
						)
					);
			}
			$where .= sprintf("%s (%s)",
					( $obj->{where} || ( $obj->{search_txt} && $obj->{search_row} ) ? ' AND ' : ' WHERE '),
					join(' OR ', @timerange));
		}


	} else {
		# keys?
		my $keys = $obj->get_keys();
		$id =~ s/\#/\\#/sig;
		my @ids	 = split(/[^0-9a-zA-Z\ ]/, $id);
		# select a record
		$where 	 = 'WHERE ';
		my $c = 0;
		foreach my $value (@ids) {
			$where .= sprintf("%s LIKE '%s%%' ",
						$keys->[$c],
						$value);
			$c++;
			$where .= 'AND '
				if($c < scalar @ids);
		}

	}

	my $retsql = sprintf("SELECT %s from %s %s %s %s",
			( join(',', @$fields) || '*' ),
			$table,
			(defined $where ? $where : ''),
			(defined $order ? $order : ''),
			(defined $limit ? $limit : ''),
			);
	$obj->debug($retsql);
	return $retsql;
}


# ------------------------------------------
sub getSqlArray {
# ------------------------------------------
	my $obj = shift or croak("No object");
	my $sql = shift or $obj->{sql} or warn 'No Sql';
	my $dbh = $obj->{dbh};

	my $sth = $dbh->prepare($sql) or warn("$DBI::errstr - $sql");
	$sth->execute or warn("$DBI::errstr - $sql");
	return $sth->fetchall_arrayref;
}

# ------------------------------------------
sub get_keys {
# ------------------------------------------
	my $obj = shift;
	my $fields = $obj->getSqlArray(sprintf('show fields from %s', $obj->{table}));
	my $ret;
	foreach my $f (@{$fields}) {
		push(@$ret, $f->[0]) if($f->[3]);
	}
	return $ret;
}

# ------------------------------------------
sub get_lock {
# ------------------------------------------
	my $obj = shift;
	my $key = sprintf(shift, @_);

	my $erg = $obj->getSqlArray(sprintf 'SELECT GET_LOCK("%s", %d)', $key, $obj->{lock});
	return $erg->[0][0];
}

# ------------------------------------------
sub release_lock {
# ------------------------------------------
	my $obj = shift;
	my $key = sprintf(shift, @_);
	my $erg = $obj->getSqlArray(sprintf 'SELECT RELEASE_LOCK("%s")', $key);
	return $erg->[0][0];
}


# ------------------------------------------
sub debug {
# ------------------------------------------
	my $obj = shift;
	my $msg = shift || return;
	return unless $obj->{debug};
	printf("Tk::Form: %s\n", $msg);
}

# ------------------------------------------
sub error {
# ------------------------------------------
	my $obj = shift;
	my $msg = shift;
	$obj->bell;
	unless($msg) {
		my $err = $obj->{error};
		$obj->{error} = '';
		return $err;
	}
	$obj->{error} = sprintf($msg, @_);
	return undef;
}

# ------------------------------------------
sub qsure {
# ------------------------------------------
	my ( $w, $question ) = @_;
	my $a = $w->messageBox(
		-message => $question,
		-title   => "Sure?",
		-type    => 'okcancel',
		-default => 'ok',
	);
	return 1 if ( $a =~ /Ok/i );
}

# ------------------------------------------
sub mimetypes {
# ------------------------------------------
	my $obj = shift or return warn("No object");
	my $mime;
	my $types = qq|
application/mac-binhex40        hqx
application/mac-compactpro      cpt
application/msword              doc
application/octet-stream        bin dms lha lzh exe class so dll
application/oda                 oda
application/pdf                 pdf
application/postscript          ai eps ps
application/smil                smi smil
application/vnd.mif             mif
application/vnd.ms-excel        xls
application/vnd.ms-powerpoint   ppt
application/vnd.wap.wbxml       wbxml
application/vnd.wap.wmlc        wmlc
application/vnd.wap.wmlscriptc  wmlsc
application/x-bcpio             bcpio
application/x-cdlink            vcd
application/x-chess-pgn         pgn
application/x-cpio              cpio
application/x-csh               csh
application/x-director          dcr dir dxr
application/x-dvi               dvi
application/x-futuresplash      spl
application/x-gtar              gtar
application/x-hdf               hdf
application/x-javascript        js
application/x-koan              skp skd skt skm
application/x-latex             latex
application/x-netcdf            nc cdf
application/x-sh                sh
application/x-shar              shar
application/x-shockwave-flash   swf
application/x-stuffit           sit
application/x-sv4cpio           sv4cpio
application/x-sv4crc            sv4crc
application/x-tar               tar
application/x-tcl               tcl
application/x-tex               tex
application/x-texinfo           texinfo texi
application/x-troff             t tr roff
application/x-troff-man         man
application/x-troff-me          me
application/x-troff-ms          ms
application/x-ustar             ustar
application/x-wais-source       src
application/zip                 zip
audio/basic                     au snd
audio/midi                      mid midi kar
audio/mpeg                      mpga mp2 mp3
audio/x-aiff                    aif aiff aifc
audio/x-mpegurl                 m3u
audio/x-pn-realaudio            ram rm
audio/x-pn-realaudio-plugin     rpm
audio/x-realaudio               ra
audio/x-wav                     wav
chemical/x-pdb                  pdb
chemical/x-xyz                  xyz
image/bmp                       bmp
image/gif                       gif
image/ief                       ief
image/jpeg                      jpeg jpg jpe
image/png                       png
image/tiff                      tiff tif
image/vnd.wap.wbmp              wbmp
image/x-cmu-raster              ras
image/x-portable-anymap         pnm
image/x-portable-bitmap         pbm
image/x-portable-graymap        pgm
image/x-portable-pixmap         ppm
image/x-rgb                     rgb
image/x-xbitmap                 xbm
image/x-xpixmap                 xpm
image/x-xwindowdump             xwd
model/iges                      igs iges
model/mesh                      msh mesh silo
model/vrml                      wrl vrml
text/css                        css
text/html                       html htm
text/plain                      asc txt
text/richtext                   rtx
text/rtf                        rtf
text/sgml                       sgml sgm
text/tab-separated-values       tsv
text/vnd.wap.wml                wml
text/vnd.wap.wmlscript          wmls
text/x-setext                   etx
text/xml                        xml xsl
video/mpeg                      mpeg mpg mpe
video/quicktime                 qt mov
video/vnd.mpegurl               mxu
video/x-msvideo                 avi
video/x-sgi-movie               movie
x-conference/x-cooltalk         ice
|;

	foreach my $t (split(/\n/, $types)) {
		my @row = split(/\s+/, $t);
		my $name = shift @row;
		$mime->{$name} = \@row
			if(defined $name);
		foreach my $endung ( @row ) {
			$obj->{mime}->{$endung} = $name; 
		}
	}
	return $mime
}


# ------------------------------------------
sub load_pics {
# ------------------------------------------
	my $obj = shift or return warn("No object");
	my %pics;
	my $data;

        $data        = <<"--EOD--";
R0lGODlhDwAPAIAAAP///0NdjSH5BAAAAAAALAAAAAAPAA8AAAIgjI+pu+BuADsy1GYjqxzrnFyI
CCoiOU6hmlLP+7DyVAAAOw==
--EOD--
	$obj->{icons}->{icon_openfile} = $obj->Photo(-data => $data);

	return %pics;
}


1;

__END__


=head1 NAME

Tk::DBI::Form - Megawidget to offering edit, delete or insert a record.

=head1 SYNOPSIS

	my $mw = MainWindow->new;
	my $tkdbi = $mw->DBIForm(
		-dbh   		=> $dbh,
		-table  	=> 'Inventory',
		-editId		=> 'yes',
		-readonly => {
			changed_by => 'xpix',
			created => 'NOW',
			...
			},
		-required => {
			name => 1,
			state => 1,
			owner => 1,
			...
			},
		-test_cb => {
			type_id => sub{
				my ($save, $name) = @_;
				if($save->{type_id} and $save->{type_id} !~ /^\d+$/) {
					$dbh->do(sprintf("INSERT INTO Type (name) VALUES ('%s')", $save->{type_id}));
					$save->{type_id} = $dbh->{'mysql_insertid'};
				}
				return undef; # Alles ok!
			},
			...
		},
		-link => {
			type_id => {
				table 	=> 'Type',
				display	=> 'name',
				id	=> 'id',
			},
			...
		},
		-validate_cb => {
			serial_no => sub {
				my ($entry, $save, $input) = @_;
				$save->{id} = 0 unless(defined $save->{id});
				$entry->configure(
					-bg => ( exists $SERIAL->{$input} ? 'red' : 'green' ),
					-fg => ( exists $SERIAL->{$input} ? 'white' : 'black' ),
					 );
				return 1 ;
			},
			...
		},
		-images => {
			id 	  => $pics{F1},
			parent_id => $pics{F2},
			...
		},
		-balloon => {
			id 	  => 'This the a unique id.',
			parent_id => 'A parent_id, in other words the father.',
			...
		},
		-events => {
			'<KeyRelease-F1>' => sub {
					$DBIFORM->{entrys}->{id}->focus;
			},
			...
		},
		-addButtons => {
			Logs => {
				-type => ['update'],
				-callback => sub{
					my ($save, $name) = @_;
					&launch_browser_log($save->{id});
				},
			},
			...,
		},
		-alternateTypes => {
			filename => {
				type => 'file',
				directory => $DOCUPATH,
			},
			...
		},

		-debug => 1,
	);

	my $ok = $tkdbi->editRecord($row->{id});


=head1 DESCRIPTION

Tk::DBI::Form is a Megawidget offering edit, delete or insert operations for table records.
At this time if this widget only compatible to MySQL Database.

=head1 OPTIONS

=head2 -dbh

The database handle to get the information from the Database.

=head2 -table

Name of the table you intend to modify records from.

=head2 -debug => 1

Switch the debug output to the standart console on.

=head2 -lock => $timeout_in_seconds

This widget have a locking mechanism. The I<timeout> is default 0 and will wait of unlock the row in seconds.
If try a client edit a row in the same table and a other client have this open to update this row with
the same widget, then have the first client a error Message:

	Sorry, but this id <%s> is locked! Please try again later.

=head2 -edit_id => 1

This allows to edit the ID-Number on the form, this is normaly a unique and autoincrement Field for each column.

=head2 -update => [qw(id col1 col2 ...)]

List of fields that are granted update priviliges on. Only these fields are visible on the Update Form

=head2 -insert => [qw(id col1 col2 ...)]

List of fields that are granted insert priviliges on. Only these fields are displayed on the Insert Form.

=head2 -link => { col1 => {table => tablename, display => col2, id => idcol, where => 'WHERE col3 = 1'}, ... }

This is a special Feature for fields located in a different table than given in -table.
Often data from further tables is used, this data usually has an id number and a
description. The id number from this table is mostly in the table to edit as id number.
Here you can display the Description for this id and the user can change this choice.
I.e.:

  -link => {
	parent_id => {
		table 	=> 'Inventory',
		display	=> 'name',
		where	=> 'WHERE type_id = 1',
		id	=> 'id',
	},
	type_id => {
		table 	=> 'Type',
		display	=> 'name',
		id	=> 'id',
	},
  }

Ok, here we have two linktables. This will display a Listwidget, thes have the column 'name'
to display in this Listbox. But the form write the id in the original column.


=head2 -required => { col1 => 1, col2 = 1, ...}

Here you can mark the fields where an entry is mandatory on the Form, is case no entry will be provided,
the form will raise an error MessageBox displaying 'col1 is a required field!'.

  -required => {
	changed_by => 1,
	deadline => 1,
	Server => 1,
  }


=head2 -readonly => { col1 => 'text', col2 = number, ...}

This option will set the columns as read only. The values are displayed but the user cannot change the data

  -readonly => {
	changed_by => $USER,
	deadline => 'NOW',
	Server => $HOST,
  }


=head2 -default => { col1 => 'text', col2 = number, ...}

This option sets the default values for the listed fields that will be displayed on the form. I.e.:

  -default => {
	changed_by => $USER,
	deadline => 'NOW',
	Server => $HOST,
  }

=head2 -balloon => { col1 => 'help text', col2 = 'help text', ...}

This option will set a Ballon message for a help message. This message is display if the user move over the input.

  -balloon => {
	parent_id => 'This is a parent_id.',
  }



=head2 -addFields => { Name => {value =>'text', type => 'text'}, Name2 = {...} }

This option allow an additional Field in the form, both (value, type) Options is required.
This Field will NOT save in the database, of course ;-)
You can get the result with $tkdbi->{SAVE}->{Name} after user submit.

I.e.:

  -addFields => {
	LogEntry => {
		value => '',
		type => 'text',
	}
  },
  ...
  my $value = $tkdbi->{SAVE}->{LogEntry};


=head2 -images => { col1 => ImageObj, col2 = ImageObj, ...}

This option sets the Image Object for an icon that will be displayed next to the input or widget.

=head2 -alternateTypes => { col1 => ImageObj, col2 = ImageObj, ...}

Here you can set a alternativeType to display. I.E.:

  -alternateTypes => {
	filename => {
		type => 'file',
		directory => $DOCUPATH,
	},
	password => {
		type => 'password',
	},
	mime => {
		type => 'mimetype',
		file => '/baa/foo.pdf',
	},
  },

=over 4

=item file

This parameter results in displaying an entry and a button, the user can click on this button
and a Fileselector will pop up on the form to select the right file and path.

=item password

This will display an entry with hidden letters as stars on the form.

=item mimetypes

This will display a pulldown menu with a lot of mimetypes. you can give optional a filename or
a shorttype and the pulldownmneu will select this entry.

=back

=head2 -events => { Event => sub{}, Event => sub{}, ...}

This option lets you add your personal events. I.E.:

  -events => {
	'<KeyRelease-F1>' => sub {
			$DBIFORM->{entrys}->{id}->focus;
   },


=head2 -validate_cb => { col1 => sub{}, col2 => sub{}, ...}

Here you can add a callback to test the input from the user in realtime.
The parameter for the subroutine is the entry, save hash with data from
the Form and the input from the User. I.E.:


  serial_no => sub {
	my ($entry, $save, $input) = @_;
	$save->{id} = 0 unless(defined $save->{id});
	$entry->configure(
		-bg => ( exists $SERIAL->{$input} ? 'red' : 'green' ),
		-fg => ( exists $SERIAL->{$input} ? 'white' : 'black' ),
		 );
	return 1 ;
  },

This changes the foreground and background color of the entry if the 
serial number exists in the table. The subroutine can return a undef value, 
then the widget will igrnore this Userinput. I.e.:

  only_numbers => sub {
	my ($entry, $save, $input) = @_;
	return undef unless($input =~ /[^0-9]+/);
	return 1 ;
  },


=head2 -test_cb => { col1 => sub{}, col2 => sub{}, ...}

Here you can add a callback to test the user input AFTER submission of the form.
The parameter for the subroutine is the save hash and the name of the
field. I.E.:

  -test_cb => {
	id => sub{
		my ($save, $name) = @_;
		if($DBIFORM->type() eq 'insert' and $save->{id}) {
			my $answer = qsure($top,sprintf('You will REPLACE row <%s>?', $save->{id}));
			return 'NOMESSAGE' unless($answer);  # Back without message
		}
		return undef; # All OK ...
	},
	parent_id => sub{
		my ($save, $name) = @_;
		my $pid = sprintf('%010d', $save->{parent_id});
		unless(exists $INV->{$pid}) {
			my $msg = sprintf('Parent ID %s not exists', $pid);
			return $msg;
		}
		return undef; # All OK!
	},
  }


The first example will pop up a MessageBox if the User makes an Insert
with an id number (replace). The second example will reformat the parent_id
Number to 0000000012. If the parent_id does not exist in the Hash, an Errormessage (MessageBox)
with the returned text. 'NOMESSAGE' as
return doesnt pop up a MessageBox. Return undef, all ok.


=head2 -cancel_cb => sub{ }

Here you can add a callback when the User activates the Cancel Button.

=head2 -addButtons => { ButtonName => {-type => ['update', 'insert'], -callback => sub{} }

Here you can add a Button to the FormBox. The -type option will only
display the button in the following state (insert, update or delete).
The callback has one parameter. The save hash.  I.e.:

		-addButtons => {
			Logs => {
				-type => ['update'],
				-callback => sub{
					my ($save, $name) = @_;
					&launch_browser_log($save->{id});
				},
			},
		},

The example will display a logbrowser when the user click on the Button 'Logs'.


=head1 METHODS

=head2 dsplRecord(id);

This will only display row data.

=head2 editRecord(id);

This will display the update form with the following id number for an update.

=head2 newRecord([id]);

This will display the insert form with the following id number for a Replace operation.

  my $datahash = $DBH->selectall_hashref(select * from table where id = 12);
  delete $datahash->{id};
  $DBIFORM->newRecord(
	{
		default => $datahash,
	},
  );

Here you see a trick to copy a column, also display a insert form with the
values from column 12.

=head2 deleRecord(id);

This will display the delete form with the following id number for a delete operation.

=head2 Table_is_Change(last_time, 'tablename');

This returns true if the table was modified the last_time (seconds at epoche).

=head1 ADVERTISED WIDGETS

The Widgets in the form are advertised with 'wi_namecolumn'.

=head1 CHANGES

  $Log: Form.pm,v $
  Revision 1.15  2003/11/06 17:55:52  xpix
  ! bugfixes in refresh_id
  * not hudge load for tree

  Revision 1.14  2003/08/13 12:30:26  xpix
  * new Option addFields

  Revision 1.13  2003/07/17 14:59:53  xpix
  ! many little bugfixes

  Revision 1.12  2003/06/24 16:40:15  xpix
  * add locking mechanism

  Revision 1.11  2003/06/20 15:07:07  xpix
  ! never change a running Widget, push a var and not a ref in @values

  Revision 1.9  2003/06/05 15:32:48  xpix
  * with new Module Tk::Program
  ! unitialized values in tm2unix

  Revision 1.8  2003/05/04 23:36:50  xpix
  * add docu for dsplRecord

  Revision 1.7  2003/05/04 20:53:39  xpix
  * new method dsplRecord for only display a record

  Revision 1.6  2003/04/29 16:34:46  xpix
  * add Doku tag Changes



=head1 AUTHOR

Frank (xpix) Herrmann. <xpix@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

Tk::JBrowseEntry, Tk::XDialogBox, Tk::NumEntry, Tk::Date, Tk::LabFrame,
Tk::FBox


=cut
