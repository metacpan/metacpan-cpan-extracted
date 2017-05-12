package t::lib::Harness;

use Exporter 'import';
use Memoize;
use WebService::SmartyStreets;

memoize 'ss';
sub ss {
    WebService::SmartyStreets->new(
        auth_id    => '4af535e2-d234-4dab-88b9-dbcc9261d227',
        auth_token => 'tnEYOxWIasGUMf1dtMXp',
    );
}

@EXPORT_OK = qw(ss);

1;
