use strict;
use warnings;

package ExportReader::View::ExportReader;
use base 'XUL::App::View::Base';
use Template::Declare::Tags
    #'HTML' => { namespace => 'html' },  # HTML namespace support
    'XUL';

template main => sub {
    show 'header';  # from XUL::App::View::Base
    window {
        attr {
            id => "exportreader-exportwin",
            xmlns => $::XUL_NAME_SPACE,
            #'xmlns:html' => $::HTML_NAME_SPACE,  # HTML namespace support
            title => 'ExportReader',
            width => 800,
            height => 600,
            persist => 'sizemode screenX screenY width height',
        }
        hbox {
            button { attr { id => 'extract-button', label => 'Extract!' } }
            spacer { attr { flex => 1 } }
        }
        hbox {
            attr { flex => 1 }
            browser {
                attr {
                    id => 'reader-browser',
                    type => 'content',
                    flex => 4,
                    src => 'http://www.google.com/reader',
                }
            }
            splitter {}
            textbox {
                attr {
                    id => 'output-box',
                    multiline => "true",
                    flex => 1,
                }
            }
        }
    }
};

1;
