use strict;
use warnings;

package HelloWorld::View::HelloWin;
use base 'XUL::App::View::Base';
use Template::Declare::Tags
    #'HTML' => { namespace => 'html' },  # HTML namespace support
    'XUL';

template main => sub {
    show 'header';  # from XUL::App::View::Base
    window {
        attr {
            id => "helloworld-hellowin",
            xmlns => $::XUL_NAME_SPACE,
            #'xmlns:html' => $::HTML_NAME_SPACE,  # HTML namespace support
            title => _('HelloWorld'),
            width => 800,
            height => 600,
            persist => 'sizemode screenX screenY width height',
        }
        # Code that we added by hand:
        label { _("Hello, world!") }
    }
};

1;
