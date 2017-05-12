use strict;
use warnings;
use lib qw(lib);

use Wurm;

#
# Minimal Wurm application for benchmarking.
#

my $app = Wurm::wrapp({
  body => {
    get => sub {
      my $meal = shift;
      return Wurm::_200();
    },
  },
});
$app
