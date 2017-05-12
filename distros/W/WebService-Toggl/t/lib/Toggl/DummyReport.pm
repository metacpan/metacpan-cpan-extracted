package Toggl::DummyReport;

use IO::All;
use JSON::MaybeXS;

use Moo;
use namespace::clean;

has url => (is => 'ro', required => 1);
has _data => (is => 'ro', lazy => 1, builder => 1);
sub _build__data { decode_json(io->catfile('t', 'data', $_[0]->url . ".json")->slurp) }

sub data { $_[0]->_data }

1;
