# $Id: sql.pl,v 1.1 2001/07/03 23:48:27 mpeppler Exp $
#
#	@(#)sql.pl	1.1	8/2/95
#
# This is the old version of the Sybase::DBlib::sql() call.

# FIXME: make it so that requiring this file overrides the sql() call
# in DBlib.pm

sub sql {
    my($db,$sql,$sep)=@_;			# local copy parameters
    my(@res, @data);

    $sep = '~' unless $sep;			# provide default for sep

    @res = ();					# clear result array

    $db->dbcmd($sql);				# pass sql to server
    $db->dbsqlexec;				# execute sql

    while($db->dbresults != NO_MORE_RESULTS) {	# copy all results
	while (@data = $db->dbnextrow) {
	    push(@res,join($sep,@data));
	}
    }

    @res;					# return the result array
}
