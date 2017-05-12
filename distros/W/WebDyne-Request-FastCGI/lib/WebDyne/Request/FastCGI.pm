#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>. All rights 
#  reserved.
#
#  This file is part of WebDyne::Request::FastCGI
#
#  WebDyne is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
package WebDyne::Request::FastCGI;


#  Compiler Pragma
#
use strict	qw(vars);
use vars	qw($VERSION @ISA);


#  External modules
#
use File::Spec::Unix;
use HTTP::Status qw(status_message RC_OK RC_NOT_FOUND RC_FOUND);
use URI;


#  WebDyne modules
#
use WebDyne::Request::FastCGI::Constant;
use WebDyne::Base;


#  Inheritance
#
use WebDyne::Request::Fake;
@ISA=qw(WebDyne::Request::Fake);


#  Version information
#
$VERSION='1.021';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Save local copy of environment for ref by Dir_config handler. ENV is reset for each request,
#  so must use a snapshot for simulating r->dir_config
#
my %Dir_config_env=%ENV;


#  All done. Positive return
#
1;


#==================================================================================================


sub content_type {

    my $r=shift();
    my $hr=$r->headers_out();
    @_ ? $hr->{'Content-Type'}=shift() :  $hr->{'Content-Type'};

}


sub custom_response {

    my ($r,$status)=(shift(), shift());
    while ($r->prev) { $r=$r->prev }
    debug("in custom response, status $status");
    @_ ? $r->{'custom_response'}{$status}=\@_ : $r->{'custom_response'}{$status};

}


sub filename {

    my $r=shift();
    @_ ? $r->{'filename'}=shift() : $r->{'filename'};

}


sub header_only {

    ($ENV{'REQUEST_METHOD'} eq 'HEAD') ? 1 : 0;

}


sub headers_in {

    my ($r, $header)=@_;
    my $hr=$r->{'headers_in'} ||= do {
	my @http_header=grep { /^HTTP_/ } keys %ENV;
	my %http_header=map { $_=>$ENV{$_} } @http_header;
	foreach my $k (keys %http_header) {
	    my $v=delete $http_header{$k};
	    $k=~s/^HTTP_//;
	    $k=~s/_/-/g;
	    $http_header{lc($k)}=$v;
	}
	\%http_header;
    };
    $header ? $hr->{lc($header)} : $hr;

}


sub dir_config0 {

    my ($r, $key)=@_;

    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    my @location=grep {$_} 
        File::Spec::Unix->rootdir(), File::Spec::Unix->splitdir($r->location());
    debug("in dir_config looking for key $key");
    
    
    while (my $location=File::Spec::Unix->catdir(@location)) {
        debug("location $location");
        if (exists $constant_hr->{$location}) {
            return $constant_hr->{$location}{$key} 
                #|| $constant_hr->{undef()}{$key} || $Dir_config_env{$key}
        }
        elsif (exists $constant_hr->{$location.=File::Spec->rootdir()}) {
            return $constant_hr->{$location}{$key} 
        }
        pop @location;
    }


    debug("explicit location key $key not found, returning top level");
    return $constant_hr->{''}{$key} || $Dir_config_env{$key}

}

sub dir_config {

    my ($r, $key)=@_;

    my $constant_hr=$WEBDYNE_DIR_CONFIG;

    my $constant_server_hr;
    if (my $server=$Dir_config_env{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
	$constant_server_hr=$constant_hr->{$server} if exists($constant_hr->{$server})
    }

    my $location=$r->location();
    debug("in dir_config looking for key $key at location $location");

    if (exists $constant_server_hr->{$location}) {
	return $constant_server_hr->{$location}{$key} 
    }    
    elsif (exists $constant_hr->{$location}) {
	return $constant_hr->{$location}{$key} 
	#|| $constant_hr->{undef()}{$key} || $Dir_config_env{$key}
    }
    else {
	debug("explicit location key $key not found, returning top level");
	return $constant_hr->{''}{$key} || $Dir_config_env{$key}
    }

}


sub location0 {

    if ($ENV{'SCRIPT_NAME'}) {
        return (File::Spec::Unix->splitpath($ENV{'SCRIPT_NAME'}))[1];
    }
    else {
        #  APPL_MD_PATH is IIS virtual dir
        #
        return $Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'} || '/';
    }

}


sub location {
    
    #  Equiv to Apache::RequestUtil->location;
    #
    my $location;
    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    my $constant_server_hr;
    if (my $server=$Dir_config_env{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
	$constant_server_hr=$constant_hr->{$server} if exists($constant_hr->{$server})
    }
    if ($Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'}) {
        #  APPL_MD_PATH is IIS virtual dir
        #
	$location=$Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'};
    }
    elsif ($ENV{'SCRIPT_NAME'}) {
        my $path=(File::Spec::Unix->splitpath($ENV{'SCRIPT_NAME'}))[1];
        my @location=grep {$_} 
	    File::Spec::Unix->rootdir(), File::Spec::Unix->splitdir($path);
	while ($location=File::Spec::Unix->catdir(@location)) {
	    debug("location $location");
	    last if exists ($constant_hr->{$location}) || exists ($constant_server_hr->{$location});
	    $location.=File::Spec::Unix->rootdir();
	    last if exists ($constant_hr->{$location}) || exists ($constant_server_hr->{$location});
	    pop @location;
	}
    }
    else {
	$location = File::Spec::Unix->rootdir();
    }
    return $location;

}


sub log_error {

    shift(); warn(@_) if $WEBDYNE_FASTCGI_WARN_ON_ERROR;

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child;
    if ($fn=~/\.html$/) {


	#  Static file
	#
	require WebDyne::Request::FastCGI::Static;
	$r_child=WebDyne::Request::FastCGI::Static->new( filename=>$fn, prev=>$r ) ||
	    return err();

    }
    else {


	#  Subrequest
	#
	$r_child=ref($r)->new( filename=> $fn, prev=>$r ) || return err();

    }

    #  Return child
    #
    return $r_child;

}


sub lookup_uri {

    my ($r, $uri)=@_;
    ref($r)->new( uri=>$uri, prev=>$r ) || return err();

}


sub new {

    my ($class, %r)=@_;
    unless ($r{'filename'}) {

	my $fn;
	unless (($fn=$ENV{'SCRIPT_FILENAME'}) &&  !$r{'uri'}) {

	    if (my $dn=$ENV{'DOCUMENT_ROOT'}) {
	        my $uri=$r{'uri'} || $ENV{'REQUEST_URI'};
		if (my $location=$class->location()) {
		    $uri=~s/^\Q$location\E//;
		}
		my $uri_or=URI->new($uri);
		$fn=File::Spec->catfile($dn, $uri_or->path());
	    }

	    elsif ($fn=$ENV{'PATH_TRANSLATED'}) {
		#  Feel free to let me know a better way under IIS/FastCGI ..
		my $script_fn=(File::Spec::Unix->splitpath($ENV{'SCRIPT_NAME'}))[2];
		$fn=~s/\Q$script_fn\E.*/$script_fn/;
	    }

	}

	$r{'filename'}=$fn || do {
	    my $env=join("\n", map {"$_=$ENV{$_}"} keys %ENV);
	    return err("unable to determine filename for request from environment: $env")
	};
	
    }

    bless \%r, $class;

}


sub redirect {

    my ($r, $location)=@_;
    CORE::print sprintf("Status: %s\r\n", RC_FOUND);
    CORE::print "Location: $location\r\n";
    $r->send_http_header;
    return RC_FOUND;

}


sub run {

    my ($r, $self)=@_;
    if (-f $r->{'filename'}) {
	return ref($self)->handler($r);
    }
    else {
	debug("file not found !");
	$r->status(RC_NOT_FOUND);
	$r->send_error_message;
	RC_NOT_FOUND;
    }

}


sub set_handlers {

    #  No-op

}


sub send_error_response {

    my $r=shift();
    my $status=$r->status();
    CORE::print "Status: $status\r\n";
    $r->send_http_header;
    debug("in send error response, status $status");
    if (my $message_ar=$r->custom_response($status)) {

	#  We have a custom response - send it
	#
	$r->print(@{$message_ar});

    }
    else {

	#  Create an generic error message
	#
	$r->print($r->err_html(
	    $status,
	    status_message($status)
	   ));
    }
}


sub err_html {

    my ($r,$status,$message)=@_;
    require CGI;
    my $error;
    my @message=(
	CGI->start_html($error=sprintf("%s Error $status", __PACKAGE__)),
	CGI->h1($error),
	CGI->hr(),
	CGI->em(status_message($status)), CGI->br(), CGI->br(),
	CGI->pre(
	    sprintf("The requested URI '%s' generated error:\n\n$message", $r->uri)
	),
	CGI->end_html()
       );
    return join(undef, @message);

}


sub send_http_header {

    my $r=shift();
    while(my ($h,$v)=each %{$r->headers_out()}) {
	CORE::print "$h: $v\r\n";
    }
    CORE::print "\r\n";

}


sub uri {

    my $r=shift();
    @_ ? $r->{'uri'}=shift() : $r->{'uri'} || $ENV{'REQUEST_URI'}

}


sub protocol {
    
    $ENV{'SERVER_PROTOCOL'}
}


sub env {

    return \%Dir_config_env;
    
}

__END__

=head1 Name

WebDyne::Request::FastCGI - FastCGI responder that handles requests for WebDyne pages.

=head1 Description

WebDyne::Request::FastCGI is a FastCGI responder that handles requests for WebDyne pages made to FastCGI based server
such as Lighttd, LiteSpeed etc.

=head1 Documentation

Information on configuration and usage is availeble from the WebDyne site, http://webdyne.org/ - or from a snapshot of
current documentation in PDF format available in the WebDyne source /doc directory.

=head1 Copyright and License

WebDyne::Request::FastCGI is Copyright (C) 2006-2010 Andrew Speer.  WebDyne::Request::FastCGI is dual licensed. It is
released as free software released under the Gnu Public License (GPL), but is also available for commercial use under
a proprietary license - please contact the author for further information.

WebDyne::Request::FastCGI is written in Perl and uses modules from CPAN (the Comprehensive Perl Archive Network).
CPAN modules are Copyright (C) the owner/author, and are available in source from CPAN directly. All CPAN modules used
are covered by the Perl Artistic License.

=head1 Author

Andrew Speer, andrew@webdyne.org

=head1 Bugs

Please report any bugs or feature requests to "bug-webdyne-request-fastcgi at rt.cpan.org", or via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebDyne-Request-FastCGI

