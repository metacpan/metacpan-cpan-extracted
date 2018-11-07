
=head1 Name

qbit::GetText

=head1 Description

Functions to internatilization application.

More information on L<GNU.org|http://www.gnu.org/software/gettext/manual/gettext.html>.

qbit::GetText use pure perl version of gettext by default. If you need to use XS version, set envirement variable FORCE_GETTEXT_XS to TRUE;

=cut

package qbit::GetText;
$qbit::GetText::VERSION = '2.8';
use strict;
use warnings;
use utf8;

use base qw(Exporter);

use Locale::Messages;
Locale::Messages->select_package($ENV{'FORCE_GETTEXT_XS'} ? 'gettext_xs' : 'gettext_pp');

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      gettext ngettext pgettext npgettext
      d_gettext d_ngettext d_pgettext d_npgettext
      set_locale
      );
    @EXPORT_OK = @EXPORT;
}

=head1 Functions

=head2 gettext

B<Arguments:>

=over

=item

B<$text> - string, message;

=item

B<@params> - array of strings, placeholders.

=back

B<Return value:> string, localized message.

=cut

sub gettext($;@) {
    my ($text, @params) = @_;
    utf8::encode($text);
    my $msg = Locale::Messages::turn_utf_8_on(Locale::Messages::gettext($text));
    return @params ? sprintf($msg, @params) : $msg;
}

=head2 ngettext

B<Arguments:>

=over

=item

B<$text> - string, message;

=item

B<$plural> - string, plural form of message;

=item

B<$n> - number, quantity of something;

=item

B<@params> - array of strings, placeholders.

=back

B<Return value:> string, localized message.

=cut

sub ngettext($$$;@) {
    my ($text, $plural, $n, @params) = @_;
    utf8::encode($text);
    utf8::encode($plural);
    my $msg = Locale::Messages::turn_utf_8_on(Locale::Messages::ngettext($text, $plural, $n));
    return @params ? sprintf($msg, @params) : $msg;
}

=head2 pgettext

B<Arguments:>

=over

=item

B<$context> - string, message context;

=item

B<$text> - string, message;

=item

B<@params> - array of strings, placeholders.

=back

B<Return value:> string, localized message.

=cut

sub pgettext($$;@) {
    my ($context, $text, @params) = @_;
    utf8::encode($context);
    utf8::encode($text);
    my $msg = Locale::Messages::turn_utf_8_on(Locale::Messages::pgettext($context, $text));
    return @params ? sprintf($msg, @params) : $msg;
}

=head2 npgettext

B<Arguments:>

=over

=item

B<$context> - string, message context;

=item

B<$text> - string, message;

=item

B<$plural> - string, plural form of message;

=item

B<$n> - number, quantity of something;

=item

B<@params> - array of strings, placeholders.

=back

B<Return value:> string, localized message.

=cut

sub npgettext($$$$;@) {
    my ($context, $text, $plural, $n, @params) = @_;
    utf8::encode($context);
    utf8::encode($text);
    utf8::encode($plural);
    my $msg = Locale::Messages::turn_utf_8_on(Locale::Messages::npgettext($context, $text, $plural, $n));
    return @params ? sprintf($msg, @params) : $msg;
}

=head2 d_*gettext

Deffered versions of *gettext functions.

 my $s = d_ngettext('site', 'sites', 1);
 # equivalent
 my $s = sub {ngettext('site', 'sites', 1)};

=cut

sub d_gettext($;@) {
    my ($text, @params) = @_;
    return sub {gettext($text, @params)}
}

sub d_ngettext($$$;@) {
    my ($text, $plural, $n, @params) = @_;

    return sub {ngettext($text, $plural, $n, @params)}
}

sub d_pgettext($$;@) {
    my ($context, $text, @params) = @_;
    return sub {pgettext($context, $text, @params)};
}

sub d_npgettext($$$$;@) {
    my ($context, $text, $plural, $n, @params) = @_;

    return sub {npgettext($context, $text, $plural, $n, @params)}
}

=head2 set_locale

B<Arguments as hash:>

=over

=item

B<lang> - string, locale (ru_RU, en_UK, ...);

=item

B<path> - string, path to locales;

=item

B<project> - string, project name.

=back

Path with locales must be C<$opts{'path'}/$opts{'lang'}/LC_MESSAGES/$opts{'project'}.mo>.

=cut

sub set_locale {
    my (%opts) = @_;

    Locale::Messages::nl_putenv("LC_ALL=$opts{'lang'}");
    Locale::Messages::nl_putenv("LANGUAGE=$opts{'lang'}");
    Locale::Messages::textdomain($opts{'project'});
    Locale::Messages::bindtextdomain($opts{'project'} => $opts{'path'});
    Locale::Messages::bind_textdomain_codeset($opts{'project'} => "UTF-8");

    return 1;
}

1;
