# NAME

Tk::HyperText - An ROText widget which renders HTML code.

# SYNOPSIS

    use Tk::HyperText;

    my $html = $mw->Scrolled ('HyperText',
      -scrollbars => 'ose',
      -wrap       => 'word',
    )->pack (-fill => 'both', -expand => 1);

    $html->setHandler (Title    => \&onNewTitle);
    $html->setHandler (Resource => \&onResource);
    $html->setHandler (Submit   => \&onFormSubmit);

    $html->loadString (qq~<html>
      <head>
      <title>Hello world!</title>
      </head>
      <body bgcolor="#0099FF">
      <font size="6" family="Impact" color="#FFFFFF">
      <strong>Hello, world!</strong>
      </font>
      </body>
      </html>
    ~);

# DESCRIPTION

`Tk::HyperText` is a widget derived from `Tk::ROText` that renders HTML
code.

## PURPOSE

First of all, **Tk::HyperText is NOT expected to become a full-fledged web
browser widget**. This module's original idea was just to be a simple
HTML-rendering widget, specifically to match the capabilities of the
_AOL Instant Messenger_'s HTML widgets. That is, to render basic text
formatting, images, and hyperlinks. Anything this module does that's extra
is only there because I was up to the challenge.

## VERSION 0.06+

This module is **NOT** backwards compatible with versions 0.05 and below.
Specifically, the module was rewritten to use `HTML::TokeParser` as its
HTML parsing engine instead of parsing it as plain text. Also, the methods
have all been changed. The old module's overloading of the standard
`Tk::Text` methods was causing all kinds of problems, and since this isn't
really a "drop-in" replacement for the other Text widgets, its methods don't
need to follow the same format.

Also, support for Cascading StyleSheets doesn't work at this time. It may be
re-implemented at a later date, but, as this widget is not meant to become
a full-fledged web browser (see ["PURPOSE"](#purpose)), the CSS support might not
return.

## EXAMPLE

Run the \`demo.pl\` script included in the distribution.

# WIDGET-SPECIFIC OPTIONS

- \-continuous, -continue

    Setting this option to 1 tells the widget **not** to re-render the entire
    contents of the widget each time the contents are updated. The default value
    is 0, so the entire page contents are rendered on any updates. This causes
    the code to be "continuous", so that i.e. if you fail to close a bold tag and
    then insert more code, the new code should carry on the unclosed tag and
    appear in bold. Setting this option to 1 would render the new code
    independently from the existing page and is therefore unnatural in HTML.

    `-continue` is an alias for `-continuous` if you're terrible at spelling.

- \-allow, -deny

    Define tags that are allowed or denied. See ["WIDGET METHODS"](#widget-methods) for more
    details.

- \-attributes

    Since Tk::HyperText doesn't yet support Cascading Style Sheets, the only
    alternative is to send in `-attributes`. This data structure defines some
    default styles for use within the rendered pages.

        my $html = $mw->Scrolled('HyperText',
          -attributes => {
            -anchor => {              # Hyperlink colors
              -normal  => '#0000FF',  # or 'blue'
              -hover   => '#FF0000',  # or 'red'
              -active  => '#FF0000',  # or 'red'
              -visited => '#990099',  # or 'purple'
            },
            -font => {
              -family => 'Times',
              -mono   => 'Courier',
              -size   => 'medium',    # or any HTML size
                                      # (1..6, xx-small..xx-large)

              # Text styles, set them to 1 to apply the effect.
              # I don't see why anyone would want to use these,
              # but they're here anyway.
              -bold   => 0, # Bold
              -italic => 0, # Italic
              -under  => 0, # Underline
              -over   => 0, # Overstrike
            },
            -style => {
              -margins => 0,         # Text margins
              -color   => '#000000', # Text color
              -back    => '#FFFFFF', # Text BG color
            },
          },
        );

# WIDGET METHODS

- _$text_\->__setHandler__ _(name => event)_

    Define a handler for certain events that happen within the widget. See
    ["EVENTS"](#events) for more information.

        $html->setHandler (Title => sub {
          my ($self,$newTitle) = @_;

          $mw->configure (-title => $newTitle);
        });

- _$text_\->__allowedTags__ _(tags)_

    Specify a set of tags that are allowed to be rendered. Pass in the tag names
    as an array. If the "allow list" has any entries, **only** these tags will be
    rendered.

- _$text_\->__deniedTags__ _(tags)_

    Specify a set of tags that are **not** allowed to be rendered. If the "allow
    list" is empty and the "denied list" has any entries, then all tags are
    allowed **except** for those in the denied list. If any entries in the denied
    list conflict with entries in the allowed list, those tags are **not**
    allowed.

- _$text_\->__allowHypertext__ _()_

    This is a preset allow/deny scheme. It allows all hypertext tags (basic
    text formatting, images, and horizontal rules) but doesn't allow tables,
    forms, lists, or other complicated tags. This will make it match the
    capabilities of _AOL Instant Messenger_'s HTML rendering widgets.

    It will allow the following tags:

        <html>, <head>, <title>, <body>, <a>, <p>, <br>, <hr>,
        <img>, <font>, <center>, <sup>, <sub>, <b>, <i>,
        <u>, <s>

    All other tags are denied.

- _$text_\->__allowEverything__ _()_

    Allows all supported tags to be rendered. It resets the "allow" and
    "deny" lists to be blank.

- _$text_\->__loadString__ _(html\_code)_

    Render a string of HTML code into the text widget. This will replace all of
    the current contents of the widget with the new HTML code.

- _$text_\->__loadBlank__ _()_

    Blanks out the contents of the widget (similar to the "`about:blank`" URI
    in most modern web browsers).

- _$text_\->__clearHistory__ _()_

    Resets the browsing history (so "visited links" will become "normal links"
    again).

- _$text_\->__getText__ _(\[as\_html\])_

    Returns the contents of the widget as a string. Send a true value as an
    argument to get the contents back including HTML code. Otherwise, only the
    plain text content is returned.

# EVENTS

All events receive a reference to its parent widget as `$_[0]`.
The following are the event handlers currently supported by
`Tk::HyperText`:

- Title ($self, $newTitle)

    This event is called every time a `<title>...</title>` sequence is found
    in the HTML code. `$newTitle` is the text of the new page title.

- Resource ($self, %info)

    This event is called whenever an external resource is requested (such as an
    image or a hyperlink trying to link to another page). `%info` contains all
    the information about the requested resource.

        # For hyperlinks (<a> tags)
        %info = (
          tag    => 'a',                 # The HTML tag.
          href   => 'http://google.com', # The <a href> attribute.
          src    => 'http://google.com', # src is an alias for href
          target => '_blank',            # The <a target> attribute
        );

        # For images (<img> tags)
        %info = (
          tag    => 'img',        # The HTML tag.
          src    => 'avatar.jpg', # The <img src> attribute.
          width  => 48,           # The <img width> attribute.
          height => 48,           # The <img height> attribute.
          vspace => '',           # <img vspace>
          hspace => '',           # <img hspace>
          align  => '',           # <img align>
          alt    => 'alt text',   # <img alt>
        );

    **Note about Images:** The `Resource` event, when called for an image, wants
    you to return the image's data, Base64-encoded. Otherwise, the image on the
    page will show up as a "broken image" icon. Here is an example of how to
    handle image resources:

        use LWP::Simple;
        use MIME::Base64 qw(encode_base64);

        $html->setHandler (Resource => sub {
          my ($self,%info) = @_;

          if ($info{tag} eq 'img') {

            # If an http:// link, get the image from the web.
            if ($info{src} =~ /^http/i) {
              my $bin = get $info{src};
              my $enc = encode_base64($bin);
              return $enc;
            }

            # Otherwise, read it from a local file.
            else {
              if (-f $src) {
                open (READ, $src);
                binmode READ;
                my @bin = <READ>;
                close (READ);
                chomp @bin;

                my $enc = encode_base64(join("\n",@bin));
                return enc;
              }
            }
          }

          return undef;
        });

    On hyperlink resources, the module doesn't need or expect any return value.
    It should be up to the handler to do what it needs (i.e. fetch the source
    of the page, blank out the HTML widget and then `loadString` the new code
    into it).

- Submit ($self,%info)

    This event is called when an HTML form has been submitted. `%info` is a
    hash containing the information about the event.

        %info = (
          form    => 'login',      # The <form name> attribute.
          action  => '/login.cgi', # The <form action> attribute.
          method  => 'POST',       # The <form method> attribute.
          enctype => 'text/plain', # The <form enctype> attribute.
          fields  => {             # Hashref of form names and values.
            username => 'soandso',
            password => 'bigsecret',
            remember => 1,
          },
        );

    The event doesn't want or expect a return value, similarly to the `Resource`
    event for normal anchor tags. Your code should know what to do with this
    event (i.e. get `LWP::UserAgent` to post the form to a remote web address,
    stream the results of the request in through `loadString`, etc.)

# HTML SUPPORT

The following tags and attributes are supported by this module:

    <html>
    <head>
    <title>
    <body>     (bgcolor, text, link, alink, vlink)
    <a>        (href, target)
    <br>
    <p>
    <form>     (name, action, method, enctype)
    <textarea> (name, cols, rows, disabled)
    <select>   (name, size, multiple)
    <option>   (value, selected)
    <input>    (name, type, size, value, maxlength, disabled, checked)
                types: text, password, checkbox, radio, button, submit, reset
    <table>    (border, cellspacing, cellpadding)
    <tr>
    <td>       (colspan, rowspan)
      <th>
      <thead>
      <tbody>
      <tfoot>
    <hr>       (height, size)
    <img>      (src, width, height, vspace, hspace, align, alt)*
    <font>     (face, size, color, back)
      <basefont>
    <h1>..<h6>
    <ol>       (type, start)
    <ul>       (type)
    <li>
    <blockquote>
    <div>      (align)
    <span>
    <pre>
    <code>
      <tt>
      <kbd>
      <samp>
    <center>
      <right>
      <left>
    <sup>
    <sub>
    <big>
    <small>
    <b>
      <strong>
    <i>
      <em>
      <address>
      <var>
      <cite>
      <def>
    <u>
      <ins>
    <s>
      <del>

# SEE ALSO

[Tk::ROText](https://metacpan.org/pod/Tk::ROText) and [Tk::Text](https://metacpan.org/pod/Tk::Text).

# CHANGES

    0.12 Feb 25, 2016
    - Add more dependencies to get CPANTS to pass.

    0.11 Feb 23, 2016
    - Add dependency on HTML::TokeParser.

    0.10 Sep 18, 2015
    - Add dependency on Tk::Derived.

    0.09 Nov 11, 2013
    - Reformatted as per CPAN::Changes::Spec -neilbowers

    0.08 Nov  1, 2013
    - Use hex() instead of eval() to convert hex strings into numbers.
    - Set default values for body colors.
    - Stop demo.pl from being installed; rename it to eg/example.

    0.06 July 14, 2008
    - The module uses HTML::TokeParser now and does "real" HTML parsing.
    - Badly broke backwards compatibility.

    0.05 July 11, 2007
    - Added support for "tag permissions", so that you can allow/deny specific tags from
      being rendered (i.e. say you're making a chat client which uses HTML and you don't
      want people inserting images into their messages, or style sheets, etc)
    - Added the tags <address>, <var>, <cite>, and <def>.
    - Added the <hr> tag.
    - Added two "default images" that are displayed when an <img> tag tries to show
      an image that couldn't be found, or was found but is a file type that isn't
      supported (e.g. <img src="index.html"> would show an "invalid image" icon).
    - Bug fix: every opened tag that modifies your style will now copy all the other
      stacks. As a result, opening <font back="yellow">, then <font color="red">, and
      then closing the red font, will still apply the yellow background to the following
      text. The same is true for every tag.
    - Added some support for Cascading StyleSheets.
    - Added some actual use for the "active link color": it's used as the hover color
      on links (using it as a true active color is mostly useless, since most of the
      time the page won't remain very long when clicking on a link to even see it)

    0.04 June 23, 2007
    - Added support for the <basefont> tag.
    - Added support for <ul>, <ol>, and <li>. I've even extended the HTML specs a
      little and added "diamonds" as a shape for <ul>, and allowed <ul> to specify
      a decimal escape code (<ul type="#0164">)
    - Added a "page history", so that the "visited link color" on pages can actually
      be applied to the links.
    - Fixed the <blockquote> so that the margin applies to the right side as well.

    0.02 June 20, 2007
    - Bugfix: on consecutive insert() commands (without clearing it in between),
      the entire content of the HTML already in the widget would be inserted again,
      in addition to the new content. This has been fixed.

    0.01 June 20, 2007
    - Initial release.

# AUTHOR

Noah Petherbridge, http://www.kirsle.net/

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
