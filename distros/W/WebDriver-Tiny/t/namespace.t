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
    accept_alert
    alert_text
    back
    base_url
    capabilities
    cookie
    cookie_delete
    cookies
    dismiss_alert
    find
    forward
    get
    import
    js
    js_async
    js_phantom
    new
    refresh
    screenshot
    source
    status
    storage
    title
    url
    user_agent
    window
    window_close
    window_fullscreen
    window_maximize
    window_position
    window_size
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
    import
    last
    location
    location_in_view
    move_to
    rect
    screenshot
    selected
    send_keys
    size
    slice
    split
    submit
    tag
    tap
    text
    uniq
    visible
/ ], "WebDriver::Tiny::Elements has the correct stuff in it's namespace";
