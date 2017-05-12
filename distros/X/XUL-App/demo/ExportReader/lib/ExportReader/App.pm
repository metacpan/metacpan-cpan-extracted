use strict;
use warnings;

package ExportReader::App;
our $VERSION = '0.01';

use XUL::App::Schema;
use XUL::App schema {
    xulfile 'exportreader.xul' =>
        requires qw( JSON.js jquery.js export.js),
        generated from 'ExportReader::View::ExportReader';

    xpifile 'exportreader.xpi' =>
        name is 'ExportReader',
        id is 'exportreader@agentz.agentz', # FIXME: ensure id is unique.
        version is '0.0.1',
        targets {
            Firefox => ['2.0' => '3.0.*'],  # FIXME
            Mozilla => ['1.5' => '1.8'],  # FIXME
        },
        creator is 'The ExportReader development team',
        developers are ['agentz'],
        contributors are [];
        homepageURL is 'http://exportreader.agentz.org', # FIXME
        iconURL is '';  # like 'chrome://exportreader/content/logo.png'
        updateURL is ''; # This should not set for AMO extensions.
};

1;
