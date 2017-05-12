use strict;
use warnings;

package YahooFavorites::View::Options;
use base 'XUL::App::View::Base';
use Template::Declare::Tags
    #'HTML' => { namespace => 'html' },  # HTML namespace support
    'XUL';

template main => sub {
    show 'header';  # from XUL::App::View::Base
    window {
        attr {
            id => "yahoofavorites-options",
            xmlns => $::XUL_NAME_SPACE,
            #'xmlns:html' => $::HTML_NAME_SPACE,  # HTML namespace support
            title => _("Options for Yahoo! Favorites"),
            width => 800,
            height => 600,
            persist => 'sizemode screenX screenY width height',
            onload => "sizeToContent(); startup();",
        }

        script {
            attr {
                type => "application/x-javascript",
                src => "options.js",
            }
        }
        hbox {
            groupbox {
                attr {
                    pack => "center",
                    orient => "vertical",
                }
                hbox {
                    attr {
                        style => "padding: 5px 5px 20px 2px",
                    }
                    description {
                        attr {
                            value => _("Yahoo Favorites"),
                            style => "font-weight: bold; font-size: x-large;",
                        }
                    }
                    spacer {
                        attr {
                            style => "width:30px",
                        }
                    }
                }
                vbox {
                    attr {
                        style => "padding-top:10px;",
                    }
                    label {
                        attr {
                            value => _("Menu Option"),
                            style => "font-weight:bold; font-size:14px; padding:0px 0px 2px 10px;",
                        }
                    }
                    radiogroup {
                        attr {
                            id => "showMenuRadioGroup",
                        }
                        radio {
                            attr {
                                id => "showMenuRadio",
                                label => _("Display Menu"),
                                value => "0",
                            }
                        }
                        radio {
                            attr {
                                id => "hideMenuRadio",
                                label => _("Hide Menu"),
                                value => "1",
                            }
                        }
                    }
                }
                spacer {
                    attr {
                        flex => "1",
                    }
                }
                hbox {
                    vbox {
                        attr {
                            align => "end",
                            pack => "end",
                        }
                        button {
                            attr {
                                label => _("OK"),
                                oncommand => "toggleMenuVisibility();",
                            }
                        }
                    }
                    spacer {
                        attr {
                            flex => "1",
                        }
                    }
                    image {
                        attr {
                            src => "about-webdigest-small.png",
                            style => "padding:3px",
                        }
                    }
                }
            }
            box {
                image {
                    attr {
                        src => "menu-options.png",
                        style => "padding: 3px 0px 3px 5px",
                    }
                }
            }
        }
    }
};

1;
