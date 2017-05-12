#!/usr/bin/perl -I.

use strict;
use LiveGeez::Services;
use LiveGeez::Config ( useapache => 0, uri_zauthority => "http://www.geez.org", uri_zpath => "/Z.pl" );
use LiveGeez::Request;


main:
{
my $r = new LiveGeez::Request ( LiveGeez::Config->new );

	ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );

	exit (0);

}


__END__


=head1 NAME

Zobel -- Remote Processing of Ethiopic Web Pages

=head1 SYNOPSIS

http://www.xyz.com/Z.pl?sys=MyFont&file=http://www.zyx.com/dir/file.html

or

% Z.pl sys=MyFont file=http://www.zyx.com/dir/file.html

=head1 DESCRIPTION

Z.pl is the front end of the "Zobel" implementation of the LiveGe'ez Remote
Processing Protocol.  The expected and intended use is via CGI query,
however the Z.pl script is servicable at the command line as well.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  LiveGeez(3).  Ethiopic(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>>

=cut
