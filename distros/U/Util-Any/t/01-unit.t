use Test::More 'no_plan';
use lib qw(./lib t/lib);
use Util::Any ();
use exampleHello ();

is_deeply([sort @{Util::Any::_all_funcs_in_class('exampleHello')}], [sort qw/hello_name hello_where/]);

undef &_use_import_module;
Util::Any->_base_import('main', "-SubExporter");
is(main->_use_import_module, "Sub::Exporter");
undef &_use_import_module;
Util::Any->_base_import('main', "-ExporterSimple");
is(main->_use_import_module, "Exporter::Simple");
undef &_use_import_module;
Util::Any->_base_import('main', "-Exporter");
is(main->_use_import_module, "Exporter");
undef &_use_import_module;

my $r = Util::Any->_create_smart_rename("hoge");
is $r->("is_hoge"), "is_hoge";
is $r->("is_hogehoge"), "is_hogehoge";
is $r->("fuga"), "hoge_fuga";
is $r->("is_fuga"), "is_hoge_fuga";
is $r->("foo_bar_hoge"), "foo_bar_hoge";
is $r->("foo_bar_hoge_fuga"), "hoge_foo_bar_hoge_fuga";
