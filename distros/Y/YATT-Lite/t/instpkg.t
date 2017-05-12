#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use YATT::Lite::Util qw(appname list_isa globref);
sub myapp {join _ => MyTest => appname($0), @_}

use Test::More;

sub NSBuilder () {'YATT::Lite::NSBuilder'}

use_ok(NSBuilder);

{
  my $builder = NSBuilder->new(app_ns => 'Foo');
  sub Foo::bar {'baz'}
  is my $pkg = $builder->buildns('INST'), 'Foo::INST1', "inst1";
  is $pkg->bar, "baz", "$pkg->bar";
}

{
  my $WDH = 'YATT::Lite::WebMVC0::DirApp';
  {
    package MyTest_NSB_Web;
    use base qw(YATT::Lite::NSBuilder);
    use YATT::Lite::MFields;
    sub default_default_app {$WDH}
    use YATT::Lite::Inc;
  }
  my $NS = 'MyTest_NSB';
  my $builder = MyTest_NSB_Web->new(app_ns => $NS);

  my $sub = $builder->buildns('INST');
  is_deeply [list_isa($sub, 1)]
    , [[$NS, [$WDH, list_isa($WDH, 1)]]]
      , "sub inherits $NS, which inherits $WDH only.";

  ok $WDH->can('_handle_yatt'), "$WDH is loaded (can handle_yatt)";
}

my $i = 0;
{
  my $CLS = myapp(++$i);
  is $CLS, 'MyTest_instpkg_1', "sanity check of test logic itself";
  my $builder = NSBuilder->new(app_ns => $CLS);
  sub MyTest_instpkg_1::bar {'BARRR'}
  is my $pkg = $builder->buildns, "${CLS}::INST1", "$CLS inst1";
  is $pkg->bar, "BARRR", "$pkg->bar";

  is my $pkg2 = $builder->buildns('TMPL'), "${CLS}::TMPL1", "$CLS tmpl1";
  is $pkg2->bar, "BARRR", "$pkg2->bar";
}

{
  my $NS = myapp(++$i);
  my $builder = NSBuilder->new(app_ns => $NS);

  my $base1 = $builder->buildns('TMPL');
  # my $base2 = $builder->buildns('TMPL');

  my $sub1 = $builder->buildns(INST => [$base1]
			       , my $fake_fn =  __FILE__ . "/fake.yatt");

  is_deeply [list_isa($sub1, 1)]
    , [[$base1, [$NS, ['YATT::Lite', list_isa('YATT::Lite', 1)]]]]
      , "sub1 inherits base1";

  is $sub1->filename, $fake_fn, "sub1->filename is defined";
}

{
  my $YL = 'MyTest_instpkg_YL';
  {
    package MyTest_instpkg_YL;
    use base qw(YATT::Lite);
    use YATT::Lite::Inc;
  }

  my $NS = myapp(++$i);
  my $builder = NSBuilder->new(app_ns => $NS);

  my $sub = $builder->buildns(INST => [$YL]
			      , my $fake2 = __FILE__ . "/fakefn2");
  is_deeply [list_isa($sub, 1)]
    , [[$YL, ['YATT::Lite', list_isa('YATT::Lite', 1)]]]
      , "sub inherits $YL only.";

  {
    my $sym = globref($sub, 'filename');
    ok my $code = *{$sym}{CODE}, "sub has filename()";
    is $code->(), $fake2, "filename is correct";
  }

  my $unknown = 'MyTest_instpkg_unk';
  eval {
    $builder->buildns(INST => [$unknown]);
  };
  like $@, qr/^None of baseclass inherits YATT::Lite: $unknown/
    , "Unknown baseclass should raise error";
}

done_testing();
