
use inc::Module::Install;

# BEGIN { $Module::Install::AUTHOR = 1; }

all_from('lib/WWW/Amazon/Wishlist.pm');

install_script('Programs/amazonwish');

requires('Carp');
requires('Getopt::Long');
requires('HTML::TreeBuilder');
requires('LWP::UserAgent');
test_requires('Test::More');

use Env;
if ($ENV{MTHURN_PERL_DEV})
  {
  warn "DDD This is author's development environment\n";
  use_ptar();
  } # if

WriteAll;

__END__
