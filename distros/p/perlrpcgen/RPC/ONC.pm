# $Id: ONC.pm,v 1.1 1997/05/01 22:08:10 jake Exp $

#   Copyright 1997 Jake Donham <jake@organic.com>

#   You may distribute under the terms of either the GNU General
#   Public License or the Artistic License, as specified in the README
#   file.

package RPC::ONC;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    ($pack,$file,$line) = caller;
	    die "Your vendor has not defined RPC::ONC macro $constname, used at $file line $line.
";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap RPC::ONC;

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__

=head1 NAME

RPC::ONC - Perl interface to ONC RPC

=head1 SYNOPSIS

    use RPC::ONC;

    # Create a client of the NFS service.

    $clnt = &RPC::ONC::Client::clnt_create('foo.bar.com',
				      NFS_PROGRAM, NFS_VERSION,
				      'netpath');

    # Set the timeout to 3 seconds.
    $clnt->clnt_control(CLSET_TIMEOUT, pack('LL', 3, 0));

=head1 DESCRIPTION

The RPC::ONC module provides access to some of the ONC RPC routines
for making and receiving remote procedure calls, as well as functions
to access members of RPC-related structures. It's intended to be used
with 'perlrpcgen', which generates Perl XS stubs for RPC clients and
servers.

Most of these routines work the same as their C equivalents and are
thus not described in detail.

=head1 CAVEAT

Not all of the ONC RPC calls are provided in this alpha version--I've
been filling them in more or less as needed. Let me know if there's
one you really need.

=head1 GLOBALS

=over 4

=item RPC::ONC::errno

Number of the error that just occurred.

=item RPC::ONC::errstr

Message corresponding to error that just occurred.

=back

=head1 CLASSES

=head2 RPC::ONC::Client

RPC::ONC::Client wraps CLIENT *.

=over 4

=item clnt_create(host, prognum, versnum, nettype)

If the call fails, clnt_create will set RPC::ONC::errno and
RPC::ONC::errstr and croak.

=item clnt_control(clnt, req, info)

The info argument should be packed as an appropriate structure for the
operation.

=item clnt_destroy(clnt)

=item set_cl_auth(clnt, auth)

Takes an RPC::ONC::Client object and an RPC::ONC::Auth object and
assigns the cl_auth field of the first to the second.

=back

=head2 RPC::ONC::Auth

RPC::ONC::Auth wraps AUTH *.

=over 4

=item authnone_create

=item authsys_create_default

=item auth_destroy(auth)

=back

=head2 RPC::ONC::svc_req

RPC::ONC::svc_req wraps struct svc_req *.

=over 4

=item rq_prog(svc_req)

Returns the rq_prog field.

=item rq_vers(svc_req)

Returns the rq_vers field.

=item rq_proc(svc_req)

Returns the rq_proc field.

=item rq_cred(svc_req)

Returns the rq_cred field as an RPC::ONC::opaque_auth object.

=item authsys_parms(svc_req)

Returns the rq_clntcred field as an RPC::ONC::authsys_parms
object. Will croak if the credentials are not the right flavor.

=item authdes_cred(svc_req)

Returns the rq_clntcred field as an RPC::ONC::authdes_cred
object. Will croak if the credentials are not the right flavor.

=back

=head2 RPC::ONC::opaque_auth

=over 4

=item oa_flavor(opaque_auth)

Returns the oa_flavor field.

=back

=head2 RPC::ONC::authsys_parms

=over 4

=item aup_time(authsys_parms)

Returns the aup_time field.

=item aup_machname(authsys_parms)

Returns the aup_machname field.

=item aup_uid(authsys_parms)

Returns the aup_uid field.

=item aup_gid(authsys_parms)

Returns the aup_gid field.

=item aup_gids(authsys_parms)

Returns the aup_gids field as an array.

=back

=head2 RPC::ONC::Svcxprt

RPC::ONC::Svcxprt wraps struct svcxprt *.

=over 4

=item svc_getcaller(transp)

Returns a sockaddr_in * which you can unpack to get the IP address of
the caller.

=back

=head1 SEE ALSO

L<perlrpcgen(1)>

=head1 AUTHOR

Jake Donham <jake@organic.com>

=head1 THANKS

Thanks to Organic Online <http://www.organic.com/> for letting me hack
at work.

=cut
