package Web::Gui;
    use warnings;
    use strict;
    our $VERSION = '0.63';
    use XUL::Gui ':all';    # the greatest trick the XUL ever pulled
                            # was convincing the world it didn't exist.
    $XUL::Gui::MOZILLA = 0; # and like that, poof. its gone.

    sub import {
        splice @_, 0, 1, 'XUL::Gui';
        push @_, '!:xul' unless @_ == 2
                         and $_[1] =~ /->/;
        goto &{ XUL::Gui->can('import') }
    }

=head1 NAME

Web::Gui - render cross platform gui applications in a web browser from perl

=head1 VERSION

version 0.63

this module is under active development, interfaces may change.

this code is currently in beta, use in production environments at your own risk

=head1 SYNOPSIS

    use Web::Gui;
    display P 'hello, world!';  # P is the HTML <p> tag

    use Web::Gui;
    display
        H3('Web Gui!'),
        (SPAN style => q{
                background-color: #222;
                outline: 2px solid #444;
                padding: 10px;
                margin:  10px;
            },
            (INPUT type => 'button',
                  value => 'click me',
                onclick => sub {print "hello\n"}
            ),
            (INPUT type => 'button',
                  value => 'function',
                onclick => function q{alert("world!")}
            ),
        );

=head1 DESCRIPTION

this module is a thin wrapper around L<XUL::Gui> that disables the mozilla
specific portions (all of the XUL tags, the filepicker, trusted mode features),
but in turn allows you to create gui's in HTML + CSS that should run on most
modern browsers.

See L<XUL::Gui> for details.

Selected macros may be coming to simplify dealing with forms and tables,
C<< sub Button {INPUT type => 'button', @_} >>

=head1 CAVEATS

using this module is the same as:

    use XUL::Gui qw(... !:xul);

    display mozilla => 0, ...;

=head2 compatibility

internet explorer has limited support for some of the mechanisms used in
XUL::Gui.  some things won't work right or at all.  event handlers work if you
use C< _onclick > instead of C< onclick > (since ie doesn't support setting
event handlers with C< setAttribute > like every other browser...)

ymmv. patches welcome

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 COPYRIGHT & LICENSE

copyright 2009-2010 Eric Strom.

this program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__ if 'first require'
