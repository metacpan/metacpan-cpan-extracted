package t::lib::Harness;

use Exporter 'import';
use Memoize;
use WebService::Lob;

memoize 'lob';
sub lob {
    my $api_key = 'test_f126eb04f7a10e05de646d4094b42c96ab6';
    WebService::Lob->new(api_key => $api_key) if $api_key;
}

@EXPORT_OK = qw(lob);

1;
