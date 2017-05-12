package XTaTIK::Docs::03_PreparingSiteSilo;

use strict;
use warnings;

our $VERSION = '0.005002'; # VERSION

1;
__END__

=encoding utf8

=for stopwords eCommerce

=head1 NAME

XTaTIK::Docs::03_PreparingSiteSilo - Preparation of site-specific config and files

=head1 NOTE ON COMPANY SILO

You can specify config variables, static files, and templates for
all of your sites by using a I<Company Silo>. See
L<XTaTIK::Docs::02_PreparingCompanySilo> for details.

=head1 YOUR SITE SILO

If you followed along L<XTaTIK::Docs::02_PreparingCompanySilo>, you now
have a directory with all the config and files that override XTaTIK's
defaults. If you are creating just one eCommerce website, simply continue
operating in that same directory (actually, you might already be done).
For running multiple sites, create a new directory somewhere and simply
I<repeat> the same process you've done to create your Company Silo
in L<XTaTIK::Docs::02_PreparingCompanySilo>. Keep in mind, right now
you'll be overriding both your Company Silo and XTaTIK defaults.

Once finished, see L<XTaTIK::Docs::04_Launch> next.

=cut