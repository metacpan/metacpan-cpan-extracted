use Test::More tests => 1;

BEGIN {
  use lib qw(lib);
  use_ok('WWW::Mixpanel');
}

diag("Testing WWW::Mixpanel $WWW::Mixpanel::VERSION, Perl $], $^X");
