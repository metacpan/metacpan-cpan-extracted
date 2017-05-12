%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<b><% pick_lang(rus => "Синхронизация пользователей LDAP", eng => "LDAP users synchronization job") %></b>
<p><blockquote>
<%perl>
  use ePortal::Auth::LDAP;
  my %created_ldap_groups;
  my $ldap_users_checked = 0;

  my $user = new ePortal::epUser;
  $user->restore_where( ext_user => 1);

  USER:
  while($user->restore_next) {
    my $ldap = new ePortal::Auth::LDAP($user->username);
    my $user_exists = $ldap->check_account;

    # --------------------------------------------------------------------
    # Check user existance
    if ( ! $user_exists ) {
      $job->CurrentResult('done');
      $m->print( sprintf("<br>[%s] %s - %s\n", $user->username, $user->FullName, 
        pick_lang(rus => "Пользователь не существует в LDAP. Удаляю...", 
              eng => "User does not exists in LDAP. Deleting...")));

      $user->delete;
      next USER;
    }

    # --------------------------------------------------------------------
    # Refresh user information
    $user->FullName( $ldap->full_name );
    $user->Title( $ldap->title );
    $user->Department( $ldap->department );
    $user->last_checked('now');
    $user->update;
    $ldap_users_checked ++;

    # --------------------------------------------------------------------
    # Create missing LDAP groups
    my @ldap_groups = $ldap->membership;
    my $G = new ePortal::epGroup;
    foreach my $g (@ldap_groups) {
      next if $G->restore($g);

      $G->GroupName( $g );
      $G->GroupDesc( $ldap->group_title($g) || $g );
      $G->ext_group(1);
      $G->insert;
      $created_ldap_groups{$g} = $G->GroupDesc;
      $job->CurrentResult('done');
    }

    # --------------------------------------------------------------------
    # Refresh group membership
    my @current_groups = $user->member_of;
    foreach my $g (@ldap_groups) {
      next if List::Util::first {$g eq $_} @current_groups;
      $job->CurrentResult('done');
      $user->add_groups($g);
      $m->print(
        '<br>',
        pick_lang(rus => "Пользователь ", eng => "User "),
        $user->username,
        pick_lang(rus => " добавлен в группу ", eng => " added to group "),
        $g, "\n");
    }  
    foreach my $g (@current_groups) {
      next if List::Util::first {$g eq $_} @ldap_groups;
      my $G = new ePortal::epGroup;
      if ( (! $G->restore($g)) or $G->ext_group) {
        $job->CurrentResult('done');
        $user->remove_groups($g);
        $m->print(
          '<br>',
          pick_lang(rus => "Пользователь ", eng => "User "),
          $user->username,
          pick_lang(rus => " удален из группы ", eng => " removed from group "),
          $g, "\n");
      }  
    }  
  }
</%perl>
  <br><b><% pick_lang(rus => "Проверено пользователей:", eng => "Users checked:") %>
  <% $ldap_users_checked %></b>
</blockquote>



%  if ( keys %created_ldap_groups ) {
<b><% pick_lang(rus => "Создание групп пользователей LDAP", eng => "LDAP users groups creation") %></b>
<p><blockquote>
  <%perl>
    foreach (keys %created_ldap_groups) {
      $m->print("<br>$_ - $created_ldap_groups{$_}\n");
    }  
  </%perl>
</blockquote>
%  }



<b><% pick_lang(rus => "Удаление пустых групп пользователей LDAP", eng => "Deletion of empty LDAP groups") %></b>
<p><blockquote>
<%perl>
  # ----------------------------------------------------------------------
  # Check empty groups

  my $group = new ePortal::epGroup;
  $group->restore_all;
  while($group->restore_next) {
    my @members = $group->members;
    next if scalar(@members) > 0;

    if ( $group->ext_group ) {
      $group->delete;
      $job->CurrentResult('done');
      $m->print( sprintf("<br>%s %s %s\n", 
          pick_lang(rus => "Группа ", eng => "Group "),
          $group->groupname,
          pick_lang(rus => "пустая. Удалена", eng => "empty. Deleted...")));
    } else {
      $m->print( sprintf("<br>%s %s %s\n", 
          pick_lang(rus => "Локальная группа ", eng => "Local group "),
          $group->groupname,
          pick_lang(rus => "пустая, может быть удалена", eng => "empty, You may delete it")));
    }
  }  
</%perl>
</blockquote>
</%method>


%#=== @METAGS attr =========================================================
%# This is default parameters for new CronJob object
<%attr>
Memo => {rus => "Синхронизация пользователей LDAP", eng => "LDAP users synchronization job"}
Period => 'daily'
</%attr>

%#=== @metags args =========================================================
<%args>
$job
</%args>
