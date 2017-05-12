#!/usr/bin/perl -w
use strict;
use lib '../../lib';
use WWW::Autosite qw(:all);
use Cwd;
use Carp;
# get abs path to sgc (s)erver (g)enerated (c)ontent
#use HTML::TextToHTML;
use HTML::FromText;



my ($method,$abs_content) = handler_content();
my $tmpl = handler_tmpl();

feed_META($tmpl,$abs_content);
feed_ENV($tmpl);
feed_FILE($tmpl,$abs_content);
feed_PLUGIN_PATH_NAVIGATION($tmpl);

feed_text($tmpl, $abs_content);


#handler_write_sgc($tmpl);
print "Content-type: text/html\n\n" if $method >2;  
print $tmpl->output;

exit;



#sub feed_text {
#	my $tmpl = shift;	 $tmpl or croak('missing tmpl arg');
#	my $abs_content = shift; 	$abs_content or croak('missing abs content arg');

#	my $conv = new HTML::TextToHTML();
	
#	my $chunk = slurp($abs_content);
#	my $body = $conv->process_chunk($chunk);
	

#	$tmpl->param( BODY => $body ); 	
#	return $tmpl;
#}


sub feed_text {
	my $tmpl = shift;	 $tmpl or croak('missing tmpl arg');
	my $abs_content = shift; 	$abs_content or croak('missing abs content arg');
	my $chunk = slurp($abs_content);

	my $conv = new HTML::FromText;	
	my $body = $conv->parse($chunk);	

	$tmpl->param( BODY => $body ); 	
	return $tmpl;
}

__END__


=head1 NAME

text.html.pl - autosite pod handler

=head1 DESCRIPTION

usage

	text.html.pl /this/file.txt > /this/file.txt.html

=head1 SEE ALSO

L<HTML::FromText>

L<WWW::Autosite>

=cut

