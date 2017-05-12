#!/usr/bin/perl -w
use strict;
use lib '../../lib';
use WWW::Autosite qw(:all);
use WWW::Autosite::Image qw(:all);
use Cwd;
use Carp;
# get abs path to sgc (s)erver (g)enerated (c)ontent

WWW::Autosite::DEBUG = 0;
 
use constant DEBUG => 1;

my ($method,$abs_content) = handler_content();
print STDERR "[image.html.pl] started for [$abs_content]\n" if DEBUG;


my $tmpl = handler_tmpl(); # main template
feed_META($tmpl,$abs_content);
feed_ENV($tmpl);
feed_FILE($tmpl,$abs_content);
feed_PLUGIN_PATH_NAVIGATION($tmpl);







my $default = <<"__TEMPLATE__";
<style>
.plugin_image {
font-size:75%;
}
</style>
<div class="plugin_image">

	<p><img src="<TMPL_VAR FILE_REL_PATH>" alt="<TMPL_VAR META_ALT>"></p>
	<p><TMPL_VAR META_TITLE></p>
	<p><TMPL_VAR META_DESCRIPTION></p>	
	<ul><li>Date: <TMPL_VAR EXIF_CREATEDATE></li> 
	<li><TMPL_VAR FILE_FILESIZE>, <TMPL_VAR COMPOSITE_IMAGESIZE></li>
	<li>Focal Length: <TMPL_VAR COMPOSITE_FOCALLENGTH35EFL></li>
	<li>Aperture: <TMPL_VAR COMPOSITE_SHUTTERSPEED></li></ul>
	
	<TMPL_VAR IMAGE_UL>

</div>	 
	 
__TEMPLATE__



# secondary template
my $itmpl = get_tmpl('plugin_image.html',\$default);

feed_META($itmpl,$abs_content);

my $data = get_prepped_exif_hash($abs_content);
for (keys %$data){ $itmpl->param($_ => $data->{$_} ); }
#$itmpl->param( IMAGE_UL => get_ul($abs_content) );



$tmpl->param( BODY => $itmpl->output);


print STDERR "[image.html.pl] fed[$abs_content], about to print tmpl output\n" if DEBUG;
print "Content-Type: text/html\n\n" if $method > 2 ;
print $tmpl->output;

exit;


=for nothing
sub feed_IMAGE {
	my $tmpl = shift;	 $tmpl or croak('missing tmpl arg');
	my $abs_content = shift; 	$abs_content or croak('missing abs content arg');

	print STDERR " feed_IMAGE() started for [$abs_content] file" if DEBUG;

	my $default = <<__DEFAULT__;

<div class="image">

<p><img src="<TMPL_VAR FILE_REL_PATH>"></p>

<ul>
<TMPL_IF META_AUTHOR><li>author: <TMPL_VAR META_AUTHOR></li></TMPL_IF>
<TMPL_IF META_LOCATION><li>location: <TMPL_VAR META_LOCATION></li></TMPL_IF>
</ul>

</div>
__DEFAULT__

	my $subtmpl = get_tmpl('plugin_image.html',\$default);
	feed_FILE($subtmpl,$abs_content);
	feed_META($subtmpl,$abs_content);


	$tmpl->param( BODY => $subtmpl->output ); 	
	return $tmpl;
}

=cut




__END__


=head1 NAME


=head1 DESCRIPTION


=head1 SEE ALSO

L<WWW::Autosite>

=cut

