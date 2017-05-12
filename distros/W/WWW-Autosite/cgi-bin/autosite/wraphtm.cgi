#!/usr/bin/perl -w
#BEGIN { use CGI::Carp 'fatalsToBrowser'; eval qq|use lib '$ENV{DOCUMENT_ROOT}/../lib';|; }
use strict;
use lib '../../lib';
use constant DEBUG => 0;
use WWW::Autosite ':all';

my $tmpl = handler_tmpl();
print STDERR "$0 started for: $ENV{PATH_TRANSLATED}\n" if DEBUG;

feed_META($tmpl,                   $ENV{PATH_TRANSLATED}  );
feed_ENV($tmpl);
feed_FILE($tmpl,                   $ENV{PATH_TRANSLATED}  );
feed_PLUGIN_PATH_NAVIGATION($tmpl, $ENV{PATH_TRANSLATED}  );
feed_PLUGIN_SITE_MAIN_MENU($tmpl);


$tmpl->param( BODY => slurp($ENV{PATH_TRANSLATED}));

print "Content-Type: text/html\n\n";
print $tmpl->output;
exit;




__END__

=pod

=head1 NAME

wraphtm.cgi

wraps any .htm file with templates

.htaccess must have

	# WRAPPING HTM, assumes any .htm file needs wrapping.
	Action wraphtm /cgi-bin/autosite/wraphtm.cgi
	AddHandler wraphtm .htm

=head1 SEE ALSO

L<WWW::Autosite>

=cut
