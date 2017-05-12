use strict;
use lib 't', 'inc';
use Test::More tests => 4;
use onlyTest;

version_install('_Foo-Bar-0.50');
ok(-f File::Spec->catfile(qw(t version 0.50 _Foo Bar.pm)));

version_install('_Foo-Bar-0.55');
ok(-f File::Spec->catfile(qw(t version 0.55 _Foo Bar.pm)));

version_install('_Foo-Bar-0.60');
ok(-f File::Spec->catfile(qw(t version 0.60 _Foo Bar.pm)));

site_install('_Foo-Bar-1.00');
ok(-f File::Spec->catfile(qw(t site _Foo Bar.pm)));
