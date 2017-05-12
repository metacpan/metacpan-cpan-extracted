package YAWF::Apache;

use strict;
use warnings;

use Apache2::Connection;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Log;

use YAWF::Request;

sub handler {
    my $r = shift;

#	     Domain        => $r->hostname,
#        URI           => $r->uri,
#        Args_GET      => $r->args,
#        Method        => $r->method,
#        Headers       => $r->headers_in,
#        DocumentRoot  => $r->document_root,
#        Error         => sub { Apache2::RequestUtil::request->log_error(join(',',@_)); },

    my $request = YAWF::Request->new(
        domain       => $r->hostname,
        uri          => $r->uri,
        args_GET     => $r->args,
        method       => $r->method,
        headers      => $r->headers_in,
        remote_ip    => $r->connection->remote_ip,
        documentroot => $r->document_root,
        error        => sub {
            Apache2::RequestUtil->request->log_error(@_);
        },
        send_status => sub {
            Apache2::RequestUtil->request->status(shift);
        },
        send_header => sub {
            if ( $_[0] eq 'Content-type' ) {
                Apache2::RequestUtil->request->content_type( $_[1] );
            }
            else {
                Apache2::RequestUtil->request->headers_out->add(
                    $_[0] => $_[1] );

                # Apache2::RequestUtil->request->err_headers_out->add(
                # $_[0] => $_[1] );
            }
        },
        send_body => sub { Apache2::RequestUtil->request->print(@_); },
        flush     => sub { $r->rflush; },

    );
    if ( !defined($request) ) {
        $r->log_error('CRITICAL: YAWF::Request object not defined!');
        return 500;
    }
    elsif ( !$request->run ) {
        $r->log_error('Error: YAWF::Request run returned zero.');
        return 500;
    }
    else {
        return 0;

        #                    return $request->yawf->reply->status;
    }
}

1;
