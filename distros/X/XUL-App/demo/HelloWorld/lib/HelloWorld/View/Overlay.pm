use strict;
use warnings;

package HelloWorld::View::Overlay;
use base 'XUL::App::View::Base';
use Template::Declare::Tags
    #'HTML' => { namespace => 'html' },  # HTML namespace support
    'XUL';

template main => sub {
    show 'header';  # from XUL::App::View::Base
    overlay {
        attr {
            id => "helloworld-overlay",
            xmlns => $::XUL_NAME_SPACE,
            #'xmlns:html' => $::HTML_NAME_SPACE,  # HTML namespace support

        }
        menupopup {
            attr { id => "menu_ToolsPopup" }
            menuitem {
                attr {
                    oncommand => "toOpenWindowByType(
                        'helloworld',
                        'chrome://helloworld/content/hellowin.xul'
                    )",
                    insertafter => "javascriptConsole,devToolsSeparator",
                    label => _("Hello World"),
                }
            }
        }

    }
};

1;
