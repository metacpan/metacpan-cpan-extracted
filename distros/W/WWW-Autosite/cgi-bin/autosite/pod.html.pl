#!/usr/bin/perl -w
use strict;
use lib '../../lib';
use WWW::Autosite qw(:handler :feed);
use Cwd;
use Carp;
WWW::Autosite::DEBUG = 1;
# get abs path to sgc (s)erver (g)enerated (c)ontent
use constant DEBUG => 1;
use Pod::Html;


my ($method,$abs_content)= handler_content();
print STDERR "abs content $abs_content, method $method\n" if DEBUG;
my $tmpl = handler_tmpl();


feed_META($tmpl,$abs_content);
feed_ENV($tmpl);
feed_FILE($tmpl,$abs_content);
feed_PLUGIN_SITE_MAIN_MENU($tmpl);
feed_PLUGIN_PATH_NAVIGATION($tmpl);


feed_POD($tmpl, $abs_content);


#handler_write_sgc($tmpl);

print "Content-Type: text/html\n\n" if $method > 2;
print $tmpl->output;

exit;



sub feed_POD {
	my $tmpl = shift;	 $tmpl or croak('missing tmpl arg');
	my $abs_content = shift; 	$abs_content or croak('missing abs content arg');

	
	chdir '/tmp'; # otherwise, if no suexec, dies
	# as it turns out.. freaking pod2html actually writes a tmp file
	# but if the script has no permission to write taht dir... it freaks out.
	# the solution is chdir to somewhere we *can* write.
	my $command = qq{pod2html --infile=$abs_content}; # WORKS for LINKING
	my $page = `$command`;
	$page=~/<body[^>]*>(.+)<\/body>/si or die('cant match body'); # rip junk out, die? just return error instead?
	my $body = $1;

	$tmpl->param( BODY => $body ); 
	
	return $tmpl;
}

__END__


=head1 NAME

pod.html.pl - autosite pod handler

=head1 DESCRIPTION

usage

	pod.html.cgi /this/file.pod > /this/file.pod.html

=head1 SEE ALSO

L<WWW::Autosite>

=cut

