#!/usr/bin/perl -w
use strict;
BEGIN { open(STDERR, ">>./logfile");} 
use lib '../../lib';
use WWW::Autosite qw(:handler :feed get_tmpl);
use Carp;
use warnings;
use constant DEBUG => 0;

my ($method,$abs_content) = handler_content();

print STDERR "text.hi.pl running.. " if DEBUG;
-T $abs_content or die("$0 accepts only text files as argument, [$abs_content] is not a -T text file.");

my $tmpl = handler_tmpl();




feed_META($tmpl,$abs_content);
feed_ENV($tmpl);
feed_FILE($tmpl,$abs_content);
feed_PLUGIN_PATH_NAVIGATION($tmpl,$abs_content);

print STDERR "fed META, ENV, FILE, NAV, " if DEBUG;
#TODO put others here

my $type;

if ($abs_content=~/pl$|cgi$|pm$/i){
	$type = 'perl';
}
elsif ($abs_content=~/\.s*html*$/i){
	$type = 'html';
}
elsif ($abs_content=~/\.js$/i){
	$type = 'javascript';
}
elsif ($abs_content=~/\.css$|\.style$/i){
	$type = 'css';
}
elsif ($abs_content=~/\.pod$/){
	$type = 'pod';
}
elsif ($abs_content=~/\.php$/){
	$type = 'php';
}

else {
	$type = 'none';
}

print STDERR "type is $type\n" if DEBUG;
## $type



   use Text::VimColor;
   my $syntax = Text::VimColor->new(
      file => $abs_content,
      filetype => $type,
   );

   #print $syntax->html;

print STDERR "made Text::VimColor object\n" if DEBUG;

# use a template so that we can set styles


my $default = <<"__DEFAULT__";
<style>
.synSpecial {
 color:#f0f;
font-weight:bold;
}
.synIdentifier {
 color: #288;
}
.synType {
 color: #8a8
}
.synConstant {
 color:#d42;
}
.synStatement {
 color:#aa2;
 font-weight:old;
}
.synComment {
 color:#789;
}
.synPreProc {
color:#987
}
.synTODO {
background-color:#888;
color:#ff0;
}
.code {
white-space:pre;
background-color:#fff;
color:#000;
font-size:small;
}

</style>

<div class="code">
<TMPL_VAR BODY>
</div>

__DEFAULT__

my $subtmpl = get_tmpl('handler_text.hi.html',\$default);
$subtmpl->param( BODY => $syntax->html );

$tmpl->param(BODY =>$subtmpl->output);

print "Content-Type: text/html\n\n" if $method > 2; 
print $tmpl->output;

print STDERR "text.hi.pl (method $method) done\n" if DEBUG;
exit;


=pod

=head1 NAME

text.hi.pl - automatic vim syntax highlighting for any .hi autosite queries 

=head1 DESCRIPTION

Autosite sgc generator. Handler to render text to colored vim syntax.

Looks for handler_text.hi.html file in AUTOSITE_TMPL. If not present, uses default.

This handler acceps a path to any text file (-T heuristic perl guess) and will vim syntax color it 
to html output.

The router is already configured to route any text.hi queries to this handler.
For example

	http://domain.com/file.pod.hi 

Would cause the router to look for this script named as pod.hi.pl and then as text.hi.pl
Which would cause the necessary conversion.
To get rid of this functionality, simply delete this script from the directory where the
router resides.


=head1 SEE ALSO

For glossary, concepts, and breakdown, please read the L<WWW::Autosite::Manual>.

=head1 AUTHOR

Leo Charre

=cut


