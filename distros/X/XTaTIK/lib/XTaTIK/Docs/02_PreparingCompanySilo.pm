package XTaTIK::Docs::02_PreparingCompanySilo;

use strict;
use warnings;

our $VERSION = '0.005002'; # VERSION

1;
__END__

=encoding utf8

=for stopwords eCommerce

=head1 NAME

XTaTIK::Docs::02_PreparingCompanySilo - Preparation of company-wide config and files

=head1 NOTE ON USEFULNESS

Having a I<Company Silo> is only useful if you have multiple websites
and you would like to share configuration and static files across all
those sites.

You don't really need a I<Company Silo>, if you're going to run just
a single eCommerce site. If that is the case, simply assume all
I<Company Silo> instructions refer to your I<Site Silo>—that is,
a directory with all of our site's files.

=head1 YOUR COMPANY SILO

If you followed along L<XTaTIK::Docs::01_Installation>, right now
you have a directory with IP2Location database file. Create
C<XTaTIK.conf> file inside of it. Consult
L<XTaTIK::Docs::Appendix::XTaTIK_conf> and select which configuration
variables you would like to override for your sites. Then,
consult L<XTaTIK::Docs::Appendix::StaticFiles> and select which
static files you'd like to override. Lastly, consult
L<XTaTIK::Docs::Appendix::Templates> and select which templates you wish
to override.

Replicate any of the files you wish to
override in your Company Silo. They will take precedence over the
default XTaTIK static files and templates. Your Site Silos will also be
able to override any files offered by either XTaTIK core or your Company
Silo.

Once finished, see L<XTaTIK::Docs::03_PreparingSiteSilo> next.

=cut