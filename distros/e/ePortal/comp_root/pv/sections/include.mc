%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
%# "Include file" section
%#----------------------------------------------------------------------------

<% $text %>

%#=== @metags init =========================================================
<%init>
	my $section = $ARGS{section};
  my $setupinfo = $section->setupinfo_hash;

  my $filename = $setupinfo->{filename};
	my $text;

  if ( -f $filename ) {
    open(F, $filename);
    $text = join '', <F>;
    close F;

  } elsif ($m->comp_exists($filename)) {
    $text = eval { $m->scomp($filename); };
    if ($@) {
      warn $@;
      $text = pick_lang( rus => "Ошибка при чтении файла $filename",
          eng => "Error while reading file $filename");
    }

 	} else {
    $text = pick_lang( rus => "Файл $filename не существует",
        eng => "File $filename doesn't exists");
  }
</%init>


%#=== @METAGS attr =========================================================
<%attr>
def_title => { eng => "Include file", rus => "Включение файла"}
def_width => 'W'
def_xacl_read => 'everyone'
def_setupinfo_hash => { filename => '/path/filename.htm' }
disable_user_setup_dialog => 1
</%attr>



%#=== @METAGS setup_dialog ====================================================
<%method setup_dialog><%perl>
  # Надо нарисовать внутреннюю часть диалога для настройки секции.
  # Исходные данные получаются в виде $setupinfo - hash
  # Возможные старые данные хранятся как {old_setupinfo}.
  my $setupinfo = $ARGS{setupinfo};

  # Convert old version data
  if ( $setupinfo->{old_setupinfo} ) {
    $setupinfo->{filename} = $setupinfo->{old_setupinfo};
    delete $setupinfo->{old_setupinfo};
  }

</%perl>
<&| /dialog.mc:label_value_row, label => pick_lang(rus => "Имя файла", eng => "File name") &>
 <& /dialog.mc:textfield, id => 'filename', 
                          -size => 40,
                          value => $setupinfo->{filename} &>
  <br>
  <span class="memo">
    <% pick_lang(rus => "Полный путь и имя файла", 
      eng => "Full path and file name") %>
  </span>

</&>
</%method>



%#=== @METAGS setup_validate ====================================================
<%method setup_validate><%perl>
  my $setupinfo = $ARGS{setupinfo};
  my $obj = $ARGS{obj};
  
  if ( $setupinfo->{filename} eq '' ) {
    throw ePortal::Exception::DataNotValid( -text => pick_lang(
          rus => "Имя файла включения не указано", 
          eng => "No file name"));
  }

  if ( (! -f $setupinfo->{filename}) and ! $m->comp_exists($setupinfo->{filename}) ) {
    throw ePortal::Exception::DataNotValid( -text => pick_lang(
          rus => "$setupinfo->{filename}: Файл не найден", 
          eng => "$setupinfo->{filename}: File not found"));
  }
</%perl></%method>

%#=== @METAGS setup_save ====================================================
<%method setup_save><%perl>
  my $setupinfo = $ARGS{setupinfo};
  my $args = $ARGS{args};

  foreach (qw/ filename /) {
    $setupinfo->{$_} = $args->{$_} if exists $args->{$_};
  }
</%perl></%method>
