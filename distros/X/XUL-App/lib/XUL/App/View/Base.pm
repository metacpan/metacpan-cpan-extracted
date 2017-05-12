use strict;
use warnings;

package XUL::App::View::Base;

use base 'Template::Declare';
use Template::Declare::Tags 'XUL';

$::XUL_NAME_SPACE = "http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul";
$::HTML_NAME_SPACE = "http://www.w3.org/1999/xhtml";

template header => sub {
    my ($self, $encoding) = @_;
    $encoding ||= 'UTF-8';
    xml_decl { 'xml', version => '1.0', encoding => $encoding };
    xml_decl { 'xml-stylesheet',
        href => "chrome://global/skin/",
        type => "text/css"
    };
};

# stub
template main => sub {
    show 'header';
    window {
        attr {
            id => 'xul-app-default',
            xmlns => $::XUL_NAME_SPACE,
            'xmlns:html' => $::HTML_NAME_SPACE,
            width => 600,
            height => 800,
        }
        label { "Welcome to XUL::App!" }
    }
};

1;

