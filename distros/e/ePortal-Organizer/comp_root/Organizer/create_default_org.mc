%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#
%#----------------------------------------------------------------------------
<%perl>
  my $username = $ARGS{username} || $ePortal->username;
  return undef unless $username;

  my $app = $ePortal->Application('Organizer');
  my $org_id = try {
    $app->DefaultPrivateOrganizerID($username);

  } catch ePortal::Exception::ObjectNotFound with {
    my $org = new ePortal::App::Organizer::Organizer;
    $org->clear;
    $org->Title(pick_lang(rus => "Личный ", eng => "Private ") . $username);
    $org->Private(1);
    $org->uid($username);
    $org->insert;
    $session{GoodMessage} = pick_lang(
        rus => "Создан новый органайзер ",
        eng => "Created new organizer ") . $org->Title;

    # install default categories
    my $C = new ePortal::App::Organizer::Category;
    my @default_categories = (
      pick_lang(rus => "Бизнес", eng => "Business"),
      pick_lang(rus => "Друзья", eng => "Friends"),
      pick_lang(rus => "Избранное", eng => "Favorite"),
      pick_lang(rus => "Клиенты", eng => "Clients"),
      pick_lang(rus => "Отложенные дела", eng => "Delayed tasks"),
      pick_lang(rus => "Планы на будущее", eng => "Future tasks"),
      pick_lang(rus => "Поздравления", eng => "Congratulations"),
      pick_lang(rus => "Праздники", eng => "Holidays"),
      pick_lang(rus => "Разное", eng => "Other"),
      pick_lang(rus => "Срочные дела", eng => "Important tasks"),
    );
    foreach my $c (@default_categories) {
      $C->clear;
      $C->org_id( $org->id );
      $C->Title( $c );
      $C->insert;
    }

    $org->id;
  };
  return $org_id;
</%perl>
