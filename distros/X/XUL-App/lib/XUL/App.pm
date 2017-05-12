package XUL::App;

use strict;
use warnings;
use base qw/ Class::Data::Inheritable /;

our $VERSION = '0.09';

__PACKAGE__->mk_classdata('FILES' => {});

our ($ID, $APP_NAME);

1;
__END__

=head1 NAME

XUL::App - Nifty XUL apps in a XUL::App

=head1 VERSION

This document describes XUL::App 0.09 released on August 13, 2008.

=head1 SYNOPSIS

    $ xulapp app --name YSearchAll

    $ cd YSearchAll

    $ xulapp view --name Overlay --type overlay

    # Edit lib/YSearchAll/App.pm to add the following lines:
    package YSearchAll::App; our $VERSION = '0.09';

    use XUL::App::Schema;
    use XUL::App schema {
    +     xulfile 'overlay.xul' =>
    +         generated from 'YSearchAll::View::Overlay',
    +         includes qw( xulapp/jquery.js overlay.js ),
    +         overlays 'chrome://browser/content/browser.xul';
    +
        xpifile 'ysearchall.xpi' =>
            name is 'YSearchAll',
            id is 'ysearchall@agentz.agentz-office',
            version is '0.0.1',
            targets {
                Firefox => ['2.0' => '3.0.*'],  # FIXME
                Mozilla => ['1.5' => '1.8'],  # FIXME
            },
            creator is 'The YSearchAll development team',
            developers are ['agentz'],
            contributors are [],
            homepageURL is 'http://searchall.agentz.org', # FIXME
            iconURL is '',  # like 'chrome://helloworld/content/logo.png'
            updateURL is ''; # This should not set for AMO extensions.
    };
    1;

    # Add and edit js/ysearchall.js manually
    $ xulapp overlay -p dev11
    $ xulapp bundle .  # generate XPI ready for deployment

=head1 DESCRIPTION

XUL::App is a nifty Firefox extension development framework based on Perl. It has a lot of parallels with L<Jifty>. In particular, this framework allows you to build real-world modern Firefox extensions using Perl. But the resulting XPI installation file is completely portable and contains I<0> Perl.

This framework has the following highlights:

=over

=item *

L<Jifty> love on the Firefox extension development land.

=item *

Building a realworld Firefox extension can be even much easier than GreaseMonkey hacks.

=item *

Use B<100%> Perl to specify XUL layout via L<Template::Declare>, no XML pain.

=item *

Automatic extension registration/unregistration for easy debugging. And no more frustration from Firefox's XUL/ext cache. (XUL::App will ensure the developer version defeats Firefox's cache.)

=item *

Transparent C<jar>-based XPI bundling, no F<chrome.manifest>, L<install.rdf>, and zip panic. XUL::App generates all of them for you according to your (declarative) Perl code.

=item *

The resulting XPI file contains B<0%> Perl and could run everywhere (Win32, Mac, Linux, and etc). It's a compiler-style framework.

=item *

I18N support via the L<Locale::Maketext::Lexicon> module (same as L<Jifty>, but
actually emulated by XUL's native I18N mechanism).

=back

Currently the module is still in B<alpha> stage and we're in severe lack of documentation and tests. (Although a real-world fully-fledged Firefox extension named SearchAll (L<https://addons.mozilla.org/en-US/firefox/addon/5712>) is already developed atop it.

You can get a lot of information from the slides that I used in the following talk:

L<http://agentzh.org/misc/slides/xulapp/xulapp.xul>  (a JS-enabled Firefox is required to view these slides)

If you're having problems in displaying the slides given above, please try out the PowerPoint (PPT) version below:

L<http://agentzh.org/misc/slides/xulapp.ppt>

or the PDF version:

L<http://agentzh.org/misc/slides/xulapp.pdf>

=head1 CAVEATS

=over

=item *

Because XUL::App writes to your ~/.mozilla/firefox directory directly, it's always recommended to backup that directory to somewhere else to prevent unexpected corruption occurring to your Firefox profiles.

=item *

After applying Firefox updates or switching to a new Firefox profile, it's required to restart your Firefox one more time so as to load your extensions. So please don't fire bug report for this.

=item *

Only Firefox 2.0.0.* and Firefox 3.0 on Linux has been tested against this framework. So you're warned when you're going to do XUL::App hacking on other platforms, such as Windows.

(BTW, I'm very willing to apply patches for other platforms.)

=back

=head1 SOURCE CONTROL

You can always get the latest source of XUL::App from the following SVN repository:

L<http://svn.openfoundry.org/xulapp/trunk/>

I really need help in improving this module's docs, tests, and implementation. If you find this thing useful and feel like contributing to it, please write to me and get a commit bit! ;)

=head1 SAMPLES

=over

=item *

SearchAll is a real-world Firefox extension that is built upon XUL::App, which can serve as a big demo for the usage of the framework:

L<http://svn.openfoundry.org/searchall/trunk/>

And it's already on the mozilla official site AMO:

L<https://addons.mozilla.org/en-US/firefox/addon/5712>

=item *

ExportReader: A Firefox extension to dump entries from Google Reader to JSON:

L<http://svn.openfoundry.org/xulapp/trunk/demo/ExportReader/>

This extension only costed me about 10 lines of Perl and 20 lines of JavaScript, in addition to a few shell commands. The process is easy and enjoyable.

Because it's mostly for personal use, The usage of this addon deserves some explanation though:

=over

=item 1.

Click the XPI file from your Firefox browser:

L<http://svn.openfoundry.org/xulapp/trunk/demo/ExportReader/exportreader.xpi>

After installation, please remember to restart the browser.

=item 2.

Enter the following chrome URL in your Firefox's address bar:

L<chrome://exportreader/content/exportreader.xul>

Then you will see the main UI of this extension.

=item 3.

Login to your Google Reader and then click the site on the left-hand-side menu whose entries are what you want to export, say, "chromatic's Journal". Ensure that the "Expanded View" is used in the right-hand-side on the Google Reader page.

=item 4.

Click the "Extract!" button on the right-upper corner. Then you'll see an alert dialog saying how many entries were found. Click "OK" then the corresponding JSON string will be in the right-most textbox which is ready for copy-and-paste.

Note that, by defaul, Google Reader lazily loads just the top 5 entries or so. So in order to export all the entries in the subscribed site, say, "chromatic's Journal", you'll have to scroll down the Reader's Expanded View and force it to retrieve more entries.

=back

=item *

A helloworld sample extension is given in my XUL::App talk's slides:

L<http://agentzh.org/misc/slides/xulapp.pdf>

=back

=head1 INSTALLATION

    perl Makefile.PL
    make
    sudo make install

=head1 BUGS

Sadly XUL::App does not run on Win32 yet. I've only tested it on Ubuntu Linux so far. If you have any problems or would love to help, please let me know ;)

=head1 AUTHOR

Agent Zhang <agentzh@yahoo.cn>

=head1 COPYRIGHT AND LICENSE

Copyright 2007, 2008 by Yahoo! China EEEE Works, Alibaba Inc. (L<http://www.eeeeworks.org>)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Artistic or GPL.

=head1 SEE ALSO

L<xulapp>, L<Locale::Maketext::Lexicon>, L<Template::Declare>, L<Jifty>.

