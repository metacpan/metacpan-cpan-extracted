#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

package WebDyne::Request::PSGI;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA);


#  External modules
#
use File::Spec::Unix;
use HTTP::Status qw(status_message RC_OK RC_NOT_FOUND RC_FOUND);
use URI;
use Data::Dumper;
$Data::Dumper::Indent=1;


#  WebDyne modules
#
use WebDyne::Request::PSGI::Constant;
use WebDyne::Util;



#  Inheritance
#
use WebDyne::Request::Fake;
@ISA=qw(WebDyne::Request::Fake);


#  Version information
#
$VERSION='2.017';


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
    @_ ? $hr->{'Content-Type'}=shift() : $hr->{'Content-Type'};

}


sub custom_response {

    my ($r, $status)=(shift(), shift());
    while ($r->prev) {$r=$r->prev}
    debug("in custom response, status $status");
    @_ ? $r->{'custom_response'}{$status}=shift() : $r->{'custom_response'}{$status};

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
        my @http_header=grep {/^HTTP_/} keys %ENV;
        my %http_header=map  {$_ => $ENV{$_}} @http_header;
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


sub dir_config {

    my ($r, $key)=@_;

    my $constant_hr=$WEBDYNE_PSGI_DIR_CONFIG;

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


sub location {

    #  Equiv to Apache::RequestUtil->location;
    #
    my $location;
    my $constant_hr=$WEBDYNE_PSGI_DIR_CONFIG;
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
            last if exists($constant_hr->{$location}) || exists($constant_server_hr->{$location});
            $location.=File::Spec::Unix->rootdir();
            last if exists($constant_hr->{$location}) || exists($constant_server_hr->{$location});
            pop @location;
        }
    }
    else {
        
        #  Actually mod_perl spec says location blank if not positively given - don't default to '/'
        #
        #$location=File::Spec::Unix->rootdir();
    }
    return $location;

}


sub log_error {

    shift(); warn(@_) if $WEBDYNE_PSGI_WARN_ON_ERROR;

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child;
    if ($fn!~/\.psp$/) {
    #if ($fn=~/\.html$/) {


        #  Static file
        #
        require WebDyne::Request::PSGI::Static;
        $r_child=WebDyne::Request::PSGI::Static->new(filename => $fn, prev => $r) ||
            return err();

    }
    else {


        #  Subrequest
        #
        $r_child=ref($r)->new(filename => $fn, prev => $r) || return err();

    }

    #  Return child
    #
    return $r_child;

}


sub lookup_uri {

    my ($r, $uri)=@_;
    ref($r)->new(uri => $uri, prev => $r) || return err();

}


sub new {


    #  New PSGI request
    #
    my ($class, %r)=@_;
    debug("$class, r: %s", Dumper(\%r));
    
    
    #  Try to figure out filename user wants
    #
    unless ($r{'filename'}) {
    
    
        #  Not supplied - need to work out
        #
        debug('filename not supplied, determining from request');


        #  Iterate through options. If *not* supplied by SCRIPT_FILENAME keep going.
        #
        my $fn;
        unless (($fn=$ENV{'SCRIPT_FILENAME'}) && !$r{'uri'}) {
        
        
            #  Need to calc from document root in PSGI environment
            #
            debug('not supplied in SCRIPT_FILENAME or r{uri}. calculating');
            if (my $dn=($r{'document_root'} || $Dir_config_env{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT)) {
            
                #  Get from URI and location
                #
                my $uri=$r{'uri'} || $ENV{'REQUEST_URI'};
                debug("uri: $uri");
                if (my $location=$class->location()) {
                    debug("location: $location");
                    $uri=~s/^\Q$location\E//;
                    debug("uri now: $uri");
                }
                my $uri_or=URI->new($uri);
                #$fn=File::Spec->catfile($dn, $uri_or->path());
                $fn=File::Spec->catfile($dn, split m{/+}, $uri_or->path());
                debug("fn: $fn from dn: $dn, uri: $uri");
                
                #  If PSP file spec'd on command line get rid of trailing /
                #$fn=~s/\.psp\/$/.psp/;
            }
            
            
            #  IIS/FastCGI, not tested recently unsure if works
            #
            elsif ($fn=$ENV{'PATH_TRANSLATED'}) {

                #  Feel free to let me know a better way under IIS/FastCGI ..
                my $script_fn=(File::Spec::Unix->splitpath($ENV{'SCRIPT_NAME'}))[2];
                $fn=~s/\Q$script_fn\E.*/$script_fn/;
                debug("fn: $fn derived from PATH_TRANSLATED script_fn: $script_fn");
            }
            
            
            #  Need to add default psp file ?
            #
            #if ($fn=~/\/$/) {
            unless ($fn=~/\.psp$/) {
            
                #  Append default doc to path, which appears at moment to be a directory ?
                #
                my $document_default=$r{'document_default'} || $Dir_config_env{'DOCUMENT_DEFAULT'} || $DOCUMENT_DEFAULT;
                debug("appending document default $document_default to fn:$fn");
                
                #  If absolute path just use it
                #
                if (File::Spec->file_name_is_absolute($document_default)) {
                
                    #  Yep - absolute path
                    #
                    $fn=$document_default
                }
                else {
                
                    #  Otherwise append to existing path
                    #
                    $fn=File::Spec->catfile($fn, split m{/+}, $document_default); #/
                }
            }
        }

        #  Final sanity check
        #
        debug("final fn: $fn");
        $r{'filename'}=$fn || do {
            #my $env=join("\n", map {"$_=$ENV{$_}"} keys %ENV);
            return err("unable to determine filename for request from environment:%s, Dir_config_env: %s", Dumper(\%ENV, \%Dir_config_env))
        };
        
    }
    
    
    #  Finished, pass back
    #
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
        debug('file is %s', $r->{'filename'});
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
    #if (my $message_ar=$r->custom_response($status)) {
    if (my $message=$r->custom_response($status)) {

        #  We have a custom response - send it
        #
        #$r->print(@{$message_ar});
        $r->print($message);

    }
    else {

        #  Create an generic error message
        #
        $r->print(
            $r->err_html(
                $status,
                status_message($status)
            ));
    }
}


sub err_html {

    #  Very basic HTML error messages for file not found and similar
    #
    my ($r, $status, $message)=@_;
    require WebDyne::HTML::Tiny;
    my $html_or=WebDyne::HTML::Tiny->new() ||
        return err();
    my $error;
    my @message=(
        $html_or->start_html($error=sprintf("%s Error $status", __PACKAGE__)),
        $html_or->h1($error),
        $html_or->hr(),
        $html_or->em(status_message($status) || 'Unknown Error'), $html_or->br(), $html_or->br(),
        $html_or->pre(
            sprintf("The requested URI '%s' generated error:\n\n$message", $r->uri)
        ),
        $html_or->end_html()
    );
    return join(undef, @message);

}


sub send_http_header {

    my $r=shift();
    return unless $r->{'header'};
    while (my ($h, $v)=each %{$r->headers_out()}) {
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
