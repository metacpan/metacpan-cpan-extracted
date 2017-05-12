#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

sub eval_ok {
  my ($text, $title) = @_;
  local $@ = '';
  local $SIG{__WARN__} = sub { die @_ };
  eval $text;
  is $@, '', $title;
}

sub error_like {
  my ($text, $pattern, $title) = @_;
  local $@ = '';
  eval "use strict; $text";
  like $@, $pattern, $title;
}

my $T;

{
  $T = q|[MFields basic]|;
  eval_ok(q{
    package T1; use YATT::Lite::Inc;
    use YATT::Lite::MFields
       (qw/cf_foo1 cf_foo2 cf_foo3/);
  }, "$T class T1");

  my $dummy = %T1::FIELDS;

  is_deeply [sort keys %T1::FIELDS]
    , [qw/cf_foo1 cf_foo2 cf_foo3/]
      , "$T t1 fields";

  error_like q{my T1 $t1; defined $t1->{cf_foo}}
    , qr/^No such class field "cf_foo" in variable \$t1 of type T1/
      , "$T field name error T1->cf_foo is detected";

  eval_ok q{my T1 $t1; defined $t1->{cf_foo1}}
    , "$T correct field name should not raise error";

  eval_ok(q{
    package T2; use YATT::Lite::Inc;
    use YATT::Lite::MFields (qw/cf_bar1 cf_bar2/);
  }, "$T class T2");

  eval_ok(q{
    package T3; use YATT::Lite::Inc;
    use parent qw/T1 T2/;
    use YATT::Lite::MFields;
  }, "$T class T3");


  $dummy = %T3::FIELDS;
  is_deeply [sort keys %T3::FIELDS]
    , [qw/cf_bar1 cf_bar2 cf_foo1 cf_foo2 cf_foo3/]
      , "$T t3 fields";


  error_like q{my T3 $t; defined $t->{cf_foo}}
    , qr/^No such class field "cf_foo" in variable \$t of type T3/
      , "$T field name error T3->cf_foo is detected";

  eval_ok q{my T3 $t; defined $t->{cf_foo1}}
    , "$T correct field name should not raise error";

}

{
  $T = "[\$meta->has]";

  eval_ok(q{
    package U1; use YATT::Lite::Inc;
    use YATT::Lite::MFields sub {
      my ($meta) = @_;
      $meta->has(name => is => 'ro', doc => "Name of the user");
      $meta->has(age => is => 'rw', doc => "Age of the user");
      $meta->has($_) for qw/weight height/;
    };
  }, "$T class U1");

  my $dummy = %U1::FIELDS;

  is_deeply [sort keys %U1::FIELDS]
    , [qw/age height name weight/]
      , "$T U1 fields";

  error_like q{my U1 $t; defined $t->{ageee}}
    , qr/^No such class field "ageee" in variable \$t of type U1/
      , "$T field name error U1->ageee is detected";

  eval_ok q{my U1 $t; defined $t->{age}}
    , "$T correct field name should not raise error";

}

{
  $T = '[Partial]';
  error_like(<<'END'
    package t3_Err; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Partial unknown => 'opt';
END
	     , qr/^Unknown Partial opt: unknown/);

  eval_ok(q{
    package t3_Foo; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Partial
      fields => [qw/foo1 foo2/];
  }, "$T use .. fields");

  my $dummy = %t3_Foo::FIELDS;
  is_deeply [sort keys %t3_Foo::FIELDS]
    , [qw/foo1 foo2/]
      , "$T \%FIELDS";

  eval_ok(q{
    package t3_Bar; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Partial;
    use YATT::Lite::MFields
      qw/barx bary barz/;
  }, "$T with MFields");

  $dummy = %t3_Bar::FIELDS;
  is_deeply [sort keys %t3_Bar::FIELDS]
    , [qw/barx bary barz/]
      , "$T \%FIELDS";

  eval_ok(q{
    package t3_App1; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Object -as_base;
    use t3_Foo;
    use t3_Bar;
    sub m1 {
      (my MY $x) = @_;
      join "", $x->{foo1}, $x->{foo2}, $x->{barx}, $x->{bary}, $x->{barz};
    }
    1;
  }, "$T use (partial) Foo and Bar");

  $dummy = %t3_App1::FIELDS;
  is_deeply [sort keys %t3_App1::FIELDS]
    , [qw/barx bary barz foo1 foo2/]
      , "$T \%FIELDS";


  error_like(q{
    package t3_App2; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Object -as_base;
    use t3_Foo;
    use t3_Bar;
    sub m1 {
      (my MY $self) = @_;
      $self->{ng};
    }
    1;
  }
	     , qr/^No such class field "ng" in variable \$self of type t3_App2/
	     , "$T field error is detected at compile time.");
}

{
  $T = '[Partial inherits Partial]';
  eval_ok(q{
    package t4_Foo; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Partial
      (fields => [qw/foo3 foo4/], parents => ['t3_Foo']);
  }, "$T partial t4_Foo");

  my $dummy = %t4_Foo::FIELDS;
  is_deeply [sort keys %t4_Foo::FIELDS]
    , [qw/foo1 foo2 foo3 foo4/]
      , "$T \%FIELDS";

  eval_ok(q{
    package t4_Bar; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Partial
      (parents => ['t3_Bar'], fields => [qw/bara barb/]);
  }, "$T partial t4_Bar");

  $dummy = %t4_Bar::FIELDS;
  is_deeply [sort keys %t4_Bar::FIELDS]
    , [qw/bara barb barx bary barz/]
      , "$T \%FIELDS";

  eval_ok(<<'END'
    package t4_App1; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use base qw/YATT::Lite::Object/;
    use t4_Foo;
    use t4_Bar;
    sub m1 {
      (my MY $x) = @_;
      join "", $x->{foo1}, $x->{foo2}, $x->{barx}, $x->{bary}, $x->{barz};
    }
    1;
END

  , "$T partital t4_App1");

  is_deeply \@t4_App1::ISA
    , [qw/YATT::Lite::Object t4_Foo t4_Bar/]
      , "$T 'use PartialMod' adds ISA";

  $dummy = %t4_App1::FIELDS;
  is_deeply [sort keys %t4_App1::FIELDS]
    , [qw/bara barb barx bary barz foo1 foo2 foo3 foo4/]
      , "$T partial t4_App1 fields";


  error_like(<<'END'
    package t4_App2; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use base qw/YATT::Lite::Object/;
    use t4_Foo;
    use t4_Bar;
    sub m1 {
      (my MY $self) = @_;
      $self->{ng};
    }
    1;
END
	     , qr/^No such class field "ng" in variable \$self of type t4_App2/
	     , "$T partital t4_App2 field error is detected at compile time.");

}

{
  $T = '[Parital Diamond inheritance]e';
  # Diamond inheritance.
  eval_ok(q{
    package t5_C1; use YATT::Lite::Inc;
    use YATT::Lite::MFields
       (qw/foo1 foo2 foo3/);
  }, "$T base class");

  eval_ok(q{
    package t5_S1; use YATT::Lite::Inc;
    use YATT::Lite::Partial parent => 't5_C1', fields => [qw/bar1 bar2/];
  }, "$T subclass 1");

  eval_ok(q{
    package t5_S2; use YATT::Lite::Inc;
    use YATT::Lite::Partial parent => 't5_C1', fields => [qw/barx bary/];
  }, "$T subclass 2");

  eval_ok(q{
    package t5_Diamond; use YATT::Lite::Inc;
    use base qw/YATT::Lite::Object/;
    use YATT::Lite::MFields
       (qw/d1 d2/);
    use t5_S1;
    use t5_S2;
  }, "$T Diamond inheritance");

  my $dummy = %t5_Diamond::FIELDS;
  is_deeply [sort keys %t5_Diamond::FIELDS]
    , [qw/bar1 bar2 barx bary d1 d2 foo1 foo2 foo3/]
      , "$T \%FIELDS";
}

{
  $T = '[-Entity, -CON]';
  eval_ok(q{
    package t6_Foo; use YATT::Lite::Inc; sub MY () {__PACKAGE__}
    use YATT::Lite::Partial
      (fields => [qw/foo3 foo4/], -Entity, -CON);
    Entity bar => sub {
      my ($this) = shift;
      defined $CON;
    };
  }, "$T defined.(without error for \$CON)");

  no warnings 'once';
  ok $t6_Foo::{'EntNS'}, "$T *EntNS";
  ok t6_Foo::EntNS->can('entity_bar'), "$T EntNS->entity_bar()";
}

done_testing();
