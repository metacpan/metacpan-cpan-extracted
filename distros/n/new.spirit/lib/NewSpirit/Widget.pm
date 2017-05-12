package NewSpirit::Widget;

# $Id: Widget.pm,v 1.10 2002/04/08 12:17:35 joern Exp $

# abstract class for creation of HTML formular input widgets

use strict;
use Carp;
use NewSpirit;

sub new {
	my $type = shift;
	
	my ($q) = @_;
	
	return bless {
		q => $q
	}, $type;
}

#---------------------------------------------------------------------
# input_widget_factory - Generic creation of a bunch of input widgets,
#                        inside a HTML table
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->factory ( %par )
#
#	The following parameter keys are recognized:
#
#	  $read_only_href	Hash ref of form elements that are
#				read only (a HIDDEN field is generated)
#				OR scalar = 1, if all elements are read only
#	  $names_lref		List ref of FORM Names of the widgets.
#				If a name begins with a '_' character,
#				the entry will be ignored
#	  $info_href		Hash ref of hashes with widget type
#				specification (keys is $names[$i])
#				(see input_widget() for details)
#	  $data_href		Hash ref with the data, $data->{$name}
#				is the value of the field $name.
#	  $buttons		HTML Code for button row
#---------------------------------------------------------------------

sub input_widget_factory {
	my $self = shift;
	
	my %par = @_;
	
	my $read_only  = $par{read_only_href};
	my $names_lref = $par{names_lref};
	my $info_href  = $par{info_href};
	my $data_href  = $par{data_href};
	my $buttons    = $par{buttons};
	
	# first print a navigation menu, if we have more
	# than one title
	
	my $title_cnt = 0;
	my $menu_html;
	
	foreach my $name (@{$names_lref}) {
		if ( $info_href->{$name}->{type} eq 'title' ) {
			++$title_cnt;
			$menu_html .= qq{[<a href="#$name">$info_href->{$name}->{description}</a>]\n};
		}
	}
	
	if ( $title_cnt ) {
		$menu_html =
			qq{<tr><td align="right" bgcolor="$CFG::BG_COLOR">}.
			qq{$CFG::FONT<b>$menu_html</b></font></td></tr>};
	}

	print <<__HTML;
<table BORDER=0 BGCOLOR="$CFG::TABLE_FRAME_COLOR" CELLSPACING=0 CELLPADDING=1>
<tr><td>
  <table $CFG::TABLE_OPTS width="100%">
__HTML
	
	foreach my $name (@{$names_lref}) {
		my $this_is_read_only;
		if ( ref $read_only ) {
			$this_is_read_only = $read_only->{$name};
		} else {
			$this_is_read_only = $read_only;
		}
	
		$self->input_widget (
			read_only => $this_is_read_only,
			name      => $name,
			info_href => $info_href->{$name},
			data_href => $data_href
		);
	}
	
	print "</table></td></tr>\n";
	
	if ( $buttons ) {
		print "<tr><td>$buttons</td></tr>\n";

	}
	
	print "</table>\n";
}


#---------------------------------------------------------------------
# input_widget - Generic creation of a input widget
#---------------------------------------------------------------------
# SYNOPSIS:
#	$self->input_widget ( %par )
#
#	The following parameter keys are recognized:
#
#	  $read_only		Print form elements or only view
#				elements (for history restore)
#	  $name			FORM Name of the widget. If this begins
#				with a '_' character, a corresponding
#^				hidden field as generated.
#	  $info_href		Hash ref with widget type specification
#	  $data_href		Hash ref with the data, $data->{$name}
#				must be defined.
#
# DESCRIPTION:
#	This method creates a input widget. It can produce
#
#	  text fields
#	  textareas
#	  simple popups (label is identical with value)
#	  complex popups and selections lists
#	  switches (implemtented as two radio buttons)
#
#	The $info_href hash must define the key 'type', which describes
#	the type of the input widget. Valid values of the 'type'
#	field are:
#
#	  list reference	creates a popup out of the list
#				values (label is identical with value)
#	  hash reference	more complex popup/selection lists
#				  type => 'popup' | 'list',
#				  items => [ [ label, value ], ... ]
#				  selected => { value, ... }
#	  'switch'		creates a switch
#	  'textarea'		creates a textarea
#	  'text(\d+)'		creates a textfield of specified length
#	  'password(\d+)'	creates a pwd field of specified length
#	  'method'		this calls a method to create the
#				widget, the name of the method derives
#				from: property_widget_$name
#				Parameters passed to the method are:
#				$name, $info_href, $data_href
#	  'type_method'		this calls a method to recieve the
#				'type' value for this widget. The
#				recieved value is interpreted again
#				using the above stated rules.
#				E.g. use this to create dynamically loaded
#				selection lists by returning a hash
#				ref wich contains the corresponding
#				selection list definition.
#---------------------------------------------------------------------

sub input_widget {
	my $self = shift;
	
	my %par = @_;
	
	my $read_only = $par{read_only};
	my $name      = $par{name};
	my $info      = $par{info_href};
	my $data      = $par{data_href};
	
	my $q = $self->{q};

	if ( $name =~ /^_/ or $read_only ) {
		print $q->hidden (
			-name => $name,
			-default => [ $data->{$name} ]
		);
		return if $name =~ /^_/;
	}
	
	if ( $info->{type} eq 'space' ) {
		print "<tr><td colspan=2>&nbsp;</td></tr>\n";
		return;
	}

	my $table_stuff =
		qq{<tr><td \%s>$CFG::FONT<b>$info->{description}</b>}.
		qq{&nbsp;&nbsp;&nbsp;</FONT></td><td valign="top" %s>$CFG::FONT}.
		qq{<a name="$name">\n};

	my $type = $info->{type};

	# if we are advised not showing form elements, content
	# will be printed read only and the method returns

	if ( $read_only ) {
		printf ($table_stuff, 'valign="top"');
		if ( $type ne 'password' ) {
			my $value = $data->{$name};
			$value =~ s/\n/<br>/g;
			$value ||= '&nbsp;';
			print "$CFG::FONT_FIXED$value</FONT>";
		} else {
			print '*' x (length ($data->{$name})/3);
		}
		print qq{</FONT></td></tr>\n};
		return 1;
	}

	if ( $info->{type} eq 'title' ) {
		printf ($table_stuff,
			'valign="center" bgcolor="#aaaaaa"',
			'bgcolor="#aaaaaa"');
	} elsif ( $info->{type} eq 'space' ) {
		printf ($table_stuff,
			'valign="center" bgcolor="#aaaaaa"',
			'bgcolor="#aaaaaa"');
	} else {
		printf ($table_stuff, 'valign="center"', '');
	}

	# Ok, now we print the according widgets, depending
	# on the type of the field

	# as long as a $type has to be resolved
	# (recomputing is possible through 'type_method')
	
	my $js_modified = "if (document.object_was_modified) object_was_modified();";
	if ( $info->{check} ) {
		$js_modified .= "if (!($info->{check})) alert ('$info->{alert}')";
	}
	while ( $type ) {
		if ( ref $type eq 'ARRAY' ) {
			print $q->popup_menu (
				-name => $name,
				-values => $type,
				-default => $data->{$name},
				-onChange => $js_modified,
			);
			$type = undef;

		} elsif ( ref $type eq 'HASH' ) {
			$self->complex_selection (
				name => $name,
				type_href => $type,
				data => $data,
			);
			$type = undef;

		} elsif ( $type eq 'switch' ) {
			print $q->radio_group (
				-name => $name,
				-values => [ 1, 0 ],
				-labels => { 1 => 'on', 0 => 'off' },
				-default => ($data->{$name} ? 1 : 0 ),
				-override => 1,
				-onChange => $js_modified,

			);
			$type = undef;

		} elsif ( $type eq 'textarea' ) {
			print $CFG::FONT_FIXED;
			print $q->textarea (
				-name => $name,
				-default => $data->{$name},
				-rows => 5,
				-columns => 60,
				-override => 1,
				-onChange => $js_modified,
			);
			$type = undef;
			print "</FONT>\n";

		} elsif ( $type =~ /text\s*(\d+)?/ ) {
			my $size = $1 || 40;
			print $q->textfield (
				-name => $name,
				-default => $data->{$name},
				-size => $size,
				-override => 1,
				-onChange => $js_modified,
			);
			$type = undef;

		} elsif ( $type =~ /password(\s*\d+)?/ ) {
			my $size = $1 || 40;
			print $q->password_field (
				-name => $name,
				-default => '',
				-size => $size,
				-override => 1,
				-onChange => $js_modified,
			);
			$type = undef;

		} elsif ( $type eq 'title' ) {
			print "&nbsp;\n";
			$type = undef;

		} elsif ( $type eq 'method' ) {
			my $method = "property_widget_$name";
			$self->$method (
				name      => $name,
				info_href => $info,
				data_href => $data
			);
			$type = undef;

		} elsif ( $type eq 'type_method' ) {
			my $method = "widget_type_$name";
			$type = $self->$method();

		} else {
			croak "unknown widget type '$type'";
		}
	}

	print qq{</FONT></td></tr>\n};
	
	1;
}

sub complex_selection {
	my $self = shift;
	
	my %par = @_;
	
	my $name  = $par{name};
	my $type  = $par{type_href};
	my $data  = $par{data};
	
	if ( $type->{type} eq 'list' or $type->{type} eq 'popup' ) {
		my $multiple = $type->{multiple} ? "MULTIPLE " : "";
		my $size = $type->{type} eq 'list' ? "size=6" : "";
		print qq{<select name="$name" $size width=254 $multiple};
		print qq{onChange="if (document.object_was_modified) object_was_modified()">\n};
		foreach my $item (@{$type->{items}}) {
			my $value = $item->[0];
			my $selected;
			if ( $type->{type} eq 'list' ) {
				$selected = $type->{selected}->{$value} ?
					"SELECTED" : "";
			} else {
				$selected = $data->{$name} eq $value ? "SELECTED" : "";
			}
			$value =~ s/"/&quot;/g;
			print qq{<option value="$value" $selected>},
			      qq{$item->[1]</option>\n};
		}
		print qq{</select>\n};
	} else {
		print "type '$type->{type}' currently not supported\n";
	}
}

1;
