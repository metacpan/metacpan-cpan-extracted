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

ePortal::PageView - Custom home page of ePortal.

=head1 SYNOPSIS

There are 3 types of PageView:

=over 4

=item *

B<user> - personal home page of a registered user

=item *

B<default> - only one PageView may be default. This is default home page of
a site

=item *

B<template> - There may be many templates. Administrator may restrict access
to these pages;


=back

=head1 METHODS

=cut

package ePortal::PageView;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::ExtendedACL/;

	use ePortal::Global;
	use ePortal::Utils;
	use ePortal::UserSection;
	use ePortal::PageSection;


############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{drop_admin_priv} = 1;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{columnswidth} ||= {
            label => {rus => 'Ширина столбцов', eng => 'Columns width'},
            fieldtype => 'popup_menu',
            values => ['N:W', 'N:W:N', 'N:N:N', 'W'],
            default => 'N:W',
            labels => {
                    'N:W' => {rus => 'Узк:Шир', eng => 'Nar:Wide'},
                    'N:W:N' => {rus => 'Узк:Шир:Узк', eng => 'Nar:Wide:Nar'},
                    'N:N:N' => {rus => 'Узк:Узк:Узк', eng => 'Nar:Nar:Nar'},
                    'W' => {rus => 'Широкая', eng => 'Wide'}},
            # N:W:N   Narrow:Wide
        };
    $p{Attributes}{title} ||= {
        label => { rus => 'Название', eng => 'Name'},
        default => pick_lang(rus => "Личная", eng => "Private"),
        };
    $p{Attributes}{pvtype} ||= {
        label => {rus => 'Тип страницы', eng => 'Type of page'},
        fieldtype => 'popup_menu',
        values => [ qw/ user default template /],
        default => 'user',
        labels => {
                user => {rus => 'Личная', eng => 'Personal'},
                default => {rus => 'По умолч.', eng => 'Default'},
                template => {rus => 'Общая', eng => 'Template'}},
        };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub set_acl_default {   #10/04/01 4:25
############################################################################
	my $self = shift;

    $self->SUPER::set_acl_default;
    if ($self->pvtype eq 'default') {
        $self->xacl_read('everyone');
    } elsif ($self->pvtype eq 'user') {
        $self->xacl_read('owner');
    }
}##set_acl_default



=head2 ColumnsCount()

Return a number of columns in the current PageView.

=cut

############################################################################
sub ColumnsCount	{	#12/13/00 4:25
############################################################################
	my $self = shift;

	my @C = split ':', $self->ColumnsWidth;
	return scalar @C;
}##ColumnsCount


=head2 ColumnsWidthPercent()

Returns array of numbers with width in percent of PageView's columns.
Narrow column counts as 1, wide column - as 2. For two-column PageView
(N:W) result would be (33,66).

I<Note>: The percent sign is not included after numbers.

=cut

############################################################################
sub ColumnsWidthPercent	{	#12/13/00 4:22
############################################################################
	my $self = shift;

	my @Columns = split ":", $self->ColumnsWidth;

	# Count total width of the view. Narrow column counts as 1, wide - 2
	my $total;
	foreach (@Columns) {
		$total += 1 if /N/;
		$total += 2 if /W/;
	}

	# Recalc widths in percent
	my @ColumnsWidth;
	foreach (@Columns) {
		use integer;
		push @ColumnsWidth, 100/$total if /N/;
		push @ColumnsWidth, 100/$total*2 if /W/;
	}

	return @ColumnsWidth;
}##ColumnsWidthPercent



=head2 AvailableSections(column_number)

Returns array (\@values, \%labels) with available sections for addition to
the column. References returned are ready to pass to CGI::popup_menu(...)

B<column_number> is number of desired column in PageView.

=cut

############################################################################
sub AvailableSections	{	#12/13/00 4:35
############################################################################
	my $self = shift;
	my $column = shift;

	my $W = (split ':', $self->ColumnsWidth)[$column-1];

	my $s = new ePortal::PageSection;
	my ($values, $labels) = $s->restore_all_hash("id","title", "width=?", "title", $W);

	return ($values, $labels);
}##AvailableSections

############################################################################
sub restore_default {   #01/27/2004 10:15
############################################################################
    my $self = shift;
    $self->restore_where(where => "pvtype='default'");
    return $self->restore_next;
}##restore_default

=head2 get_UserSection($column)

Does restore_where(for the column) on ePortal::UserSection object.

If $column is undef then all UserSection (for all columns) are selected.
This is the same as call to children().

Returns ePortal::UserSection object ready to restore_next().

=cut

############################################################################
sub get_UserSection	{	#12/14/00 2:03
############################################################################
	my $self = shift;
	my $column = shift;

	my $S = new ePortal::UserSection;
	if ($column) {
		$S->restore_where(where => 'colnum=? and pv_id=?', order_by => 'id', bind => [$column, $self->id]);
	} else {
		$S->restore_where(where => ' pv_id=?', order_by => 'id', bind => [$self->id]);
	}
	return $S;
}##get_UserSection


############################################################################
sub children	{	#10/25/00 2:55
############################################################################
	my $self = shift;
	return $self->get_UserSection;
}##children


############################################################################
sub xacl_check_insert   {   #05/17/01 2:40
############################################################################
	my $self = shift;

	# only registered users
	return 0 if $ePortal->username eq '';

	return 1;
}##acl_check_insert


=head2 CopyFrom($template_id)

Copy PageView object from denoted by $template_id to current one. The
pvtype attribute is changed to 'user'. Also copies all daughter UserSection
objects.

Returns: 1 on success.

=cut

############################################################################
sub CopyFrom	{	#02/05/01 2:48
############################################################################
	my $self = shift;
	my $template_id = shift;

	$self->clear;
	my $PVt = new ePortal::PageView;
    $PVt->restore_or_throw($template_id);

	# Copy ALL data from original
	$self->data ($PVt->data);

	# Redefine some unique for new object attributes
	$self->id(undef);
    $self->uid( $ePortal->username );
	$self->pvtype( 'user' );
	return undef if not $self->insert;

	# Copy all child UserSections
	my $S = new ePortal::UserSection;
    my $St = new ePortal::UserSection;
    $St->restore_where(where => 'pv_id =?', bind => [$template_id]);
    while( $St->restore_next) {
        $S->data( $St->data );
        $S->id(undef);
        $S->pv_id( $self->id );
        $S->insert;
    }
	1;
}##CopyFrom


############################################################################
# Function: value
# Description: Ala trigger. Adjust some attributes when any value changes
############################################################################
sub value	{	#10/04/01 4:34
############################################################################
	my $self = shift;
	my $attr = lc shift;

	if (@_) {	# Assing new value
		my $newvalue = shift;
		if ($attr eq 'pvtype') {
			if ($newvalue eq 'user') {
                $self->xacl_read('owner');
                $self->uid($ePortal->username);

			} elsif ($newvalue eq 'default') {
                $self->xacl_read('everyone');

#           } elsif ($newvalue eq 'template') {
#                $self->xacl_read('everyone');
			}
		}
		return $self->SUPER::value($attr, $newvalue);
	} else {
		return $self->SUPER::value($attr);
	}
}##value



############################################################################
# Function: delete
############################################################################
sub delete	{	#10/15/01 11:32
############################################################################
	my $self = shift;

    if ($self->xacl_check_delete) {
        my $dbh = $self->dbh();
        $dbh->do("DELETE FROM UserSection WHERE pv_id=?", undef, $self->id);
    }

	$self->SUPER::delete();
}##delete


############################################################################
# Некоторые функции для задания константных значений
# Description: Цвет заголовка секции и ее рамки
############################################################################
sub CaptionColor		{	return '#CCCCFF'; }
sub MaxPersonalPages 	{	return 5	}

############################################################################
sub xacl_check_update   {   #04/16/03 4:12
############################################################################
    my $self = shift;
    return 1 if $ePortal->isAdmin;
    return 1 if $self->pvtype eq 'user' and $self->uid eq $ePortal->username;
    return 0;
}##xacl_check_update


############################################################################
sub ObjectDescription   {   #01/22/2004 4:39
############################################################################
    my $self = shift;
    return pick_lang(rus => "Домашняя страница: ", eng => "Home page: ") . 
        $self->Title;
}##ObjectDescription

1;

__END__

=head1 ePortal::PageSection object

ePortal::PageSection package is used to implement a single section on a home
page with a dialog box around it.

Customization of a PageSection is available with a corresponding 
HTML::Mason component file. Some predefined method should exists in this 
component.

Here is a brief description of PageSection's component file:

=head2 The content of a section

To produce a content the component is called with one parameter: 
ePortal::UserSection object. Individual settings are available with 
C<setupinfo> hash stored in database;

 <%init>
 my $section = $ARGS{section};  # ePortal::UserSection object
 my $setupinfo = $section->setupinfo_hash;
 </%init>
 HTML code is here


=head2 initialialization

To initialize PageSection object define some attributes:

 <%attr>
 def_title => { eng => 'Resources catalogue', rus => 'Каталог ресурсов'},
 def_width => 'N',
 def_url => '/catalog/index.htm',
 def_setupinfo_hash => {}
 def_xacl_read => 'everyone'
 </%attr>


=head2 setup_dialog method

This method is used to customize a section with a setup dialog. 
{old_setupinfo} is used for compatibility with old version of ePortal.

 <%method setup_dialog><%perl>
  my $setupinfo = $ARGS{setupinfo};
  if ( $setupinfo->{old_setupinfo} ) {
    $setupinfo->{filename} = $setupinfo->{old_setupinfo};
    delete $setupinfo->{old_setupinfo};
  }
 <&| /dialog.mc:label_value_row, label => pick_lang(rus => "Имя файла", eng => "File name") &>
 <& /dialog.mc:textfield, id => 'filename', 
                          -size => 40,
                          value => $setupinfo->{filename} &>
 </&>
 </%method>

This dialog may be disabled for ordinary users with special attribute

 <%attr>
 disable_user_setup_dialog => 1
 </%attr>


=head2 setup_validate method

This method is used for C<setupinfo> data validation.

 <%method setup_validate><%perl>
  my $setupinfo = $ARGS{setupinfo};
  my $obj = $ARGS{obj};
  if ( $setupinfo->{filename} eq '' ) {
    throw ePortal::Exception::DataNotValid( -text => ...);
  }
 </%perl></%method>


=head2 setup_save method

This method is used to save custom data into C<setupinfo> hash.

 <%method setup_save><%perl>
  my $setupinfo = $ARGS{setupinfo};
  my $args = $ARGS{args};

  foreach (qw/ filename /) {
    $setupinfo->{$_} = $args->{$_} if exists $args->{$_};
  }
 </%perl></%method>

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut

