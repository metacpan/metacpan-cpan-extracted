#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2017 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#

#------------------------------------------------------------------------------
#
#  WebDyne Apache configuration section
#
#------------------------------------------------------------------------------
#
#


#  Need mod_perl, load up if not already done
#
<!-- 

#
my @out;
if ($MP2_INSTALLED) {
	@out=(
		'<IfModule !mod_perl.c>',
        	"LoadModule perl_module \"$FILE_MOD_PERL_LIB\"",
       		'</IfModule>'
        );
}
else {
	@out=(
		'<IfModule !mod_perl.c>',
        	"LoadModule perl_module \"$FILE_MOD_PERL_LIB\"",
       		'AddModule  mod_perl.c',
       		'</IfModule>'
       	);
}
$OUT=join($/, @out);

-->


#  Fix up @INC path, do any other init stuff before loading WebDyne
#  module
#
<!--
use Config;

my $installbin_dn=$DIR_INSTALLBIN || $Config{'installbin'};
my $perl5lib_fn;

unless ($perl5lib_fn=$INC{$FILE_PERL5LIB}) {
	$perl5lib_fn=File::Spec->catfile($installbin_dn, $FILE_PERL5LIB);
}
else {
	$perl5lib_fn=File::Spec->canonpath($perl5lib_fn);
}

$OUT=qq[PerlRequire "$perl5lib_fn"]

-->


#  Load Apache::compat module if running mod_perl 1.99
#
<!--
use Config;

my $installbin_dn=$DIR_INSTALLBIN || $Config{'installbin'};

my $mod_perl_1_99_compat_fn=File::Spec->catfile($installbin_dn, $FILE_MOD_PERL_1_99_COMPAT);
$OUT=qq[PerlRequire "$mod_perl_1_99_compat_fn"]

-->


#  Load WebDyne modules
#
PerlModule	WebDyne WebDyne::Compile


#  Associate .psp files with WebDyne
#
<!-- 
my @out;
if ($MP2_INSTALLED) {
	@out=(
		'AddHandler	perl-script	.psp',
		'PerlHandler	WebDyne'
        );
}
else {
	@out=(
		'<LocationMatch "\.psp">',
		'SetHandler perl-script',
		'PerlHandler WebDyne',
		'</LocationMatch>'
       	);
}
$OUT=join($/, @out);

-->


#  Block access to any module .pm files that might available in public
#  areas as a precaution
#
<Files ~ "\.pm$">
Order allow,deny
Deny from all
</Files>


#  Set disk cache dir and allow apache access
#
PerlSetVar WEBDYNE_CACHE_DN "<!-- $WEBDYNE_CACHE_DN -->"
<Directory "<!-- $WEBDYNE_CACHE_DN -->">
Order allow,deny
Allow from all
Deny from none
</Directory>


#  Some config setting defaults. See documentation for full range. Commented out
#  options represent defaults
#
<Perl>

#  Error display/extended display on/off. More granular options below. 
#  Set to 1 to enable, 0 to disable
#
#  $WebDyne::WEBDYNE_ERROR_SHOW=<!-- $WEBDYNE_ERROR_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=<!-- $WEBDYNE_ERROR_SHOW_EXTENDED -->;


#  Extended error control.
#
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_PRE -->;
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_LINES_POST -->;
#
#
#  Max length of source line to show in ouput. 0 for unlimited.
#
#  $WebDyne::WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX=<!-- $WEBDYNE_ERROR_SOURCE_CONTEXT_LINE_FRAGMENT_MAX -->;
#
#
#  Show filename (including full filesystem path)
#
#
#  $WebDyne::WEBDYNE_ERROR_SOURCE_FILENAME_SHOW=<!-- $WEBDYNE_ERROR_SOURCE_FILENAME_SHOW -->;
#
#
#  Show backtrace, show full or brief backtrace
#
#  $WebDyne::WEBDYNE_ERROR_BACKTRACE_SHOW=<!-- $WEBDYNE_ERROR_BACKTRACE_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_BACKTRACE_SHORT=<!-- $WEBDYNE_ERROR_BACKTRACE_SHORT -->;
#
#
#  Show eval trace. Uses SOURCE_CONTEXT_LINES to determine number of lines to show
#
#  $WebDyne::WEBDYNE_ERROR_EVAL_CONTEXT_SHOW=<!-- $WEBDYNE_ERROR_EVAL_CONTEXT_SHOW -->;
#
#
#
#  CGI Params
#
#  $WebDyne::WEBDYNE_ERROR_CGI_PARAM_SHOW=<!-- $WEBDYNE_ERROR_CGI_PARAM_SHOW -->;
#
#
#  URI and version
#
#  $WebDyne::WEBDYNE_ERROR_URI_SHOW=<!-- $WEBDYNE_ERROR_URI_SHOW -->;
#  $WebDyne::WEBDYNE_ERROR_VERSION_SHOW=<!-- $WEBDYNE_ERROR_VERSION_SHOW -->;


#  CGI Upload facility. Set to 0 to enable, max post size as required
#
#  $WebDyne::WEBDYNE_CGI_DISABLE_UPLOADS=<!-- $WEBDYNE_CGI_DISABLE_UPLOADS -->;
#  $WebDyne::WEBDYNE_CGI_POST_MAX=<!-- $WEBDYNE_CGI_POST_MAX -->; #(512 * 1024); #512Kb


#  Send no-cache headers ?
#
#  $WebDyne::WEBDYNE_NO_CACHE=<!-- $WEBDYNE_NO_CACHE -->;


#  Warnings fatal ? 
#
#  $WebDyne::WEBDYNE_WARNINGS_FATAL=<!-- $WEBDYNE_WARNINGS_FATAL -->;


#  Encoding
#
#  $WebDyne::WEBDYNE_CHARSET='<!-- $WEBDYNE_CHARSET -->';


#  Include a Content-Type meta tag ?
#
#  $WebDyne::WEBDYNE_CONTENT_TYPE_HTML_META=<!-- $WEBDYNE_CONTENT_TYPE_HTML_META -->;


#  Default <html> tag paramaters, eg { lang	=>'en-US' }
#
#  $WebDyne::WEBDYNE_HTML_PARAM=<!-- $WEBDYNE_HTML_PARAM || 'undef'-->;


#  CGI Paramater expansion. Will make POST submit strings of "foo=bar&car=dar" into
#  individual paramaters. Set to 0 if not desired
#
#  $WebDyne::WEBDYNE_CGI_PARAM_EXPAND=<!-- $WEBDYNE_CGI_PARAM_EXPAND -->;


#  Reload modules from disk if changed ?
#
#
#  $WebDyne::WENDYNE_RELOAD=<!-- $WEBDYNE_RELOAD -->;

</Perl>
