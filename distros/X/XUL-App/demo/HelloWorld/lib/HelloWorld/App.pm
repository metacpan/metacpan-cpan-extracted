use strict;
use warnings;

package HelloWorld::App;
our $VERSION = '0.01';

use XUL::App::Schema;
use XUL::App schema {
    # Code that we added by hand:
    xulfile 'overlay.xul' =>
        generated from 'HelloWorld::View::Overlay',
        overlays 'chrome://browser/content/browser.xul';

    xulfile 'hellowin.xul' =>
        generated from 'HelloWorld::View::HelloWin';

    xpifile 'helloworld.xpi' =>
        name is 'HelloWorld',
        id is 'helloworld@agentz.agentz-office', # FIXME: ensure id is unique.
        version is '0.0.1',
        targets {
            Firefox => ['2.0' => '3.0.*'],  # FIXME
            Mozilla => ['1.5' => '1.8'],  # FIXME
        },
        creator is 'The HelloWorld development team',
        developers are ['agentz'],
        contributors are [],
        homepageURL is 'http://helloworld.agentz.org', # FIXME
        iconURL is '',  # like 'chrome://helloworld/content/logo.png'
        updateURL is ''; # This should not set for AMO extensions.
};

1;
