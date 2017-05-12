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
# The main ThePersistent class without ACL checking. All system tables
# without ACL should grow from this class
# ------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::Support - Helper package between ThePersistent
classes and ePortal.

=head1 SYNOPSIS

ePortal::ThePersistent classes are entirely independent of ePortal itself.
ePortal::ThePersistent::Support is medium layer between them.

=head1 METHODS

=cut

package ePortal::ThePersistent::Support;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::Cached/;

    use Carp;
    use ePortal::Global;
    use ePortal::Utils;     # import logline, pick_lang
    use Apache::Util qw/escape_html escape_uri/;
    use Params::Validate qw/:types/;

    use Error qw/:try/;
    use ePortal::Exception;

############################################################################
sub initialize  {   #07/03/00 4:08
############################################################################
    my $self = shift;

    $self->SUPER::initialize(DBH => $ePortal->dbh, @_ );
}##initialize






############################################################################
my %initialize_attribute_defaults = (
############################################################################
    id => {
        type => 'ID',
        dtype => 'Number',
        auto_increment => 1,
    },
    enabled => {
        label      => {rus => 'Вкл/выкл', eng => 'Enabled'},
        dtype      => 'YesNo',
        default    => 1,
    },
    ts => {
        label      => { rus => 'Последнее изменение', eng => 'Time stamp'},
        dtype      => 'DateTime',
    },
    title => {
        label      => {rus => 'Наименование', eng => 'Name'},
        size       => 40,
    },
    author => {
        label      => {rus => 'Автор документа', eng => 'Author'},
        size       => 64,
        default    => sub { $ePortal->username },
    },
    nickname => {
        label      => {rus => 'Короткое имя', eng => 'Nickname'},
        size       => 20,
    },
    priority => {
        label      => {rus => 'Приоритет', eng => 'Priority'},
        dtype      => 'Number',
        maxlength  => 4,
        fieldtype  => 'popup_menu',
        values     => [ 1 .. 9 ],
        default    => 5,
        labels     => {
                1 => { rus => '1-Высокий', eng => '1-High'},
                2 => '2',
                3 => '3',
                4 => '4',
                5 => {rus => '5-Средний', eng => '5-Medium'},
                6 => '6',
                7 => '7',
                8 => '8',
                9 => {rus => '9-Низкий', eng => '9-Low'},
            },
    },
    memo => {
                label => {rus => 'Примечания', eng => 'Memo'},
                fieldtype => 'textarea',
                rows => 4,
                columns => 50,
    },
    upload_file => {
            type => 'Transient',
            label => { rus => 'Прикрепить файл', eng => 'Attach a file'},
            dtype => 'Varchar',
            fieldtype => 'upload',
    },
    firstcreated => {
        label      => { rus => 'Дата создания', eng => 'Create time'},
        dtype      => 'DateTime',
    },
    lastmodified => {
        label      => { rus => 'Последнее изменение', eng => 'Last edited'},
        dtype      => 'DateTime',
    },
    lastmodifieduid => {
        label      => {rus => 'Автор посл.изменения', eng => 'Last editor'},
        size       => 64,
        default    => sub { $ePortal->username },
    },  
);

############################################################################
sub initialize_attribute    {   #05/27/2003 3:37
############################################################################
    my ($self, $att_name, $attr) = @_;

    if (my $H = $initialize_attribute_defaults{$att_name}) {
        foreach (keys %$H) {
            $attr->{$_} ||= ref($H->{$_}) eq 'CODE'
                ? $H->{$_}()
                : $H->{$_};
        }
    }
    $self->SUPER::initialize_attribute($att_name, $attr);
}##initialize_attribute

############################################################################
# Function: insert
# Description: Overloaded.
#   Если объект содержит атрибут id и он == 0
# Parameters: None
# Returns:
#   1 on success,
#   undef on error,
#   0 on access violation
#
############################################################################
sub insert  {   #07/04/00 1:18
############################################################################
    my $self = shift;

    # --------------------------------------------------------------------
    # Check if ID field is auto_increment
    my ($id_field, $id_is_autoincrement);
    if ($id_field = $self->attribute('id')) {
        $id_is_autoincrement = $id_field->{auto_increment};
    }


    # --------------------------------------------------------------------
    # Validate this object before insert
    my $err_msg = $self->validate(1);
    throw ePortal::Exception::DataNotValid( -text => $err_msg, -object => $self)
        if ($err_msg);

    # --------------------------------------------------------------------
    # Set LastModified field
    if ($self->attribute('firstcreated')) {
        $self->value('firstcreated', 'now');
    }
    if ($self->attribute('lastmodified')) {
        $self->value('lastmodified', 'now');
    }
    if ($self->attribute('lastmodifieduid')) {
        $self->value('lastmodifieduid', $ePortal->username);
    }

    # Do INSERT
    my $result = $self->SUPER::insert(@_);

    if ($id_is_autoincrement and $result) {
        my $newid = $self->dbh->selectrow_array('SELECT last_insert_id()');
        $self->id( $newid );
        warn "Cannot get last_insert_id" if $newid == 0;
    }

    return $result;
}##insert


############################################################################
# Function: update
# Description:
############################################################################
sub update  {   #10/26/01 9:05
############################################################################
    my $self = shift;

    # --------------------------------------------------------------------
    # Validate this object before update
    my $err_msg = $self->validate(0);
    throw ePortal::Exception::DataNotValid( -text => $err_msg, -object => $self)
        if $err_msg;

    if ($self->attribute('lastmodified')) {
        $self->value('lastmodified', 'now');
    }
    if ($self->attribute('lastmodifieduid')) {
        $self->value('lastmodifieduid', $ePortal->username);
    }

    return $self->SUPER::update(@_);
}##update


############################################################################
# Function: delete
# Description: Overloaded. Deletes ACL for the object. Исключение составляет
#   объект ACL, т.к. получится бесконечная рекурсия.
# Parameters: same as for ePortal::ThePersistent::Base::delete
# Returns: Count of deleted objects
#
############################################################################
sub delete  {   #09/19/00 4:00
############################################################################
    my $self = shift;
    my $counter;

    die "Recursive delete does not allow ID as parameter" if @_;

    my $children = $self->children;

    if (ref($children) eq 'ARRAY') {
        foreach my $child ( @{$children} ) {
            $counter += $child->delete();
        }
    } elsif ( UNIVERSAL::isa($children,'ePortal::ThePersistent::Base') ) {
        while ($children->restore_next) {
            $counter += $children->delete();
        }
    }

    $counter += $self->SUPER::delete();
    return $counter;
}##delete


############################################################################
# Function: parent
# Description: Прототип.
#   Возвращает ThePersistent объект-родитель. Это необходимо
#   для наследования прав ACL.
#   Этот метод необходимо перегружать.
# Parameters: None
# Returns:
#   undef если данный объект в принципе не имеет родителя (top level object)
#   ThePersistent object
#
############################################################################
sub parent  {   #09/25/00 10:26
############################################################################
    return undef;
}##parent

############################################################################
# Function: children
# Description: Прототип.
#   Возвращает либо ThePersistent объект, содержащий всех
#   наследников (применительно к ACL) для данного объекта, либо
#   ссылку на массив готовых ThePersistent объектов.
# Parameters: None
# Returns: undef or ThePersistent object or array ref
#
############################################################################
sub children    {   #10/24/00 1:49
############################################################################
    return undef;
}##children




############################################################################
# Function: restore
# Description: Overloaded function. Accepts as argument ID or nickname
# Parameters: ID or nickname
# Returns: The same value as restore
#
############################################################################
sub restore {   #02/21/01 2:54
############################################################################
    my $self = shift;
    my @id = @_;

    my $result = $self->SUPER::restore(@id);
    if (!$result and $self->attribute('nickname')) {
        $self->restore_where(where => "nickname=?", bind => [$id[0]]);
        $result = $self->restore_next();
    }

    if (ref ($self->{STH})) {
      $self->{STH}->finish;
      $self->{STH} = undef;
    }

    return $result;
}##restore


############################################################################
sub restore_or_throw    {   #02/27/03 2:05
############################################################################
    my $self = shift;

    if (! $self->restore(@_)) {
        throw ePortal::Exception::ObjectNotFound( -object => $self,-value => $_[0] );
    }
    1;
}##restore_or_throw

############################################################################
# Function: restore_all_array
# Description: Возвращает ссылку на массив значений конкретного поля.
# Parameters:
#   attribute (field name)
#   where clause
#   order by
# Returns: array ref
#
sub restore_all_array   {   #11/01/00 9:36
############################################################################
    my $self = shift;
    my $field = shift;
    my $where = shift;
    my $order_by = shift;
    my @bind_values;

    # Здесь храним данные
    my @nb_values;

    # Делаем работу
    #eval {
    $self->restore_where(where => $where, order_by => $order_by, bind => \@bind_values);
    #};
    while($self->restore_next) {
        push @nb_values, $self->value($field);
    }

    return \@nb_values;
}##restore_all_array


############################################################################
# Function: restore_all_hash
# Description: Возвращает ссылку на хэш из двух конкретных полей. Также
#   Возвращается в list context ссылка массив ключей этого хэша в порядке,
#   указанным order by.
# Parameters:
#   attribute (field name) for hash key
#   attribute (field name) for hash value
#   where clause
#   order by
# Returns: hash ref [array ref]
#
sub restore_all_hash    {   #11/01/00 9:39
############################################################################
    my $self = shift;
    my $hashkey = shift || 'id';
    my $hashvalue = shift || 'title';
    my $where = shift;
    my $order_by = shift;
    my @bind_values = @_;

    # Здесь храним данные
    my @nb_values;
    my %nb_labels;

    $self->restore_where(where => $where, order_by => $order_by, bind => \@bind_values);
    while($self->restore_next) {
        push @nb_values, $self->value($hashkey);
        $nb_labels{ $self->value($hashkey) } = $self->value($hashvalue) || $self->value($hashkey);
    }

    return wantarray? (\@nb_values, \%nb_labels): \%nb_labels;
}##restore_all_hash


############################################################################
# Function: validate.
#   Dummy function. Always returns all Ok! You must overload it!
# Description: Validates this object before inserting or updating it.
# Parameters:
#   param1 != 0 if validating before insert operation
# Returns:
#   undef if all Ok
#   pick_lang message with error description
#
############################################################################
sub validate    {   #02/20/01 4:40
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    if ( $self->attribute('title') and $self->title eq '') {
        return pick_lang(rus => "Не указано наименование", eng => 'No name');
    }

    undef;
}##validate


############################################################################
# Function: value_from_req
# Description: Unsafe way to assign a value to attribute.
# Object may check this value for sanity.
# Parameters:
#   attribute name
#   new value
# Returns:
#
############################################################################
sub value_from_req  {   #09/08/2003 9:45
############################################################################
    my ($self, $att, $value) = @_;
    $self->value($att, $value);
}##value_from_req



############################################################################
# Function: htmlLabel
# Description: Label of the object
# Parameters: attribute name
# Returns: HTML string
#
############################################################################
sub htmlLabel   {   #03/31/01 11:05
############################################################################
    my $self = shift;
    my $attr = lc shift;
    my $label;

    my $A = $self->attribute($attr);
    if (not defined $A->{label}) {
        $label = "Label not defined for [$attr]";
    } else {
        $label = $A->{label};
        $label = pick_lang($label) if ref($label) eq 'HASH';
    }

    return qq{<span class="dlglabel">$label</span>};
}##htmlLabel

############################################################################
# Function: htmlValue
# Description: Read-only value of attribute
# Parameters: attribute name
# Returns: HTML string
#
############################################################################
sub htmlValue   {   #03/31/01 11:09
############################################################################
    my $self = shift;
    my $attr = lc shift;
    my $v;

    eval { $v = $self->value($attr) };
    if ($@) {
        return '<span style="color:#FF0000">' .
            "Attribute $attr does not exists in object " . ref($self) .
            '</span>';
    }

    my $a = $self->attribute($attr);
    if ($a and $a->{fieldtype} eq 'popup_menu') {
        my $a = $self->attribute($attr);
        $v = $a->{labels}{$self->value($attr)} if ref($a->{labels}) eq 'HASH';
        if (ref($a->{popup_menu}) eq 'CODE') {
            my ($val, $lab) = $a->{popup_menu}($self);
            $v = $lab->{$self->value($attr)};
        }
        $v ||= $self->value($attr);

    } elsif ($a and $a->{dtype} eq 'YesNo') {
        if ($v) {
            $v = pick_lang(rus => "Да", eng => "Yes");
        } else {
            $v = pick_lang(rus => "Нет", eng => "No");
        }
    }


    $v = pick_lang($v) if ref($v) eq 'HASH';

    return escape_html( $v );

#   return '<span class="dlgfield">' .
#       escape_html( $v ) .
#       '</span>';
}##htmlValue



############################################################################
# Function: htmlField
# Description:Test field for a attribute
# Parameters:
#   attribute name, hash with optional parameters
#       fieldtype - type of dialog control
#       other parameters to CGI() function
# Returns: HTML string
#
############################################################################
sub htmlField   {   #03/31/01 11:12
############################################################################
    my $self = shift;
    my $attr = lc shift;
    my %p = @_;

    # CGI parameters by default
    my %CGI = (
        -class => 'dlgfield',
        -name => $attr,
    );

    # Guess some parameters from object attribute
    my $fieldtype;
    my $defaultvalue;
    my $A = $self->attribute($attr);
    if ($A) {
        $defaultvalue = $self->value($attr);
        $defaultvalue = join(', ', @$defaultvalue) if ( $A->{dtype} =~ /^Ar/i );

        foreach (qw/size maxlength rows columns/) {
            $p{"-$_"} ||= $A->{$_} if defined $A->{$_};
        }

        $fieldtype = $A->{fieldtype};
        $fieldtype = 'YesNo' if ($A->{dtype} eq 'YesNo');
        $fieldtype = 'date' if ($A->{dtype} =~ /^Date/i);
        $fieldtype = 'datetime' if ($A->{dtype} =~ /^DateT/i);
    }
    $fieldtype ||= $p{fieldtype} || 'textfield' if not $fieldtype;

    #
    #--- popup_menu ---
    #
    if ($fieldtype eq 'popup_menu') {
        if ($A) {
            $CGI{-labels} = $A->{labels} if ref($A->{labels}) eq 'HASH';
            $CGI{-values} = $A->{values} if ref($A->{values}) eq 'ARRAY';
            if (ref($A->{values}) eq 'CODE') {
                $CGI{-values} = $A->{values}($self);
            }
            if (ref($A->{popup_menu}) eq 'CODE') {
                ($CGI{-values},$CGI{-labels}) = $A->{popup_menu}($self);
            }
        }
        $CGI{'-default'} = $defaultvalue;
        foreach my $key (qw /-labels -values -default -class -name/) {
            $CGI{$key} = $p{$key} if exists $p{$key};
        }

        if (ref($CGI{-labels}) eq 'HASH') {
            foreach (keys %{$CGI{-labels}}) {
                $CGI{-labels}{$_} = pick_lang($CGI{-labels}{$_}) if ref($CGI{-labels}{$_}) eq 'HASH';
            }
        }

        return CGI::popup_menu( {%CGI} );
    };


    #
    #--- textfield ---
    #
    if ($fieldtype eq 'textfield') {
        $CGI{'-value'} = $defaultvalue;
        $CGI{'-size'} = 30;
        $CGI{'-maxlength'} = $defaultmaxlength || 64;
        foreach my $key (qw /-class -maxlength -name -size -value/) {
            $CGI{$key} = $p{$key} if exists $p{$key};
        }
        return CGI::textfield( {%CGI} );
    };

    #
    #--- password ---
    #
    if ($fieldtype eq 'password') {
        $CGI{'-value'} = $defaultvalue;
        $CGI{'-size'} = 30;
        $CGI{'-maxlength'} = $defaultmaxlength || 64;
        foreach my $key (qw /-class -maxlength -name -size -value/) {
            $CGI{$key} = $p{$key} if exists $p{$key};
        }
        return CGI::password_field( {%CGI} );
    };

    #
    #--- textarea ---
    #
    if ($fieldtype eq 'textarea') {
        $CGI{'-default'} = $defaultvalue;
        $CGI{'-rows'} = 8;
        $CGI{'-columns'} = 70;
        foreach my $key (qw /-class -default -rows -columns /) {
            $CGI{$key} = $p{$key} if exists $p{$key};
        }
        return CGI::textarea( {%CGI} );
    };

    #
    #--- upload ---
    #
    if ($fieldtype eq 'upload') {
        $CGI{'-default'} = $defaultvalue;
        $CGI{'-size'} = 30;
        foreach my $key (qw /-class -default -size -maxlength/) {
            $CGI{$key} = $p{$key} if exists $p{$key};
        }
        return CGI::filefield( {%CGI} );
    };

    #
    #--- YesNo ---
    #
    if ($fieldtype eq 'YesNo') {
        $CGI{'-default'} = $defaultvalue;
        $CGI{-values} = [0, 1];
        $CGI{-labels} = {
                1 => pick_lang(rus => 'Да',  eng => 'Yes'),
                0 => pick_lang(rus => 'Нет', eng => 'No')
        };
        return CGI::popup_menu( {%CGI} );
    }

    #
    #--- checkbox ---
    #
    if ($fieldtype eq 'checkbox') {
        $CGI{'-checked'} = $defaultvalue;
        $CGI{'-value'} = 1;
        $CGI{'-label'} = '';
        foreach my $key (qw /-class -default -value -label/) {
            $CGI{$key} = $p{$key} if exists $p{$key};
        }

        $CGI{-label} = pick_lang($CGI{-label}) if ref($CGI{-label}) eq 'HASH';

        return CGI::checked( {%CGI} );
    }

    #
    #--- Date --- DateTime ---
    #
    my $date_field_style =  $p{date_field_style} ||
                            $ePortal->UserConfig('date_field_style') ||
                            $ePortal->date_field_style;
    if ($date_field_style ne 'java' and ($fieldtype eq 'date' or $fieldtype eq 'datetime')) {
        my @date = split('[\s\.]+', $defaultvalue, 4);
        my %CGIdate = %CGI;
        my %CGImonth = %CGI;
        my %CGIyear = %CGI;
        my %CGItime = %CGI;

        $CGIdate{-value} = $date[0];
        $CGIdate{-size} = 2;
        $CGIdate{-maxlength} = 2;
        $CGIdate{-name} = $attr . '_d';

        $CGImonth{-default} = ($date[1] * 1) ||  (Date::Calc::Today())[1];
        $CGImonth{-values} = [1..12];
        $CGImonth{-name} = $attr . '_m';
        $CGImonth{-labels} = pick_lang( rus => {
                            1 => "январь", 2 => "февраль", 3 => "март",
                            4 => "апрель", 5 => "май", 6 => "июнь",
                            7 => "июль", 8 => "август", 9 => "сентябрь",
                            10 => "октябрь", 11 => "ноябрь", 12 => "декабрь"},
                            eng => {
                            1 => "January", 2 => "February", 3 => "March",
                            4 => "April", 5 => "May", 6 => "June",
                            7 => "July", 8 => "August", 9 => "September",
                            10 => "Oktober", 11 => "November", 12 => "December"},
                            );

        $CGIyear{-name} = $attr . '_y';
        $CGIyear{-value} = $date[2] || (Date::Calc::Today())[0];
        $CGIyear{-size} = 4;
        $CGIyear{-maxlength} = 4;

        $CGItime{-name} = $attr . '_t';
        $CGItime{-value} = $date[3] || join ':', (Date::Calc::Now())[0,1];
        $CGItime{-size} = 5;
        $CGItime{-maxlength} = 5;
        $CGItime{-onBlur} = "javascript:ValidateTime('$CGItime{-name}');return true;";

        if ($fieldtype eq 'date') {     # only Date part
            return CGI::textfield( {%CGIdate} ) . '.' .
                    CGI::popup_menu( {%CGImonth} ) . '.' .
                    CGI::textfield( {%CGIyear} ) ;
        } else {    # DateTime
            return CGI::textfield( {%CGIdate} ) . '.' .
                    CGI::popup_menu( {%CGImonth} ) . '.' .
                    CGI::textfield( {%CGIyear} ) . ' : ' .
                    CGI::textfield( {%CGItime} );
        }
    }

    if ($date_field_style eq 'java' and ($fieldtype eq 'date' or $fieldtype eq 'datetime')) {
        my @date = split('[\s\.]+', $defaultvalue, 4);
        my %CGIdate = %CGI;
        my %CGItime = %CGI;

        $CGIdate{-value} = (split ' ', $defaultvalue)[0];
        $CGIdate{-size} = 10;
        $CGIdate{-maxlength} = 10;
        $CGIdate{-name} = $attr . '_date';
        $CGIdate{-onBlur} = "javascript:ValidateDate('$CGIdate{-name}');return true;";

        $CGItime{-name} = $attr . '_time';
        $CGItime{-value} = (split ' ', $defaultvalue)[1] || '00:00:00';
        $CGItime{-size} = 8;
        $CGItime{-maxlength} = 8;
        $CGItime{-onBlur} = "javascript:ValidateTime('$CGItime{-name}');return true;";

        my $click_here = pick_lang(rus => 'Нажмите сюда, чтобы появился календарь',
            rus => 'Click here to show calendar window');
        my $html = CGI::textfield( {%CGIdate} ) .
                CGI::a( {-href => "javascript:DateSelector('$CGIdate{-name}')",
                    -onMouseOver => "window.status='$click_here';return true;",
                    -onMouseOut => "window.status='';return true;",
                    -title => $click_here},
                    img(src => "/images/ePortal/pdate.gif"));

        if ($fieldtype eq 'datetime') {
            $html .= '&nbsp;' . CGI::textfield( {%CGItime} );
        }
        return $html;
    }

    if ($fieldtype eq 'popup_tree') {
        $CGI{'-value'} = $defaultvalue;
        $CGI{'-size'} = 30;
        $CGI{'-maxlength'} = $defaultmaxlength || 64;
        foreach my $key (qw /-class -maxlength -name -size -value/) {
            $CGI{$key} = $p{$key} if exists $p{$key};
        }

        my $click_here = pick_lang(rus => 'Нажмите сюда, чтобы появился календарь',
            rus => 'Click here to show calendar window');

        my $objid = $self->id;
        my $objtype = ref($self);

        return CGI::textfield( {%CGI} ) .
                CGI::a( {-href => "javascript:TreeSelector('$CGI{-name}',$objid,'$objtype');",
                    -onMouseOver => "window.status='$click_here';return true;",
                    -onMouseOut => "window.status='';return true;",
                    -title => $click_here},
                    img(src => "/images/ePortal/pdate.gif"))
    }

    #
    #--- xacl --- ExtendedACL
    #
    if ($fieldtype eq 'xacl') {
        $CGI{-values} = ['admin', 'everyone', 'uid', 'gid','registered', 'owner'];
        $CGI{-labels} = {
                admin => pick_lang(rus => 'Только администратор',  eng => 'Admin only'),
                everyone => pick_lang(rus => 'Все', eng => 'Everyone'),
                uid => pick_lang(rus => 'Только пользователь', eng => 'Only user'),
                gid => pick_lang(rus => 'Группа пользователей', eng => 'Group of users'),
                owner => pick_lang(rus => 'Владелец', eng => 'Owner'),
                registered => pick_lang(rus => 'Зарегистрированный', eng => 'Registered'),
        };
        $CGI{-onchange} = "on_change_xacl_combo('$attr');";

        # current values
        my ($uid_def, $gid_def);
        my ($uid_style, $gid_style) = ('none', 'none');
        if ($defaultvalue =~ /^uid:(.*)/) {
            $defaultvalue = 'uid';
            $uid_def = $1;
            $uid_style = 'inline';
        }
        if ($defaultvalue =~ /^gid:(.*)/) {
            $defaultvalue = 'gid';
            $gid_def = $1;
            $gid_style = 'inline';
        }
        $CGI{'-default'} = $defaultvalue;

        # list of groups
        my $G = new ePortal::epGroup;
        my ($G_values, $G_labels) = $G->restore_all_hash('groupname','groupname', 'hidden=0');

        return CGI::popup_menu( {%CGI} ) .
            '<div id="'. $attr.
                '_uidspan" class="smallfont" style="display:'.
                $uid_style . ';"><br>' .
            pick_lang(rus => 'Имя:', eng => 'Name:') .
            CGI::textfield({
                    -name => $attr.'_uid',
                    -class => 'dlgfield',
                    -size => 20,
                    -value => $uid_def}) .
            qq{</div>} .
            '<div id="'.$attr.'_gidspan" class="smallfont" style="display:'.$gid_style.';"><br>' .
            pick_lang(rus => 'Группа:', eng => 'Group:') .
            CGI::popup_menu({
                    -name => $attr.'_gid',
                    -class => 'dlgfield',
                    -values => $G_values,
                    -labels => $G_labels,
                    -default => $gid_def}) .
            qq{</div>}

            ;
    }

    die "Unknown fieldtype parameter for htmlField [$fieldtype]";
}##htmlField


############################################################################
# Function: htmlSave
# Description: Get parameters from HTTP request, update or create new
#   object.
# Parameters: %ARGS from mason component
# Returns: throw Exception on error
#
############################################################################
sub htmlSave    {   #04/02/01 1:22
############################################################################
    my $self = shift;
    my %ARGS = @_;

    # Save attributes from HTTP request into self
    FIELD:
    foreach my $field ( $self->attributes ) {
        next FIELD if $field eq 'id';

        # Date and DateTime fields may be passed as multi-field. See htmlField
        # for details
        my $A = $self->attribute($field);
        if ( $A->{dtype} =~ /^DateT/oi ) {
            if ( exists $ARGS{$field.'_d'} ) {      # combobox style
                my $datestring = $ARGS{$field.'_d'} . '.' . $ARGS{$field.'_m'} . '.' .$ARGS{$field.'_y'} . ' ' .$ARGS{$field.'_t'};
                eval { $self->value($field, $datestring); };
                $self->value($field, undef) if $@;
                next FIELD;

            } elsif ( exists $ARGS{$field.'_date'} ) {  # java style
                my $datestring = $ARGS{$field.'_date'} . ' ' .$ARGS{$field.'_time'};
                eval { $self->value($field, $datestring); };
                $self->value($field, undef) if $@;
                next FIELD;
            }

        } elsif ( $A->{dtype} =~ /^Date/oi ) {
            if ( exists $ARGS{$field.'_d'} ) {      # combobox style
                my $datestring = $ARGS{$field.'_d'} . '.' . $ARGS{$field.'_m'} . '.' .$ARGS{$field.'_y'};
                eval { $self->value($field, $datestring); };
                $self->value($field, undef) if $@;
                next FIELD;

            } elsif ( exists $ARGS{$field.'_date'} ) {  # java style
                my $datestring = $ARGS{$field.'_date'};
                eval { $self->value($field, $datestring); };
                $self->value($field, undef) if $@;
                next FIELD;
            }

        } elsif ($field =~ /^xacl_/o) {     # ExtendedACL
            next if ! exists $ARGS{$field};
            my $v = $ARGS{$field};
            if ($v eq 'uid') { $v = 'uid:' . $ARGS{$field . '_uid'}; }
            if ($v eq 'gid') { $v = 'gid:' . $ARGS{$field . '_gid'}; }
            $self->value($field, $v);
            next FIELD;

        } elsif ( $A->{dtype} =~ /^Ar/oi) { # Array
            next if ! exists $ARGS{$field};
            my $v = [split('\s*,\s*', $ARGS{$field})];
            $self->value($field, $v);
            next FIELD;
        }

        # Default field processing
        if (exists $ARGS{$field}) {
            $self->value($field, $ARGS{$field});
        }
    }

    if (! $ARGS{skip_object_insert_update}) {
        if ($self->check_id()) {
            return $self->update;
        } else {
            return $self->insert;
        }
    }
}##htmlSave

############################################################################
sub htmlSave2    {   #04/02/01 1:22
############################################################################
    my $self = shift;
    my %ARGS = @_;

    # Save attributes from HTTP request into self
    FIELD:
    foreach my $field ( $self->attributes_at ) {
        next if ! exists $ARGS{$field};

        my $A = $self->attribute($field);
        if ( $A->{dtype} =~ /^Ar/oi) { # Array
            $ARGS{$field} = [split('\s*,\s*', $ARGS{$field})];
        }

        try {
            $self->value_from_req($field, $ARGS{$field});
        } otherwise {
            throw ePortal::Exception::DataNotValid(-text => 
            pick_lang(rus => "Несовместимый формат данных: $field", eng => "Incompatible data format: $field"));
        };
    }
}##htmlSave2


############################################################################
# Function: export_to_string
# Description: Export object data into text string
# Parameters: none
# Returns: text string with object
#
############################################################################
sub export_to_string    {   #05/29/01 12:58
############################################################################
    my $self = shift;

    # Export myself
    my $export_string = '[' . ref($self) . "]\r\n";
    foreach my $field ( $self->attributes ) {
        my $v = $self->value($field);
        $v =~ s/\r/\\r/g;
        $v =~ s/\n/\\n/g;
        $export_string .= lc($field) . "=$v\r\n";
    }
    $export_string .= "\r\n";

    # Export children
    my $ch = $self->children;
    if (ref $ch) {
        while($ch->restore_next) {
            $export_string .= $ch->export_to_string();
        }
    }

    return $export_string;
}##export_to_string


############################################################################
# Function: import_object
# Description: Import object from external storage
# Parameters:
#   data hasref
#   id of parent object
# Returns:
#   undef on error
#
############################################################################
sub import_object   {   #05/31/01 3:22
############################################################################
    my $self = shift;
    my $data = shift;
    my $parent_id = shift;      # not used here. Please overload like
                                # $data->{parent_id} = $parent_id

    $self->data($data);
    $self->id(undef);       # clear ID attribute

    $self->insert;
}##import_object


############################################################################
sub ObjectDescription   {   #04/15/03 10:46
############################################################################
    my $self = shift;

    return $self->Title if $self->attribute('title');

    return ref($self) . ':' . $self->_id;
}##ObjectDescription


############################################################################
# Function: attachment
# Description: Returns ThePersistent object with attachments
############################################################################
sub Attachment  {   #06/16/2003 4:53
############################################################################
    my $self = shift;

    my $att = new ePortal::Attachment;
    $att->restore_where(obj => $self);
    return undef if ! $att->restore_next;
    return $att;
}##attachment

############################################################################
# Function: Attachments
# Description: Number of attachments of the object
#
############################################################################
sub Attachments {   #10/16/2003 3:04
############################################################################
    my $self = shift;
    
    return scalar $self->dbh->selectrow_array(
        "SELECT count(*) FROM Attachment WHERE object_id=?",
        undef, sprintf("%s=%d", ref($self), $self->id));
}##Attachments

1;


__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
