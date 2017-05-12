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

ePortal::HTML::List - List of objects support.

=head1 SYNOPSIS

This module is used to make a list of objects. Example:

 <% $list->draw_list %>

 <%method folder_name><%perl>
     my $list = $ARGS{list};
     my $obj = $list->{obj};
     . . .
 </%perl>
 <% HTML output %>
 </%method>

 <%method onStartRequest><%perl>
    my $obj = new ePortal::Notepad::View01;
    $list   = new ePortal::HTML::List( obj => $obj, class=>"smallfont" );
    $list->add_column_image();
    $list->add_column( id => "title", title => "Column title",
            width => "60%", url => "url.htm?objid=#id#");
    $list->add_column_method( id => "folder_name", title => "Folder name");
    $list->add_column_system( delete => 1);

    my $location = $list->handle_request;
    return $location if $location;

    $obj->restore_where($list->restore_parameters);
 </%perl></%method>

=head1 METHODS

=cut

package ePortal::HTML::List;
    our $VERSION = '4.5';

	use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang, CGI
	use Carp;

	use ePortal::HTML::ListColumn;


=head2 new()

Object contructor. Takes the same arguments as L<initialize()|initialize()>

=cut

############################################################################
sub new	{	#09/07/01 2:04
############################################################################
	my ($proto, %p) = @_;

	my $class = ref($proto) || $proto;
	my $self = {};
	bless $self, $class;

	# Set some defaults. This is @metags List_attributes
	$self->{action_bar} 	= undef;	# action bar present
	$self->{columns}		= [];		# array with columns objects
	$self->{class}			= undef;	# default class for all columns
	$self->{form_action}	= $ENV{SCRIPT_NAME};
	$self->{form_method}	= 'GET';
	$self->{form_name} 		= 'theForm';
	$self->{search}			= 0;		# call search_form method on parent?
	$self->{more_data}		= undef;	# there is more data in recorset
	$self->{pages}			= undef;	# total pages, undef if unknown
	$self->{page}			= 1;		# current page
	$self->{rowspan}		= 4;		# space in pixels between rows
	$self->{rows_per_page} 	= 20;
	$self->{obj}			= undef;	# the object to iterate
	$self->{rows_fetched}	= 0;		# rows counter per page
	$self->{after_row}		= undef;	# comp method name
	$self->{before_row}		= undef;	# comp method name
    $self->{total_columns}  = 0;        #
	$self->{list_cb}		= undef;	# combo-box default choice
	$self->{list_items}		= [];		# list of selected rows (checkbox)
	$self->{edit_url}		= undef;	# url for icon_edit(url=>...)
    $self->{state}          = {};       # custom state parameters
    $self->{sorting}        = undef;    # current SortBy for restore_where
    $self->{width}          = '99%';    # the width of the table

	$self->initialize(%p);
	return $self;
}##new




=head2 initialize()

Object initializer. See L<Attributes|List attributes> for details.

=cut

############################################################################
sub initialize	{	#09/07/01 2:07
############################################################################
    my ($self, %p) = @_;

	# overwrite known initialization parameters
	foreach my $key (keys %$self) {
		$self->{$key} = $p{$key} if exists $p{$key};
		die "Unknown key [$key] for List.pm" if not exists $self->{$key};
	}

	$self;
}##initialize


=head2 handle_request()

Handle request and do redirect if needed. Return new location.

=cut

############################################################################
sub handle_request	{	#09/07/01 2:08
############################################################################
    my ($self, %p) = @_;
	$self->initialize(%p);

    my %args = $ePortal->m->request_args;           # this is %ARGS
	my %state = $self->list_state(1);		# these keys we use
	my $location;							# will return this

    foreach (qw/page list_cb sorting/) {
        $self->{$_} = $args{$_}         if exists $args{$_};
        $self->{$_} = $p{$_}            if defined $p{$_};  # !!! only defined values !!!
	}


	# somebody pressed a button in the list form
	if ($args{list_submit}) {

		# get list of selected items
		my @id = ref($args{list_chbox}) eq 'ARRAY' ? @{$args{list_chbox}} : ($args{list_chbox});
		$self->{list_items} = [@id];

		if ($args{list_btcreate}) {	# "Create" pressed
            my %state = $self->list_state;
            $state{objid} = 0;
            $location = href($self->{button_create}{url}, %state);

		} elsif ($args{list_btdelete}) {	# "Delete selected" pressed

			# do redirect if needed
			if ($self->{button_delete}{url}) {
				$location = href($self->{button_delete}{url}, objid => $self->{list_items});
			} else {
				$location = href("/delete.htm", objid => $self->{list_items},
						objtype => ref($self->{obj}),
						done => href($ENV{SCRIPT_NAME}, $self->list_state));
            }
        }
	}	# if list_submit

    # Calculate LIMITs
    # limit_offset counts from 0 !!!
	$self->{limit_rows} = $self->{rows_per_page} + 1; # One more to know is any data more?
    $self->{limit_offset} = 0;
	if ($self->{page} > 1) {
			# limit_offset counts from 0
		$self->{limit_offset} = ($self->{page}-1) * $self->{rows_per_page};
	}

#   if ($location) {
#       $ePortal->m->comp("/redirect.mc", location => $location);
#   }

	return $location;
}##handle_request


=head2 columns()

Returns array of ListColumn objects.

=cut

############################################################################
sub columns	{	#09/10/01 12:59
############################################################################
    my $self = shift;
	my @columns = @{$self->{columns}}; # create new instance array
	return @columns;
}##columns


=head2 columns_count()

Returns a number of columns

=cut

############################################################################
sub columns_count	{	#09/10/01 1:54
############################################################################
    my $self = shift;
	return scalar @{$self->{columns}};
}##columns_count

=head2 add_column()

Add new column to the List. Arguments are:

=over 4

=item * title

Column title

=item * class

C<class> for the cell

=item * align valign

Cell alignment

=item * id

ID of the column. Should be unique for the List. This is field name for
simple column.

=item * nowrap

Add C<nowrap> tag to the cell

=item * url

URL for the cell content. The string like #arg# is replaced with value of
attribute C<arg> of the object

=item * width

Width of the cell

=back

=cut

############################################################################
sub add_column	{	#09/07/01 2:41
############################################################################
    my ($self, %p) = @_;

	$p{obj} = $self->{obj};
	$p{class}	||= $self->{class};
	$p{method}  ||= \&column_default; #'column_default';

	my $column = new ePortal::HTML::ListColumn(%p);
	push @{$self->{columns}}, $column;

	$self->{total_columns} = scalar @{$self->{columns}} + @{$self->{columns}} - 1;
	$column;
}##add_column


=head2 add_column_image()

Add a column with an image. See L<add_column()|add_column()> for arguments.
Additional arguments are:

=over 4

=item * src

URL for the image

=back

=cut

############################################################################
sub add_column_image	{	#09/10/01 1:09
############################################################################
    my ($self, %p) = @_;

	$p{id} 		||= 'image';
	$p{method} 	||= \&column_image; #'column_image';

	unless (defined $p{src}) {	# install default image for the column
        $p{src} = '/images/icons/msg.gif';
		$p{width} = 10;
	}

	$self->add_column(%p);
}##add_column_image


=head2 add_column_image()

Add a column. A method named C<ID> will be called for cell content. See
L<add_column()|add_column()> for arguments.

=cut

############################################################################
sub add_column_method	{	#09/10/01 1:09
############################################################################
    my ($self, %p) = @_;

	$p{method} ||= \&column_method; #'column_method';

	$self->add_column(%p);
}##add_column_method



=head2 add_column_enabled()

Add a column with ON|OFF state. Be default this column is linked to
C<enabled> object attribute. See L<add_column()|add_column()> for
arguments.

=cut

############################################################################
sub add_column_enabled	{	#09/10/01 1:09
############################################################################
    my ($self, %p) = @_;

	$p{id}     ||= 'enabled';
	$p{align} 	= "center";
	$p{method} ||= \&column_enabled; #'column_enabled';

	$self->add_column(%p);
}##add_column_enabled


=head2 add_column_image()

The same as add_column_enabled(). See L<add_column()|add_column()> for arguments.

=cut

############################################################################
sub add_column_yesno	{	#09/10/01 1:09
############################################################################
    my ($self, %p) = @_;

	$p{id}     ||= 'enabled';
	$p{align} 	= "center";
	$p{method} ||= \&column_yesno; #'column_yesno';

	$self->add_column(%p);
}##add_column_yesno


=head2 add_column_system()

Add a system column. See L<add_column()|add_column()> for arguments.
Additional arguments are:

=over 4

=item * acl

Show ACL button

=item * delete

Show DELETE button

=item * edit

Show EDIT button

=item * checkbox

Show SELECTED checkbox

=item * export

Show EXPORT button

=back

=cut

############################################################################
sub add_column_system	{	#09/10/01 2:38
############################################################################
    my ($self, %p) = @_;

	$p{id} 		||= 'system_column';
	$p{method} 	||= \&column_system; #'column_system';
	$p{nowrap}	= 1;
	$p{align} 	= "right";
	$p{width} 	= 5;
	$p{width} += 20 if $p{edit};
	$p{width} += 20 if $p{checkbox};
	$p{width} += 20 if $p{delete};
	$p{width} += 20 if $p{acl};
	$p{width} += 20 if $p{export};

	$self->add_column(%p);
}##add_column_system


=head2 add_button_create()

Add a button B<Create new> in action bar.

=over 4

=item * value

Button caption

=back

=cut

############################################################################
sub add_button_create	{	#09/11/01 12:25
############################################################################
    my ($self, %p) = @_;

	$p{class} ||= 'button';
	$p{name}  ||= 'list_btcreate';
	$p{value} ||= pick_lang(rus => "Новый", eng => "New");
	$self->{action_bar} = 1;

	$self->{button_create} = \%p;
}##add_button_create


=head2 add_button_delete()

Add a button B<Delete> in action bar.

=over 4

=item * value

Button caption

=back

=cut

############################################################################
sub add_button_delete	{	#09/11/01 12:25
############################################################################
    my ($self, %p) = @_;

	$p{class} ||= 'button';
	$p{name}  ||= 'list_btdelete';
	$p{value} ||= pick_lang(rus => "Удалить", eng => "Delete");
	$self->{action_bar} = 1;

	$self->{button_delete} = \%p;
}##add_button_delete


=head2 add_cb()

Add combo-box to the list. See L<add_column()|add_column()> for arguments.
Additional parameters are

=over 4

=item * values labels default

Parameters for C<CGI::popup_menu>

=back

=cut

############################################################################
sub add_cb	{	#09/11/01 12:44
############################################################################
    my ($self, %p) = @_;

	# add combobox
	$p{class} ||= 'dlgfield';
	$p{name}  ||= 'list_cb';
	$self->{action_bar} = 1;
	$self->{cb_label} = $p{label};
	$self->{cb} = \%p;
	$self->{list_cb} ||= $p{default};

	# Add selector button
	my %b;
	$b{class} = 'button';
	$b{name} = 'list_btcb';
	$b{value} = "...";
	$self->{button_cb} = \%b;
}##add_cb


############################################################################
# Function: html_cb
# Description: Generate HTML code for custom ComboBox
# Returns:
#
############################################################################
sub html_cb	{	#09/11/01 12:48
############################################################################
    my ($self, %p) = @_;

	return undef if not defined $self->{cb};

	$self->{cb}{default} = $self->{list_cb};
	foreach (qw/class name default values labels/) {
		$p{$_} = $self->{cb}{$_} if defined $self->{cb}{$_};
	}
	$p{onChange} = "javascript:document.forms['$self->{form_name}'].submit();";
	#$p{onChange} = "javascript:document.theForm.submit();";

	return CGI::popup_menu(\%p) . $self->_html_button('cb');
}##html_cb

############################################################################
# Function: html_hidden
# Description: Paste needed parameters as hidden form fields. Should be used
# 	as last as possible to include most recent values (the list will know
# 	page count only after last row in the table)
# Returns:
# 	HTML string
#
############################################################################
sub html_hidden	{	#09/10/01 1:51
############################################################################
    my $self = shift;

  	my %hash;
	$hash{list_submit} = 1;

	my $content;
	foreach (keys %hash) {
		$content .= CGI::hidden( -name => $_, -value => $hash{$_}, -override => 1) . "\n";
	}

	return $content;
}##html_hidden

############################################################################
# Function: _html_button
# Description: make HTML code for the button
# Returns: HTML string
#
############################################################################
sub _html_button	{	#09/11/01 12:28
############################################################################
    my ($self, $button) = @_;
	my %p;

	return undef if not defined $self->{"button_$button"};

	foreach (qw/class name value/) {
		$p{$_} = $self->{"button_$button"}{$_} if defined $self->{"button_$button"}{$_};
	}

	return CGI::submit(\%p);
}##_html_button


############################################################################
sub html_button_create	{	#09/11/01 12:28
############################################################################
    my ($self, @p) = @_;
	return $self->_html_button('create', @p);
}##html_button_create


############################################################################
sub html_button_delete	{	#09/11/01 12:28
############################################################################
    my ($self,@p) = @_;
	return $self->_html_button('delete', @p);
}##html_button_delete


############################################################################
# Function: next_row
# Description: Get next row for the table. Calculate all related fields
# Parameters: none
# Returns: [1|0]
#
############################################################################
sub next_row	{	#09/10/01 2:06
############################################################################
    my $self = shift;

	# Run to the first row of the current page
	if ($self->{rows_fetched} == 0) {	# first row
		if ($self->{limit_offset} == 0) { # FOR BACKWARD COMPATIBILITY
			for(my $i=1; ($i <= ($self->{page}-1) * $self->{rows_per_page})
				&& $self->{obj}->restore_next	; $i++) { }
		}
	}

	# end of page reached
	if ($self->{rows_fetched} >= $self->{rows_per_page}) {
		$self->{pages} = $self->{page} + 1;
		$self->{action_bar} ||= -1;	# to show page selector anyway
		return undef;
    }

	$self->{action_bar} ||= -1 if $self->{pages} > 1;

	# Get next row data
	my $rc = $self->{obj}->restore_next;
	$self->{rows_fetched} ++;
	$self->{more_data} = $rc;

	# end of recordset
	if (! $rc) {
		$self->{pages} = $self->{page};
	}

	return $rc;
}##next_row

############################################################################
# Function: list_state
# Description: The current state of the list as hash
# Returns: hash
#
############################################################################
sub list_state	{	#09/11/01 4:14
############################################################################
    my ($self,$full) = @_;
	my %hash;

    # internal variables
    $hash{page} = $self->{page} if $self->{page} > 1;
    $hash{list_cb} = $self->{list_cb} if $self->{list_cb};
    $hash{sorting} = $self->{sorting} if $self->{sorting};

    # html page may supply its own state variables
    foreach (keys %{$self->{state}}) {
        $hash{$_} = $self->{state}{$_};
    }

	return wantarray? %hash : \%hash;
}##list_state


=head2 draw_list()

Draw the list.

=cut

############################################################################
sub draw_list	{	#12/17/01 3:15
############################################################################
    my ($self, @p) = @_;
	$self->initialize(@p);

	my @out;

	$ePortal->m->flush_buffer;  # output acceleration
	$ePortal->m->comp("/message.mc");

	push @out, $self->actionbar_top;
    push @out, $ePortal->m->scomp("/empty_table.mc", height => 6 );

    push @out, CGI::start_table( {-width => $self->{width}, -border=>0,
            -cellpadding=>0, -cellspacing=>0,
			-columns => $self->{total_columns}});

	push @out, $self->table_header;
	push @out, $self->table_rows;
	push @out, '</table>';

    push @out, $ePortal->m->scomp("/empty_table.mc", height => 6 );
	push @out, $self->actionbar_bottom;

	# Return resulting HTML or output it directly to client
	defined wantarray ? join("\n", @out) : $ePortal->m->out( join("\n", @out) );
}##draw_list


############################################################################
sub actionbar_top	{	#12/17/01 3:21
############################################################################
    my $self = shift;

	return if not $self->{action_bar};
	my @out;

    push @out, CGI::start_table( {-width => $self->{width}, -border=>0, -cellpadding=>0, -cellspacing=>0});
    push @out, CGI::start_form( {-name => $self->{form_name},
			-method => $self->{form_method}, -action => $self->{form_action}});
    push @out,
		CGI::Tr( {-bgcolor => "#cdcdcd"},
            CGI::td( {},
				$self->html_button_create() .
				$self->html_button_delete() .
        		'&nbsp;'),
			CGI::td( {-align => "right", -nowrap => 1},
				CGI::span( {-class => "smallbold"}, $self->{cb_label}) . $self->html_cb )
		);
	push @out, '</table>';

	# Return resulting HTML or output it directly to client
	defined wantarray ? join("\n", @out) : $ePortal->m->out( join("\n", @out) );
}##actionbar_top

############################################################################
# Function: actionbar_bottom
# Description:
# Parameters:
# Returns:
#
############################################################################
sub actionbar_bottom	{	#12/17/01 3:27
############################################################################
    my $self = shift;

#	return if (not $self->{action_bar}) and ($self->{pages} == 1);
	my @out;

	my $page = $self->{page};
	my $pages = $self->{pages};
	my %list_state = $self->list_state;

    push @out, CGI::start_table( {-width => $self->{width}, -border=>0, -cellpadding=>0, -cellspacing=>0});
	push @out, '<tr bgcolor="#cdcdcd">';

	push @out, CGI::td( {}, $self->html_button_create . $self->html_button_delete . '&nbsp;');

	my ($p1, $pp, $pn);
	if ($page > 1) {
		$list_state{page} = 1;
		$p1 = CGI::a( { -href => href($ENV{SCRIPT_NAME}, %list_state)}, '1');
    }
	if ($page > 2) {
		$list_state{page} = $page-1;
		$pp = CGI::a( { -href => href($ENV{SCRIPT_NAME}, %list_state), title => pick_lang(rus => "Пред", eng => 'Prev')}, '&lt;&lt;');
	}
	if ($pages > $page) {
		$list_state{page} = $page+1;
		$pn = CGI::a( { -href => href($ENV{SCRIPT_NAME}, %list_state), title => pick_lang(rus => "След", eng => 'Next')}, '&gt;&gt;');
	}

	if ($pages > 1) {
        push @out, CGI::td( {-align => 'right'},
                    pick_lang(rus => 'Страница: ', eng => 'Page:') .
					$p1 . $pp . CGI::b($page) . $pn);
	}

	push @out, '</td></tr></table>';

	if ( $self->{action_bar} > 0) {
		push @out, $self->html_hidden;
		push @out, '</form>';
	}

	# Return resulting HTML or output it directly to client
	defined wantarray ? join("\n", @out) : $ePortal->m->out( join("\n", @out) );
}##actionbar_bottom



############################################################################
sub table_header	{	#12/17/01 3:37
############################################################################
    my $self = shift;

	my @out;
	my $form_name = $self->{form_name};

	push @out, '<tr bgcolor="#cdcdcd">';
	my $columncounter = 0;
	foreach my $column ( $self->columns ) {
		my $W = $column->{width}? qq| width="$column->{width}" | : '';

        # Add SORT BY images to column title
        my $SORT = '&nbsp;';
        if ( defined($column->{sorting}) ) {
            my %state = $self->list_state;
            $state{page} = 1;   # always redirect to 1st page
            if ($self->{sorting} eq $column->{id}) { # already sorted
                $state{sorting} = '!' . $column->{id};
                $SORT .= img(src => '/images/icons/descend.gif',
                    href => href($ENV{SCRIPT_NAME}, %state),
                    title => pick_lang(rus => "Сортировать по убыванию", eng => "Sort descending"),
                    );
            } else {
                $state{sorting} = $column->{id};
                $SORT .= img(src => '/images/icons/ascend.gif',
                    href => href($ENV{SCRIPT_NAME}, %state),
                    title => pick_lang(rus => "Сортировать по возрастанию", eng => "Sort acending"));
            }
        }

        # Empty cell between every column
		if ($columncounter++ > 0) {
            push @out, $ePortal->m->scomp('/empty_td.mc', width => 3 );
		}
		push @out, qq|<td class="list_header" align="center"$W>|;
		if ($column->{id} eq 'system_column' and $column->{checkbox}) {
			push @out, img( src => "/images/ePortal/plus.gif", href => "javascript:CheckAll(true, '$form_name')" );
			push @out, img( src => "/images/ePortal/minus.gif", href => "javascript:CheckAll(false, '$form_name')" );
		} else {
            push @out, CGI::b( $column->{title} . $SORT );
		}
		push @out, '</td>';
	}
	push @out, '</tr>';

	# Return resulting HTML or output it directly to client
	defined wantarray ? join("\n", @out) : $ePortal->m->out( join("\n", @out) );
}##table_header



############################################################################
# Function: table_rows
# Description:
# Parameters:
# Returns:
#
############################################################################
sub table_rows	{	#12/17/01 3:41
############################################################################
    my $self = shift;
	my @out;
	my ($currentrow, $counter, $more_data);

	while( $more_data = $self->next_row ) {
		$currentrow ++;
		$self->{bgcolor} = $counter++ % 2 == 0? '#FFFFFF' : '#eeeeee';

		if ($self->{before_row}) {
			push @out, CGI::Tr( {-bgcolor => $self->{bgcolor} },
                $ePortal->m->scomp('/empty_td.mc' ),
                CGI::td({-colspan => $self->{total_columns}},
                    $ePortal->m->request_comp->scall_method($self->{before_row}, list => $self)));
		}
		push @out, qq|<tr bgcolor="$self->{bgcolor}">|;

 		my $columncounter = 0;
		foreach my $column ( $self->columns ) {
			if ($columncounter++ > 0) {
                push @out, $ePortal->m->scomp('/empty_td.mc');
			}

			#my $td_data = $ePortal->m->base_comp->scall_method($column->{method}, list => $self, column => $column);
			my $td_data = $column->{method}($self, $column);
 			push @out, CGI::td($column->td_params, [$td_data]);

 		}	# end of foreach column

		push @out, "</tr>";

		if ($self->{after_row}) {
			push @out, CGI::Tr({-bgcolor => $self->{bgcolor}},
                $ePortal->m->scomp('/empty_td.mc') .
                $ePortal->m->scomp('/empty_td.mc') .
                CGI::td({-colspan => $self->{total_columns}-2},
                    $ePortal->m->request_comp->scall_method($self->{after_row}, list => $self)))
		}

		if ($self->{rowspan}) {
            push @out, $ePortal->m->scomp("/empty_tr.mc", colspan => $self->{total_columns}, height => $self->{rowspan});
		}

  } # end of while restore_next

	# is there any more data
	$self->{more_data} = $more_data;
	$self->{multipage} ||= $more_data;

	if ($currentrow == 0) {
		push @out, CGI::Tr({},
			CGI::td({-class => "smallfont", -colspan => $self->{total_columns}},
                CGI::font({-color => 'red'},
					pick_lang(rus => 'Нет данных для просмотра', eng => 'No data to show'))
				));
	}

	# Return resulting HTML or output it directly to client
	defined wantarray ? join("\n", @out) : $ePortal->m->out( join("\n", @out) );
}##table_rows


############################################################################
sub column_default	{	#12/17/01 4:13
############################################################################
    my ($self, $column) = @_;

	my $content = $column->content;
	if ($column->{url}) {
		my $id = $self->{obj}->id;
		my $url = $column->{url};
        $url =~ s/#([^#]*)#/$self->{obj}->value($1)/eg;
		$content = CGI::a({-href => $url}, $content);
	}
	return $content;
}##column_default


############################################################################
sub column_image	{	#12/17/01 4:19
############################################################################
    my ($self, $column) = @_;

	my $content = img( src => $column->{src} );
	if ($column->{url}) {
		my $id = $self->{obj}->id;
		my $url = $column->{url};
		$url =~ s/#(.*)#/$self->{obj}->value($1)/eg;
		$content = CGI::a({-href => $url}, $content);
    }
	return $content;
}##column_image


############################################################################
sub column_method	{	#12/17/01 4:20
############################################################################
    my ($self, $column) = @_;

    my $content = $ePortal->m->request_comp->scall_method($column->{id}, list => $self, $column => $column);
	if ($column->{url}) {
		my $id = $self->{obj}->id;
		my $url = $column->{url};
		$url =~ s/#(.*)#/$self->{obj}->value($1)/eg;
		$content = CGI::a({-href => $url}, $content);
    }
	return $content;
}##column_method


############################################################################
sub column_system	{	#12/17/01 4:22
############################################################################
    my ($self, $column) = @_;
	my @out;

	$column->prepare_system_column;

	if ( $column->{"show_checkbox"}) {
		push @out, CGI::checkbox( {-name => "list_chbox",
				-value => $self->{obj}->id,
				-label=>"",
				-class=>"dlgfield"} );
	}
	if ( $column->{"show_edit"} ) {
        push @out, icon_edit( $self->{obj}, url => $self->{edit_url}, objtype => $column->{objtype} );
	}
	if ($column->{"show_export"}) {
		push @out, icon_export( $self->{obj} );
	}
	if ($column->{"show_delete"}) {
        push @out, icon_delete( $self->{obj}, objtype => $column->{objtype} );
	}

	return join("\n", @out);
}##column_system


############################################################################
sub column_enabled	{	#12/17/01 4:35
############################################################################
    my ($self, $column) = @_;
	my $content;

	if ($self->{obj}->enabled != 0) {
		$content = img( src => "/images/ePortal/on.gif",
            href => href("/on_off.htm", objid => $self->{obj}->id, objtype => $column->{objtype}),
			title => pick_lang(rus => "Выключить", eng => 'Disable') );
	} else {
		$content = img( src => "/images/ePortal/off.gif",
            href => href("/on_off.htm", objid => $self->{obj}->id, objtype => $column->{objtype}),
			title => pick_lang(rus => "Включить", eng => 'Enable') );
	}
	return $content;
}##column_enabled


############################################################################
sub column_yesno	{	#12/17/01 4:35
############################################################################
    my ($self, $column) = @_;
	my $content;

	if ($self->{obj}->value($column->{id} )) {
		$content = '<span style="color:#006600;">' .
			pick_lang(rus =>'да', eng => 'yes') .
			'</span>';
	} else {
		$content = '<span style="color:#660000;">' .
			pick_lang(rus =>'нет', eng => 'no') .
			'</span>';
	}
	return $content;
}##column_yesno


=head2 restore_parameters()

List of parameters to pass to restore_where() function of ThePersistent
object.

=cut

############################################################################
sub restore_parameters  {   #10/01/02 10:27
############################################################################
    my $self = shift;
    my %p = @_;

    # LIMITs for SQL clause
    $p{limit_offset} = $self->{limit_offset};
    $p{limit_rows} = $self->{limit_rows};

    # Sorting
    if ( my ($desc,$sortcolumn) = ($self->{sorting} =~ /^(\!?)(.*)$/)) {
        $desc = ' DESC' if $desc eq '!';
        foreach my $column ( $self->columns ) {
            if ($column->{id} eq $sortcolumn) {
                if ($column->{sorting} eq '1') {
                    $p{order_by} = $column->{id} . $desc;
                } else {
                    $p{order_by} = $column->{sorting} . $desc;
                }
                last;
            }
        }
    }

    return %p;
}##restore_parameters

1;


__END__

=head1 List Attributes

=over 4

=item * class

Default class for all table cells

=item * form_action

ACTION attribute for the form. Default is $ENV{SCRIPT_NAME}

=item * form_method

Default is GET

=item * form_name

Default is 'theForm'

=item * more_data

1 if there is more data after L<draw_list()|draw_list()>

=item pages

Number of pages in the List. Undef if unknown

=item * page

Current page number

=item * rowspan

Space in pixels between rows

=item * rows_per_page

Rows to display per list page

=item * obj

The L<ThePersistent|ePortal::ThePersistent> object to iterate

=item * rows_fetched

Rows fetched so far

=item * after_row

Method name to call after each row

=item * before_row

Method name to call before each row

=item * total_columns

Number of columns in the table.

=item * list_cb

combo-box default choice

=item * edit_url

url for icon_edit()

=back

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
