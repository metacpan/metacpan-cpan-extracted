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
<p>
<& /item_caption.mc, title =>
    pick_lang(rus => "Процесс загрузки событий", eng => "Loading in progress") &>

<%perl>
  my %args = $m->request_args;
  $m->flush_buffer;
  my $filepath = "/Organizer/$args{file}";
  if ( ! $m->comp_exists($filepath) ) {
    $session{ErrorMessage} = pick_lang(rus => "Данные не найдены", eng => "Data not found");
  } else {
    my $C = new ePortal::App::Organizer::Category;
    $C->restore_where(org_id => $session{_org_id}, title => $args{category_title});
    if ( (! $C->restore_next) ) {
      $C->org_id( $session{_org_id} );
      $C->title( $args{category_title} );
      $C->insert;
    }

    my @lines = split "\n", $m->scomp($filepath);
    my $A = new ePortal::App::Organizer::Anniversary;
    my $counter=0;
    foreach my $line (@lines) {
      if ( my ($d, $m, $y, $t) = ($line =~ /^(\d\d)[\.\/-](\d\d)[\.\/-]?(\d\d\d\d)?\s+(.*)$/)) {
        $A->restore_where(org_id => $session{_org_id}, an_day => $d, an_month => $m, an_year => $y, title => $t);
        if ( ! $A->restore_next ) {
          $A->clear;
          $A->org_id( $session{_org_id} );
          $A->an_day( $d );
          $A->an_month( $m );
          $A->an_year( $y );
          $A->title( $t );
          $A->category_id( $C->id );
          $A->insert;
          $counter++;
        }
      }
    }
    $session{GoodMessage} =
      pick_lang(rus => "Обработано строк: ", eng => "Lines read: ") . scalar(@lines) . '<br>' .
      pick_lang(rus => "Добавлено событий: ", eng => "Dates added: ") . $counter;
  }
</%perl>

<& /message.mc &>

