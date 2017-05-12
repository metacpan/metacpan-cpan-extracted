#!/usr/bin/perl -w
use strict;
use Cwd;
use lib '../../lib';
use WWW::Autosite ':all';
WWW::Autosite::DEBUG =1;
use WWW::Autosite::Dir ':all';
use constant DEBUG => 1;
# drop in replacement for apache index listing

my $abs_dir = $ENV{DOCUMENT_ROOT}.'/'.$ENV{REQUEST_URI}; 
print STDERR "dir.cgi : $abs_dir\n";
my $dmpl = get_tmpl_dir();
$dmpl->param('LISTING' => get_loop_dir($abs_dir));
my $dirchunk = $dmpl->output;










# main tmpl
my $tmpl = handler_tmpl();
my $nav = get_plugin_path_navigation($abs_dir);

print STDERR "nav: $nav\n\n" if DEBUG;

$tmpl->param(PLUGIN_PATH_NAVIGATION => $nav );


$tmpl->param(BODY => $dirchunk);
print "Content-type: text/html\n\n";
print $tmpl->output;
exit;

