use Test2::V0;

require Test2::Plugin::Cover;
is(Test2::Plugin::Cover->enabled, 0, "Not enabled");

Test2::Plugin::Cover->enable;
is(Test2::Plugin::Cover->enabled, 1, "enabled");

Test2::Plugin::Cover->import(disabled => 1);
is(Test2::Plugin::Cover->enabled, 0, "Not enabled");

Test2::Plugin::Cover->import();
is(Test2::Plugin::Cover->enabled, 1, "enabled");

done_testing;
