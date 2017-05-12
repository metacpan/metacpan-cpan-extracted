use strict;
use warnings;
use lib qw(lib);

#
# Minimal Wurm application (with mob support) for benchmarking.
#

use Wurm qw(mob);

my $app = Wurm::wrapp({
  body => {
    get => sub {
      my $meal = shift;
      return Wurm::_200();
    },
  },
});
$app
