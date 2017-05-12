#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use YATT::Lite::Breakpoint;

use YATT::Lite::Object;
use YATT::Lite::Util::FindMethods;

{
  package T1; sub MY () {__PACKAGE__}
  use base qw(YATT::Lite::Object);
  use fields qw(ITEMS cf_name cf_OTHER);

  sub cmd_mark {
    (my MY $self, my ($i)) = @_;
    push @{$self->{ITEMS}}, [caller($i)]->[3];
  }

  sub _before_after_new {
    (my MY $self) = @_;
    $self->cmd_mark(1);
    $self->SUPER::_before_after_new();
  }

  sub after_new {
    (my MY $self) = @_;
    $self->cmd_mark(1);
    $self->SUPER::after_new;
  }

  sub _after_after_new {
    (my MY $self) = @_;
    $self->cmd_mark(1);
    $self->SUPER::_after_after_new;
  }

  sub cmd_items {
    (my MY $self) = @_;
    wantarray ? @{$self->{ITEMS}} : $self->{ITEMS};
  }

  #----------------------------------------

  my MY $obj1 = T1->new(name => 'FOO');

  ::is_deeply [$obj1->cmd_items]
    , [qw/T1::_before_after_new
	  T1::after_new
	  T1::_after_after_new/]
    , "initialization hook";

  ::is $obj1->{cf_name}, 'FOO', "cf_name";

  ::is $obj1->cget('name'), 'FOO', "cget(name)";

  ::is_deeply [sort $obj1->cf_list]
    , [qw/OTHER name/]
    , "cf_list";

  ::is_deeply [sort $obj1->cf_list(qr/^cf_([a-z]\w*)/)]
    , [qw/name/]
    , "cf_list(regexp)";
}

{
  package T2; sub MY () {__PACKAGE__}
  use base qw(T1);

  sub _before_after_new {
    (my MY $self) = @_;
    $self->cmd_mark(1);
    $self->SUPER::_before_after_new();
  }

  sub after_new {
    (my MY $self) = @_;
    $self->cmd_mark(1);
    $self->SUPER::after_new;
  }

  sub _after_after_new {
    (my MY $self) = @_;
    $self->cmd_mark(1);
    $self->SUPER::_after_after_new;
  }

  my MY $obj1 = T2->new(name => 'BAR');

  ::is_deeply [$obj1->cmd_items]
    , [qw/T2::_before_after_new
	  T1::_before_after_new
	  T2::after_new
	  T1::after_new
	  T2::_after_after_new
	  T1::_after_after_new/]
    , "initialization hook, inheritance";


  ::is_deeply [::FindMethods($obj1, sub {/^cmd_/})]
    , [qw/cmd_items cmd_mark/]
    , "FindMethods(\$obj1)";

}

done_testing();
