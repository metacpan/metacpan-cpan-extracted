package t::lib::Harness;

use Exporter 'import';
use Memoize;
use WebService::SiftScience;

memoize 'ss';
sub ss {
    my $api_key = '70db2aff3e3ffdf9';
    WebService::SiftScience->new(api_key => $api_key) if $api_key;
}

@EXPORT_OK = qw(ss);

1;
