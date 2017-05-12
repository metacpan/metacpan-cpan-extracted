use strict;
use warnings;

package YahooFavorites::View::WebDigest;
use base 'XUL::App::View::Base';
use Template::Declare::Tags
    #'HTML' => { namespace => 'html' },  # HTML namespace support
    'XUL';

template main => sub {
    show 'header';  # from XUL::App::View::Base

    overlay {
        attr {
            id => "WebdigestOverlay",
            xmlns => $::XUL_NAME_SPACE,
        }
        script {
            attr {
                type => "application/x-javascript",
                src => "chrome://yahoofavorites/content/webdigest.js",
            }
        }
        stringbundleset {
            attr {
                id => "stringbundleset",
            }
            stringbundle {
                attr {
                    id => "bundle_webdigest",
                    src => "chrome://yahoofavorites/content/webdigest.properties",
                }
            }
        }
        toolbox {
            attr {
                id => "navigator-toolbox",
            }
            toolbarpalette {
                attr {
                    id => "BrowserToolbarPalette",
                }
                toolbarbutton {
                    attr {
                        id => "web-button-webdigest",
                        class => "toolbarbutton-1 chromeclass-toolbar-additional",
                        label => _("Yahoo Favorites"),
                        oncommand => "webdigestMain.loadWebdigestPage();",
                    }
                }
                toolbarbutton {
                    attr {
                        id => "web-button-tagPage",
                        class => "toolbarbutton-1 chromeclass-toolbar-additional",
                        label => _("Tag this page"),
                        tooltiptext => _("Tag this page"),
                        oncommand => "webdigestMain.loadTagPage();",
                    }
                }
            }
        }
        menubar {
            attr {
                id => "main-menubar",
            }
            menu {
                attr {
                    id => "webdigest-menu",
                    label => _("Yahoo Favorites"),
                    insertafter => "helpMenu",
                    accesskey => "Y",
                }
                menupopup {
                    menuitem {
                        attr {
                            id => "web-menu-tagPage",
                            label => _("Tag this page"),
                            accesskey => "Y",
                            oncommand => "webdigestMain.loadTagPage();",
                        }
                    }
                    menuseparator {};
                    menuitem {
                        attr {
                            id => "web-menu-myWebdigest",
                            label => _("My Web Digest"),
                            accesskey => "M",
                            oncommand => "webdigestMain.loadRelevantPage('mywebdigest');",
                        }
                    }
                    menuseparator {};
                    menuitem {
                        attr {
                            label => _("Top Digest"),
                            accesskey => "P",
                            oncommand => "webdigestMain.loadRelevantPage('popular');",
                        }
                    }
                    menuitem {
                        attr {
                            label => _("Latest Digest"),
                            accesskey => "N",
                            oncommand => "webdigestMain.loadRelevantPage('new');",
                        }
                    }
                    menuseparator {};
                    menuitem {
                        attr {
                            label => _("About Yahoo Favorites"),
                            accesskey => "H",
                            oncommand => "webdigestMain.loadRelevantPage('about');",
                        }
                    }
                }
            }
        }
        popup {
            attr {
                id => "contentAreaContextMenu",
            }
            menuitem {
                attr {
                    id => "web-context-tagCurrent-aftersearch",
                    insertafter => "context-searchselect",
                    label => _("Tag this page"),
                    image => "chrome://yahoofavorites/content/mywebycntag_14x14.png",
                    class => "menuitem-iconic",
                    oncommand => "webdigestMain.loadTagPage();",
                }
            }
            menuitem {
                attr {
                    id => "web-context-tagCurrent",
                    insertafter => "context-bookmarkpage",
                    label => _("Tag this page"),
                    class => "menuitem-iconic",
                    image => "chrome://yahoofavorites/content/mywebycntag_14x14.png",
                    oncommand => "webdigestMain.loadTagPage();",
                }
            }
            menuitem {
                attr {
                    id => "web-context-tagLink",
                    insertafter => "context-bookmarklink",
                    label => _("Add the current link to Yahoo Favorites"),
                    class => "menuitem-iconic",
                    image => "chrome://yahoofavorites/content/mywebycntag_14x14.png",
                    oncommand => "webdigestMain.loadTagLink(typeof(gContextMenu.linkURL)=='string'?gContextMenu.linkURL:gContextMenu.linkURL(), gContextMenu.linkText());",
                }
            }
        }
    }
};

1;
