%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#----------------------------------------------------------------------------
<%once>
my( $catalog,                    # The Catalog object to be shown
  $item,                   # Optional CtlgItem to be shown
  $parent_group,           # nearest Group object or the item itself
  $item_date               # date of new composite item
  );
</%once>
<%cleanup>
  ($catalog, $item, $parent_group) = ();
</%cleanup>
<%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate( @_, {
        catalog => {type => OBJECT, isa => 'ePortal::Catalog', optional => 1},
        item => { type => OBJECT, isa => 'ePortal::CtlgItem', optional => 1},
        item_date => { type => SCALAR, optional => 1},
      });
  }
  $catalog = $ARGS{catalog} || new ePortal::Catalog;
  $item_date = $ARGS{item_date};
  $item = $ARGS{item} || new ePortal::CtlgItem;

  # Looking for nearest parent Group object. We need it for
  # creting new items
  $parent_group = $catalog;
  while( ( $parent_group and 
           $parent_group->check_id and 
           $parent_group->RecordType ne 'group')
          ) {
    $parent_group = $parent_group->parent;
  }

  my $content = $m->scomp('SELF:dialog_content');
  ($catalog, $item, $parent_group) = ();
  return if $content !~ /\w/;
</%perl>
<& /dialog.mc, width => '100%',
      title => pick_lang(rus => "Управление каталогом", eng => "Manage catalogue"),
      content => $content &>
<& /empty_table.mc, height => 5 &>



%#=== @metags dialog_content ====================================================
<%method dialog_content><%perl>

  # ----------------------------------------------------------------------
  # The Catalog group object menu
  my @menu_catalog;
  if ($catalog->RecordType eq 'group' and $parent_group->xacl_check_children) {
    push @menu_catalog, $m->scomp('SELF:menu_item', 
      title => pick_lang(rus => "Добавить раздел", eng => "Add group"),
      href => href('/catalog/group_edit.htm', parent_id => $catalog->id)
      );
    push @menu_catalog, $m->scomp('SELF:menu_item', 
      title => pick_lang(rus => "Добавить ссылку", eng => "Add link"),
      href => href('/catalog/file_edit.htm', parent_id => $catalog->id, recordtype => 'link'),
      );
    push @menu_catalog, $m->scomp('SELF:menu_item', 
      title => pick_lang(rus => "Добавить ресурс", eng => "Add resource"),
      href => href('/catalog/file_edit.htm', parent_id => $catalog->id, recordtype => 'file'),
      );
    push @menu_catalog, $m->scomp('SELF:menu_item', 
      title => pick_lang(rus => "С группировкой по дате", eng => "Groupped by date"),
      href => href('/catalog/file_edit.htm', parent_id => $catalog->id, recordtype => 'composite'),
      );
  }

  # ----------------------------------------------------------------------
  # Current selected item menu
  my @menu_item;
  if ( $catalog->check_id  and $catalog->xacl_check_update ) {
    if ( $catalog->RecordType eq 'composite' ) {
      push @menu_item, $m->scomp('SELF:menu_item', 
        title => pick_lang(rus => "Добавить статью", eng => "Add article"),
        href => href('/catalog/composite_edit.htm', objid => 0, 
                      parent_id => $catalog->id, 
                      item_date => $item_date),
        );
    }

    if ( $catalog->RecordType eq 'group' ) {
      push @menu_item, $m->scomp('SELF:menu_item', 
        title => pick_lang(rus => "Изменить группу", eng => "Edit the group"),
        href => href('/catalog/group_edit.htm', objid => $catalog->id),
        );

    } else {
      push @menu_item, $m->scomp('SELF:menu_item', 
        title => pick_lang(rus => "Изменить ресурс", eng => "Edit resource"),
        href => href('/catalog/file_edit.htm', objid => $catalog->id),
        );
    }

  }

  if ( $catalog->RecordType eq 'composite' and $catalog->xacl_check_update) {
      push @menu_item, $m->scomp('SELF:menu_item', 
        title => pick_lang(rus => "Уровни группировок", eng => "Groupping"),
        href => href('/catalog/compositecat_edit.htm', objid => $catalog->id ),
        );
  }

  if ( $catalog->check_id  and $catalog->xacl_check_delete ) {
      push @menu_item, $m->scomp('SELF:menu_item', 
        title => pick_lang(rus => "Удалить ресурс", eng => "Delete resource"),
        href => href('/delete.htm', objid => $catalog->id, objtype => ref($catalog), 
                  back_url => '/catalog/' . (0+$catalog->parent_id) . '/' ),
        );
  }

  # ----------------------------------------------------------------------
  # Personal composite item
  my @menu_composite;
  if ( $item->check_id and $item->xacl_check_update ) {
    push @menu_composite, $m->scomp('SELF:menu_item', 
      title => pick_lang(rus => "Изменить статью", eng => "Edit article"),
      href => href('/catalog/composite_edit.htm', objid => $item->id ),
      );
    push @menu_composite, $m->scomp('SELF:menu_item', 
      title => pick_lang(rus => "Удалить статью", eng => "Delete article"),
      href => href('/delete.htm', objid => $item->id, objtype => ref($item), 
                back_url => '/catalog/' . (0+$item->parent_id) . '/?cal_date=' . $item_date ),
      );
  }
</%perl>

% if (@menu_composite) {    
  <b>::&nbsp;<% pick_lang(rus => "Статья", eng => "Article") %></b>
  <ul><% join "\n", @menu_composite %></ul>
% }

% if (@menu_item) {    
  <b>::&nbsp;<% truncate_string($catalog->Title, 20) |h %></b>
  <ul><% join "\n", @menu_item %></ul>
% }

% if (@menu_catalog) {
  <b>::&nbsp;<% pick_lang(rus => "Добавление в каталог", eng => "Catalogue additions") %></b>
  <ul><% join "\n", @menu_catalog %></ul>
% }

</%method>


%#=== @metags menu_item ====================================================
<%method menu_item><%perl>
  my $title = $ARGS{title};
  my $href = $ARGS{href};
</%perl>
<li><a href="<% $href %>"><% $title |h %></a>
</%method>
