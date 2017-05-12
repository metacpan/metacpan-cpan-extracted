use strict;
use warnings;

package YahooFavorites::View::About;
use base 'XUL::App::View::Base';
use Template::Declare::Tags
    #'HTML' => { namespace => 'html' },  # HTML namespace support
    'XUL';
use YahooFavorites::App;

template main => sub {
    show 'header';  # from XUL::App::View::Base
    window {
        attr {
            id => "yahoofavorites-about",
            xmlns => $::XUL_NAME_SPACE,
            #'xmlns:html' => $::HTML_NAME_SPACE,  # HTML namespace support
            onload => 'sizeToContent()',
            title => _("About Yahoo! Favorites"),
            class => 'dialog',
        }
        groupbox {
            attr { align => "center", orient => "horizontal" }
            vbox {
                description {
                    attr {
                        value => _("Yahoo Favorites"),
                        style => "font-weight: bold; font-size: x-large;",
                    }
                }
                description {
                    attr {
                        value => $YahooFavorites::App::VERSION .
                            " - " . _("Copyright (c) 2006, 2007, 2008.")
                    }
                }
                spacer { attr { style => "height:15px" } }
                description {
                    attr {
                        value => _("Home Page"),
                        style => "font-weight: bold;"
                    }
                }
                description {
                    attr {
                        value => "http://www.yahoo.com.cn",
                        style => "cursor: pointer !important;color : blue;",
                        onclick => "window.open(event.target.value);",
                    }
                }
                spacer { attr { style => "height:15px" } }
                description {
                    attr {
                        value => "",
                        style => "font-weight: bold;",
                    }
                }
                description {
                    attr {
                        value => _("Yahoo! China, Aliaba Inc."),
                        style => "cursor: pointer !important;color : blue;",
                        onclick => "window.open('http://www.yahoo.com.cn/');",
                    }
                }
            }
            image {
                attr {
                    src => "chrome://yahoofavorites/content/about-webdigest.png",
                    style => "padding: 0px 5px 0px 5px"
                }
            }
        }

        box {
            attr {
                align => "right",
                pack => "center",
                flex => "1",
            }
            button {
                attr {
                    label => _("Close window"),
                    oncommand => "window.close();",
                }
            }
        }
    }
};

1;
