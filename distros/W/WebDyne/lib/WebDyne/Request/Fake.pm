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
use vars   qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Cwd qw(fastcwd);
use Data::Dumper;
use HTTP::Status (RC_OK);
use WebDyne::Util;
use WebDyne::Constant;


#  Var to hold package wide hash, for data shared across package
#
my %Package;


#  Snapshot environment for Dir_config
#
#my %Dir_config_env;


#  Version information
#
$VERSION='2.069';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Run init code for utility accessors unless already done
#
&_init unless defined(&method);


#  All done. Positive return
#
1;


#==================================================================================================

sub _init {

    #  Load quick and dirty mod_perl equivalent handler accessors that get info from
    #  environment vars if they exist
    #
    my %handler=(
        method          => 'REQUEST_METHOD',
        protocol        => 'SERVER_PROTOCOL',
        args            => 'QUERY_STRING',
        path_info       => 'PATH_INFO',
        content_length  => 'CONTENT_LENGTH',
        hostname        => 'SERVER_NAME',
        get_server_name => 'SERVER_NAME',
        get_server_port => 'SERVER_PORT',
        get_remote_host => 'REMOTE_ADDR',
        user            => 'REMOTE_USER',
        ap_auth_type    => 'AUTH_TYPE',
        unparsed_uri    => 'REQUEST_URI',
    );
    while (my ($k, $v)=each %handler) {
        *{$k}=sub { return $ENV{$v} } unless defined &{$k}
    }

}


sub dir_config0 {

    #  Old very simplistic dir_config
    #
    my ($r, $key)=@_;
    return $ENV{$key};

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
            debug("in dir_config looking for key $key at location $location");
            
            
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
                foreach my $hr_key ($location, '') {
                    debug("looking at hr: $hr, k: $hr_key");
                    #  Maybe $hr->{$location}{$key} or $hr->{''}{$key} ?
                    #
                    if (exists $constant_hr->{$hr_key}) {
                        debug('found $hr->{%s}', $hr_key);
                        return $hr->{$hr_key}{$key} if exists($hr->{$hr_key}{$key});
                    }
                    else {
                        debug('no match on hr:$hr {%s}', $hr_key);
                    }
                }
                #  No - $hr->{$key} is last chance
                #
                if (exists $hr->{$key}) {
                    debug('found $hr->{%s}', $key);
                    return $hr->{$key}
                }
                else {
                    debug("no match on $hr {%s}", $key);
                }
            }
                
            #  Nothing found
            #
            debug("no key found for location: $location or any other match, %s");
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
            (map { $_=>$ENV{$_} } grep {/^WebDyne/i} keys %ENV), 
            (map { $_=>$ENV{$_} } grep {exists $ENV{$_} } keys %{$constant_hr})
            #(map { $_=>$ENV{$_} } @{$WEBDYNE_PSGI_ENV_KEEP},
            #%{$WEBDYNE_PSGI_ENV_SET}
        );
        return \%dir_config;
    }

}


sub filename {

    my $r=shift();

    #  Store cwd as takes a fair bit of processing time.
    File::Spec->rel2abs($r->{'filename'}, ($Package{'_cwd'} ||= fastcwd()));

}


sub headers {

    #  Set/get header. r=request, d=direction(in/out), k=key, v=value
    #
    my ($r, $d, $k, $v)=@_;
    
    if (@_ == 4) {
        return $r->{$d}{$k}=$v
    }
    elsif (@_ == 3) {
        return $r->{$d}{$k}
    }
    elsif (@_ == 2) {
        return ($r->{$d} ||= {});
    }
    else {
        return err("incorrect usage of %s $d object, r->$d(%s)", ref($r), join(',', @_[1..$#_]));
    }

}


sub headers_out {

    my $r=shift();
    return $r->headers('headers_out', @_);
    
}


sub headers_in {

    my $r=shift();
    return $r->headers('headers_in', @_);
    
}


sub is_main {

    my $r=shift();
    $r->{'main'} ? 0 : 1;

}


sub log_error {

    my $r=shift();
    warn(@_) unless !$r->{'warn'};

}


sub lookup_file0 {

    #  Old, simplistic version
    #
    my ($r, $fn)=@_;
    my $r_child=ref($r)->new(filename => $fn, main=>$r) || return err();

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child;
    if ($fn!~WEBDYNE_PSP_EXT_RE) { # fastest


        #  Static file. Should migrate to this module but OK is PSGI for moment
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
    my $fn=File::Spec::Unix->catfile((File::Spec->splitpath($r->filename()))[1], $uri);
    return $r->lookup_file($fn);

}


sub main {

    my $r=shift();
    #@_ ? $r->{'main'}=shift() : $r->{'main'} || $r;
    @_ ? $r->{'main'}=shift() : $r->{'main'};

}


sub new {

    my ($class, %r)=@_;
    debug("$class, r:%s", Dumper(\%r));
    return bless \%r, $class;

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


sub parsed_uri {

    my $r=shift();
    require URI;
    URI->new($r->uri());

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


sub register_cleanup {

    #my $r=shift();
    my ($r, $cr)=@_;
    push @{$r->{'register_cleanup'} ||= []}, $cr;

    #my $ar=$r->{'register_cleanup'} ||= [];
    #push @

}


sub cleanup_register {

    &register_cleanup(@_);

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
    @_ ? $r->{'status'}=shift() : $r->{'status'} || RC_OK;

}


sub uri {

    shift()->{'filename'}

}


sub document_root {

    my $r=shift();
    @_ ? $r->{'document_root'}=shift() : $r->{'document_root'} || ($ENV{'DOCUMENT_ROOT'} || fastcwd());
    
}


sub output_filters {

    #  Stub
}


sub location {

    #  Get/set location
    my ($self, $location)=@_;
    if ($location) {
        return $self->{'location'}=$location;
    }
    else {
        return $self->{'location'} || $ENV{'WebDyneLocation'}
    }

}


sub header_only {

    #  Stub
}


sub set_handlers {

    #  Stub
}


sub noheader {

    my $r=shift();
    @_ ? $r->{'header'}=shift() : $r->{'header'};

}


sub send_http_header {

    my $r=shift();
    return unless $r->{'header'};
    my $fh=$r->{'select'} || \*STDOUT;
    CORE::printf $fh ("Status: %s\n", $r->status());
    while (my ($header, $value)=each(%{$r->{'headers_out'}})) {
        CORE::print $fh ("$header: $value\n");
    }
    CORE::print $fh "\n";

}


sub content_type {

    my ($r, $content_type)=@_;
    return ($content_type ? $r->{'headers_out'}{'Content-Type'}=$content_type : $ENV{'CONTENT_TYPE'});
    #CORE::print("Content-Type: $content_type\n");

}


sub handler {

    # Replicate mod_perl handler function
    #
    my ($r, $handler)=@_;
    return ($handler ? $r->{'handler'}=$handler : $r->{'handler'} ||= 'default-handler');

}


sub custom_response {

    my ($r, $status)=(shift, shift);
    $r->status($status);
    $r->send_http_header();
    $r->print(@_);

}


sub args {

    return $ENV{'QUERY_STRING'};
    
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


sub AUTOLOAD {

    my ($r, $v)=@_;
    debug("$r AUTOLOAD: $AUTOLOAD, v: $v");
    my $k=($AUTOLOAD=~/([^:]+)$/) && $1;
    warn(sprintf("Unhandled '%s' method, using AUTOLOAD. Caller:%s", $k, Dumper([caller(0)])));
    $v ? $r->{$k}=$v : $r->{$k};


}


sub DESTROY {

    my $r=shift();
    debug("$r DESTROY");
    if (my $cr_ar=delete $r->{'register_cleanup'}) {
        foreach my $cr (@{$cr_ar}) {
            $cr->($r);
        }
    }

}
