package XTaTIK::Docs::Appendix::StaticFiles;

use strict;
use warnings;

our $VERSION = '0.005002'; # VERSION

1;
__END__

=encoding utf8

=for stopwords overriden nav shoutout

=head1 NAME

XTaTIK::Docs::Appendix::StaticFiles - Map of XTaTIK static files you can override

=head1 PRECEDENCE

Static files can be found in XTaTIK core, your Company Silo, and your
Site Silo. If files of the same name exist, your Site Silo location
will take precedence over Company Silo, which in turn takes precedence
over files in XTaTIK core.

This, of course, does mean you can place a static file into your
Company Silo and it will be available to all of your Sites.

=head1 XTaTIK CORE FILES TO OVERRIDE

These static files you can override directly from either your
company or site silos. You'll likely won't ever need to touch the SASS
files, however.

    public
    ├── favicon.ico
    ├── product-pics
    │   └── nopic.png
    ├── content-pics
    │   ├── nav-logo.png # Does not exist by default!!
    │   ├── shoutout-art.png # Does not exist by default!!
    │   └── index-logo.png
    └── sass
        ├── bootstrap-extras.scss
        ├── bs-callout.scss
        ├── main.scss
        └── reset.scss

=over 4

=item * C<nopic.jpg>—the image file to display when product photo is not
    available

=item * C<nav-logo.png>—the little logo to display in the nav on every
    page. This file does not exist by default and if neither
    Site nor Company silos have this file, market/company text will be
    shown instead

=item * C<index-logo.png>—the large logo displayed on the home page
    during shoutout animation

=item * C<shoutout-art.jpg>—if present, will be used during the first portion
    of shoutout animation, instead of C<index-logo.png>

=item * I<sass files>—these files are used to provide XTaTIK
    core styles. Generally, you'd use additional Company/Site SASS files
    instead of overriding core files. B<Note:> this also means
    the filenames mentioned above are I<reserved> and cannot be used
    by Company/Site silos without the overriding effect.

=back


=head1 COMPANY SILO FILES

    ├── JS
    │   └── ** any file **
    └── sass
        ├── bootstrap
        │   └── company-variables.scss
        └── user
            └── ** any file **

You can place any JavaScript file into C<JS> directory
and any SASS file into C<sass/user> directory in your Company Silo.
They sill by C<sort>ed and loaded in that order.

=over 4

=item * C<company-variables.scss>—you can use this file to override
    Bootstrap's and
    L<XTaTIK's SASS variables|XTaTIK::Docs::Appendix::SASSVariables>.
    Be sure to append C<!default> to your variables here, so you
    could override them per-site from Site Silos.

=back


=head1 SITE SILO FILES

    ├── JS
    │   └── ** any file **
    └── sass
        ├── bootstrap
        │   └── site-variables.scss
        └── user
            └── ** any file **

Same as with Company Silo files, you can place
any JavaScript file into C<JS> directory
and any SASS file into C<sass/user> directory in your Company Silo.
They sill by C<sort>ed and loaded in that order.

=over 4

=item * C<site-variables.scss>—you can use this file to override
    Bootstrap's and
    L<XTaTIK's SASS variables|XTaTIK::Docs::Appendix::SASSVariables>.
    Any Company Silo SASS variables marked with C<!default> flag can
    also be overriden from here

=back


=cut

