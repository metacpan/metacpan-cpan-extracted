use strict;
use warnings;
use lib qw(lib);

#
# Minimal Wurm application with Plack debugging.
#

use Wurm qw(let);
use Plack::Builder;

sub _panels() {[qw(
  DBITrace
  Environment
  Memory
  Parameters
  Response
  Timer
)]}

sub _html() {<<EOT
<doctype html>
<html>
<head>
  <title>Wurm Plack/PSGI Debug</title>
  <meta charset="utf-8">
</head>
<body>
</body>
</html>
EOT
}

my $grub = Wurm::let->new
->gate(sub {
  my $meal = shift;
  return Wurm::_200('text/html', _html());
})
;

my $app = Wurm::wrapp($grub->molt);
builder {
  enable 'SimpleLogger';
  # Enable these if running behind a reverse proxy
  #enable 'ReverseProxy';
  #enable 'ReverseProxyPath';
  enable 'Debug', panels => _panels();
  $app
};
