
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


package WebDyne::Request::Fake;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD %Package);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Cwd qw(fastcwd);
use Data::Dumper;
use HTTP::Status qw(status_message HTTP_OK HTTP_NOT_FOUND HTTP_FOUND);
use HTTP::Headers::Fast;
use HTTP::Negotiate qw(choose);
use HTTP::AcceptLanguage;
use HTTP::Headers::Util qw(split_header_words);
use CGI::Simple::Cookie;
use File::stat;
use File::Spec;
use File::Spec::Unix;
use WebDyne::Util;
use WebDyne::Constant;
use WebDyne::Request::Common qw(handler_methods_all handler_methods_check);
use URI;


#  Version information
#
$VERSION='3.009';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Run init code for utility accessors unless already done. Picked method() as arbitrary test
#
&init() unless defined(&method);


#  All done. Positive return
#
1;


#==================================================================================================


sub init {


    #  Do ENV filtering here
    #
    local %ENV=(
        (map { $_=>$ENV{$_}  } (
            grep { defined($ENV{$_}) } (qw(
                DOCUMENT_DEFAULT
                DOCUMENT_ROOT
                REQUEST_METHOD
                REQUEST_URI
                PATH_INFO
                SCRIPT_NAME
                QUERY_STRING
                SERVER_PROTOCOL
                SERVER_NAME
                SERVER_PORT
                REMOTE_ADDR
                REMOTE_PORT
                REMOTE_USER
                AUTH_TYPE
                HTTPS 
                APPL_MD_PATH
            ),
            (grep {/^WEBDYNE/i} keys %ENV), # Note not WEBDYNE_, just /WEBDYNE/i to allow for DirConfig type entries such as WebDyneHandler
            (grep {/^HTTP_/i} keys %ENV),
            (grep {/^CONTENT_/i} keys %ENV)
        )))
    );


    #  Setup pass through methods
    #
    my %method=(
        accept_encoding     => sub { shift()->headers_in('accept-encoding') },
        accept_language     => sub { shift()->headers_in('accept-language') },
        accept              => sub { shift()->headers_in('accept') },
        args                => sub { shift()->env->{'QUERY_STRING'} },
        as_string           => undef,
        authority           => sub { shift()->uri->authority },
        authorization       => sub { shift()->headers_in('authorization') },
        auth_type           => sub { shift()->{'env'}->{'AUTH_TYPE'} },
        base                => 'base_url',
        #base_url            => sub { URI->new($_[0]->host . $_[0]->script_name()) },
        base_url            => sub { my $uri_or=shift()->uri->canonical->clone; $uri_or->path('/'), $uri_or->query(undef); $uri_or },
        body_handle         => sub { shift->{'input'} },
        body                => undef,
        cache_control       => sub { shift()->headers_in('cache-control') },
        charset             => sub { my $content_type=shift()->content_type || return; (my @split=split_header_words($content_type)) || return; my %param=@{$split[0]}; return lc($param{'charset'}) },
        cleanup_register    => undef,
        client_address      => sub { shift()->env->{'REMOTE_ADDR'} },
        content             => 'body',
        content_encoding    => sub { shift()->headers_in('content-encoding') },
        content_length      => undef,
        content_type        => undef,
        cookie              => 'cookies',
        cookies             => undef,
        custom_response     => undef,
        cwd                 => undef,
        dir_config          => undef,
        document_root       => undef,
        env                 => sub { \%ENV },
        etag                => sub { shift()->headers_out('etag', @_) },
        filename            => undef,
        finalize            => undef,
        finfo               => undef,
        form_parameters     => undef,
        forwarded_for       => sub { shift()->headers_in('x-forwarded-for') },
        fragment            => sub { shift()->uri->fragment },
        handler             => undef,
        header              => 'headers_in',
        headers             => 'headers_in',
        header_only         => undef,
        headers_in          => undef,
        headers_out         => undef,
        hostname            => sub { shift()->env->{'SERVER_NAME'} }, # Prob should be local host name
        #host                => sub { shift()->uri->host if $_[0]->uri->authority },
        host                => sub { shift()->headers_in('host') },
        https               => sub { shift()->env->{'HTTPS'} },
        http_version        => 'protocol',
        id                  => undef,
        if_modified_since   => sub { shift()->headers_in('if-modified-since') },
        if_none_match       => sub { shift()->headers_in('if-none-match') },
        input               => sub { shift()->{'input'} },
        is_ajax             => sub { (shift()->headers_in('x-requested-with') eq 'XMLHttpRequest') },
        is_main             => undef,
        location            => undef,
        log_error           => undef,
        lookup_file         => undef,
        lookup_uri          => undef,
        main                => undef,
        media_type             => sub { my $content_type=shift()->content_type || return; (my @split=split_header_words($content_type)) || return; return lc($split[0][0]) },
        method              => sub { shift->env->{'REQUEST_METHOD'} || 'GET' },
        mtime               => undef,
        multipart_parameters=> undef,
        next                => undef,
        notes               => undef,
        origin              => sub { shift()->headers_in('origin') },
        output_filters      => undef,
        path_info           => sub { shift->env->{'PATH_INFO'} },
        path_parameters     => undef,
        path                => 'path_info',
        pool                => undef,
        preferred_charset   => undef,
        preferred_encoding  => undef,
        preferred_language  => undef,
        preferred_media_type=> undef,
        prev                => undef,
        print               => undef,
        protocol            => sub { shift()->env->{'SERVER_PROTOCOL'} || 'HTTP/1.1' },
        query_parameters    => undef,
        query_string        => 'args',
        redirect            => undef,
        referer             => sub { shift()->headers_in('referer') },
        register_cleanup    => 'cleanup_register',
        remote_address      => 'client_address',
        remote_host         => 'client_address',
        remote_port         => sub { shift()->env->{'REMOTE_PORT'} },
        remote_user         => 'user',
        request_time        => undef,
        route               => undef,
        run                 => undef,
        scheme              => undef,
        script_name         => sub { shift()->env->{'SCRIPT_NAME'} },
        secure              => sub { (shift()->https eq 'on') },
        sendfile            => undef,
        send_http_header    => undef,
        server_name         => sub { shift()->env->{'SERVER_NAME'} },
        server_port         => sub { shift()->env->{'SERVER_PORT'} },
        session_id          => undef,
        session             => undef,
        set_handlers        => undef,
        status_line         => undef,
        status              => undef,
        unparsed_uri        => sub { shift()->filename() },
        uploads             => undef,
        #uri                 => sub { $_[0]->{'uri'} ||= URI->new($_[0]->filename()) },
        uri                 => undef,
        url                 => 'uri',
        user_agent          => sub { shift()->headers_in('user-agent') },
        user                => sub { shift()->env->{'REMOTE_USER'} },
        write               => undef,
        err_html            => undef,
        DESTROY             => undef
            
    );


    #   Not really valid here but setup anyway
    #
    foreach my $handler (qw(req res)) {
        *{$handler}=sub { return shift() };
    }


    #  Now setup abstraction methods. Slightly different than PSGI, PAGI, Apache so just do it here
    #
    my %method_check;
    while (my ($method, $dispatch)=each %method) {
        $method_check{$method}++;
        if (defined(*{sprintf('%s::%s', __PACKAGE__, $method)}{'CODE'})) {
            #  Do nothing, defined here
            #
            warn("duplicate method for $method") if $dispatch;
            debug("skip $method, defined in this package");
            
        }
        elsif (!defined($dispatch)) {
            #  Do nothing, will fall through
            #
            debug("skip $method, will inherit from Fake");
        }
        elsif (ref($dispatch) eq 'CODE') {
            #  Turn into method
            #
            debug("setting method: $method to code ref: $dispatch");
            *{$method}=$dispatch;
        }
        else {
            #  Existing method
            #
            debug("setting method: $method to dispatch: $dispatch");
            *{$method}=sub { shift()->$dispatch(@_) };
        }
    }
    
    
    #  Done, do runtime check and return, will warn if we have missed anything
    #
    return handler_methods_check(__PACKAGE__, \%method_check);
    
}


sub uri {

    $_[0]->{'uri'} ||= URI->new($_[0]->filename()) 
    
}


sub body {

    my $r=shift();
    return $r->{'body'} ||= do {
        if (my $fh=$r->{'input'}) {
            seek($fh,0,0);
            local $/;
            <$fh>
        }
    };
    
}


sub cookies {

    my $r=shift();
    my %cookies=CGI::Simple::Cookie->parse(
        $r->headers_in('cookie'));
    if (@_) {
        $r->headers_out('set-cookie', CGI::Simple::Cookie->new(@_)->as_string());
    }
    return \%cookies;
}


sub dir_config {

    
    #  Newer more comprehensive dir_config that pulls from WEBDYNE_CONF
    #
    my ($r, $key)=@_;
    debug("r: $r, caller: %s", Dumper([caller(0)]));
    

    #  Get hash ref from config file
    #
    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    debug('using constant_hr: %s', Dumper($constant_hr));


    #  Optionally load WEBDYNE_DIR_CONFIG from current dir
    #
    if ($WEBDYNE_DIR_CONFIG_CWD_LOAD) {
    

        #  Yes, wanted. Get cwd, skip if already processed
        #
        my $cwd_dn=$r->cwd();
        my $dir_config_hr=($Package{'_dir_config'}{$cwd_dn} ||= do {
            my $webdyne_conf_fn=File::Spec->catfile($cwd_dn, sprintf('.%s', $WEBDYNE_CONF_FN));
            debug("fn: $webdyne_conf_fn");
            if (-f $webdyne_conf_fn) {
                debug("found: $webdyne_conf_fn, reading");
                my $webdyne_conf_hr=do($webdyne_conf_fn) ||
                    warn "unable to read document root dir_config constant file, $!";
                debug('webdyne_conf_hr: %s', Dumper($webdyne_conf_hr));
                $webdyne_conf_hr->{'WebDyne::Constant'}{'WEBDYNE_DIR_CONFIG'};
            }} || {}
        );
        if (keys %{$dir_config_hr}) {
            $constant_hr={
                %{$constant_hr},
                %{$dir_config_hr}
            } 
        }
    }    


    #  OK - heirarchy is this:
    #
    #  If WEBDYNE_PSGI_DIR_CONFIG=$hr order of return
    #
    #  $ENV{$key} # Wins everything
    #  $hr->{$servername}{$location}{$key}
    #  $hr->{$servername}{''}{$key}
    #  $hr->{$servername}{$key}
    #  $hr->{$location}{$key}
    #  $hr->{''}{$key} 
    #  $hr->{$key}
    #

    if ($key) {
    
        #  Key specified, returning just that value
        #
        #if (exists $Dir_config_env{$key}) {
        if (exists $ENV{$key}) {
        
            #  $ENV{$key} # Wins everything
            #
            #debug('found $ENV{%s}, returning %s', $key, $Dir_config_env{$key});
            debug('found $ENV{%s}, returning %s', $key, $ENV{$key});
            #return $Dir_config_env{$key};
            return $ENV{$key};
            
        }
        else {
            

            #  Get location we are operating in
            #
            my $location=$r->location();
            debug("in dir_config looking for key: $key at location: $location");
            
            
            #  Array of hashes we may need to look through
            #
            my @constant_hr=($constant_hr);


            #  Do we have $hr->{$servername}{$location} ?
            #
            if (my $server=($ENV{'WebDyneServer'} || $ENV{'HOSTNAME'} ||  $ENV{'SERVER_NAME'})) {

                #  Have $servername
                #
                debug("using server: $server");
                if (exists $constant_hr->{$server}) {
                
                    #  Add to array of hashes we have to look at
                    #
                    unshift @constant_hr, (my $constant_server_hr=$constant_hr->{$server});
                    debug("pushing $constant_server_hr onto dir_config review stack: %s", Dumper($constant_server_hr));
                    
                }
                
            }
            
            
            #  Now iterate across array, return on first match
            #
            foreach my $hr (@constant_hr) {
                my %location;
                foreach my $hr_key ($location, '') {
                    next if ($location{$location}++);
                    debug("looking at hr: $hr, hr_key: $hr_key");
                    #  Maybe $hr->{$location}{$key} or $hr->{''}{$key} ?
                    #
                    if (exists $constant_hr->{$hr_key}) {
                        debug("found hr: $hr, hr_key: $hr_key");
                        return $hr->{$hr_key}{$key} if exists($hr->{$hr_key}{$key});
                    }
                    else {
                        debug("no match on hr: $hr, hr_key: $hr_key");
                    }
                }
                #  No - $hr->{$key} is last chance
                #
                if (exists $hr->{$key}) {
                    debug("found hr: $hr, key: $key");
                    return $hr->{$key}
                }
                else {
                    debug("no match on hr: $hr, key: $key");
                }
            }
                
            #  Nothing found
            #
            debug("no key found for location: $location or any other match");
            return undef;
            
        }
                
    }
    else {

        #  Return dump of whole thing with ENV vars taking precendence at top level. Scrub mixing in ENV at moment, exposes
        #  too many non WebDyne vars if called with dir_config(). Do properly with Plack::Middleware::AddEnv or similar later
        #
        #my %dir_config=(%{$constant_hr}, %Dir_config_env);
        my %dir_config=(
            %{$constant_hr}, 
            (map { $_=>$ENV{$_} } grep {/^WEBDYNE_/i} keys %ENV), 
            (map { $_=>$ENV{$_} } grep {exists $ENV{$_} } keys %{$constant_hr})
            #(map { $_=>$ENV{$_} } @{$WEBDYNE_PSGI_ENV_KEEP},
            #%{$WEBDYNE_PSGI_ENV_SET}
        );
        return \%dir_config;
    }

}


sub filename {

    my $r=shift();
    return undef unless defined $r->{'filename'};

    #  Store cwd as takes a fair bit of processing time.
    File::Spec->rel2abs($r->{'filename'}, ($Package{'_cwd'} ||= fastcwd()));

}


sub headers_in {
    my $r=shift();
    if (@_) {
        return ($r->{'headers_in'} ||= HTTP::Headers::Fast->new())->header(@_);
    }
    else {
        return ($r->{'headers_in'} ||= HTTP::Headers::Fast->new());
    }
}


sub headers_out {
    my $r=shift();
    if (@_) {
        return ($r->{'headers_out'} ||= HTTP::Headers::Fast->new())->header(@_);
    }
    else {
        return ($r->{'headers_out'} ||= HTTP::Headers::Fast->new());
    }
}


sub is_main {

    my $r=shift();
    $r->{'main'} ? 0 : 1;

}


sub log_error {

    my $r=shift();
    warn(@_) unless !$r->{'warn'};

}



sub lookup_file {

    my ($r, $fn)=@_;
    debug("r: $r, fn: $fn");
    my $r_child;
    if ($fn!~WEBDYNE_PSP_EXT_RE) { # fastest


        #  Static file. Should migrate to this module but OK is PSGI for moment
        #
        debug('non psp file, passing to WebDyne::Request::PSGI::Static');
        require WebDyne::Request::PSGI::Static;
        $r_child=WebDyne::Request::PSGI::Static->new(filename => $fn, prev => $r, env=>$r->env()) ||
            return err();

    }
    else {


        #  Subrequest
        #
        debug('psp file, creating new request');
        $r_child=ref($r)->new(filename => $fn, prev => $r) || return err();

    }

    #  Return child
    #
    debug("returning r_child: $r_child");
    return $r_child;

}


sub lookup_uri {

    my ($r, $uri)=@_;
    my $fn=File::Spec::Unix->catfile((File::Spec->splitpath($r->filename()))[1], $uri);
    return $r->lookup_file($fn);

}


sub main {

    my $r=shift();
    #@_ ? $r->{'main'}=shift() : $r->{'main'} || $r;
    @_ ? $r->{'main'}=shift() : $r->{'main'};

}


sub new {


    #  Instantiate new fake handler
    #
    my ($class, %r)=@_;
    debug("$class, r:%s", Dumper(\%r));
    my $r=bless(\%r, $class);


    #  Now move ENV into headers
    #
    foreach my $env ((grep {/^HTTP_/} keys %ENV), qw(CONTENT_TYPE CONTENT_LENGTH)) {
        my $header=$env;
        exists $ENV{$header} || next;
        my $value=$ENV{$header};
        $header=~s/^HTTP_//;
        $header=~s/_/-/g;
        debug("setting header: $header, value: $value");
        $r->headers_in(lc($header), $value);
    }
    
    
    #  If Headers in supplied as array or hash ref convert
    #
    if (ref($r{'headers_in'}) eq 'ARRAY') {
        $r{'headers_in'}=HTTP::Headers::Fast->new(@{$r->{'headers_in'}})
    }
    elsif (ref($r{'headers_in'}) eq 'HASH') {
        $r{'headers_in'}=HTTP::Headers::Fast->new(%{$r->{'headers_in'}})
    }
    
        
    #  Done
    #
    return $r;

}


sub notes {

    my ($r, $k, $v)=@_;
    if (@_ == 3) {
        return $r->{'_notes'}{$k}=$v
    }
    elsif (@_ == 2) {
        return $r->{'_notes'}{$k}
    }
    elsif (@_ == 1) {
        return ($r->{'_notes'} ||= {});
    }
    else {
        return err('incorrect usage of %s notes object, r->notes(%s)', +__PACKAGE__, join(',', @_[1..$#_]));
    }

}




sub prev {

    my $r=shift();
    @_ ? $r->{'prev'}=shift() : $r->{'prev'};

}


sub print {

    my $r=shift();
    my $fh=$r->{'select'} || \*STDOUT;
    debug("print fh: $fh");
    CORE::print $fh ((ref($_[0]) eq 'SCALAR') ? ${$_[0]} : @_);

}


sub cleanup_register {

    #my $r=shift();
    my ($r, $cr)=@_;
    push @{$r->{'register_cleanup'} ||= []}, $cr;

    #my $ar=$r->{'register_cleanup'} ||= [];
    #push @

}




sub pool {

    #  Used by mod_perl2, usually for cleanup_register in the form of $r->pool->cleanup_register(), so just
    #  return $r and let the code then call cleanup_register
    #
    my $r=shift();

}


sub run {

    my ($r, $self)=@_;
    debug("r: $r, self: $self");
    (ref($self) || $self)->handler($r);
    #(ref($self) ? $self : $self)->handler($r);

}


sub status {

    my $r=shift();
    @_ ? $r->{'status'}=shift() : $r->{'status'} || HTTP_OK;

}


sub document_root {

    my $r=shift();
    @_ ? $r->{'document_root'}=shift() : $r->{'document_root'} || ($ENV{'DOCUMENT_ROOT'} || fastcwd());
    
}


sub output_filters {

    #  Stub
}


sub location {


    #  Equiv to Apache::RequestUtil->location;
    #
    my $r=shift();
    debug("r: $r, caller: %s", Dumper([caller(0)]));
    my $location;
    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    my $constant_server_hr;
    #if (my $server=$Dir_config_env{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
    if (my $server=$ENV{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
        $constant_server_hr=$constant_hr->{$server} if exists($constant_hr->{$server})
    }
    #if ($Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'}) {
    if ($location=$r->{'location'}) {
        return $location;
    }
    elsif ($ENV{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'}) {

        #  APPL_MD_PATH is IIS virtual dir. If that or a fixed location set use it.
        #
        #$location=$Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'};
        $location=$ENV{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'};
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



sub header_only {

    #  Stub
}


sub set_handlers {

    #  Stub
}




sub send_http_header {

    my $r=shift();
    return unless $r->{'header'};
    my $fh=$r->{'select'} || \*STDOUT;
    CORE::printf $fh ("Status: %s\n", $r->status());
    while (my ($header, $value)=each(%{$r->headers_out()})) {
        CORE::print $fh ("$header: $value\n");
    }
    CORE::print $fh "\n";

}


sub content_type { # Was bi-directional but now only reads from response headers.

    my ($r, $content_type)=@_;
    debug("r: $r, %s", Dumper(\@_));
    #return ($content_type ? $r->headers_out('content-type', $content_type) : $r->headers_in('content-type'));
    return ($content_type ? $r->headers_out('content-type', $content_type) : $r->headers_out('content-type'));

}


sub content_length {

    my ($r, $content_length)=@_;
    debug("r: $r, %s", Dumper(\@_));
    return ($content_length ? $r->headers_out('content-length', $content_length) : $r->headers_in('content-length'));

}


sub handler {

    # Replicate mod_perl handler function
    #
    my ($r, $handler)=@_;
    return ($handler ? $r->{'handler'}=$handler : $r->{'handler'} ||= 'default-handler');

}


sub custom_response {

    my ($r, $status)=(shift(), shift());
    while ($r->prev) {$r=$r->prev}
    debug("in custom response, status $status");
    @_ ? $r->{'custom_response'}{$status}=shift() : $r->{'custom_response'}{$status};

}


sub cwd {

    #  Return cwd of current psp file
    #
    my $r=shift();
    return $r->{'_cwd'} ||= do {
        debug("$r, fn: %s", $r->filename());
        my $fn=$r->filename();
        my $dn;
        unless (-d ($dn=File::Spec->rel2abs($fn))) {
            #  Not a directory, must be file
            #
            $dn=(File::Spec->splitpath($fn))[1] || fastcwd();
            debug("return calculated dn: $dn");
            $dn;
        }
        else {
            debug("return existing dn: $dn");
            $dn;
        }
        
    }

}


# TO DO
#
sub status_line {

    my $r=shift();
    return sprintf('%s %s',$r->status, status_message($r->status));
    
}


sub write {

    #  Just print for Fake, other handlers can map to native
    #
    return &print(@_);
    
}


sub finalize {

    #  No op
    
}


sub redirect {

    #  No op

}



sub as_string {

    my $r=shift();
    my @return;
    push @return, join(' ', map {$r->$_} qw(method unparsed_uri protocol));
    push @return, $r->headers_in->as_string();
    push @return, undef; #Blank line between headers and body
    push @return, $r->body();
    return join("\n", grep {$_} @return);

}


sub mtime {

    shift()->finfo->mtime();

}

sub next {

}


sub preferred_charset {

    return &preferred_media_type(@_);    
    
}

sub preferred_encoding {

    return &preferred_media_type(@_);    
    
}


sub preferred_language {

    my ($r, $lang_ar, @param)=@_;
    unless (ref($lang_ar) eq 'ARRAY') {
        $lang_ar=[$lang_ar, @param];
    }
    return HTTP::AcceptLanguage->new($r->accept_language())->match(@{$lang_ar});
    

}


sub preferred_media_type {

    my ($r, $variant_ar, @param)=@_;
    unless (ref($variant_ar) eq 'ARRAY') {
        $variant_ar=[map {[$_]} $variant_ar, @param];
    }
    return choose($variant_ar, $r->headers_in);

}


sub session {

}

sub session_id {

}

sub route {

}

sub path_parameters {

}


sub sendfile {

}


sub finfo {

    return stat(shift->filename());
    
}

sub form_parameters {

}

sub id {

}

sub multipart_parameters {

}

sub query_parameters {

    use Hash::MultiValue;
    return Hash::MultiValue->new(shift()->uri->query_form);

}

sub request_time {

}

sub scheme {

    return 'http',
    
}


sub uploads {

}


# Error handling, autoload


sub err_html {

    #  Very basic HTML error messages for file not found and similar
    #
    my ($r, $status, $error)=@_;
    require WebDyne::HTML::Tiny;
    my $html_or=WebDyne::HTML::Tiny->new( mode=>$WEBDYNE_HTML_TINY_MODE, r=>$r ) ||
        return err();
    #my $heading=sprintf("%s error - $error", ref($r) || __PACKAGE__);
    my $heading=sprintf("%s error.", ref($r) || __PACKAGE__);
    my @body=(
        $html_or->start_html(title=>"WebDyne Error: $status"),
        $html_or->h3($heading),
        $html_or->hr(),
        $html_or->em(status_message($status) || 'Unknown Error'), $html_or->br(), $html_or->br(),
        $html_or->pre(
            sprintf("The requested URI '%s' generated error:\n\n$error", $r->uri)
        ),
        $html_or->end_html()
    );
    return join('', @body);

}


sub AUTOLOAD { #no subsort

    my ($r, $v)=@_;
    debug("$r AUTOLOAD: $AUTOLOAD, v: $v");
    my $k=($AUTOLOAD=~/([^:]+)$/) && $1;
    warn(sprintf("Unhandled '%s' method, using AUTOLOAD. Caller:%s", $k, Dumper([caller(0)])));
    $v ? $r->{$k}=$v : $r->{$k};


}


sub DESTROY { #no subsort

    my $r=shift();
    debug("$r DESTROY");
    if (my $cr_ar=delete $r->{'register_cleanup'}) {
        debug('found cleanup code refs: %s', Dumper($cr_ar));
        foreach my $cr (grep {ref($_) eq 'CODE'} @{$cr_ar}) {
            debug("running code ref: $cr against r: $r");
            $cr->($r);
        }
    }
    else {
        debug('no cleanup code registered');
    }

}

__END__

=begin markdown

# WebDyne::Request::Fake #

# NAME #

WebDyne::Request::Fake - synthetic request/response object used for direct WebDyne rendering

# SYNOPSIS #

```perl
use WebDyne::Request::Fake;

my $r = WebDyne::Request::Fake->new(
    filename => 'page.psp',
    method   => 'GET',
);
```

# DESCRIPTION #

`WebDyne::Request::Fake` is the baseline WebDyne request adapter. It is used when rendering pages outside a real web server environment, for example through `WebDyne::html`, `WebDyne::html_sr`, `wdrender`, and related command-line tooling.

The module provides a normalized request/response API and also acts as the fallback implementation for methods not implemented by more specific request adapters.

# METHODS #

Notable methods implemented directly by this class include:

* **new(%options)**

    Construct a synthetic request object.

* **filename()**

    Get or derive the current source filename being requested.

* **uri()**

    Return a `URI` object for the current request.

* **headers_in() / headers_out()**

    Access request and response headers.

* **status() / status_line()**

    Access or update response status information.

* **print() / write()**

    Append response body output.

* **finalize()**

    Finalize the synthetic response for downstream consumers.

* **redirect($url)**

    Set redirect-style response headers and status.

* **dir_config($name)**

    Look up directory-style configuration, including values sourced from `WEBDYNE_DIR_CONFIG` and optional local `.webdyne.conf.pl` loading.

* **err_html()**

    Generate an error response using WebDyne’s HTML error facilities.

# NOTES #

`WebDyne::Request::Fake` intentionally carries both request and response responsibilities. More specialized adapters such as `WebDyne::Request::Apache`, `WebDyne::Request::PSGI`, and `WebDyne::Request::PAGI` inherit from it for missing behavior.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Request::Fake


=head1 NAME

WebDyne::Request::Fake - synthetic request/response object used for direct WebDyne rendering


=head1 SYNOPSIS


 use WebDyne::Request::Fake;
 
 my $r = WebDyne::Request::Fake->new(
     filename => 'page.psp',
     method   => 'GET',
 );

=head1 DESCRIPTION

C<WebDyne::Request::Fake> is the baseline WebDyne request adapter. It is used when rendering pages outside a real web server environment, for example through C<WebDyne::html>, C<WebDyne::html_sr>, C<wdrender>, and related command-line tooling.

The module provides a normalized request/response API and also acts as the fallback implementation for methods not implemented by more specific request adapters.


=head1 METHODS

Notable methods implemented directly by this class include:

=over

=item *

B<new(%options)>

Construct a synthetic request object.



=item *

B<filename()>

Get or derive the current source filename being requested.



=item *

B<uri()>

Return a C<URI> object for the current request.



=item *

B<headers_in() / headers_out()>

Access request and response headers.



=item *

B<status() / status_line()>

Access or update response status information.



=item *

B<print() / write()>

Append response body output.



=item *

B<finalize()>

Finalize the synthetic response for downstream consumers.



=item *

B<redirect($url)>

Set redirect-style response headers and status.



=item *

B<dir_config($name)>

Look up directory-style configuration, including values sourced from C<WEBDYNE_DIR_CONFIG> and optional local C<.webdyne.conf.pl> loading.



=item *

B<err_html()>

Generate an error response using WebDyne’s HTML error facilities.



=back


=head1 NOTES

C<WebDyne::Request::Fake> intentionally carries both request and response responsibilities. More specialized adapters such as C<WebDyne::Request::Apache>, C<WebDyne::Request::PSGI>, and C<WebDyne::Request::PAGI> inherit from it for missing behavior.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
