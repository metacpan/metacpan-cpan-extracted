# Generate tv_grab_it from tv_grab_it.in.  This is to set the path to
# the files in /usr/local/share/xmltv or wherever.
#
# The second argument is the share directory for the final
# installation.
#
# $Id: tv_grab_it.PL,v 1.2 2003/07/19 14:51:15 epaepa Exp $
#
die "usage: $_ output_file share_dir" if @ARGV != 2;
require 'lib/set_share_dir.pl';
set_share_dir('grab/it/tv_grab_it.in', $ARGV[0], $ARGV[1]);
