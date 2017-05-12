=head1 NAME

Unicode::CheckUTF8 - checks if scalar is valid UTF-8

=head1 SYNOPSIS

   use Unicode::CheckUTF8 qw(is_utf8);
   my $is_ok = is_utf8($scalar);

=head1 DESCRIPTION

This is an XS wrapper around some Unicode Consortium code to check
if a string is valid UTF-8, revised to conform to what expat/Mozilla
think is valid UTF-8, especially with regard to low-ASCII characters.

Note that this module has NOTHING to do with Perl's internal UTF8 flag
on scalars.

This module is for use when you're getting input from users and want
to make sure it's valid UTF-8 before continuing.

=head1 HISTORY

This is some old code, dating back to before Perl 5.8 and before
Unicode support in Perl.  I wish I didn't have to keep using this
code, but I can't find any other code on CPAN for UTF-8 checking
that's both sufficiently fast and more importantly, correct.  So now
there's yet another way to do it.

=cut

package Unicode::CheckUTF8;

use base 'Exporter';

BEGIN {
   $VERSION = "1.03";

   @EXPORT = qw();
   @EXPORT_OK = qw(isLegalUTF8String is_utf8);

   require XSLoader;
   XSLoader::load Unicode::CheckUTF8, $VERSION;
}

1;

=head1 BUGS

Hopefully not, but mail me if so!

=head1 AUTHOR

Brad Fitzpatrick E<lt>brad@danga.comE<gt>, based on Unicode Consortium code.

Artur Bergman, helping me kill old Inline code using his awesome
knowledge of all things Perl and XS.



