#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use File::Spec::Unix;
use HTTP::Status qw(status_message RC_OK RC_NOT_FOUND RC_FOUND);
use URI;
use Data::Dumper;
use Plack::Request;
$Data::Dumper::Indent=1;


#  WebDyne modules
#
use WebDyne::Request::PSGI::Constant;
use WebDyne::Util;
use WebDyne::Constant;


#  Inheritance
#
use WebDyne::Request::Fake;
@ISA=qw(Plack::Request WebDyne::Request::Fake);


#  Version information
#
$VERSION='2.070';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Save local copy of environment for ref by Dir_config handler. ENV is reset for each request,
#  so must use a snapshot for simulating r->dir_config
#
my %Dir_config_env=%{$WEBDYNE_PSGI_ENV_SET}, (map { $_=>$ENV{$_} } (
    qw(DOCUMENT_DEFAULT DOCUMENT_ROOT),
    @{$WEBDYNE_PSGI_ENV_KEEP},
    grep {/WebDyne/i} keys %ENV
));


#  All done. Positive return
#
1;


#==================================================================================================


sub new {


    #  New PSGI request
    #
    my ($class, %r)=@_;
    debug("$class, r: %s, calller:%s", Dumper(\%r, [caller(0)]));
    
    
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
            if (my $dn=($r{'document_root'} || $ENV{'DOCUMENT_ROOT'} || $Dir_config_env{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT)) {
            
                #  Get from URI and location
                #
                my $uri=$r{'uri'} || $ENV{'PATH_INFO'} || $ENV{'SCRIPT_NAME'};
                debug("uri: $uri");
                $fn=File::Spec->catfile($dn, split m{/+}, $uri); #/
                debug("fn: $fn from dn: $dn, uri: $uri");
                
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
            #unless ($fn=~/\.psp$/) { # fastest
            unless ($fn=~WEBDYNE_PSP_EXT_RE) { # fastest

                #  Is it a directory that exists ? Only append default document if that is the case, else let the api code
                #  handle it
                #
                if  ((-d $fn) || !$fn) {
                    
            
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
                else {
                    
                    #  Not .psp file, do not want
                    #
                    $fn=undef;
                }
            }
        }


        #  Final sanity check
        #
        debug("final fn: $fn");
        $r{'filename'}=$fn; 
        
    }
    
    
    #  Finished, pass back
    #
    return bless \%r, $class;

}


sub new_from_filename {

    #  Test method, not used
    #
    my ($class, $fn, $select_fh)=@_;
    my %r=(filename=>$fn, select=>$select_fh, env=>\%ENV);
    return bless(\%r, $class);
    
}


sub content_type {

    my $r=shift();
    my $hr=$r->headers_out();
    #@_ ? $r->headers_out()->{'Content-Type'}=shift() : $r->SUPER::content_type();
    return @_ ? $r->headers_out()->{'Content-Type'}=shift() : ($r->headers_out()->{'Content-Type'} || $ENV{'CONTENT_TYPE'});

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

    (shift()->method() eq 'HEAD') ? 1 : 0 

}


sub headers_in {
    my $r=shift();
    return $r->headers();
}


sub headers_out {

    my $r=shift();
    return WebDyne::Request::Fake::headers($r, 'headers_out', @_);

}    


sub location {


    #  Equiv to Apache::RequestUtil->location;
    #
    my $r=shift();
    debug("r: $r, caller: %s", Dumper([caller(0)]));
    my $location;
    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    my $constant_server_hr;
    if (my $server=$Dir_config_env{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
        $constant_server_hr=$constant_hr->{$server} if exists($constant_hr->{$server})
    }
    if ($Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'}) {

        #  APPL_MD_PATH is IIS virtual dir. If that or a fixed location set use it.
        #
        $location=$Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'};
    }
    elsif (my $uri_path=join('', grep {$_} @ENV{qw(SCRIPT_NAME PATH_INFO)})) {
        
        #  Strip file name
        #
        $uri_path=~s{[^/]+\Q@{[WEBDYNE_PSP_EXT]}\E$}{}x; #\
        debug("uri_path: $uri_path");
        my @location=('/', grep {$_} File::Spec::Unix->splitdir($uri_path));
        
        #  Start iterating through directories
        #
        while ($location=File::Spec::Unix->catdir(@location)) {
            debug("location: $location");
            last if exists($constant_hr->{$location}) || exists($constant_server_hr->{$location});
            $location.='/' unless ($location eq '/');
            last if exists($constant_hr->{$location}) || exists($constant_server_hr->{$location});
            pop @location;
        }
    }
    else {
        
        #  Actually mod_perl spec says location blank if not positively given - don't default to '/'
        #
        #$location=File::Spec::Unix->rootdir();
    }
    
    #  
    #
    return $location;

}


sub log_error {

    my $r=shift();
    warn(@_) if $WEBDYNE_PSGI_WARN_ON_ERROR;

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child;
    if ($fn!~WEBDYNE_PSP_EXT_RE) { # fastest


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


sub redirect {

    my ($r, $location)=@_;
    $r->status(HTTP_FOUND);
    $r->headers_out('Location' => $location);
    return HTTP_FOUND;

}


sub run {

    my ($r, $self)=@_;
    debug("self: $self, r:$r");
    if (-f $r->{'filename'}) {
        debug('file is %s', $r->{'filename'});
        return ref($self)->handler($r);
    }
    else {
        debug("file not found !");
        $r->status(RC_NOT_FOUND);
        $r->send_error_message;
        return HTTP_NOT_FOUND;
    }

}


sub send_error_response {

    my $r=shift();
    my $status=$r->status();
    debug("in send error response, status $status");
    if (my $message=$r->custom_response($status)) {

        #  We have a custom response - send it
        #
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
    my $html_or=WebDyne::HTML::Tiny->new( mode=>$WEBDYNE_HTML_TINY_MODE, r=>$r ) ||
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
    return join('', @message);

}


sub send_http_header {

    #  Stub
    
}

