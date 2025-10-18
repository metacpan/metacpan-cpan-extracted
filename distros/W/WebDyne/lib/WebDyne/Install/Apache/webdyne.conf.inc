#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
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

<!--
#  Fix up @INC path, do any other init stuff before loading WebDyne
#  module
#
##use Config;
##
##my $installbin_dn=$DIR_INSTALLBIN || $Config{'installbin'};
##my $perl5lib_fn;
##
##unless ($perl5lib_fn=$INC{$FILE_PERL5LIB}) {
##	$perl5lib_fn=File::Spec->catfile($installbin_dn, $FILE_PERL5LIB);
##}
##else {
##	$perl5lib_fn=File::Spec->canonpath($perl5lib_fn);
##}
##
##$OUT=qq[#PerlRequire "$perl5lib_fn"]
##
-->


#  Load Apache::compat module if running mod_perl 1.99
#
<!--
use Config;

my $installbin_dn=$DIR_INSTALLBIN || $Config{'installbin'};

my $mod_perl_1_99_compat_fn=File::Spec->catfile($installbin_dn, $FILE_MOD_PERL_1_99_COMPAT);
$OUT=qq[#PerlRequire "$mod_perl_1_99_compat_fn"]

-->


#  Adjust and/or uncomment if using local::lib for installs
#
<!--
if (my $perl5lib=$ENV{'PERL5LIB'}) {
    $OUT=sprintf('PerlSwitches -I%s', $perl5lib);
}
else {
    $OUT='#PerlSwitches -I/opt/perl5'
}
-->
#

#  Load WebDyne modules
#
PerlModule	WebDyne WebDyne::Compile


#  Associate .psp files with WebDyne
#
<!-- 
my @out;
if ($MP2_INSTALLED) {
	@out=(
		'AddHandler	modperl	.psp',
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

<!-- 

if ($HTTPD_VER eq '2.2') {
$OUT=<<__PM_DENY_22__;

#  Apache 2.2 block config
#
<Files ~ "\.pm\$">
Order allow,deny
Deny from all
</Files>
__PM_DENY_22__

}
elsif ($HTTPD_VER eq '2.4') {

$OUT=<<__PM_DENY_24__;

#  Apache 2.4 block config
#
<Files ~ "\.pm\$">
Require all denied
</Files>

__PM_DENY_24__

}

-->

#  Set disk cache dir and allow apache access
#
PerlSetVar WEBDYNE_CACHE_DN "<!-- $WEBDYNE_CACHE_DN -->"

<!-- 

if ($HTTPD_VER eq '2.2') {
$OUT=<<"__CACHE_ALLOW_22__";

#  Apache 2.2 cache allow config
#
<Directory "$WEBDYNE_CACHE_DN">
Order allow,deny
Allow from all
Deny from none
</Directory>

__CACHE_ALLOW_22__
}
elsif ($HTTPD_VER eq '2.4') {
$OUT=<<"__CACHE_ALLOW_24__";

#  Apache 2.4 cache allow config
#
<Directory "$WEBDYNE_CACHE_DN">
Require all granted
</Directory>
__CACHE_ALLOW_24__
}

-->


#  Some config setting defaults. See documentation for full range. Commented out
#  options represent defaults
#
PerlRequire "<!-- File::Spec->catfile($DIR_APACHE_CONF, 'webdyne_conf.pl') -->"


#  Optional debugging. Everything or some things. Note debugging only enabled if
#  WebDybe installed with WEBDYNE_DEBUG=1; perl Makefile.PL; make install
#
#PerlSetEnv WEBDYNE_DEBUG 1
#PerlSetEnv WEBDYNE_DEBUG "render,perl"
#PerlSetEnv WEBDYNE_DEBUG_FILE "/var/log/webdyne_debug.log"


