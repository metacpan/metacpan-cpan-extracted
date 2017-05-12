# Generate tv_grab_nl from tv_grab_nl.in.  This is to set the path to
# the files in /usr/local/share/xmltv or wherever.
#
# The second argument is the share directory for the final
# installation.
#
# $Id: tv_grab_nl.PL,v 1.1 2004/01/02 20:07:26 epaepa Exp $
#
die "usage: $_ output_file share_dir" if @ARGV != 2;
require 'lib/set_share_dir.pl';
set_share_dir('grab/nl/tv_grab_nl.in', $ARGV[0], $ARGV[1]);
