#!/usr/bin/perl -w
use lib '../../lib'; 
use warnings;
use strict;
use WWW::Autosite ':all';
WWW::Autosite::DEBUG = 0;
use constant DEBUG => 1;



print STDERR "router.cgi started\n" if DEBUG;

# 0) 	user uploads file /demo.pod
#	client browser requests /demo.pod.html
# 	.htaccess file rewriterule seeks for /.tmp/demo.pod.html
# 	.htaccess reports 404, redirects to this script

my $error_doc ="/404.htm";
my $script_dir = script_dir();
print STDERR  "\n[0.script dir is [$script_dir], error doc is set to [$error_doc], request is $ENV{REQUEST_URI}\n" if DEBUG;


# 2) find out of the 404 is 'handleable' (ie: xxxxxx.xxx.xxx)
# does it look as if something was requested that could be an sgc?
request_sgc() or router_giveup('no requset_sgc');
print STDERR "\n[2.request_sgc worked\n" if DEBUG;

# 2.5) the original document (ie: demo.pod) exists
request_abs_content() or router_giveup('cant get request abs content'); 
print STDERR "\n[2.5.request_abs_content worked\n" if DEBUG;

# 3) the request type has a handler present? (ie: -f ./pod.html.cgi)
request_has_handler() or router_giveup('request does not have handler we can detect');
print STDERR "\n[3.request_has_handler worked\n" if DEBUG;

# 5) ok, handle it.
request_route();
exit;
 








# show 404 and exit
sub router_giveup {
	my $why = shift; $why ||= 'dunno.';
	print "Content-type: text/html\n\n";
	my $tmpl = handler_tmpl();

	my $msg = "<p>$ENV{REQUEST_URI} does not exist.</p>";
	$msg .= "<!-- $why --> " if DEBUG;
	
	$tmpl->param( BODY => $msg);
	print $tmpl->output;
	exit;
}






__END__

=pod

=head1 NAME

router.cgi - match requests to handlers for autosite

=head1 DESCRIPTION

The purpose of the router is to coordinate what the client browser asked for with what the server is configured to offer.
For a real breakdown please read L<WWW::Autosite>

=head1 SEE ALSO

L<WWW::Autosite>

=head1 AUTHOR

Leo Charre

=cut
