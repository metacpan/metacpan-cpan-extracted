#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::HTML::Dialog - A widget for generating HTML code for Dialogs.

=head1 SYNOPSIS

This module is used to make a dialog windows. All drawing methods returns
the HTML in scalar or array context or output it with $m-E<gt>print in void
context.

    # Typical example:
    &nbsp;
    <% $dlg->dialog_start( title => 'Dialog's title', width => 400) %>
    <% $dlg->field( "field1", RO => 1) %>
    <% $dlg->field( "hidden_field", hidden=>1)  %>
    <% $dlg->field( "field")  %>
    <% $dlg->row('&nbsp;') %>
    <% $dlg->buttons(delete_button => 1) %>
    <% $dlg->dialog_end %>
    <p>

    <%method onStartRequest><%perl>
        $obj = new ePortal::ThePersistent::SupportObject;
        $dlg = new ePortal::HTML::Dialog( obj => $obj);

        my $location = try {
          $dlg->handle_request( );
        } catch ePortal::Exception::DataNotValid with {
          my $E = shift;
          $session{ErrorMessage} = $E->text;
          '';
        };

        if ($dlg->isButtonPressed('ok') { ... }
        return $location if $location;
    </%perl></%method>

    %#=== @metags once =========================================================
    <%once>
    my ($dlg, $obj);
    </%once>

    %#=== @metags cleanup =========================================================
    <%cleanup>
    ($dlg, $obj) = ();
    </%cleanup>


=head1 METHODS

=cut

package ePortal::HTML::Dialog;
    our $VERSION = '4.5';

	use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang, CGI
	use Carp;
    use Params::Validate qw/:types/;
    use Apache::Util qw/escape_html escape_uri/;
    

=head2 new()

Object contructor. Maintain the same parameters as C<initialize()>.
Initializes all internal attributes to their default values.

 my $d = new ePortal::HTML::Dialog( obj => $object );
 my $location = $d->handle_reqest();
 ...

=cut

############################################################################
sub new	{	#11/20/01 2:49
############################################################################
	my ($proto, @p) = @_;

	my $self = {};
	my $class = ref($proto) || $proto;
	bless $self, $class;

	# --------------------------------------------------------------------
	# Load defaults. This is ALL possible attributes
    #
	$self->{align} 		= "center";

	$self->{action} 	= $ENV{SCRIPT_NAME};
	$self->{formname} 	= "dialog";
	$self->{multipart_form} = undef;
	$self->{method}		= 'POST';	# GET is incompatible with multipart forms

	$self->{bgcolor} 	= '#FFFFFF';
	$self->{color} 		= '#CCCCFF';			# Color of dialog
	$self->{width} 		= '98%';

	$self->{obj}		= undef;
	$self->{objid} 		= undef	# Optional hidden field
	$self->{objtype}	= undef;

	$self->{title} 		= undef; 									# The title of dialog
	$self->{title_popup}= undef;				# a Popup message for title
	$self->{title_url} 	= undef;				# A URL to anchor from title
	$self->{focus}		= undef;				# item name to focus

	# buttons on dialog's caption
	$self->{q_button}	   		= 0;
	$self->{q_button_url}  		= undef;
	$self->{q_button_title}		= pick_lang(rus => "Помощь", eng => "Help");
	$self->{edit_button}   		= 0;
	$self->{edit_button_url}  	= undef;
	$self->{edit_button_title}	= pick_lang(rus => "Настроить", eng => "Setup");
	$self->{min_button}	      	= 0;
	$self->{min_button_url}   	= undef;
	$self->{min_button_title} 	= pick_lang(rus => "Свернуть", eng => "Minimize");
	$self->{max_button}	      	= 0;
	$self->{max_button_url}   	= undef;
	$self->{max_button_title} 	= pick_lang(rus => "Развернуть", eng => "Maximize");
	$self->{x_button} 	      	= 0;
	$self->{x_button_url}     	= undef;
	$self->{x_button_title}   	= pick_lang(rus => "Закрыть", eng => "Close dialog");
	$self->{copy_button} 	  	= 0;
	$self->{copy_button_url}  	= undef;
	$self->{copy_button_title}	= pick_lang(rus => "Копировать", eng => "Copy object");

	# Buttons
	$self->{ok_button}		= 1;
	$self->{ok_url}			= undef;
	$self->{ok_label}		= pick_lang(rus => "Сохранить!", eng => "Save!");
	$self->{cancel_button}  = 1;
	$self->{cancel_url}		= undef;
	$self->{cancel_label} 	= pick_lang(rus => "Отменить", eng => "Cancel");
	$self->{more_button}	= 0;
	$self->{more_label}		= pick_lang(rus => "Дальше", eng => "More");
    $self->{delete_button}  = 0;
	$self->{delete_label}   = pick_lang(rus => "Удалить !!!", eng => "Delete !!!");
    $self->{apply_button}   = 0;
    $self->{apply_label}    = pick_lang(rus => "Применить", eng => "Apply");

	# some private attributes used in dialog's methods
	# We define these here for methods don't blame me about unknown attributes
#	$self->{label} = undef;
#	$self->{field} = undef;
#	$self->{text}  = undef;

	# Do initialization with user parameters
	$self->initialize(@p);

	return $self;
}##new




=head2 initialize()

Accept many parameters to configure visual representation of dialog and its
internal logic.

See L<Dialog attributes> for details.

=cut

############################################################################
sub initialize	{	#11/20/01 2:54
############################################################################
    my ($self, %p) = @_;

	# overwrite known initialization parameters
	foreach my $key (keys %p) {
		$self->{$key} = $p{$key} if exists $self->{$key};

		die "Unknown key [$key] for Dialog.pm" if not exists $self->{$key};
	}

	# Adjust some parameters
	if (ref $self->{obj}) {
		$self->{objtype} = ref($self->{obj});
		$self->{objid}   = $self->{obj}->id;
	}
	$self->{method} = 'POST' if $self->{multipart_form};

	# Adjust URLs for caption buttons
    foreach (qw/q edit min max x copy/) {
        $self->{$_.'_button_url'} = $self->{$_."_button"} eq '1'
            ? href( $self->{action}, 'dlgb_'.$_ => 1, objid => $self->{objid}, back_url => $self->{back_url})
            : $self->{$_."_button"};
	}

	# Disable some buttons when no object selected
	if ($self->{objid} == 0) {
		$self->{delete_button} = 0;
		$self->{copy_button} = 0;

    } elsif (UNIVERSAL::isa($self->{obj}, 'ePortal::ThePersistent::ExtendedACL') ) {
        $self->{ok_button} = 0 if ! $self->{obj}->xacl_check_update;
        $self->{delete_button} = 0 if ! $self->{obj}->xacl_check_delete;
	}


	# Adjust dialog's title
	if ($self->{title_url}) {
		$self->{title_as_html} = CGI::a( {-href => $self->{title_url}, -title => $self->{title_popup}}, $self->{title});
	} else {
		$self->{title_as_html} = $self->{title};
	}

	$self;
}##initialize


=head2 handle_request(%hash)

Responsible for handling request from dialog events. This function processes
button presses, does object preservation, deletion, copying, etc.

As result it returns an URL for external redirect. It does not do redirect
itself.

=cut

############################################################################
sub handle_request	{	#09/07/01 2:08
############################################################################
    my ($self, @p) = @_;

	$self->initialize(@p);

    my $m = $ePortal->m;
    my %args = $m->request_args;            # this is %ARGS
	my $location;						# will return this

	# Calculate back_url
	$self->{back_url} = $args{back_url} if exists $args{back_url};
	if ($self->{back_url} eq '') {
		# Calculate SCRIPT_NAME from HTTP_REFERER
		my $hr = $ENV{HTTP_REFERER};
		$hr =~ s/\?.*//;
        $hr =~ s|https?://[^/]*||;
		if ($ENV{SCRIPT_NAME} ne $hr) {
			$self->{back_url} = $ENV{HTTP_REFERER};
		}
	}

    # Initialize the dialog's object
	$args{objid} = $p{objid} if defined $p{objid};
	if (ref($self->{obj}) and $args{objid} ) {
        $self->{obj}->restore_or_throw($args{objid});

		# object changed. Reinitialize dialog
		$self->initialize();
	}

	# Check if a button was pressed
	$self->{button_pressed} = undef;
	$self->{button_pressed} = 'ok' if $args{dialog_submit}; # as default
    foreach (qw/q max min edit delete copy x
                ok cancel more apply/) {
		$self->{button_pressed} = $_ if $args{'dlgb_'.$_};
	}

	# Process CANCEL
	if ($self->isButtonPressed('cancel')) {		# "Cancel" button
		$location = $self->{cancel_url} || $self->{back_url};

	# process OK
    } elsif ($self->isButtonPressed('ok') or $self->isButtonPressed('apply')) {           # "Ok" button
		if (ref $self->{obj}) {				# we have an object?
			if ($self->{obj}->htmlSave(%args)) {
				$location = $self->{ok_url} || $self->{back_url};
			} else {
                $session{ErrorMessage} = pick_lang(rus => "Ошибка при сохранении данных", eng => "Error during data save");
			}
		} else {
			$location = $self->{ok_url} || $self->{back_url};
		}
        $location = undef if $self->isButtonPressed('apply');

	# Process DELETE
	} elsif ($self->isButtonPressed('delete')) {
		$location = href("/delete.htm", objtype => $self->{objtype},
						objid => $self->{objid},
						done => $self->{back_url});

	# Process COPY
	} elsif	($self->isButtonPressed('copy')) {
		$self->{obj}->id(undef);
		if ($self->{obj}->insert) {
			$session{GoodMessage} = pick_lang( rus => "Объект скопирован", eng => "Object copied");
			$location = href($ENV{SCRIPT_NAME}, objid => $self->{obj}->id, back_url => $self->{back_url});
		} else {
            $session{ErrorMessage} = "Cannot copy the object";
		}

    # Process MORE
	} elsif ($self->isButtonPressed('more')) {
        # dialog does nothing
    }

	# redirect is done by mason component. We just return new location
	return $location;
}##handle_request


=head2 isButtonPressed($button_name)

Checks is a button was pressed. Use this function only after call to
handle_request().

I<button_name> is one of: qw/q max min edit delete copy x ok cancel
more/

=cut

############################################################################
sub isButtonPressed	{	#10/22/01 11:34
############################################################################
    my ($self, $button) = @_;

	return $self->{button_pressed} eq $button;
}##isButtonPressed




=head2 dialog_start()

Start a dialog. Output its caption and start E<lt>FORME<gt> tag.

=cut

############################################################################
sub dialog_start	{	#11/21/01 3:48
############################################################################
    my ($self, @p) = @_;
	$self->initialize(@p);

	my @out;
	my $m = $HTML::Mason::Commands::m;

	$m->flush_buffer;  # output acceleration
	$m->comp("/message.mc");


	# Start of dialog's table
	push @out, CGI::start_table({-width => $self->{width}, -border => 0,
                -cellspacing => 1, -cellpadding => 1,
				-bgcolor => $self->{color}, -align => $self->{align}});

	# Dialog's form
	if ( $self->{formname} ) {
		my %form_parameters = (-name => $self->{formname}, -method => $self->{method}, -action => $self->{action});
        push @out, $self->{multipart_form}?
            CGI::start_multipart_form(%form_parameters) :
			CGI::start_form(%form_parameters);
		push @out, CGI::hidden(-name => 'dialog_submit', -value => 1, -override => 1);
		push @out, CGI::hidden(-name => 'objid',         -value => $self->{objid}, -override => 1);
		push @out, CGI::hidden(-name => 'objtype',       -value => $self->{objtype}, -override => 1);
		push @out, CGI::hidden(-name => 'back_url',      -value => $self->{back_url}, -override => 1);
	}

	# a Row with caption
	push @out, CGI::start_Tr();
    push @out, CGI::td({-align => 'left', -bgcolor => $self->{color},
						-class => 'sidemenu', -nowrap => 1},
						[ $self->{title_as_html} ]);
	my @buttons;
	foreach (qw/edit q copy min max x/) {
		push @buttons, img( src => "/images/ePortal/dlg_" . $_ . ".png",
						href => $self->{$_ . "_button_url"},
						title => $self->{$_ . "_button_title"} )
						if $self->{$_."_button"};
	}
	push @out, CGI::td({-align => 'right', -nowrap => 1},
						[ join('&nbsp;', @buttons) ]);
	push @out, CGI::end_Tr();

	# a Row with dialog's content (start of table)
	push @out, CGI::start_Tr();
	push @out, CGI::start_td({-colspan => 2, -bgcolor => "#FFFFFF"});
    push @out, CGI::start_table({ -width => '100%', -cellpadding => 0, -cellspacing => 0,
					-border => 0, -bgcolor => '#FFFFFF'});

	# Return resulting HTML or output it directly to client
    defined wantarray ? join("\n", @out) : $m->print( join("\n", @out) );
}##dialog_start


=head2 dialog_end()

Output closing tags for E<lt>TABLEE<gt> and E<lt>FORME<gt>, focus the
cursor

=cut

############################################################################
sub dialog_end	{	#11/21/01 4:23
############################################################################
    my ($self, @p) = @_;

	my @out;
	my $m = $HTML::Mason::Commands::m;

    push @out, '</form>' if $self->{formname};
	push @out, '</table></td></tr>';
	push @out, '</table>';

	if ($self->{focus}) {
		push @out, qq{
<script language="JavaScript">
<!--
	document.$self->{formname}.$self->{focus}.focus();
// -->
</script>};
	}

	# Return resulting HTML or output it directly to client
    defined wantarray ? join("\n", @out) : $m->print( join("\n", @out) );
}##dialog_end



=head2 row()

Generates a row for dialog's table. Parameters are passed in two modes:

 row(text, -colspan=>2, -align=>"center", option => xxx)
 row(label, value, option => xxx)

B<text> is shown in 2 cells colspan. B<label,value> is shown in 2 cells.
B<Options> are passed directly to CGI module.

=cut

############################################################################
sub row	{	#11/21/01 4:29
############################################################################
    my ($self, @p) = @_;

	my $html;
	my $m = $HTML::Mason::Commands::m;

	if (scalar(@p) % 2 == 1) {	# just odd number of arguments
		my $text = shift @p;
		my %params = @p;
		$params{-colspan} ||= 2;
		$params{-align}   ||= 'center';
		$html = CGI::Tr({},
				CGI::td({%params}, $text));
	} else {
		my $label = shift @p; my $value = shift @p;
		my $separator;
        $separator = ':' if $label and $value;
        $html = CGI::Tr({},
				CGI::td({-width => '50%', -class => 'dlglabel', -valign => 'top'},
					$label . $separator),
				CGI::td({-width => '50%', -class => 'dlgfield', -valign => 'top'},
					$value));
    }

	# Return resulting HTML or output it directly to client
    defined wantarray ? $html : $m->print( $html );
}##row





=head2 field($field_name,%parameters)

Display an input field for an attribute of the object. Field label and it's
dialog control is determined via C<htmlLabel()> and C<htmlField()>.

Parameters are:

=over 4

=item * label

Override default label

=item * value

Set this value for the field

=item * vertical=>1

if true then input control displayed under the label. Else result is like
B<label> : B<control>.

=item * RO=>1

C<htmlValue()> is used instead of C<htmlField()> to display read-only
value. Read-only field also assumes hidden field too.

=item * hidden=>1

make hidden field

=back

=cut

############################################################################
sub field	{	#11/21/01 4:47
############################################################################
    my ($self, $field, %p) = @_;

	my ($html, $label, $value);
	if ($field) {
        if ( exists $p{label} ) {
            $label = $p{label};
        } elsif ( $self->{obj} and $self->{obj}->attribute($field) ) {
            $label = $self->{obj}->attribute($field)->{label};
        } else {
            $label = $field;
        }

		if ($p{RO}) {
			$html = CGI::hidden({
                -name => $field,
				-value => exists $p{value}
					? $p{value}
                    : Apache::Util::escape_html($self->{obj}->value($field)),
				-override => 1});
            $value = exists $p{value}
                ? $p{value}
				: $self->{obj}->htmlValue($field);

		} elsif ($p{hidden}) {
			$html = CGI::hidden({
                -name => $field,
                -value => exists $p{value}
                    ? $p{value}
                    : Apache::Util::escape_html($self->{obj}->value($field)),
				-override => 1});
			$label = $value = undef;

		} else {
			$value = exists $p{value}
                ? $p{value}
                : $self->{obj}->htmlField($field, date_field_style => $p{date_field_style});
			$self->{focus} ||= $field;
		}
	} else {
		$label = "field [$field] not found";
	}

    if ( $label or $value ) {
        $label = pick_lang($label) if ref($label) eq 'HASH';
        $label = qq{<span class="dlglabel">$label</span>} if $label;

        if ( $p{vertical} ) {
            $html .= $self->row($label . '<br>' . $value, %p);
        } elsif ( $p{horizontal} or ($p{decoration} eq 'none')) {
            $html .= $label . $value;
        } else {
            $html .= $self->row($label, $value);
        }
	}

	# Return resulting HTML or output it directly to client
    defined wantarray ? $html : $ePortal->m->print( $html );
}##field


=head2 buttons()

Draw a row with a buttons. By default only 2 buttons are shown: ok_button
and cancel_button. See L<initialize()|initialize()> for details.

=cut


############################################################################
sub buttons	{	#11/21/01 4:52
############################################################################
    my ($self, %p) = @_;

    my $decoration = $p{decoration};
    delete $p{decoration};
	$self->initialize(%p);

	my $m = $HTML::Mason::Commands::m;

	my @buttons;
	foreach my $b (qw/ more ok cancel delete/) {
 	if ($self->{$b."_button"}) {
#        if ($b eq 'cancel') {
#               BAD IDEA. sometimes I need to travel through a list and then press a cancel
#            push @buttons, CGI::button( -name => "dlgb_$b", -value => $self->{$b."_label"}, -class => 'button', -onClick => "javascript:history.go(-1);");
#        } else {
            push @buttons, CGI::submit( -name => "dlgb_$b", -value => $self->{$b."_label"}, -class => 'button');
#        }
	}}

    my $html = join('&nbsp;&nbsp;&nbsp;&nbsp;', @buttons) . '&nbsp;';
    $html = CGI::Tr({}, CGI::td({-colspan => 2, -align => 'right'}, $html ))
        if $decoration ne 'none';

	# Return resulting HTML or output it directly to client
    defined wantarray ? $html : $m->print( $html );
}##buttons


#%#=== @metags radio_group ====================================================
#<%method radio_group><%perl>
#	my $fieldname = $ARGS{fieldname} || "radio_group";
#	my $label	 = $ARGS{label};
#	my $values = $ARGS{values};
#	my $labels = $ARGS{labels};
#	my $default = $ARGS{default};
#</%perl>
#	<& /dialog.mc:row,
#			label => $label,
#			field => scalar CGI::radio_group(
#							-name 		=> $fieldname,
#							-values 	=> $values,
#							-labels 	=> $labels,
#							-default 	=> $default,
#							-linebreak => 'true',
#							-class 		=> "dlgfield",
#							)
#			&>
#</%method>



1;

__END__

=head1 DIALOG ATTRIBUTES

This attributes may be used in ant call to handle_request, initialize, or
any call to dialog.mc method.

=over 4

=item * obj

This is ThePersistent object to edit

=item * objid,objtype

This attributes are set automaticaly from I<obj>




=item * action,formname,multipart_form

These attributes are form specific. Defaults:

	action = $ENV{SCRIPT_NAME}
	formname = "dialog"

If undef passed then no FORM tags generated.


=item * bgcolor,color,width

Display attributes


=item * title,title_popup,title_url

The title of dialog

=item * align

Align the table

=item * focus

Item name to focus the cursor. Set automaticaly


=item * xxx_button, xxx_button_title

A button at top of dialog. xxx may be (q edit min max x copy )

Set xxx_button=1 to make default action or set to any URL


=item * yyy_button,yyy_label

Usual buttons at bottom of dialog. yyy may be (ok cancel more delete)

Default is ok and cancel

=back




=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut


