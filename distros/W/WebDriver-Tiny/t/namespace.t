use strict;
use warnings;

use Test::More tests => 2;
use WebDriver::Tiny;

is_deeply [ sort keys %WebDriver::Tiny:: ], [ qw/
    (&{}
    ((
    ()
    BEGIN
    CARP_NOT
    DESTROY
    Elements::
    VERSION
    __ANON__
    _req
    alert_accept
    alert_dismiss
    alert_text
    back
    base_url
    capabilities
    cookie
    cookie_delete
    cookies
    find
    forward
    get
    html
    import
    js
    js_async
    new
    refresh
    screenshot
    status
    title
    url
    user_agent
    window
    window_close
    window_fullscreen
    window_maximize
    window_minimize
    window_rect
    window_switch
    windows
/ ], "WebDriver::Tiny has the correct stuff in it's namespace";

is_deeply [ sort keys %WebDriver::Tiny::Elements:: ], [ qw/
    BEGIN
    VERSION
    _req
    append
    attr
    clear
    click
    css
    enabled
    find
    first
    html
    import
    last
    prop
    rect
    screenshot
    selected
    send_keys
    size
    slice
    split
    tag
    tap
    text
    uniq
    visible
/ ], "WebDriver::Tiny::Elements has the correct stuff in it's namespace";
