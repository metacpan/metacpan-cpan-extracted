package SWISHED::Handler;
# this is the script that implements the swished daemon with mod_perl 2.0 

use lib '/usr/local/swished/lib';
use SWISHED::Core;
use strict;
use warnings;

# old way.
## these require mod_perl w/ apache 2.0!
#use Apache::RequestRec ();
#use Apache::RequestIO (); 
#use Apache::Const -compile => qw(OK);


# new way! run under mod_perl vers 1 or 2. pek
# TODO: what about mod_perl 1.99? joshr
#
my $APACHE_OK = 0;
if(! $ENV{MOD_PERL}) {
	# no need to override $APACHE_OK global
} elsif ($ENV{MOD_PERL} =~ m!^mod_perl/2!) {
    require Apache2::RequestRec;
    require Apache2::RequestIO;
    require Apache2::Const;
    Apache2::Const->import(-compile => qw(OK));
    $APACHE_OK = $Apache2::Const::OK;
} elsif ($ENV{MOD_PERL} =~ m!^mod_perl/1!) {
    require Apache::RequestRec;
    require Apache::RequestIO;
    require Apache::Const;
    Apache::Const->import(-compile => qw(OK));
    $APACHE_OK = $Apache::Const::OK;
} else {
    die "$0: MOD_PERL env var '$ENV{MOD_PERL}' doesn't match expected syntax\n";
}

# by default will use the index specified in $ENV{'SWISHED_INDEX_DEFAULT'}

sub handler {
	my $r = shift;
	$r->content_type('text/plain'); 
	SWISHED::Core::do_search();	# this uses CGI.pm to handle mod_perl-ness 
	#return Apache::OK; # old way
    $APACHE_OK;
}

1;

__END__

=head1 NAME

SWISHED::Handler - perl module to provide a persistent swish-e daemon

=head1 SYNOPSIS

Put lines like the following in your httpd.conf file:

	PerlRequire /usr/local/swished/lib/startup.pl
	PerlPassEnv SWISHED_INDEX_DEFAULT 
	<Location /swished>
		PerlResponseHandler SWISHED::Handler
		PerlSetEnv SWISHED_INDEX_DEFAULT /var/lib/sman/sman.index
		SetHandler perl-script
	</Location> 

=head1 DESCRIPTION 

Swished is a mod_perl module providing a persistent swish-e daemon

=head1 AUTHOR

Josh Rabinowitz

=head1 SEE ALSO

L<SWISHED::Core>, L<SWISH::API>, L<SWISH::API::Remote>

=cut



# $Log: Handler.pm,v $
# Revision 1.8  2006/07/06 18:00:52  joshr
# bump to version 0.10, comment and documentation changes
#
# Revision 1.7  2006/06/17 17:10:00  joshr
# change how we handle using Apache*::OK and MODPERL env var.
#
# Revision 1.6  2006/06/04 16:58:59  joshr
# added Log CVS thingy
#
