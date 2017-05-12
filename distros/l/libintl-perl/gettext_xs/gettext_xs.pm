#! /bin/false

# vim: tabstop=4

# Perl XS implementation of Uniforum message translation.
# Copyright (C) 2002-2016 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Locale::gettext_xs;

require DynaLoader;
require Exporter;

use vars qw (%EXPORT_TAGS @EXPORT_OK @ISA);

%EXPORT_TAGS = (locale_h => [ qw (
								  gettext
								  dgettext
								  dcgettext
								  ngettext
								  dngettext
								  dcngettext
								  pgettext
								  dpgettext
								  dcpgettext
								  npgettext
								  dnpgettext
								  dcnpgettext
								  textdomain
								  bindtextdomain
								  bind_textdomain_codeset
								  )
							  ],
				libintl_h => [ qw (LC_CTYPE
								   LC_NUMERIC
								   LC_TIME
								   LC_COLLATE
								   LC_MONETARY
								   LC_MESSAGES
								   LC_ALL)
							   ],
				);

@EXPORT_OK = qw (gettext
				 dgettext
				 dcgettext
				 ngettext
				 dngettext
				 dcngettext
                 pgettext
                 dpgettext
                 dcpgettext
                 npgettext
                 dnpgettext
                 dcnpgettext
				 textdomain
				 bindtextdomain
				 bind_textdomain_codeset
				 nl_putenv
                 setlocale
				 LC_CTYPE
				 LC_NUMERIC
				 LC_TIME
				 LC_COLLATE
				 LC_MONETARY
				 LC_MESSAGES
				 LC_ALL);
@ISA = qw (Exporter DynaLoader);

bootstrap Locale::gettext_xs;

require File::Spec;

# Reimplement pgettext functions
sub pgettext ($$) {
	my ($msgctxt, $msgid) = @_;

	my $msg_ctxt_id = join("\004", $msgctxt, $msgid);
	return Locale::gettext_xs::_pgettext_aux
		("", $msg_ctxt_id, $msgid, Locale::gettext_xs::LC_MESSAGES());
}
sub dpgettext ($$$) {
	my ($domain, $msgctxt, $msgid) = @_;

	my $msg_ctxt_id = join("\004", $msgctxt, $msgid);
	return Locale::gettext_xs::_pgettext_aux
		($domain, $msg_ctxt_id, $msgid, Locale::gettext_xs::LC_MESSAGES());
}
sub dcpgettext ($$$$) {
	my ($domain, $msgctxt, $msgid, $category) = @_;

	my $msg_ctxt_id = join("\004", $msgctxt, $msgid);
	return Locale::gettext_xs::_pgettext_aux
		($domain, $msg_ctxt_id, $msgid, $category);
}

# Reimplement npgettext functions
sub npgettext ($$$$) {
	my ($msgctxt, $msgid1, $msgid2, $n) = @_;

	my $msg_ctxt_id = join("\004", $msgctxt, $msgid1);
	return Locale::gettext_xs::_npgettext_aux
		("", $msg_ctxt_id, $msgid1, $msgid2, $n, Locale::gettext_xs::LC_MESSAGES());
}
sub dnpgettext ($$$$$) {
	my ($domain, $msgctxt, $msgid1, $msgid2, $n) = @_;

	my $msg_ctxt_id = join("\004", $msgctxt, $msgid1);
	return Locale::gettext_xs::_npgettext_aux
		($domain, $msg_ctxt_id, $msgid1, $msgid2, $n, Locale::gettext_xs::LC_MESSAGES());
}
sub dcnpgettext ($$$$$$) {
	my ($domain, $msgctxt, $msgid1, $msgid2, $n, $category) = @_;

	my $msg_ctxt_id = join("\004", $msgctxt, $msgid1);
	return Locale::gettext_xs::_npgettext_aux
		($domain, $msg_ctxt_id, $msgid1, $msgid2, $n, $category);
}

# Wrapper function that converts Perl paths to OS paths.
sub bindtextdomain ($;$) {
	my ($domain, $directory) = @_;

	if (defined $domain && length $domain && 
		defined $directory && length $directory) {
		return Locale::gettext_xs::_bindtextdomain 
			($domain, File::Spec->catdir ($directory));
	} else {
		return &Locale::gettext_xs::_bindtextdomain;
	}
}

# In the XS version, making the prototype optional, does not work.
sub textdomain (;$) {
	my $domain = shift;

	if (defined $domain) {
		return Locale::gettext_xs::_textdomain ($domain);
	} else {
		return Locale::gettext_xs::_textdomain ("");
	}
}

sub nl_putenv ($) {
    my ($envspec) = @_;
    
    return unless defined $envspec;
    return unless length $envspec;
    return if substr ($envspec, 0, 1) eq '=';
    
    my ($var, $value) = split /=/, $envspec, 2;
    
    if ($^O eq 'MSWin32') {
        $value = '' unless defined $value;
        return unless Locale::gettext_xs::_nl_putenv ("$var=$value") == 0;
        if (length $value) {
            $ENV{$var} = $value;
        } else {
            delete $ENV{$var};
        }
    } else {
        if (defined $value) {
            $ENV{$var} = $value;
        } else {
            delete $ENV{$var};
        }
    }

    return 1;
}

1;

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
tab-width: 4
End:

