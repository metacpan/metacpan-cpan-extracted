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
package WebDyne;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION $VERSION_GIT_REF %CGI_TAG_WEBDYNE @ISA $AUTOLOAD @EXPORT_OK);
use warnings;
no warnings qw(uninitialized redefine once);
use overload;


#  WebDyne constants, base modules
#
use WebDyne::Util;
use WebDyne::Constant;
use WebDyne::HTML::Tiny;


#  External Modules
#
use Storable;
use HTTP::Status qw(is_success is_error is_redirect RC_OK RC_FOUND RC_NOT_FOUND);
use Fcntl;
use Tie::IxHash;
use Digest::MD5 qw(md5_hex);
use File::Spec::Unix;
use Data::Dumper;
$Data::Dumper::Indent=1;
use HTML::Entities qw(decode_entities encode_entities);
use CGI::Simple;
use JSON;
use Cwd qw(getcwd);


#  Inherit from the Compile module, not loaded until needed though.
#
@ISA=qw(WebDyne::Compile);


#  Export a couple of convenience methods for scripts
#
use Exporter qw(import);
@EXPORT_OK = qw( html html_sr );


#  Version information
#
$VERSION='2.019';
chomp($VERSION_GIT_REF=do { local (@ARGV, $/) = ($_=__FILE__.'.tmp'); <> if -f $_ });


#  Debug load
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  Shortcut error handler, save using ISA;
#
require WebDyne::Err;
*err_html=\&WebDyne::Err::err_html || *err_html;
*err_eval=\&WebDyne::Err::err_eval || *err_eval;


#  Our webdyne "special" tags
#
%CGI_TAG_WEBDYNE=map {$_ => 1} (

    'block',
    'perl',
    'subst',
    'dump',
    'json',
    'api',
    'include',
    'htmx'

);


#  Var to hold package wide hash, for data shared across package
#
my %Package;


#  Do some class wide initialisation
#
&init_class();


#  Eval safe not effective - die if turned on
#
if ($WEBDYNE_EVAL_SAFE) {die "WEBDYNE_EVAL_SAFE disabled in this version\n"}


#  All done. Positive return
#
1;


#==================================================================================================


#  Packace init, attempt to load optional Time::HiRes, Devel::Confess modules
#
BEGIN {
    eval {require Time::HiRes;    Time::HiRes->import('time')};
    eval {require Devel::Confess; Devel::Confess->import()};
}



#  Convenience method for script usage, not used when called from mod_perl or PSGI - they call
#  handler method below. Return scalar ref for efficiency here
#  
sub html_sr {


    #  Supplied with class and options hash. Options can be supplied as hash ref
    #  or hash, convert.
    #
    my ($fn, $opt_hr)=(shift(), shift());
    unless (ref($opt_hr) eq 'HASH') {
        $opt_hr={ %{$opt_hr}, @_ } if $opt_hr;
    }
    $opt_hr->{'filename'} ||= $fn;


    #  Capture handler output
    #
    my $html;
    my $html_fh=$opt_hr->{'outfile'} || do {
        require IO::String; IO::String->new($html);
    };
    $opt_hr->{'select'}=$html_fh;
    
    
    #  Need to setup a fake request handler if initiated via script
    #
    require WebDyne::Request::Fake;
    my $r=WebDyne::Request::Fake->new(%{$opt_hr}) ||
        return err();
        

    #  Get handler
    #
    my $handler=$opt_hr->{'handler'};
    if ($handler) {
        eval("require $handler") ||
            return err("unable to load handler $handler, $@");
    }
    $handler ||= (__PACKAGE__);
    
    
    #  Run
    #
    defined($handler->handler($r)) || return err();


    #  Manual cleanup
    #
    $r->DESTROY();
    

    #  Returm
    #
    if (ref($html_fh) eq 'IO::String') {
        $html_fh->close();
        return \$html;
    }
    else {
        return \undef;
    }

}


#  Or scalar
#
sub html { return ${&html_sr(@_)} };


#  Main handler for mod_perl and PSGI
#
sub handler : method {    # no subsort


    #  Get self ref/class, request ref
    #
    my ($self, $r, $param_hr)=@_;
    debug("handler called with self $self, r $r, MP2 $MP2");


    #  Start timer so we can optionally keep stats on how long handler takes to run
    #
    my $time=($self->{'_time'}=time());


    #  Work out class and correct self ref
    #
    my $class=ref($self) || do {


        #  Need new self ref, as self is actually class. Do inline so quicker than -> new
        #
        my %self=(

            _time => $time,
            _r    => $r,
            %{delete $self->{'_self'}},

        );
        $self=bless \%self, $self;
        ref($self);


    };


    #  Setup error handlers
    #
    local $SIG{'__DIE__'}=sub {
        debug('in __DIE__ sig handler, caller %s', join(',', (caller(0))[0..3]));

        #  Updated to *NOT* throw error if in eval block (i.e. if $@ is set). Stops error handler being called
        #  if non WebDyne module has eval code which triggers non WebDyne AUTOLOAD block. Might need to be more
        #  sophisticated and look at traceback for Autoload::AUTOLOAD but another day
        return err(@_) unless $@;
    };
    local $SIG{'__WARN__'}=sub {
        debug('in __WARN__ sig handler, caller %s', join(',', (caller(0))[0..3]));
        return err(@_)
        }
        if $WEBDYNE_WARNINGS_FATAL;


    #  Debug
    #
    debug(
        "in WebDyne::handler. class $class, self $self, r $r, param_hr %s",
        Dumper($param_hr));


    #  Skip all processing if header request only
    #
    if ($r->header_only()) {return &head_request($r)}


    #  Debug
    #
    debug(
        "enter handler, r $r, location %s file %s, param %s",
        $r->location(), $r->filename(), Dumper($param_hr));


    #  Get full path, mtime of source file, check file exists
    #
    my $srce_pn=$r->filename() ||
        return $self->err_html('unable to get request filename');
    my $srce_mtime=(-f $srce_pn && (stat(_))[9]) || do {

        #  File not found, we don't want to handle this anymore ..
        #
        debug("srce_mtime for file '$srce_pn' not found, could not stat !");
        return &Apache::DECLINED;

    };
    debug("srce_pn $srce_pn, srce_mtime (real) $srce_mtime");


    #  Used to use inode as unique identifier for file in cache, but that
    #  did not take into account the fact that the same file may have diff
    #  Apache locations (and thus WebDyne::Chain) handlers for the same
    #  physical file.  So we now use an md5 hash of handler, location and
    #  file name, but the var name is still "inode";
    #
    RENDER_BEGIN:
    my $srce_inode=(
        $self->{'_inode'} ||= md5_hex(ref($self), $r->location, $srce_pn)
            ||
            return $self->err_html("could not get md5 for file $srce_pn, $!"));
    debug("srce_inode $srce_inode");


    #  Var to hold pointer to cached metadata area, so we are not constantly
    #  dereferencing $Package{'_cache'}{$srce_inode};
    #
    my $cache_inode_hr=(
        $Package{'_cache'}{$srce_inode} ||= {

            data  => undef,    # holds compiled representation of html/psp file
            mtime => undef,    # last modified time of the Storable disk cache file
            nrun  => undef,    # number of times this page run by this mod_perl child
            lrun  => undef,    # last run time of this page by this mod_perl child

            # Created if needed
            #
            # meta       =>  undef,  # page meta data, held in meta section or supplied by add-on modules
            # eval_cr    =>  undef,  # where anonymous sub's representing eval'd perl code within this page are held
            # perl_init  =>  undef,  # flags that perl code in __PERL__ block has been init'd (run once at page load)

        }) || return $self->err_html('unable to initialize cache_inode_hr ref');


    #  Get "effective" source mtime, as may be a combination of things including
    #  template (eg menu) mtime. Here so can be subclassed by other handler like
    #  menu systems
    #
    debug("about to call source_mtime, self $self");
    $srce_mtime=${
        $self->source_mtime($srce_mtime) || return $self->err_html()}
        || $srce_mtime;
    debug("srce_pn $srce_pn, srce_mtime (computed) $srce_mtime");


    #  Need to stat cache file mtime in case another process has updated it (ie via self->cache_compile(1)) call,
    #  which will make our memory cache stale. Would like to not have to do this stat one day, perhaps via shmem
    #  or similar check
    #
    #  Only do if cache directory defined
    #
    my ($cache_pn, $cache_mtime);
    if ($WEBDYNE_CACHE_DN) {
        debug("webdyne_cache_dn $WEBDYNE_CACHE_DN");
        $cache_pn=File::Spec->catfile($WEBDYNE_CACHE_DN, $srce_inode);
        $cache_mtime=((-f $cache_pn) && (stat(_))[9]);
    }
    else {
        debug('no webdyne_cache_dn');
    }


    #  Test if compile/reload needed
    #
    if ($WEBDYNE_RELOAD || $self->{'_compile'} || ($cache_inode_hr->{'mtime'} < $srce_mtime) || ($cache_mtime > $cache_inode_hr->{'mtime'})) {


        #  Debug
        #
        debug(
            "compile/reload needed _compile %s, cache_inode_hr mtime %s, srce_mtime $srce_mtime, WEBDYNE::RELOAD $WEBDYNE_RELOAD",
            $self->{'_compile'}, $cache_inode_hr->{'mtime'});


        #  use Module::Reload to reload modules
        #
        if ($WEBDYNE_RELOAD) {
            local $SIG{'__DIE__'};
            unless ($INC{'Module/Reload.pm'}) {
                debug('loading Module::Reload');
                eval {require Module::Reload};
                return $self->err_html('unable to load Module::Reload - is it installed ?') if $@;
            }
            debug('running Module::Reload->check');
            $Module::Reload::Debug=1;
            Module::Reload->check();

            #delete $Package{'_cache'}{$srce_inode};
        }


        #  Null out cache_inode to clear any flags
        #
        foreach my $key (keys %{$cache_inode_hr}) {
            debug("nulling out cache_inode_hr key: $key");
            $cache_inode_hr->{$key}=undef;
        }


        #  Try to clear/reset package name space if possible
        #
        eval {
            require Symbol;
            &Symbol::delete_package("WebDyne::${srce_inode}");
        } || do {
            eval {} if $@;    #clear $@ after error above
            my $stash_hr=*{"WebDyne::${srce_inode}::"}{HASH};
            foreach (keys %{$stash_hr}) {
                undef *{"WebDyne::${srce_inode}::${_}"};
            }
            %{$stash_hr}=();
            delete *WebDyne::{'HASH'}->{$srce_inode};
        };


        #  Debug
        #
        debug("srce_pn $srce_pn, cache_pn $cache_pn, mtime $cache_mtime");


        my $container_ar;
        if ($self->{'_compile'} || ($cache_mtime < $srce_mtime)) {


            #  Debug
            #
            debug("compiling srce: $srce_pn, dest $cache_pn");


            #  Recompile from source
            #
            eval {require WebDyne::Compile}
                || return $self->err_html(
                errsubst('unable to load WebDyne:Compile, %s', $@ || 'undefined error'));


            #  Source newer than compiled version, must recompile file
            #
            $container_ar=$self->compile(
                {

                    srce => $srce_pn,
                    dest => $cache_pn,

                }) || return $self->err_html();


            #  Check for any unhandled errors during compile
            #
            errstr() && return $self->err_html();


            #  Update mtime flag, or use current time if we were not able to read
            #  cache file (probably because temp dir was not writable - which would
            #  generated a warning in the logs from the Compile module, so no point
            #  making a fuss about it here anymore.
            #
            $cache_mtime=(stat($cache_pn))[9] if $cache_pn;    # ||
                                                               #return $self->err_html("could not stat cache file '$cache_pn'");
            $cache_inode_hr->{'mtime'}=$cache_mtime || time();


        }
        else {

            #  Debug
            #
            debug("loading from disk cache");


            #  Load from storeable file
            #
            $container_ar=Storable::lock_retrieve($cache_pn) ||
                return $self->err_html("Storable error when retreiveing cached file '$cache_pn', $!");


            #  Update mtime flag
            #
            $cache_inode_hr->{'mtime'}=$cache_mtime;


            #  Re-run perl-init for this node. Not done above because handled in compile if needed
            #
            if (my $meta_hr=$container_ar->[0]) {
                if (my $perl_ar=$meta_hr->{'perl'}) {
                    my $perl_debug_ar=$meta_hr->{'perl_debug'} ||
                        return err('unable to load perl_debug array reference');
                    $self->perl_init($perl_ar, $perl_debug_ar) || return $self->err_html();
                }
            }
        }


        #  Done, install into memory cache
        #
        if (my $meta_hr=$container_ar->[0] and $cache_inode_hr->{'meta'}) {

            #  Need to merge meta info
            #
            foreach (keys %{$meta_hr}) {$cache_inode_hr->{'meta'}{$_} ||= $meta_hr->{$_}}

        }
        elsif ($meta_hr) {

            #  No merge - just use from container
            #
            $cache_inode_hr->{'meta'}=$meta_hr;

        }
        $cache_inode_hr->{'data'}=$container_ar->[1];

        #  Corner case. Delete _CGI if WEBDYNE_CGI_EXPAND_PARAM set to force re-read of
        #  CGI params in case was set in <perl> section - which means would not be seen
        #  early enough. Will only happen after first compile, so no major performance
        #  impact on CGI object recreation
        #
        #  Update: Re-init rather than delete or WebDyne::State worn't work
        #
        #delete $self->{'_CGI'} if $WEBDYNE_CGI_PARAM_EXPAND;
        if ((my $cgi_or=$self->{'_CGI'}) && $WEBDYNE_CGI_PARAM_EXPAND) {
            $cgi_or->delete_all();  # Added this after cache code issues so don't get two instanced of param. Keep and eye for problems with WebDyne::State
            $cgi_or->_initialize();
        }


    }
    else {

        debug('no compile or disk cache fetch needed - getting from memory cache');

    }


    #  Separate meta and actual data into separate vars for ease of use
    #
    my ($meta_hr, $data_ar)=@{$cache_inode_hr}{qw(meta data)};
    debug('meta_hr %s, ', Dumper($meta_hr));


    #  Custom handler ?
    #
    if (my $handler_ar=$meta_hr->{'handler'} || $r->dir_config('WebDyneHandler')) {
        my ($handler, $handler_param_hr)=ref($handler_ar) ? @{$handler_ar} : $handler_ar;
        if (ref($self) ne $handler) {
            debug("passing to custom handler '$handler', param %s", Dumper($handler_param_hr));
            unless ($Package{'_handler_load'}{$handler}) {
                debug("need to load handler '$handler' -  trying");
                (my $handler_fn=$handler)=~s/::/\//g;
                $handler_fn.='.pm';
                eval {require $handler_fn} ||
                    return $self->err_html("unable to load custom handler '$handler', $@");
                UNIVERSAL::can($handler, 'handler') ||
                    return $self->err_html("custom handler '$handler' does not seem to have a 'handler' method to call");
                debug('loaded OK');
                $Package{'_handler_load'}{$handler}++;
            }
            my %handler_param_hr=(%{$param_hr}, %{$handler_param_hr}, meta => $meta_hr);
            bless $self, $handler;

            #  Force recalc of inode in next handler so recompile done
            delete $self->{'_inode'};

            #  Add meta-data. Something inefficient here, why supplying as handler param and
            #  self attrib ? If don't do it Fake/FastCGI request handler breaks but Apache does
            #  not ?
            $self->{'_meta_hr'}=$meta_hr;
            return &{"${handler}::handler"}($self, $r, \%handler_param_hr);
        }
    }


    #  Contain cache code ?
    #
    if ((my $cache=($self->{'_cache'} || $meta_hr->{'cache'})) && !$self->{'_cache_run_fg'}++) {
        debug("found cache routine $cache, adding to inode $srce_inode");
        my $cache_inode;
        my $eval_cr=$Package{'_eval_cr'}{'!'};
        if (ref($cache) eq 'CODE') {
            debug('CODE cache ref type');
            my %param=(
                cache_cr   => $cache,
                srce_inode => $srce_inode
            );
            $cache_inode=${
            
                #  OK - what does this do ? It calls the cache code ref in the document via the eval_cr code execution
                #  routine which is supplied as follows
                #
                #  $_[0] = self (instance) ref
                #  $_[1] = r (request ref)
                #  $_[2] = CGI (CGI ref)
                #  $_[3] = \%param above
                #
                #  And we are executing code '$_[3]->{'cache_cr'}->($_[0], $_[3]->{'srce_inode'}', so
                #  $cache->($self, $srce_inode)
                #
                #  Change mind - back to not supplying r, CGI as standard. User can request
                #
                ##$eval_cr->($self, undef, \%param, q[$_[3]->{'cache_cr'}->($_[0], $_[3]->{'srce_inode'})], 0) ||
                #  
                #  Before we added r,CGI as params for eval_cr it looked like this
                #
                #$eval_cr->($self, undef, \%param, q[$_[1]->{'cache_cr'}->($_[0], $_[1]->{'srce_inode'})], 0) ||
                $eval_cr->($self, undef, \%param, q[$_[1]->{'cache_cr'}->($_[0], $_[1]->{'srce_inode'})], 0) ||
                    return $self->err_html(
                    errsubst(
                        'error in cache code: %s', errstr() || $@ || 'no inode returned'
                    ));
            }
        }
        else {
            debug('non-CODE cache type');
            $cache_inode=${
                $eval_cr->($self, undef, $srce_inode, $cache, 0) ||
                    return $self->err_html(
                    errsubst(
                        'error in cache code: %s', errstr() || $@ || 'no inode returned'
                    ));
            }
        }
        $cache_inode=$cache_inode ? md5_hex($srce_inode, $cache_inode) : $self->{'_inode'};

        #  Will probably make inodes with algorithm below some day so we can implement a "maxfiles type limit on
        #  the number of cache files generated. Not today though ..
        #
        #$cache_inode=$cache_inode ? $srce_inode .'_'. md5_hex($cache_inode) : $self->{'_inode'};
        debug("cache inode $cache_inode, compile %s", $self->{'_compile'});

        if (($cache_inode ne $srce_inode) || $self->{'_compile'}) {

            #  Using a cache file, different inode.
            #
            debug("goto RENDER_BEGIN, inode node was $srce_inode, now $cache_inode");
            $self->{'_inode'}=$cache_inode;
            goto RENDER_BEGIN;

            #return &handler($self,$r,$param_hr); #should work instead of goto for pendants
        }

    }


    #  Is it plain HTML which can be/is pre-rendered and stored on disk ? Note to self, leave here - should
    #  run after any cache code is run, as that may change inode.
    #
    my $html_sr;
    if ($self->{'_static'} || ($meta_hr && ($meta_hr->{'html'} || $meta_hr->{'static'}))) {

        #my $cache_pn=File::Spec->catfile($WEBDYNE_CACHE_DN, $srce_inode);
        if ($cache_pn && (-f (my $fn="${cache_pn}.html")) && ((stat(_))[9] >= $srce_mtime) && !$self->{'_compile'}) {

            #  Cache file exists, and is not stale, and user/cache code does not want a recompile. Tell Apache or FCGI
            #  to serve it up directly.
            #
            debug("returning pre-rendered file ${cache_pn}.html");
            if ($MP2 || $ENV{'FCGI_ROLE'} || $ENV{'psgi.version'}) {

                #  Do this way for mod_perl2, FCGI. Note to self need r->output_filter or
                #  Apache 2 seems to add junk characters at end of output
                #
                debug('using MP2 or FCGI_ROLE path');
                my $r_child=$r->lookup_file($fn, $r->output_filters);
                debug("r_child: $r_child");
                $r_child->handler('default-handler');
                $r_child->content_type($WEBDYNE_CONTENT_TYPE_HTML);

                #  Apache bug ? Need to set content type on r also
                $r->content_type($WEBDYNE_CONTENT_TYPE_HTML);
                debug("set content type to: $WEBDYNE_CONTENT_TYPE_HTML, running");
                return $r_child->run();

            }
            else {

                #  This way for older versions of Apache, other request handlers
                #
                debug('using legacy path');
                $r->filename($fn);
                $r->handler('default-handler');
                $r->content_type($WEBDYNE_CONTENT_TYPE_HTML);
                return &Apache::DECLINED;
            }
        }
        elsif ($cache_pn) {

            #  Cache file defined, but out of date of non-existant. Register callback handler to write HTML output
            #  after render complete
            #
            debug('storing to disk cache html %s', \$data_ar->[0]);
            my $cr=sub {
                &cache_html(
                    "${cache_pn}.html", ($meta_hr->{'static'} || $self->{'_static'}) ? $html_sr : \$data_ar->[0])
            };
            $MP2 ? $r->pool->cleanup_register($cr) : $r->register_cleanup($cr);
        }
        else {

            #  No cache directory, store in memory cache. Each apache process will get a different version, but will
            #  at least still be only compiled once for each version.
            #
            debug('storing to memory cache html %s', \$data_ar->[0]);
            my $cr=sub {
                $cache_inode_hr->{'data'}=[
                    ($meta_hr->{'static'} || $self->{'_static'}) ? ${$html_sr} : $data_ar->[0]]
            };
            $MP2 ? $r->pool->cleanup_register($cr) : $r->register_cleanup($cr);
        }

    }


    #  Debug
    #
    debug('about to render');


    #  Set default content type to text/html, can be overridden by render code if needed
    #
    $r->content_type($WEBDYNE_CONTENT_TYPE_HTML);


    #  Redirect 'print' function to our own routine for later output
    #
    my $select=($self->{'_select'} ||= CORE::select());
    debug("select handle is currently $select, changing to *WEBDYNE");
    tie(*WEBDYNE, 'WebDyne::TieHandle', $self) ||
        return $self->err_html("unable to tie output to 'WebDyne::TieHandle', $!");
    CORE::select WEBDYNE if $select;


    #  Get the actual html. The main event - convert data_ar to html
    #
    $html_sr=$self->render({data => $data_ar, param => $param_hr}) || do {


        #  Our render routine returned an error. Debug
        #
        RENDER_ERROR:
        debug("render error $r, select $select");


        #  Return error
        #
        debug("selecting back to $select for error");
        CORE::select $select if $select;
        untie *WEBDYNE;
        return $self->err_html();


    };


    #  Done with STDOUT redirect
    #
    debug("selecting back to $select");
    CORE::select $select if $select;
    untie *WEBDYNE;


    #  Check for any unhandled errors during render - render may have returned OK, but
    #  maybe an error occurred along the way that was not passed back ..
    #
    debug('errstr after render %s', errstr());
    errstr() && return $self->err_html();
    &CGI::Simple::cgi_error() && return $self->err_html(&CGI::Simple::cgi_error());


    #  Check for any blocks that user wanted rendered but were
    #  not present anywhere
    #
    #if ($WEBDYNE_DELAYED_BLOCK_RENDER && (my $block_param_hr=delete $self->{'_block_param'})) {
    if (my $block_param_hr=delete $self->{'_block_param'}) {
        my @block_error;
        foreach my $block_name (keys %{$block_param_hr}) {
            unless (exists $self->{'_block_render'}{$block_name}) {
                push @block_error, $block_name;
            }
        }
        if (@block_error) {
            debug('found un-rendered blocks %s', Dumper(\@block_error));
            return $self->err_html(
                err('unable to locate block(s) %s for render', join(', ', map {"'$_'"} @block_error)))
        }
    }


    #  If no error, status must be ok unless otherwise set
    #
    $r->status(RC_OK) unless $r->status();
    debug('r status set, %s', $r->status());


    #  Formulate header, calc length of return.
    #
    #  Modify to remove error checking - WebDyne::FakeRequest does not supply
    #  hash ref, so error generated. No real need to check
    #
    my $header_out_hr=$r->headers_out();    # || return err();
    my %header_out=(

        'Content-Length' => length ${$html_sr},
        #($meta_hr->{'no_cache'} || $WEBDYNE_NO_CACHE) && (
        #    'Cache-Control' => 'no-cache',
        #    'Pragma'        => 'no-cache',
        #    'Expires'       => '-5'
        #    )
        %{$WEBDYNE_HTTP_HEADER}

    );
    foreach (keys %header_out) {$header_out_hr->{$_}=$header_out{$_}}


    #  Debug
    #
    debug('sending header');


    #  Send header
    #
    $r->send_http_header() if !$MP2;


    #  Print. Commented out version only seems to work in Apache 1/mod_perl1
    #
    #$r->print($html_sr);
    $MP2 ? $r->print(${$html_sr}) : $r->print($html_sr);


    #  Work out the form render time, log
    #
    RENDER_COMPLETE:
    my $time_render=sprintf('%0.4f', time()-$time);
    debug("form $srce_pn render time $time_render");


    #  Do we need to do house cleaning on cache after this run ? If so
    #  add a perl handler to do it after we finish
    #
    if (
        $WEBDYNE_CACHE_CHECK_FREQ
        &&
        ($r eq ($r->main() || $r)) &&
        !((my $nrun=++$Package{'_nrun'}) % $WEBDYNE_CACHE_CHECK_FREQ)
    ) {


        #  Debug
        #
        debug("run $nrun times, scheduling cache clean");


        #  Yes, we need to clean cache after finished
        #
        my $cr=sub {&cache_clean($Package{'_cache'})};
        $MP2 ? $r->pool->cleanup_register($cr) : $r->register_cleanup($cr);


        #  Used to be sub { $self->cache_clean() }, but for some reason this
        #  made httpd peg at 100% CPU usage after cleanup. Removing $self ref
        #  fixed.
        #


    }
    elsif ($WEBDYNE_CACHE_CHECK_FREQ) {

        #  Only bother to update counters if we are checking cache periodically
        #


        #  Update cache script frequency used, time used indicators, nrun=number
        #  of runs, lrun=last run time
        #
        $cache_inode_hr->{'nrun'}++;
        $cache_inode_hr->{'lrun'}=time();

    }
    else {


        #  Debug
        #
        debug("run $nrun times, no cache check needed");

    }


    #  Debug exit
    #
    debug("handler $r exit status %s, leaving with Apache::OK", $r->status);    #, Dumper($self));


    #  Complete
    #
    HANDLER_COMPLETE:
    return &Apache::OK;


}


sub init_class {


    #  Try to load correct modules depending on Apache ver, taking special care
    #  with constants. This mess will disappear if we only support MP2
    #
    if ($MP2) {

        local $SIG{'__DIE__'};
        eval {
            #require Apache2;
            require Apache::Log;
            require Apache::Response;
            require Apache::SubRequest;
            require Apache::Const; Apache::Const->import(-compile => qw(OK DECLINED));
            require APR::Table;
            require APR::Pool;
        } || eval {
            require Apache2::Log;
            require Apache2::Response;
            require Apache2::SubRequest;
            require Apache2::Const; Apache2::Const->import(-compile => qw(OK DECLINED));
            require Apache2::RequestRec;
            require Apache2::RequestUtil;
            require Apache2::RequestIO;
            require APR::Table;
            require APR::Pool;
        };
        eval {} if $@;
        unless (UNIVERSAL::can('Apache', 'OK')) {
            if (UNIVERSAL::can('Apache2::Const', 'OK')) {
                *Apache::OK=\&Apache2::Const::OK;
                *Apache::DECLINED=\&Apache2::Const::DECLINED;
            }
            elsif (UNIVERSAL::can('Apache::Const', 'OK')) {
                *Apache::OK=\&Apache::Const::OK;
                *Apache::DECLINED=\&Apache::Const::DECLINED;
            }
            else {
                *Apache::OK=sub {0}
                    unless defined &Apache::OK;
                *Apache::DECLINED=sub {-1}
                    unless defined &Apache::DECLINED;
            }
        }
    }
    elsif ($ENV{'MOD_PERL'}) {

        local $SIG{'__DIE__'};
        eval {
            require Apache::Constants; Apache::Constants->import(qw(OK DECLINED));
            *Apache::OK=\&Apache::Constants::OK;
            *Apache::DECLINED=\&Apache::Constants::DECLINED;
        } || do {
            *Apache::OK=sub {0}
        };
        eval {} if $@;
    }
    else {

        *Apache::OK=sub {0};
        *Apache::DECLINED=sub {-1};

    }


    #  If set, delete all old cache files at startup
    #
    if ($WEBDYNE_STARTUP_CACHE_FLUSH && (-d $WEBDYNE_CACHE_DN)) {
        my @file_cn=glob(File::Spec->catfile($WEBDYNE_CACHE_DN, '*'));
        foreach my $fn (grep {/\w{32}(\.html)?$/} @file_cn) {
            unlink $fn;    #don't error here if problems, user will never see it
        }
    }


    #  Make all errors non-fatal
    #
    errnofatal(1);


    #  Alias request method to just 'r' also
    #
    *WebDyne::r=\&WebDyne::request || *WebDyne::r;


    #  Eval routine for eval'ing perl code in a non-safe way (ie hostile
    #  code could probably easily subvert us, as all operations are
    #  allowed, including redefining our subroutines etc).
    #
    my $eval_perl_cr=sub {


        #  Get self ref
        #
        my ($self, $data_ar, $eval_param_hr, $eval_text, $index, $tag_fg)=@_;
        $eval_text=decode_entities($eval_text);


        #  Debug
        #
        my $inode=$self->{'_inode'} || 'ANON';    # Anon used when no inode present, eg wdcompile
        my $html_line_no=$data_ar->[WEBDYNE_NODE_LINE_IX];


        #  Get CGI vars
        #
        my $cgi_or=$self->{'_CGI'} || $self->CGI();
        my $param_hr=(
            $self->{'_eval_cgi_hr'} ||= do {
                $cgi_or->Vars();

            }
        );


        #  Only eval subroutine if we have not done already, if need to eval store in
        #  cache so only done once.
        #
        my $eval_cr=$Package{'_cache'}{$inode}{'eval_cr'}{$data_ar}{$index} ||= do {

            #  Why did I do this ? No vars to perl_init so nothing created ?
            #
            #$Package{'_cache'}{$inode}{'perl_init'}{+undef} ||= $self->perl_init();
            no strict;
            no integer;
            debug("calling eval sub: $eval_text");

            #  Get code ref. Do this way so run in sub with no access to vars in this scope
            #
            my $sub_cr=&eval_cr($inode, \$eval_text, $html_line_no);
            if ($@) {
                my $err=$@; eval {};

                #return err("eval of code returned error: $err");
                return $self->err_eval("eval of code returned error: $err", \$eval_text, $inode);
            }
            elsif (!defined($sub_cr)) {
                return err("eval of code did not return a true value");
            }
            elsif (!(ref($sub_cr) eq 'CODE')) {
                return err("eval of code did not return a code ref");
            }


            #  Store code away for error handling. Keep this and next bit to jog memory
            #
            #$Package{'_cache'}{$inode}{'eval_code'}{$data_ar}{$index}=$eval;


            #  Old way we did it code
            #
            #eval("package WebDyne::$_[0]; $WebDyne::WEBDYNE_EVAL_USE_STRICT;\n" . "#line $_[2]\n" . "sub{${$_[1]}\n}");
            #&eval_cr($inode, \$eval_text, $html_line_no) || return
            #    $self->err_eval("$@", \$eval_text);


            #  Done
            #
            $sub_cr;

        };

        #debug("eval done, eval_cr $eval_cr");


        #  Run eval
        #
        my @eval;
        eval {

            #  The following line puts all CGI params in %_ during the eval so they are easy to
            #  get to ..
            local *_=$param_hr;
            debug("eval call starting, tag_fg: $tag_fg");

            #  Note change here. Now supplying request handler, CGI instanced as standard params to all code calls
            #
            #@eval=$tag_fg ? $eval_cr->($self, $eval_param_hr) : scalar $eval_cr->($self, $eval_param_hr);[B
            #
            #  Change of mind again. Don't supply r, CGI as standard, let user call for if wanted. Back to original code
            #
            #@eval=$tag_fg ? $eval_cr->($self, $eval_param_hr) : scalar $eval_cr->($self, $self->{'_r'}, $cgi_or, $eval_param_hr);
            @eval=$tag_fg ? $eval_cr->($self, $eval_param_hr) : scalar $eval_cr->($self, $eval_param_hr);
            debug("eval call complete, $@, %s", Dumper(\@eval));

        };
        if (!@eval || $@ || !$eval[0]) {

            #  An error occurred - handle it and return.
            #
            if (my $err=(errstr() || $@)) {

                #  Eval error or err() called during routine.
                #
                return $self->err_eval($err, \$eval_text, $inode);

            }
            else {

                #  Some other problem
                #
                #return err ('code did not return a true value: %s, %s', $eval_text, Dumper(\@eval));

            }

        }
        elsif ($eval[0] eq $self) {


            #  $self fell through, probably means no explicit return was done, e.g perl code was sub foo {}
            #
            undef @eval;

        }


        #  Quick sanity check on return
        #
        if (grep {ref($_) && (ref($_) !~ /(?:SCALAR|ARRAY|HASH)/)} @eval) {

            #  Whatever it is we can't render it unless SCALAR, ARRAY or HASH
            #
            return err('return from eval of ref type \'%s\' not supported', join(',', grep {$_} map {ref($_)} @eval));

        }


        #  Done
        #
        \@eval;

    };


    #  The code ref for the eval statement if using Safe module. NOTE: old and unmaintained.
    #
    my $eval_safe_cr=sub {


        #  Get self ref
        #
        my ($self, $data_ar, $eval_param_hr, $eval_text, $index)=@_;


        #  Inode
        #
        my $inode=$self->{'_inode'} || 'ANON';    # Anon used when no inode present, eg wdcompile


        #  Get CGI vars
        #
        my $cgi_or=$self->{'_CGI'} || $self->CGI();
        my $param_hr=(
            $self->{'_eval_cgi_hr'} ||= do {

                $cgi_or->Vars();

            }
        );

        #  Init Safe mode environment space
        #
        my $safe_or=$self->{'_eval_safe'} || do {
            debug('safe init (eval_init)');
            require Safe;
            require Opcode;

            #  Used to use Safe->new($inode), but bug in Safe (actually Opcode) is Safe root namespace too long
            #
            Safe->new();
        };
        $self->{'_eval_safe'} ||= do {
            $safe_or->permit_only(@{$WEBDYNE_EVAL_SAFE_OPCODE_AR});
            $safe_or;
        };


        #  Only eval subroutine if we have not done already, if need to eval store in
        #  cache so only done once
        #
        local *_=$param_hr;
        ${$safe_or->varglob('_self')}=$self;
        ${$safe_or->varglob('_eval_param_hr')}=$eval_param_hr;
        #${$safe_or->varglob('_r')}=$self->{'_r'};
        #${$safe_or->varglob('_CGI')}=$cgi_or;
        #my $html_sr=$safe_or->reval("sub{$eval_text}->(\$::_self, \$::_r, \$::_CGI, \$::_eval_param_hr)", $WebDyne::WEBDYNE_EVAL_USE_STRICT) ||
        #
        #  Change mind, remove r and CGI as supplied params, user can request if wanted.
        #
        my $html_sr=$safe_or->reval("sub{$eval_text}->(\$::_self, \$::_eval_param_hr)", $WebDyne::WEBDYNE_EVAL_USE_STRICT) ||
            return errstr() ? err() : err($@ || 'undefined return from Safe->reval()');


        #  Run through the same sequence as non-safe routine
        #
        if (!defined($html_sr) || $@) {


            #  An error occurred - handle it and return.
            #
            if (my $err=(errstr() || $@)) {

                #  Eval error or err() called during routine.
                #
                return $self->err_eval($err, \$eval_text, $inode);

            }
            else {

                #  Some other problem
                #
                return err('code did not return a true value: %s', $eval_text);
            }


        }


        #  Array returned ? Convert if so
        #
        (ref($html_sr) eq 'ARRAY') && do {
            $html_sr=\join(undef, map {ref($_) ? ${$_} : $_} @{$html_sr})
        };


        #  Any 'printed data ? Prepend to output. Used to do $self->{'_print_ar'}{$data_ar} but changed to
        #  just $self->{'_print_ar'}. See code history for background
        #
        if (my $print_ar=delete $self->{'_print_ar'}) {
            debug("print_ar: $print_ar %s", Dumper($print_ar));
            foreach my $item (reverse @{$print_ar}) {
                debug("prepending printed data %s for data_ar: $data_ar, %s", Dumper($item, $data_ar));
                my $print_html=(ref($_) eq 'SCALAR') ? ${$_} : $_;
                $html_sr=ref($html_sr) ? \($print_html . ${$html_sr}) : ($print_html . $html_sr);
            }

        }
        else {
            debug('no printed data detected');
        }


        #  Make sure we return a ref
        #
        return ref($html_sr) ? $html_sr : \$html_sr;


    };


    #  Hash eval routine, works similar to the above, but returns a hash ref
    #
    my $eval_hash_cr=sub {


        #  Run eval and turn into tied hash
        #
        debug('eval_hash_cr, %s', Dumper(\@_));
        tie(my %hr, 'Tie::IxHash', @{$eval_perl_cr->(@_) || return err()});
        return \%hr;


    };


    #  Array eval routine, works similar to the above, but returns an array ref
    #
    my $eval_array_cr=sub {


        #  Run eval and return default - which is an array ref
        #
        debug('eval_array_cr, %s', Dumper(\@_));
        return $eval_perl_cr->(@_) || err();

    };


    #  Code ref eval routine
    #
    my $eval_code_cr=sub {


        #  Need to eval some code. Dispatch to perl code ref
        #
        my ($self, $data_ar, $eval_param_hr, $eval_text, $index, $tag_fg)=@_;
        debug("eval code start $eval_text");
        my $html_ar=$eval_perl_cr->(@_) || return err();
        debug("eval code finish %s", Dumper($html_ar));


        #  We only accept first item of any array ref returned (which might be an array ref itself)
        #
        my $html_sr=$html_ar->[0];


        #  If array ref returned and not rendering a tag convert to string. If in tag CGI.pm can
        #  use array ref so leave alone
        #
        if ((ref($html_sr) eq 'ARRAY') && !$tag_fg) {
            $html_sr=\join(undef, map {(ref($_) eq 'SCALAR') ? ${$_} : $_} @{$html_sr}) ||
                return err('unable to generate scalar from %s', Dumper($html_sr));
        }


        #  Any 'printed data ? Prepend to output. Used to do $self->{'_print_ar'}{$data_ar} but changed to
        #  just $self->{'_print_ar'}. See code history for background
        #
        if (my $print_ar=delete $self->{'_print_ar'}) {
            debug("print_ar: $print_ar %s", Dumper($print_ar));
            foreach my $item (reverse @{$print_ar}) {
                debug("prepending printed data %s for data_ar: $data_ar, %s", Dumper($item, $data_ar));
                my $print_html=(ref($item) eq 'SCALAR') ? ${$item} : $item;
                $html_sr=ref($html_sr) ? \($print_html . ${$html_sr}) : ($print_html . $html_sr);
            }
        }
        else {
            debug('no printed data detected');
        }


        #  Make sure we return a ref
        #
        return ref($html_sr) ? $html_sr : \$html_sr;

    };


    #  Scalar (${foo}) routine
    #
    my $eval_scalar_cr=sub {

        my $value=$_[2]->{$_[3]};
        unless ($value) {
            if (!exists($_[2]->{$_[3]}) && $WEBDYNE_STRICT_VARS) {
                return err("no '$_[3]' parameter value supplied, parameters are: %s", join(',', map {"'$_'"} keys %{$_[2]}))
            }
        }

        #  Get rid of any overloading
        if (ref($value) && overload::Overloaded($value)) {$value="$value"}
        return ref($value) ? $value : \$value

    };


    #  Init anon text and attr evaluation subroutines, store in class space
    #  for quick retrieval when needed, save redefining all the time
    #
    my %eval_cr=(

        '$' => $eval_scalar_cr,
        '@' => $eval_array_cr,
        '%' => $eval_hash_cr,
        '!' => $eval_code_cr,
        '+' => sub {return \($_[0]->CGI()->param($_[3]))},
        '*' => sub {return \$ENV{$_[3]}},
        '^' => sub {
            my $m=$_[3]; my $r=$_[0]->{'_r'};
            UNIVERSAL::can($r, $m) ? \$r->$m : err("unknown request method '$m'")
        }

    );


    #  Store in class name space
    #
    $Package{'_eval_cr'}=\%eval_cr;

}


sub cache_clean {


    #  Get cache_hr, only param supplied
    #
    my $cache_hr=shift();
    debug('in cache_clean');


    #  Values we want, either last run time (lrun) or number of times run
    #  (nrun)
    #
    my $clean_method=$WEBDYNE_CACHE_CLEAN_METHOD ? 'nrun' : 'lrun';


    #  Sort into array of inode values, sorted descending by clean attr
    #
    my @cache=sort {$cache_hr->{$b}{$clean_method} <=> $cache_hr->{$a}{$clean_method}}
        keys %{$cache_hr};
    debug('cache clean array %s', Dumper(\@cache));


    #  If > high watermark entries, we need to clean
    #
    if (@cache > $WEBDYNE_CACHE_HIGH_WATER) {


        #  Yes, clean
        #
        debug('cleaning cache');


        #  Delete excess entries
        #
        my @clean=map {delete $cache_hr->{$_}} @cache[$WEBDYNE_CACHE_LOW_WATER..$#cache];


        #  Debug
        #
        debug('removed %s entries from cache', scalar @clean);

    }
    else {

        #  Nothing to do
        #
        debug(
            'no cleanup needed, cache size %s less than high watermark %s',
            scalar @cache, $WEBDYNE_CACHE_HIGH_WATER
        );

    }


    #  Done
    #
    return \undef;

}


sub head_request {


    #  Head request only
    #
    my $r=shift();


    #  Clear any handlers
    #
    $r->set_handlers(PerlHandler => undef);


    #  Send the request
    #
    $r->send_http_header() if !$MP2;


    #  Done
    #
    return &Apache::OK;

}


sub render_reset {

    my ($self, $data_ar)=@_;
    $data_ar ? $self->{'_perl'}[0]=$data_ar : delete $self->{'_perl'};

}


sub render {


    #  Convert data array structure into HTML
    #
    my ($self, $param_hr)=@_;


    #  If not supplied param as hash ref assume all vars are params to be subs't when
    #  rendering this data block
    #
    ref($param_hr) || ($param_hr={param => {@_[1..$#_]}}) if $param_hr;


    #  Debug
    #
    debug('in render, param data %s, stack: %s', $param_hr->{'data'}, join('*', @{$self->{'_perl'}}));


    #  Get node array ref
    #
    my $data_ar=$param_hr->{'data'} || $self->{'_perl'}[0][WEBDYNE_NODE_CHLD_IX] ||
        return err('unable to get HTML data array');
    #$self->{'_perl'}[0] ||= $data_ar;


    #  Debug
    #
    #debug("render data_ar $data_ar %s", Dumper($data_ar));
    debug("render data_ar $data_ar");


    #  If block name spec'd register it now
    #
    $param_hr->{'block'} && (
        $self->render_block($param_hr) || return err());


    #  Get CGI object
    #
    #my $cgi_or=$self->{'_CGI'} || $self->CGI() ||
    #    return err ("unable to get CGI object from self ref");
    my $cgi_or=$self->{'_html_tiny_or'} || $self->html_tiny(CGI=>$self->CGI()) ||
        return err("unable to get HTML::Tiny object from self ref");
    debug("CGI $cgi_or");


    #  Stub out entity_encode - we don't want attributes escaped
    #
    local *HTML::Tiny::entity_encode=sub {$_[1]}
        unless
        $WEBDYNE_CGI_AUTOESCAPE;
        
        
    #  Any data params for this render
    #
    my $param_data_hr=$param_hr->{'param'};


    #  Recursive anon sub to do the render, init and store in class space
    #  if not already done, saves a small amount of time if doing many
    #  iterations
    #
    my $render_cr=$Package{'_render_cr'} ||= sub {


        #  Get self ref, node array etc
        #
        my ($render_cr, $self, $cgi_or, $data_ar, $param_data_hr)=@_;


        #  Get tag
        #
        my ($html_tag, $html_line_no)=
            @{$data_ar}[WEBDYNE_NODE_NAME_IX, WEBDYNE_NODE_LINE_IX];
        my $html_chld;


        #  Save current data block away for reference by error handler if something goes
        #  wrong
        #
        push @{$self->{'_data_ar'}},$data_ar;
        unshift @{$self->{'_perl_data'}}, $param_data_hr;


        #  Debug
        #
        debug("render tag $html_tag, line $html_line_no");


        #  Get attr hash ref
        #
        my $attr_hr=$data_ar->[WEBDYNE_NODE_ATTR_IX];


        #  If subst flag present, means we need to process attr values
        #
        if ($data_ar->[WEBDYNE_NODE_SBST_IX]) {
            $attr_hr=$self->subst_attr($data_ar, $attr_hr, $param_data_hr) ||
                return err();
        }


        #  If param present, use for sub-render
        #
        $attr_hr->{'param'} && ($param_data_hr=$attr_hr->{'param'});


        #  Process sub nodes to get child html data, only if not a perl tag or block tag
        #  though - they will choose when to render sub data. Subst is OK
        #
        if (!$CGI_TAG_WEBDYNE{$html_tag} || ($html_tag eq 'subst')) {


            #  Not a perl tag, recurse through children and render them, building
            #  up HTML from inside out
            #
            my @data_child_ar=$data_ar->[WEBDYNE_NODE_CHLD_IX] ? @{$data_ar->[WEBDYNE_NODE_CHLD_IX]} : undef;
            foreach my $data_chld_ar (@data_child_ar) {


                #  Debug
                #
                debug('data_chld_ar %s', Dumper($data_chld_ar));


                #  Only recurse on children which are are refs, as these are sub nodes. A
                #  child that is not a ref is merely HTML text
                #
                if (ref($data_chld_ar)) {


                    #  It is a sub node, render recursively
                    #
                    $html_chld.=${
                        (
                            $render_cr->($render_cr, $self, $cgi_or, $data_chld_ar, $param_data_hr)
                                ||
                                return err())};

                    #$html_chld.="\n";

                }
                else {


                    #  Text node only, add text to child html string
                    #
                    $html_chld.=$data_chld_ar;

                }

            }

        }
        else {

            debug("skip child render, under $html_tag tag");

        }


        #  Debug
        #
        debug("html_chld $html_chld");
        my $html;


        #  Render *our* node now, trying to use most efficient/appropriated method depending on a number
        #  of factors
        #
        if ($CGI_TAG_WEBDYNE{$html_tag}) {


            #  Special WebDyne tag, render using our self ref, not CGI object
            #
            debug("rendering webdyne tag $html_tag");
            $html=${ $self->$html_tag($data_ar, $attr_hr, $param_data_hr, $html_chld) ||
                return err() };



        }
        elsif ($attr_hr) {


            #  Normal CGI tag, with attributes and perhaps child text
            #
            debug("rendering normal HTML tag: $html_tag with attr: %s", Dumper($attr_hr));
            $html=$cgi_or->$html_tag(grep {$_} $attr_hr || {}, $html_chld) ||
                return err( "CGI tag '<$html_tag>' did not return any text" );
            

        }
        elsif ($html_chld) {


            #  Normal CGI tag, no attributes but with child text
            #
            debug("rendering normal HTML tag: $html_tag, no attributes but with child text");
            $html=$cgi_or->$html_tag($html_chld) ||
                return err("CGI tag '<$html_tag>' did not return any text");


        }
        else {


            #  Empty CGI object, eg <hr>
            #
            debug("rendering empty HTML tag: $html_tag");
            $html=$cgi_or->$html_tag() ||
                return err("CGI tag '<$html_tag>' did not return any text");

        }


        #  No errors, pop error handler stack
        #
        pop @{$self->{'_data_ar'}};
        shift @{$self->{'_perl_data'}};
        

        #  Return
        #
        return \$html;


    };


    #  At the top level the array may have completly text nodes, and no children, so
    #  need to take care to only render children if present.
    #
    my @html;
    foreach my $data_ar (@{$data_ar}) {


        #  Is this a sub node, or only text (ref means sub-node)
        #
        if (ref($data_ar)) {


            #  Sub node, we call call render routine
            #
            push @html,
                ${$render_cr->($render_cr, $self, $cgi_or, $data_ar, $param_data_hr) || return err()};


        }
        else {


            #  Text only, do not render just push onto return array
            #
            push @html, $data_ar;

        }
    }


    #  Return scalar ref of completed HTML string
    #
    debug('render exit, html %s', Dumper(\@html));
    return \join(undef, @html);


}


sub redirect {


    #  Redirect render to different location
    #
    my ($self, $param_hr)=@_;


    #  If not supplied param as hash ref assume all vars are params to be subs't when
    #  rendering this data block
    #
    ref($param_hr) || ($param_hr={@_[1..$#_]}) if $param_hr;


    #  Debug
    #
    debug('in redirect, param %s', Dumper($param_hr));


    #  Restore select handler before anything else so all output goes
    #  to main::STDOUT;
    #
    if (my $select=$self->{'_select'}) {
        debug("restoring select handle to $select");
        CORE::select $select;
    }


    #  If redirecting to a different uri, run its handler
    #
    if ($param_hr->{'uri'} || $param_hr->{'file'} || $param_hr->{'location'}) {


        #  Get HTML from subrequest
        #
        my $status=$self->subrequest($param_hr) ||
            return err();
        debug("redirect status was $status");


        #  GOTOs considered harmful - except here ! Speed things up significantly, removes uneeded checks
        #  for redirects in render code etc.
        #
        my $r=$self->r() || return err();
        $r->status($status);
        if (my $errstr=errstr()) {
            debug("error in subrequest: $errstr");
            return errsubst("error in subrequest: $errstr")
        }
        elsif (is_error($status)) {
            debug("sending error response status $status with r $r");
            $r->send_error_response(&Apache::OK)
        }
        elsif (($status != &Apache::OK) && !is_success($status) && !is_redirect($status)) {
            return err("unknown status code '$status' returned from subrequest");
        }
        else {
            debug("status $status OK");
        }
        goto HANDLER_COMPLETE;


    }
    else {


        #  html/text/json must be a param
        #
        my $html_sr=$param_hr->{'html'} || $param_hr->{'text'} || $param_hr->{'json'} ||
            return err('no data supplied to redirect method');


        #  Set content type
        #
        my $r=$self->r() || return err();
        if ($param_hr->{'html'}) {
            $r->content_type($WEBDYNE_CONTENT_TYPE_HTML)
        }
        elsif ($param_hr->{'text'}) {
            $r->content_type($WEBDYNE_CONTENT_TYPE_TEXT)
        }
        elsif ($param_hr->{'json'}) {
            $r->content_type($WEBDYNE_CONTENT_TYPE_JSON)
        }


        #  And length
        #
        my $headers_out_hr=$r->headers_out || return err();
        $headers_out_hr->{'Content-Length'}=length(ref($html_sr) ? ${$html_sr} : $html_sr);


        #  Set status, send header
        #
        $r->status(RC_OK);
        $r->send_http_header() if !$MP2;


        #  Print directly and shorcut return from render routine with non-harmful GOTO ! Should
        #  always be SR, but be generous.
        #
        $r->print(ref($html_sr) ? ${$html_sr} : $html_sr);
        goto RENDER_COMPLETE;


    }


}


sub subrequest {


    #  Redirect render to different location
    #
    my ($self, $param_hr)=@_;


    #  Debug
    #
    debug('in subrequest %s', Dumper($param_hr));


    #  Get request object, var for subrequest object
    #
    my ($r, $cgi_or)=map {$self->$_() || return err("unable to run '$_' method")} qw(request CGI);
    my $r_child;


    #  Run taks appropriate for subrequest - location redirects with 302, uri does sinternal redirect,
    #  and file sends content of file.
    #
    if (my $location=$param_hr->{'location'}) {


        #  Does the request handler take care of it ?
        #
        if (UNIVERSAL::can($r, 'redirect')) {


            #  Let the request handler take care of it
            #
            debug('handler does redirect, handing off');
            $r->redirect($location);    # no return value
            return RC_FOUND;

        }
        else {


            #  Must do it ourselves
            #
            debug('doing redirect ourselves');
            my $headers_out_hr=$r->headers_out || return err();
            $headers_out_hr->{'Location'}=$location;
            $r->status(RC_FOUND);
            $r->send_http_header if !$MP2;
            return RC_FOUND;

        }
    }
    if (my $uri=$param_hr->{'uri'}) {

        #  Handle internally if possible
        #
        if (UNIVERSAL::can($r, 'internal_redirect')) {


            #  Let the request handler take care of it
            #
            debug('handler does internal_redirect, handing off');
            $r->internal_redirect($uri);    # no return value
            return $r->status;

        }
        else {

            #  Must do it ourselves
            #
            $r_child=$r->lookup_uri($uri) ||
                return err('undefined lookup_uri error');
            debug('r_child handler %s', $r->handler());
            $r->headers_out($r_child->headers_out());
            $r->uri($uri);

        }


    }
    elsif (my $file=$param_hr->{'file'}) {

        #  Get cwd, make request absolute rel to cwd if no dir given.
        #
        my $dn=(File::Spec->splitpath($r->filename()))[1];
        my $file_pn=File::Spec->rel2abs($file, $dn);


        #  Get a new request object
        #
        $r_child=$r->lookup_file($file_pn) ||
            return err('undefined lookup_file error');
        $r->headers_out($r_child->headers_out());

    }
    else {


        #  Must be one or other
        #
        return err('must specify file, uri or locations for subrequest');

    }


    #  Save child object, else cleanup handlers will be run when
    #  we exit and r_child is destroyed, but before r (main) is
    #  complete.
    #
    #  UPDATE no longer needed, leave here as reminder though ..
    #
    #push @{$self->{'_r_child'}},$r_child;


    #  Safty check after calling getting r_child - should always be
    #  OK, but do sanity check.
    #
    my $status=$r_child->status();
    debug("r_child status return: $status");
    if (($status && !is_success($status)) || (my $errstr=errstr())) {
        if ($errstr) {
            return errsubst(
                "error in status phase of subrequest to '%s': $errstr",
                $r_child->uri() || $param_hr->{'file'}
            )
        }
        else {
            return err(
                "error in status phase of subrequest to '%s', return status was $status",
                $r_child->uri() || $param_hr->{'file'}
            )
        }
    }


    #  Debug
    #
    debug('cgi param %s', Dumper($param_hr->{'param'}));


    #  Set up CGI with any new params
    #
    while (my ($param, $value)=each %{$param_hr->{'param'}}) {


        #  Add to CGI
        #
        $cgi_or->param($param, $value);
        debug("set cgi param $param, value $value");


    }


    #  Debug
    #
    debug("about to call child handler with params self $self %s", Dumper($param_hr->{'param'}));


    #  Change of plan - used to check result, but now pass back whatever the child returns - we
    #  will let Apache handle any errors internally
    #
    defined($status=(ref($r_child)=~/^WebDyne::/) ? $r_child->run($self) : $r_child->run()) ||
        return err();
    debug("r_child run return status $status, rc_child status %s", $r_child->status());
    return $status || $r_child->status();


}


sub eof {

    goto HANDLER_COMPLETE;

}


sub erase_block {

    #  Erase a block section so not rendered if encountered again
    #
    my ($self, $param_hr)=@_;


    #  Has user only given name as param
    #
    ref($param_hr) || ($param_hr={name => $param_hr, param => {@_[2..$#_]}});


    #  Get block name
    #
    my $name=$param_hr->{'name'} || $param_hr->{'block'} ||
        return err('no block name specified');
    debug("in erase_block, name $name");
    delete $self->{'_block_param'}{$name};
    delete $self->{'_block_render'}{$name}

}


sub unrender_block {

    #  Synonym for erase_block
    #
    return shift()->erase_block(@_);

}


sub render_block {


    #  Render a <block> section of HTML
    #
    my ($self, $param_hr)=@_;


    #  Has user only given name as param
    #
    ref($param_hr) || ($param_hr={name => $param_hr, param => {@_[2..$#_]}});


    #  Get block name
    #
    my $name=$param_hr->{'name'} || $param_hr->{'block'} ||
        return err('no block name specified');
    debug("in render_block, name $name");


    #  Get current data block
    #
    #my $data_ar=$self->{'_perl'}[0] ||
    #return err("unable to get current data node");
    my $data_ar=$self->{'_perl'}[0] || do {

        #if ($WEBDYNE_DELAYED_BLOCK_RENDER) {
        push @{$self->{'_block_param'}{$name} ||= []}, $param_hr->{'param'};    # if $WEBDYNE_DELAYED_BLOCK_RENDER;
        return \undef;

        #}
        #else {
        #  return err("unable to get current data node")
        #}
    };


    #  Find block name
    #
    my @data_block_ar;


    #  Debug
    #
    debug("render_block self $self, name $name, data_ar $data_ar, %s", Dumper($data_ar));


    #  Have we seen this search befor ?
    #
    unless (exists($self->{'_block_cache'}{$name})) {


        #  No, search for block
        #
        debug("searching for node $name in data_ar");


        #  Do it
        #
        my $data_block_all_ar=$self->find_node(
            {

                data_ar => $data_ar,
                tag     => 'block',
                all_fg  => 1,

            }) || return err();


        #  Debug
        #
        debug('find_node returned %s', join('*', @{$data_block_all_ar}));


        #  Go through each block found and svae in block_cache
        #
        foreach my $data_block_ar (@{$data_block_all_ar}) {


            #  Get block name
            #
            my $name=$data_block_ar->[WEBDYNE_NODE_ATTR_IX]->{'name'};
            debug("looking at block $data_block_ar, name $name");


            #  Save
            #
            #$self->{'_block_cache'}{$name}=$data_block_ar;
            push @{$self->{'_block_cache'}{$name} ||= []}, $data_block_ar;


        }


        #  Done, store
        #
        @data_block_ar=@{$self->{'_block_cache'}{$name}};


    }
    else {


        #  Yes, set data_block_ar to whatever we saw before, even if it is
        #  undef
        #
        @data_block_ar=@{$self->{'_block_cache'}{$name}};


        #  Debug
        #
        debug("retrieved data_block_ar @data_block_ar for node $name from cache");


    }


    #  Debug
    #
    #debug("set block node to $data_block_ar %s", Dumper($data_block_ar));


    #  Store params for later block render (outside perl block) if needed
    #
    push @{$self->{'_block_param'}{$name} ||= []}, $param_hr->{'param'};    # if $WEBDYNE_DELAYED_BLOCK_RENDER;


    #  No data_block_ar ? Could not find block - remove this line if global block
    #  rendering is desired (ie blocks may lay outside perl code calling render_bloc())
    #
    unless (@data_block_ar) {

        #if ($WEBDYNE_DELAYED_BLOCK_RENDER) {
        return \undef;

        #}
        #else {
        #  return err("could not find block '$name' to render") unless $WEBDYNE_DELAYED_BLOCK_RENDER;
        #}
    }


    #  Now, was it set to something ?
    #
    my @html_sr;
    foreach my $data_block_ar (@data_block_ar) {


        #  Debug
        #
        debug("rendering block name $name, data $data_ar with param %s", Dumper($param_hr->{'param'}));


        #  Yes, Get HTML for block immedialtly
        #
        my $html_sr=$self->render(
            {

                data  => $data_block_ar->[WEBDYNE_NODE_CHLD_IX],
                param => $param_hr->{'param'},

            }) || return err();


        #  Debug
        #
        debug("block $name rendered HTML $html_sr %s, pushing onto name $name, data_ar $data_block_ar", ${$html_sr});


        #  Store away for this block
        #
        push @{$self->{'_block_render'}{$name}{$data_block_ar} ||= []}, $html_sr;


        #  Store
        #
        push @html_sr, $html_sr;


    }
    if (@html_sr) {


        #  Return scalar or array ref, depending on number of elements
        #
        #debug('returning %s', Dumper(\@html_sr));
        return $#html_sr ? $html_sr[0] : \@html_sr;

    }
    else {


        #  No, could not find block below us, store param away for later
        #  render. NOTE now done for all blocks so work both in and out of
        #  <perl> section. Moved this code above
        #
        #push @{$self->{'_block_param'}{$name} ||=[]},$param_hr->{'param'};


        #  Debug
        #
        debug("block $name not found in tree, storing params for later render");


        #  Done, return undef at this stage
        #
        return \undef;

    }


}


sub block {


    #  Called when we encounter a <block> tag
    #
    my ($self, $data_ar, $attr_hr, $param_data_hr, $text)=@_;
    debug("in block code, data_ar $data_ar");


    #  Get block name
    #
    my $name=$attr_hr->{'name'} ||
        return err('no block name specified');
    debug("in block, looking for name $name, attr given %s", Dumper($attr_hr));


    #  Only render if registered, do once for every time spec'd
    #
    if (exists($self->{'_block_render'}{$name}{$data_ar})) {


        #  The block name has been pre-rendered - return it
        #
        debug("found pre-rendered block $name");


        #  Var to hold render result
        #
        my $html_ar=delete $self->{'_block_render'}{$name}{$data_ar};


        #  Return result as a single scalar ref
        #
        return \join(undef, map {${$_}} @{$html_ar});


    }
    elsif (exists($self->{'_block_param'}{$name})) {


        #  The block params have been registered, but the block itself was
        #  not yet rendered. Do it now
        #
        debug("found block param for $name in register");


        #  Var to hold render result
        #
        my @html_sr;


        #  Render the block for as many times as it has parameters associated
        #  with it, eg user may have called ->render_block several times in
        #  their code
        #
        foreach my $param_data_block_hr (@{$self->{'_block_param'}{$name}}) {


            #  If no explicit data hash, use parent hash - not sure how useful
            #  this really is
            #
            $param_data_block_hr ||= $param_data_hr;


            #  Debug
            #
            debug("about to render block $name, param %s", Dumper($param_data_block_hr));


            #  Render it
            #
            push @html_sr, $self->render(
                {

                    data  => $data_ar->[WEBDYNE_NODE_CHLD_IX],
                    param => $param_data_block_hr

                }) || return err();

        }


        #  Return result as a single scalar ref
        #
        return \join(undef, map {${$_}} @html_sr);

    }
    elsif ($attr_hr->{'display'}) {


        #  User wants block displayed normally
        #
        return $self->render(
            {

                data  => $data_ar->[WEBDYNE_NODE_CHLD_IX],
                param => $param_data_hr

            }) || err();

    }
    else {


        #  Block name not registered, therefore do not render - return
        #  blank
        #
        return \undef;

    }


}


sub json {


    #  Called when we encounter a <json> tag
    #
    my ($self, $data_ar, $attr_hr, $param_data_hr, $text)=@_;
    debug("$self rendering json tag in block $data_ar, attr %s", $attr_hr);


    #  Check we have a handler
    #
    $attr_hr->{'handler'} ||
        return err('no json tag perl handler supplied');


    #  Run the code in perl routine specifying it is JSON, get return ref of
    #  some kind
    #
    my $json_xr=$self->perl(undef, {json => 1, %{$attr_hr}}) ||
        return err();
    debug("json_xr %s", Dumper($json_xr));


    #  Convert to JSON
    #
    my $json_or=JSON->new() ||
        return err('unable to create new JSON object');
    debug("json_or: $json_or");
    $json_or->canonical(defined($attr_hr->{'canonical'}) ? $attr_hr->{'canonical'} : $WEBDYNE_JSON_CANONICAL);
    my $json=eval {$json_or->encode($json_xr)} ||
        return err('error %s on json_encode of %s', $@, Dumper($json_xr));
    debug("json %s", Dumper($json));


    #  Get new WebDyne::HTML::Tiny object ready to encode result into <script> tag
    #
    my $html_or=$self->html_tiny() ||
        return err();
    my %attr=(
        type => 'application/json',
        %{$attr_hr}
    );
    delete @attr{qw(package method handler)};


    #  Render and return
    #
    my $html=$html_or->script(\%attr, $json);
    debug("generated HTML: $html");
    return \$html

}


sub htmx {


    #  Called when we encounter a <htmx> tag
    #
    my ($self, $data_ar, $attr_hr)=@_;
    debug("$self rendering htmx tag, data_ar: $data_ar, attr_hr: %s", Dumper($attr_hr));
    
    
    #  Get the request headers to look for a 'HX-Request' flag
    #
    my $r=$self->r() ||
        return err('unable to get request handler !');
    my $hx_request=$r->headers_in->{'hx-request'};
    debug("hx_request header: $hx_request");
    
    
    #  Check if we want to fire on match
    #
    if (exists ($attr_hr->{'display'})) {
        unless ($attr_hr->{'display'}) {
            #  Defined but no match. Bail
            #
            return \undef;
        }
    }


    #  Check we have a handler
    #
    my $html_sr;
    if (my $handler=$attr_hr->{'handler'}) {
    
    
        #  Return whatever HTML we get back
        #
        debug("htmx rendering with handler $handler");
        $html_sr=$self->perl($data_ar, $attr_hr) ||
            return err();
        debug("html_sr: $html_sr");
        
    }
    else {
    
        #  No handler, just render
        #
        debug('htmx render without handler');
        $html_sr=$self->render({ data=> $data_ar->[$WEBDYNE_NODE_CHLD_IX] }) ||
            return err();
        debug("html_sr: $html_sr");
        
    }
    
    
    #  Done
    #
    if ($hx_request) {

        #  Return fragment only
        #
        debug('returning htmx tag as html fragment only');
        return $self->redirect( html=>$html_sr );
        
    }
    else {
    
        #  Continue render and return whole page
        #
        debug('returning normal render of htmx tag into page');
        return $html_sr;
        
    }
    
}


sub api {


    #  Called when we encounter a <api> tag
    #
    my ($self, $data_ar, $attr_hr)=@_;
    debug("$self rendering api tag in block $data_ar, attr %s", $attr_hr);
    
    
    #  Need Router::Simple. Build params needed allowing for synonyms
    #
    require Router::Simple;
    my $rest_or=$self->{'_rest_or'} ||= Router::Simple->new();
    my @route=(grep {$_}
        @{$attr_hr}{qw(name method handler pattern match data dest destination)}
    );
    $route[2] ||= undef;
    my @option=(grep ${_},
        @{$attr_hr}{qw(option options constraint constraints)}
    );
    debug('route param: %s, %s', Dumper(\@route, \@option));
    $rest_or->connect(@route, $option[0]);
    
    
    #  Now look for match. Set PATH_INFO to '' if not exists to stop warning
    #
    $ENV{'PATH_INFO'} ||= '';
    
    
    #  And match
    #
    if (my $match_hr=$rest_or->match(\%ENV)) {
    

        #  We have a match
        #
        debug('route match: %s', Dumper(match_hr));


        #  Run the code in perl routine specifying it is JSON, get return ref of
        #  some kind
        #
        my $json_xr=$self->perl(undef, {json => 1, %{$attr_hr}, param=>$match_hr }) ||
            return err();
        debug("json_xr %s", Dumper($json_xr));


        #  Convert to JSON
        #
        my $json_or=JSON->new() ||
            return err('unable to create new JSON object');
        debug("json_or: $json_or");
        $json_or->canonical(defined($attr_hr->{'canonical'}) ? $attr_hr->{'canonical'} : $WEBDYNE_JSON_CANONICAL);
        my $json=eval {$json_or->encode($json_xr)} ||
            return err('error %s on json_encode of %s', $@, Dumper($json_xr));
        debug("json %s", Dumper($json));
        
        
        #  Return as JSON data only
        #
        return $self->redirect( json => $json );
        
    }
    else {
    
        #  No match
        #
        debug('no match');
        return \undef;
        
    }
    
}


sub perl {


    #  Called when we encounter a <perl> tag
    #
    my ($self, $data_ar, $attr_hr, $param_data_hr, $text)=@_;
    debug("$self rendering perl tag in block $data_ar, attr %s", Dumper($attr_hr));


    #  Add current working directory to @INC for any use or require commands
    #  in perl code
    #
    local @INC=@INC;
    push @INC, $self->cwd();


    #  HTML scalar ref to return, starts out empty
    #
    my $html_sr=\undef;

    #  Get current inode
    #
    my $inode=$self->{'_inode'} || 'ANON';


    #  Load any modules spec'd by require attribute
    #
    if (my $require_fn=$attr_hr->{'require'}) {

        #  Eval string to build
        #
        debug("about to require $require_fn");
        $self->eval_require($require_fn, $attr_hr) ||
            return err();

    }


    #  If inline, run now
    #
    if (my $perl_code=$attr_hr->{'perl'}) {


        #  May be inline code params to supply to this block
        #
        my $perl_param_hr=$attr_hr->{'param'} || $self->{'_perl_data'}[0];
        debug("found inline perl code %s, param %s", Dumper(\$perl_code, $perl_param_hr));


        #  Run the same code as the inline eval (!{! ... !}) would run,
        #  for consistancy
        #
        $html_sr=$Package{'_eval_cr'}{'!'}->($self, $data_ar, $perl_param_hr, $perl_code) ||
            err();


    }
    elsif (grep {$attr_hr->{$_}} qw(package method handler)) {


        #  Not inline, must want to call a handler, get method and caller. package synonym for class, method for handler
        #
        my $function=join('::', grep {$_} map {exists($attr_hr->{$_}) && $attr_hr->{$_}} qw(package method handler)) ||
            return err('could not determine perl routine to run');
        debug("found call to perl function: $function");


        #  Try to get the package name as an array, pop the method off
        #
        my @package=split(/\:+/, $function);
        my $method=pop @package;


        #  And return package
        #
        my $package=join('::', grep {$_} @package);


        #  Debug
        #
        debug("perl package: $package, method $method");


        #  If no method by now, dud caller
        #
        $method ||
            return err("no handler found in perl tag");


        #  Need to load a package
        #
        if ($package) {
            debug("about to require $package");
            $self->eval_require($package, $attr_hr) ||
                return err()
        }

        #  Push data_ar so we can use it if the perl routine calls self->render(). render()
        #  then has to "know" where it is in the data_ar structure, and can get that info
        #  here.
        #
        #unshift @{$self->{'_perl'}}, $data_ar->[$WEBDYNE_NODE_CHLD_IX];
        unshift @{$self->{'_perl'}}, $data_ar;
        debug("unshift $data_ar onto perl stack, stack:%s", join('*', @{$self->{'_perl'}}));


        #  Contruct subroutine call
        #
        unless ($function=~/::/) {
            $function="WebDyne::${inode}::${function}"
        }
        debug("about to eval $function");


        #  Run the eval code to get HTML
        #
        $html_sr=$Package{'_eval_cr'}{'!'}->($self, $data_ar, $attr_hr->{'param'}, "&${function}") || do {


            #  Error occurred. Pop data ref off stack and return
            #
            debug("error occured on eval, passing to error handler, $@");
            shift @{$self->{'_perl'}};
            debug("shift off perl stack, stack:%s", join('*', @{$self->{'_perl'}}));
            return err();


        };


        #  Debug
        #
        debug('perl eval return %s', Dumper($html_sr));


        #  Return if we want the data for a JSON tag (above)
        #
        debug('attr: %s', Dumper($attr_hr));
        if (!$attr_hr->{'json'}) {
            if ((my $ref=ref($html_sr)) eq 'HASH') {

                #  Render with HASH ref supplied.
                #
                debug('HASH ref detected, rendering');
                $html_sr=$self->render(%{$html_sr}) ||
                    return err();

            }
            elsif ($ref ne 'SCALAR') {

                # If not JSON or HASH ref should be scalar. If not error
                #
                return err("error in perl method '$method'- code did not return a SCALAR ref value.");
            }

        }
        else {
            debug('returning json data');
        }


        #  If get to here shift perl data_ar ref from stack
        #
        debug("shift off perl stack, stack:%s", join('*', @{$self->{'_perl'}}));
        shift @{$self->{'_perl'}};

    }

    return $attr_hr->{'hidden'} ? \undef : $html_sr;

}


sub eval_require {


    #  Code to require or load a module
    #
    my ($self, $require_fn, $attr_hr)=@_;


    #  Inode ?
    #
    my $inode=$self->{'_inode'} || 'ANON';


    #  Eval cr
    #
    my $eval_cr=sub {

        local $SIG{__DIE__};
        eval {} if $@;    #Clear $@;
        my $ret=eval(shift());
        if ($@) {
            my $err=$@; eval {};
            return err("attempt to load $require_fn returned error $err");
        }
        elsif (!$ret) {
            return err("eval of '$require_fn' did not return a true value");
        }
        return $ret

    };


    #  File or module ? Try via syntax, allow force with 'file' attribute
    #
    if ($require_fn=~m([./\\]) || $attr_hr->{'file'}) {


        #  File contains a '.', '/' or '\'. Probably a file. Convert to full path
        #
        debug("found perl require command for: $require_fn, interpreting as local file");
        my $require_cn=$self->rel2abs($require_fn);
        debug("converted to full path $require_fn");


        #  Need to load a file. Delete from INC so forced to reload in this inode package space;
        #
        delete $INC{$require_cn};
        my $eval=sprintf(q[package WebDyne::%s; require '%s'], $inode, $require_cn);
        return $eval_cr->($eval) ||
            err();


    }
    else {

        #  Probably a module as no match above
        #
        debug("found perl require command for $require_fn, interpreting as module with import: %s", Dumper($attr_hr->{'import'}));


        #  Do any imports now
        #
        my @import;
        if (ref($attr_hr->{'import'}) eq 'ARRAY') {
            @import=@{$attr_hr->{'import'}}
        }
        else {
            @import=split(/\s+/, $attr_hr->{'import'});
        }
        debug("about to import functions: %s into inode:$inode", Dumper(\@import));


        #  This only works for modules
        #
        map {*{"WebDyne::${inode}::$_"}=\&{"${require_fn}::$_"}} grep {$_} @import;


        #  Check if already loaded ?
        #
        my @package=split(/\:+/, $require_fn);


        #  And return package
        #
        my $package_fn=join('/', @package) . '.pm';
        if ($INC{$package_fn}) {

            #  Already loaded
            #
            debug('package %s already loaded in %%INC', $package_fn);
            return 1;

        }
        else {

            my $eval="require $require_fn";
            return $eval_cr->($eval) ||
                err();

        }


    }

}


sub eval_cr {


    #  Return eval subroutine ref for inode ($_[0]) and eval code ref ($_[1]). Avoid using
    #  var names so not available in eval code
    #
    #eval("package WebDyne::$_[0]; $WebDyne::WEBDYNE_EVAL_USE_STRICT;\n" . "#line $_[2]\n" . "sub{${$_[1]}\n}");
    my $eval=join(
        $/,
        "package WebDyne::$_[0]; $WebDyne::WEBDYNE_EVAL_USE_STRICT;",
        "#line $_[2] WebDyne::$_[0]",
        "sub{${$_[1]}}"
    );
    return eval($eval);


}


sub perl_init_eval {


    #  Eval routine for perl_init code. Avoid using var names so things like $self not available
    #  in eval code;
    #local $SIG{__DIE__};
    my $eval=join(
        $/,
        "package WebDyne::$_[0]; $WebDyne::WEBDYNE_EVAL_USE_STRICT;",
        "#line $_[2] WebDyne::$_[0]",
        "${$_[1]}",
        ';1'
    );
    return eval($eval);

}


sub perl_init {


    #  Init the perl package space for this inode
    #
    my ($self, $perl_ar, $perl_debug_ar)=@_;
    my $inode=$self->{'_inode'} || 'ANON';    #ANON used when run from command line


    #  Prep package space
    #
    debug("$self init perl code $perl_ar in $inode, %s", Dumper($perl_ar));
    *{"WebDyne::${inode}::err"}=\&err;
    *{"WebDyne::${inode}::self"}=sub {$self};
    *{"WebDyne::${inode}::AUTOLOAD"}=sub {die("unknown function $AUTOLOAD")};


    #  Run each piece of perl code
    #
    foreach my $ix (0..$#{$perl_ar}) {


        #  Get perl code and debug information
        #
        my $perl_sr=$perl_ar->[$ix];
        my ($perl_line_no, $perl_srce_fn)=@{$perl_debug_ar->[$ix]};
        debug("about to run $perl_sr at line:$perl_line_no from fn:$perl_srce_fn");


        #  Do not execute twice
        #
        debug('execution current count is: %s', $Package{'_cache'}{$inode}{'perl_init'}{$perl_sr} ||= 0);
        $Package{'_cache'}{$inode}{'perl_init'}{$perl_sr}++ && next;


        #  Set inc to include psp dir so can include packages easily
        #
        local @INC=@INC;
        push @INC, $self->cwd();


        #  Error handler
        #
        my $error_cr=sub {

            #  An error has occurred. Deregister self subroutine call in package
            #
            #undef *{"WebDyne::${inode}::self"};


            #  Make up a fake data block with details of error
            #
            my @data;
            @data[
                WEBDYNE_NODE_LINE_IX,
                WEBDYNE_NODE_LINE_TAG_END_IX,
                WEBDYNE_NODE_SRCE_IX,
            ]=($perl_line_no, $perl_line_no, $perl_srce_fn);


            #  Save away as current data block for reference by error handler
            #
            push @{$self->{'_data_ar'}}, \@data;

        };


        #  Var for eval return value
        #
        my $ret;


        #  Wrap in anon CR, eval for syntax
        #
        if ($WEBDYNE_EVAL_SAFE) {


            #  Safe mode, vars don't matter so much
            #
            my $safe_or=$self->{'_eval_safe'} || do {
                debug('safe init (perl_init)');
                require Safe;
                require Opcode;

                #Safe->new($self->{'_inode'});
                Safe->new();
            };
            $self->{'_eval_safe'} ||= do {
                $safe_or->permit_only(@{$WEBDYNE_EVAL_SAFE_OPCODE_AR});
                $safe_or;
            };


            #  Run safe eval
            #
            $ret=$safe_or->reval(${$perl_sr}, $WebDyne::WEBDYNE_EVAL_USE_STRICT);


        }
        else {


            #  Now run eval after getting eval string;
            #
            debug("running perl_init_eval on $perl_sr now, line $perl_line_no");
            $ret=&perl_init_eval($inode, $perl_sr, $perl_line_no);

        }


        #  Check for errors
        #
        if (my $err=($@ || errstr())) {
            $error_cr->();
            eval {};    #Clear $@
            return $self->err_eval("error in __PERL__block: $err", $perl_sr, $inode);
        }
        elsif (!$ret) {
            $error_cr->();
            return err("eval of perl_init did not return a true value");
        }

    }


    #  Done. Undef self ref sub but leave error handler and autoload
    #
    undef *{"WebDyne::${inode}::self"};
    debug('perl_init complete');
    return \undef;

}


sub subst {


    #  Called to eval text block, replace params
    #
    my ($self, $data_ar, $attr_hr, $param_data_hr, $text)=@_;


    #  Debug
    #
    debug("eval $text %s", Dumper($param_data_hr));


    #  Get eval code refs for subst
    #
    my $eval_cr=$Package{'_eval_cr'} ||
        return err('unable to get eval code ref table');


    #  Do we have to replace something in the text, look for pattern. We
    #  should always find something, as subst tag is only inserted at
    #  compile time in front of text with one of theses patterns
    #
    my $index;
    my $cr=sub {
        my $sr=$eval_cr->{$_[0]}($self, $data_ar, $param_data_hr, $_[1], $_[2]) ||
            return err();
        (ref($sr) eq 'SCALAR') ||
            return err("eval of '$_[1]' returned %s ref, should return SCALAR ref", ref($sr));
        $sr;
    };
    $text=~s/([\$!+*^])\{(\1?)(.*?)\2}/${$cr->($1, $3, $index++) || return err()}/ge;


    #  Done
    #
    debug("return *$text*");
    return \$text;


}


sub subst_attr {


    #  Called to eval tag attributes
    #
    my ($self, $data_ar, $attr_hr, $param_hr)=@_;


    #  Debug
    #
    debug('subst_attr %s', Dumper({%{$attr_hr}, perl => undef}));


    #  Get eval code refs for subst
    #
    my $eval_cr=$Package{'_eval_cr'} ||
        return err('unable to get eval code ref table');


    #  Hash to hold results
    #
    my %attr=%{$attr_hr};


    #  Go through each attribute and value. *MUST BE DETERMINISTIC AND IN SAME ORDER EACH RUN*. If not the eval cached using
    #  $index may change ! So don't use while.
    #
    #  Actually can use while - but have to use attribute name as index so always deterministic
    #
    #my $index;
    #foreach my $attr_name (sort keys %attr) {
    while (my ($attr_name, $attr_value)=each %attr) {


        #  Get value
        #
        #my $attr_value=$attr{$attr_name};


        #  Skip perl attr, as that is perl code, do not do any regexp on perl code, as we will
        #  probably botch it.
        #
        debug("subst_attr $attr_name: $attr_value");
        next if ($attr_name eq 'perl');


        #  Look for attribute value strings that need substitution. First and second attemps did'nt work as single regexp
        #
        if ($attr_value=~/^\s*([\@%!+*^])\{(\1?)(.*)\2}\s*$/so || $attr_value=~/^\s*(\$)\{(\1?)([^{]+)\2}\s*$/so) {

            #  Straightforward $@%!+^ operator, must be only content of value (can't be mixed
            #  with string, e.g. <popup_list values="foo=@{qw(bar)}" dont make sense
            #
            my ($oper, $eval_text)=($1, $3);
            debug("subst_attr $attr_name path 1: oper:$oper, eval_text: $eval_text");

            #my $eval=$eval_cr->{$oper}->($self, $data_ar, $param_hr, $eval_text, $index++, 1) ||
            my $eval=$eval_cr->{$oper}->($self, $data_ar, $param_hr, $eval_text, $attr_name, 1) ||
                return err();
            $attr{$attr_name}=(ref($eval) eq 'SCALAR') ? ${$eval} : $eval;

        }
        else {

            #  Trickier - might be interspersed in strings, e.g <submit name="foo=1&${bar}=2&car=${dar}"/>
            #  Substitution needed
            #
            debug("subst_attr path 2: $attr_name, $attr_value");
            my $cr=sub {
                my $sr=$eval_cr->{$_[0]}($self, $data_ar, $param_hr, $_[1], $_[2]) ||
                    return err();
                (ref($sr) eq 'SCALAR') ||
                    return err("eval of '$_[1]' returned %s ref, should return SCALAR ref", ref($sr));
                $sr;
            };

            #$attr_value=~s/([\$!+*^]){1}{(\1?)(.*?)\2}/${$cr->($1,$3,$index++) || return err()}/ge;
            $attr_value=~s/([\$!+*^]){1}{(\1?)(.*?)\2}/${$cr->($1,$3,$attr_name) || return err()}/ge;
            $attr{$attr_name}=$attr_value;

        }

    }


    #  Debug
    #
    debug('returning attr hash %s', Dumper({%attr, perl => undef}));


    #  Return new attribute hash
    #
    \%attr;

}


sub include {


    #  Called to include text/psp block. Can be called from <include> tag or
    #  perl code, so need to massage params appropriatly.
    #
    my $self=shift();
    my ($data_ar, $param_hr, $param_data_hr, $text);


    #  Normally get:
    #
    #  my ($self, $data_ar, $attr_hr, $param_data_hr, $text)=@_;
    #
    #  from tag, but in this case param_hr subs for attr_hr because
    #  we use that for code called from perl. Check what called us
    #  now - if first param (after self) is array ref, called from
    #  tag
    #
    if (ref($_[0]) eq 'ARRAY') {

        #  Called from <include> tag
        #
        ($data_ar, $param_hr, $param_data_hr, $text)=@_;
    }
    else {

        #  Called from perl code, massage params into hr if not already there
        #
        $param_hr=shift();
        ref($param_hr) || ($param_hr={file => $param_hr, param => {@_}});

    }


    #  Debug
    #
    debug('in include, param %s, %s', Dumper($param_hr, $param_data_hr));


    #  Get CWD
    #
    my $r=$self->r() || return err();
    #my $dn=(File::Spec->splitpath($r->filename()))[1] ||
    my $dn=$self->cwd() ||
        return err('unable to determine cwd for requested file %s', $r->filename());
    debug("dn: $dn");


    #  Any param must supply a file name as an attribute
    #
    my $fn=$param_hr->{'file'} ||
        return err('no file name supplied with include tag');
    my $pn=File::Spec->rel2abs($fn, $dn);


    #  Check what user wants to do
    #
    if (my $node=(grep {exists $param_hr->{$_}} qw(head body))[0]) {


        #  They want to include the head or body section of an existing pure HTML
        #  file.
        #
        debug('head or body render');
        my %option=(

            nofilter => 1,
            noperl   => 1,
            stage0   => 1,
            srce     => $pn,
            
            #  Note this - don't want implicit <p> tags for included files at body start,
            #  i.e. <body><p>Some Text in included file may end up as <body><p><p> in initiator file 
            implicit_body_p_tag => 0,

        );
        
        
        #  Bring in WebDyne::Compile - going to need it
        #
        eval {require WebDyne::Compile}
            || return $self->err_html(
            errsubst('unable to load WebDyne:Compile, %s', $@ || 'undefined error'));
        

        #  compile spec'd file
        #
        my $container_ar=$self->compile(\%option) ||
            return err();
        my $block_data_ar=$container_ar->[1];
        debug('compiled to data_ar %s', Dumper($block_data_ar));

        #  Find the head or body tag
        #
        my $block_ar=$self->find_node(
            {

                data_ar => $block_data_ar,
                tag     => $node,

            }) || return err();
        @{$block_ar} ||
            return err("unable to find block '$node' in include file '$fn'");
        debug('found block_ar %s', Dumper($block_ar));


        #  Find_node returns array of blocks that match - we only want first
        #
        $block_ar=$block_ar->[0];


        #  Need to finish compiling now found
        #
        $self->optimise_one($block_ar) || return err();
        $self->optimise_two($block_ar) || return err();
        debug('optimised data now %s', Dumper($block_ar));


        #  Need to encapsulate into <block display=1> tag, so alter tag name, attr
        #
        $block_ar->[WEBDYNE_NODE_NAME_IX]='block';
        $block_ar->[WEBDYNE_NODE_ATTR_IX]={name => $node, display => 1};


        #  Incorporate into top level data so we don't have to do this again if
        #  called from tag
        #
        @{$data_ar}=@{$block_ar} if ($data_ar && !$param_hr->{'nocache'});


        #  Render included block and return after stripping <p></p>
        #
        my $html_sr=$self->render({data => $block_ar->[$WEBDYNE_NODE_CHLD_IX], param => $param_hr->{'param'}}) || 
            return err();
        return $html_sr;
        

    }
    elsif (my $block=$param_hr->{'block'}) {

        #  Wants to include a paticular block from a psp library file
        #
        debug('block render');
        my %option=(

            nofilter 	=> 1,
            #noperl     => 1,
            stage1 	=> 1,
            srce   	=> $pn,
            implicit_body_p_tag => 0,

        );


        #  Bring in WebDyne::Compile - going to need it
        #
        eval {require WebDyne::Compile}
            || return $self->err_html(
            errsubst('unable to load WebDyne:Compile, %s', $@ || 'undefined error'));


        #  compile spec'd file
        #
        my $container_ar=$self->compile(\%option) ||
            return err();
        my $block_data_ar=$container_ar->[1];
        debug('block data %s', Dumper($block_data_ar));


        #  Find the block node with name we want
        #
        debug("looking for block name $block");
        my $block_ar=$self->find_node(
            {

                data_ar => $block_data_ar,
                tag     => 'block',
                attr_hr => {name => $block},

            }) || return err();
        @{$block_ar} ||
            return err("unable to find block '$block' in include file '$fn'");
        debug('found block_ar %s', Dumper($block_ar));


        #  Find_node returns array of blocks that match - we only want first
        #
        $block_ar=$block_ar->[0];


        #  Set to attr always display
        #
        $block_ar->[$WEBDYNE_NODE_ATTR_IX]{'display'}=1;


        #  Incorporate into top level data so we don't have to do this again if
        #  called from tag
        #
        #  COMMENTED OUT FOR NOW: Doesn't work in terms of stripping <p></p> tags
        #
        @{$data_ar}=@{$block_ar} if ($data_ar && !$param_hr->{'nocache'});
        #@{$data_ar}=@{$block_ar} if $data_ar;


        #  We don't want to render <block> tags, so start at
        #  child of results [WEBDYNE_NODE_CHLD_IX].
        #
        debug('calling render');
        my $html_sr=$self->render({data => $block_ar->[$WEBDYNE_NODE_CHLD_IX], param => ($param_hr->{'param'} || $param_data_hr)}) || 
            return err();
        return $html_sr;


    }
    else {


        #  Plain vanilla file include, no mods
        #
        debug('vanilla file include');
        my $fh=IO::File->new($pn, O_RDONLY) || return err("unable to open file '$fn' for read, $!");
        local $/;
        my $html = <$fh>;
        $fh->close();
        
        
        #  Need to create fake <block> tag to hold this if want to cache
        #
        if ($data_ar && !$param_hr->{'nocache'}) {
        
            #  Yes, want to cache this file, create fake block tag and force display
            #
            my @block=('block', { name=>'file', display=>1 }, [$html], undef, 1, 1, \$pn);
            @{$data_ar}=@block;
            
        }
        
        #  And return HTML
        #
        return \$html;

    }

}


sub find_node {


    #  Find a particular node in the tree
    #
    my ($self, $param_hr)=@_;


    #  Get max depth we can descend to, zero out in params
    #
    my ($data_ar, $tag, $attr_hr, $depth_max, $prnt_fg, $all_fg)=@{$param_hr}{
        qw(data_ar tag attr_hr depth prnt_fg all_fg)
    };
    debug("find_node looking for tag $tag in data_ar $data_ar, %s", Dumper($data_ar));


    #  Array to hold results, depth
    #
    my ($depth, @node);


    #  Create recursive anon sub
    #
    my $find_cr=sub {


        #  Get params
        #
        my ($find_cr, $data_ar, $data_prnt_ar)=@_;
        debug("find_cr, data_ar $data_ar, data_prnt_ar $data_prnt_ar");


        #  Do we match at this level ?
        #
        if ((my $data_ar_tag=$data_ar->[$WEBDYNE_NODE_NAME_IX]) eq $tag) {


            #  Match for tag name, now check any attrs
            #
            my $tag_attr_hr=$data_ar->[$WEBDYNE_NODE_ATTR_IX];


            #  Debug
            #
            debug("tag '$tag' match, $data_ar_tag, checking attr %s", Dumper($tag_attr_hr));


            #  Check for match
            #
            if (
                (grep {$tag_attr_hr->{$_} eq $attr_hr->{$_}} keys %{$tag_attr_hr}) ==
                (keys %{$attr_hr})
            ) {


                #  Match, debug
                #
                debug("$data_ar_tag attr match, saving");


                #  Tag name and attribs match, push onto node
                #
                push @node, $prnt_fg ? $data_prnt_ar : $data_ar;
                return $node[0] unless $all_fg;


            }

        }
        else {

            debug("mismatch on tag $data_ar_tag for tag '$tag'");

        }


        #  Return if out of depth
        #
        return if ($depth_max && (++$depth > $depth_max));


        #  Start looking through current node
        #
        my @data_child_ar=$data_ar->[$WEBDYNE_NODE_CHLD_IX] ? @{$data_ar->[$WEBDYNE_NODE_CHLD_IX]} : undef;
        foreach my $data_child_ar (@data_child_ar) {


            #  Only check and/or recurse through children that are child nodes, (ie
            #  are refs), ignor non-ref (text) nodes
            #
            ref($data_child_ar) && do {


                #  We have a ref, recurse look for match
                #
                if (my $data_match_ar=$find_cr->($find_cr, $data_child_ar, $data_ar)) {


                    #  Found match during recursion, return
                    #
                    return $data_match_ar unless $all_fg;

                }

            }

        }

    };


    #  Start it running with our top node
    #
    $find_cr->($find_cr, $data_ar);


    #  Debug
    #
    debug('find complete, return node %s', \@node);


    #  Return results
    #
    return \@node;

}


sub delete_node {


    #  Delete a particular node from the tree
    #
    my ($self, $param_hr)=@_;


    #  Get max depth we can descend to, zero out in params
    #
    my ($data_ar, $node_ar)=@{$param_hr}{qw(data_ar node_ar)};
    debug("delete node $node_ar starting from data_ar $data_ar");


    #  Create recursive anon sub
    #
    my $find_cr=sub {


        #  Get params
        #
        my ($find_cr, $data_ar)=@_;


        #  Iterate through child nodes
        #
        foreach my $data_chld_ix (0..$#{$data_ar->[$WEBDYNE_NODE_CHLD_IX]}) {

            my $data_chld_ar=$data_ar->[$WEBDYNE_NODE_CHLD_IX][$data_chld_ix] ||
                return err("unable to get chld node from $data_ar");
            debug("looking at chld node $data_chld_ar");

            if ($data_chld_ar eq $node_ar) {

                #  Found node we want to delete. Get rid of it, all done
                #
                debug("match - splicing at chld $data_chld_ix from array %s", Dumper($data_ar));
                splice(@{$data_ar->[$WEBDYNE_NODE_CHLD_IX]}, $data_chld_ix, 1);
                return \1;

            }
            else {


                #  Not target node - recurse
                #
                debug("no match - recursing to chld $data_chld_ar");
                ${$find_cr->($find_cr, $data_chld_ar) || return err()} &&
                    return \1;

            }
        }


        #  All done, but no cigar
        #
        return \undef;

    };


    #  Start
    #
    return $find_cr->($find_cr, $data_ar) || err()

}


sub CGI {


    #  Return CGI::Simple object
    #
    my $self=shift();
    debug("$self get CGI::Simple object");


    #  Accessor method for CGI::Simple object
    #
    return $self->{'_CGI'} ||= do {


        #  CGI good practice
        #
        $CGI::Simple::DISABLE_UPLOADS=$WEBDYNE_CGI_DISABLE_UPLOADS;
        $CGI::Simple::POST_MAX=$WEBDYNE_CGI_POST_MAX;


        #  And create it. CGI::Simple looks for mod_perl in an eval
        #  block and we don't want to trigger an error so be careful
        #
        local $SIG{'__DIE__'}=sub {};
        my $cgi_or=CGI::Simple->new($MOD_PERL && $self->{'_r'});
        eval {} if $@; # May leave $@ set on init;
        #my $cgi_or=CGI::Simple->new(); # Needs PerlOpt +GlobalRequest
        #$cgi_or->delete(ref($self->{'_r'})) # Pretty crappy way of doing it


        #  Expand params if we need to
        #
        &CGI_param_expand($cgi_or) if $WEBDYNE_CGI_PARAM_EXPAND;


        #  Return new CGI object
        #
        $cgi_or;

    };

}


sub html_tiny {


    my $self=shift();
    debug("$self get HTML::Tiny object");
    return ($self->{'_html_tiny_or'} ||= WebDyne::HTML::Tiny->new(mode => 'html', @_)) ||
        err('unable to instantiate new WebDybe::HTTP::Tiny object');

}


sub CGI_param_expand {

    #  Expand CGI params if the form "foo;a=b" into "foo=param", "a=b";
    #
    my $cgi_or=shift() ||
        return err("unable to get CGI object");
    debug("$cgi_or param_expand");
    ##local ($CGI::LIST_CONTEXT_WARN)=0;
    foreach my $param (grep /=/, $cgi_or->param()) {
        my (@pairs)=split(/[&;]/, $param);
        foreach my $pair (@pairs) {
            my ($key, $value)=split('=', $pair, 2);
            $value ||= $cgi_or->param($param);
            $key=&CGI::Simple::unescape($key);
            $value=&CGI::Simple::unescape($value);
            debug("$cgi_or param $key => $value");
            $cgi_or->param($key, $value);
        }
        $cgi_or->delete($param);
    }
}


sub request {


    #  Accessor method for Apache request object
    #
    my $self=shift();
    return @_ ? $self->{'_r'}=shift() : $self->{'_r'};

}


sub dump {


    #  Run the dump CGI dump routine. Is here because it produces different output each
    #  time it is run, and if not a WebDyne tag it would be optimised to static text by
    #  the compiler
    #
    my ($self, $data_ar, $attr_hr)=@_;
    my $cgi_or=$self->CGI() ||
        return err();
    my @html;
    if ($WEBDYNE_DUMP_FLAG || $attr_hr->{'force'} || $attr_hr->{'display'}) {
    

        #  Always do CGI vars
        #
        my $cgi_ix=tie(my %cgi, 'Tie::IxHash', $cgi_or->Vars());
        $cgi_ix->SortByKey();
        push @html, Data::Dumper->Dump([\%cgi], ['WebDyne::CGI']);
        
        
        #  Others are optional. Environment
        #
        if ($attr_hr->{'env'} || $attr_hr->{'all'}) {
    

            #  Environment
            #
            my $env_ix=tie(my %env, 'Tie::IxHash', %ENV);
            $env_ix->SortByKey();
            push @html, Data::Dumper->Dump([\%env], ['WebDyne::ENV']);
            
        }
        
        
        #  @INC Library path
        #
        if ($attr_hr->{'lib'} || $attr_hr->{'inc'} || $attr_hr->{'all'}) {
        
        
            #  @INC wanted
            #
            push @html, Data::Dumper->Dump([\@INC], ['WebDyne::INC']);

            #  %INC wanted
            #
            my $inc_ix=tie(my %inc, 'Tie::IxHash', %INC);
            $inc_ix->SortByKey();
            push @html, Data::Dumper->Dump([\%inc], ['WebDyne::INC']);
            
        }
        
        

        #  WebDyne constants
        #
        if ($attr_hr->{'constant'} || $attr_hr->{'all'}) {
    

            #  Constant
            #
            my $constant_ix=tie(my %constant, 'Tie::IxHash', 
                map { $_=> encode_entities($WebDyne::Constant::Constant{$_}) } keys(%WebDyne::Constant::Constant)
            );
            $constant_ix->SortByKey();
            push @html, Data::Dumper->Dump([\%constant], ['WebDyne::Constant']);
            
        }


        #  Version mandatory
        #
        my $version_ix=tie(my %version, 'Tie::IxHash', (
            VERSION         => $VERSION,
            VERSION_GIT_REF => $VERSION_GIT_REF
        ));
        push @html, Data::Dumper->Dump([\%version], ['WebDyne::VERSION']);
        

        #  Render time
        #
        push @html, sprintf('Render time: %.3f sec', $self->render_time());
            
        
        #  Wrap in a pre tag and return
        #
        my $html_or=$self->html_tiny();
        return \($html_or->pre(join(undef, @html)));
        
    }
    else {
    
        #  Not wanted, return nothing
        #
        return \undef;
    }

}


sub cwd {

    #  Return cwd of current psp file
    #
    my $self=shift();
    return $self->{'_cwd'} ||= do {
        debug("$self, fn: %s", $self->{'_r'}->filename());
        my $fn=$self->{'_r'}->filename();
        my $dn;
        unless (-d ($dn=File::Spec->rel2abs($fn))) {
            #  Not a directory, must be file
            #
            $dn=(File::Spec->splitpath($self->{'_r'}->filename()))[1] || getcwd();
            debug("return calculated dn: $dn");
            $dn;
        }
        else {
            debug("return existing dn: $dn");
            $dn;
        }
    }

}


sub cwd0 {

    #  Return cwd of current psp file
    #
    return (File::Spec->splitpath(shift()->{'_r'}->filename()))[1] || getcwd();

}


sub filename {

    #  Return the full filename from the request handler
    #
    return shift()->{'_r'}->filename();

}


sub rel2abs {


    #  Concatenate cwd onto supplied file
    #
    my ($self, $fn)=@_;
    return File::Spec->rel2abs($fn, $self->cwd());

}


sub source_mtime {

    #  Get mtime of source file. Is a no-op here so can be subclassed by other handlers. We
    #  return undef, means engine will use original source mtime
    #
    \undef;

}


sub cache_mtime {

    #  Mtime accessor - will return mtime of srce inode (default), or mtime of supplied
    #  inode if given
    #
    my $self=shift();
    my $inode_pn=${
        $self->cache_filename(@_) || return err()};
    \(stat($inode_pn))[9] if $inode_pn;

}


sub render_time {

    #  Time so far in render
    #
    my $self=shift();
    return time-$self->{'_time'}
    
}


sub cache_filename {

    #  Get cache fq filename given inode or using srce inode if not supplied
    #
    my $self=shift();
    my $inode=@_ ? shift() : $self->{'_inode'};
    my $inode_pn=File::Spec->catfile($WEBDYNE_CACHE_DN, $inode) if $WEBDYNE_CACHE_DN;
    \$inode_pn;

}


sub cache_inode {

    #  Get cache inode string, or generate new unique inode
    #
    my $self=shift();
    @_ && ($self->{'_inode'}=md5_hex($self->{'_inode'}, $_[0]));

    #  See comment in handler section about future inode gen
    #
    #@_ && ($self->{'_inode'}.=('_'. md5_hex($_[0])));
    \$self->{'_inode'};

}


sub cache_html {

    #  Write an inode that is fully HTML out to disk to we dispatch it as a subrequest
    #  next time. This is a &register_cleanup callback
    #
    my ($cache_pn, $html_sr)=@_;
    debug("cache_html @_");

    #  If there was an error no html_sr will be supplied
    #
    if ($html_sr) {

        #  No point || return err(), just warn so (maybe) is written to logs, otherwise go for it
        #
        my $cache_fh=IO::File->new($cache_pn, O_WRONLY | O_CREAT | O_TRUNC) ||
            return warn("unable to open cache file $cache_pn for write, $!");
        CORE::print $cache_fh ${$html_sr};
        $cache_fh->close();
    }
    \undef;

}


sub cache_compile {

    #  Compile flag accessor - if set will force inode recompile, regardless of mtime
    #
    my $self=shift();
    @_ && ($self->{'_compile'}=shift());
    debug("cache_compile set to %s", $self->{'_compile'});
    \$self->{'_compile'};

}


sub filter {


    #  No op
    #
    my ($self, $data_ar)=@_;
    debug('in filter');
    $data_ar;

}


sub meta {

    #  Return/read/update meta info hash
    #
    my ($self, @param)=@_;
    my $inode=$self->{'_inode'};
    debug("get meta data for inode $inode");
    my $meta_hr=$Package{'_cache'}{$inode}{'meta'} ||= (delete $self->{'_meta_hr'} || {});
    debug("existing meta $meta_hr %s", Dumper($meta_hr));
    if (@param == 2) {
        return $meta_hr->{$param[0]}=$param[1];
    }
    elsif (@param) {
        return $meta_hr->{$param[0]};
    }
    else {
        return $meta_hr;
    }

}


sub static {


    #  Set static flag for this instance only. If all instances wanted
    #  set in meta data. This method used by WebDyne::Static module
    #
    my $self=shift();
    $self->{'_static'}=1;


}


sub cache {

    #  Set cache handler for this instance only. If all instances wanted
    #  set in meta data. This method used by WebDyne::Cache module
    #
    my $self=shift();
    $self->{'_cache'}=shift() ||
        return err('cache code ref or method name must be supplied');

}


sub set_filter {

    #  Set cache handler for this instance only. If all instances wanted
    #  set in meta data. This method used by WebDyne::Cache module
    #
    my $self=shift();
    $self->{'_filter'}=shift() ||
        return err('filter name must be supplied');

}


sub set_handler {


    #  Set/return internal handler. Only good in __PERL__ block, after
    #  that is too late !
    #
    my $self=shift();
    my $meta_hr=$self->meta() || return err();
    @_ && ($meta_hr->{'handler'}=shift());
    \$meta_hr->{'handler'};

}


sub select {


    #  If we are in select mode where print output is redirected to handler output
    #
    shift->{'_select'};

}


sub inode {


    #  Return inode name
    #
    my $self=shift();
    @_ ? $self->{'_inode'}=shift() : $self->{'_inode'};

}


sub data_ar {


    #  Return current data node, assumes we are in a perl block or subst
    #
    my $self=shift();
    return $self->{'_data_ar'}[-1] if $self->{'_data_ar'};

}


sub data_ar_html_srce_fn {


    #  The file name that this data node was sourced from
    #
    my ($self, $data_ar)=@_;
    if ($data_ar ||= $self->data_ar()) {
        return ${$data_ar->[$WEBDYNE_NODE_SRCE_IX]}
    }

}


sub data_ar_html_line_no {


    #  The line number (in the original HTML file) this data node was sourced from. Return tag start line in scalar ref, tag start + tag end in array ref
    #
    my ($self, $data_ar)=@_;
    if ($data_ar ||= $self->data_ar()) {
        return wantarray ? @{$data_ar}[$WEBDYNE_NODE_LINE_IX, $WEBDYNE_NODE_LINE_TAG_END_IX] : $data_ar->[$WEBDYNE_NODE_LINE_IX];
    }


}


sub print {

    my $self=shift();
    debug("$self in print, %s", Dumper(\@_));
    return $self->say(@_) if $self->{'_autonewline'};
    #push @{$self->{'_print_ar'} ||= []}, [map {(ref($_) eq 'ARRAY') ? @{$_} : $_ } @_];
    push @{$self->{'_print_ar'} ||= []}, map {(ref($_) eq 'ARRAY') ? @{$_} : $_ } @_;
    return \undef;

}


sub printf {

    my $self=shift();
    debug("$self in printf, %s", Dumper(\@_));
    #push @{$self->{'_print_ar'} ||= []}, [sprintf(shift(), @_)];
    push @{$self->{'_print_ar'} ||= []}, sprintf(shift(), @_);
    return \undef;

}


sub autonewline {
    my $self=shift();
    return @_ ? $self->{'_autonewline'}=($_[0] ? "\n" : 0) : $self->{'_autonewline'};
    
}


sub say {

    my $self=shift();
    debug("$self in say, %s", Dumper(\@_));
    my $print_ar=($self->{'_print_ar'} ||= []);
    foreach my $item (@_) {
        if (ref($item) eq 'ARRAY') {
            push @{$print_ar}, join("\n", @{$item})
        }
        elsif (ref($item) eq 'SCALAR') {
            push @{$print_ar}, ${$item}."\n";
        }
        else {
            push @{$print_ar}, $item."\n";
        }
    }
    return \undef;

}


sub DESTROY {


    #  Stops AUTOLOAD chucking wobbly at end of request because no DESTROY method
    #  found, logs total page cycle time
    #
    my $self=shift();


    #  Call CGI reset_globals if we created a CGI object
    #
    $self->{'_CGI'} && (&CGI::Simple::_reset_globals);


    #  Work out complete request cylcle time
    #
    debug("in destroy self $self, param %s", Dumper(\@_));
    my $time_request=sprintf('%0.4f', time()-$self->{'_time'});
    debug("page request cycle time , $time_request sec");


    #  Destroy object
    #
    %{$self}=();
    undef $self;

}


sub webdyne_status {

    return \%Package;

}


sub AUTOLOAD {


    #  Get self ref
    #
    my $self=$_[0];
    debug("AUTOLOAD $self, $AUTOLOAD");


    #  Get method user was looking for
    #
    my $method=(reverse split(/\:+/, $AUTOLOAD))[0];


    #  Vars for iterator, call stack
    #
    my $i; my @caller;


    #  Start going backwards through call stack, looking for package that can
    #  run method, pass control to it if found
    #
    my %caller;
    while (my $caller=(caller($i++))[0]) {
        next if ($caller{$caller}++);
        push @caller, $caller;
        if (my $cr=UNIVERSAL::can($caller, $method)) {

            # POLLUTE is virtually useless - no speedup in real life ..
            if ($WEBDYNE_AUTOLOAD_POLLUTE) {
                my $class=ref($self);
                *{"${class}::${method}"}=$cr;
            }

            #return $cr->($self, @_);
            goto &{$cr}
        }
    }


    #  If we get here, we could not find the method in any caller. Error
    #
    err("unable to find method '$method' in call stack: %s", join(', ', @caller));
    goto RENDER_ERROR;

}


#  Package to tie select()ed output handle to so we can override print() command
#
package WebDyne::TieHandle;
*debug=\&WebDyne::Util::debug;


sub TIEHANDLE {

    my ($class, $self)=@_;
    debug("$self TIEHANDLE class: $class");
    bless \$self, $class;
}


sub PRINT {

    my $self=shift();
    debug("$self PRINT %s", join('*', @_));
    return ${$self}->print(@_);

}


sub PRINTF {

    my $self=shift();
    debug("$self PRINTF %s", join('*', @_));
    return ${$self}->printf(@_);

}


sub DESTROY {
    my $self=shift();
    debug("$self DESTROY");
    delete ${$self}->{'_print_ar'};
}


sub UNTIE {
    my $self=shift();
    debug("$self UNTIE");
    delete ${$self}->{'_print_ar'};
}


sub AUTOLOAD {
    debug("AUTOLOAD %s", join('*', @_));
}


__END__

=pod

=head1 WebDyne.pm(3pm)

=head1 NAME

WebDyne - Dynamic Perl web application framework with template
    compilation and modular design

=head1 SYNOPSIS

SYNOPSIS

    #  Basic usage
    #
    use WebDyne qw(html html_sr);
    
    # Render a .psp file to HTML (returns a string)
    #
    my $html = html('app.psp', { param1 => 'value', param2 => 'value' });
    
    # Render a .psp file to HTML (returns a scalar ref)
    #
    my $html_ref = html_sr('app.psp', { param1 => 'value', param2 => 'value' });
    
    # With additional options
    #
    my $html = html('template.psp', { outfile => $fh });

=head1 DESCRIPTION

I<<< WebDyne >>>  is a high-performance, dynamic Perl web application framework. It provides method to integrate Perl code in
 HTMLfiles with dynamic compilation, caching, and a modular architecture.
 WebDyne is designed for flexibility and performance, supporting both CGI
 and persistent environments (mod_perl, PSGI). The core interface for
 scripts is via the  html  and html_sr  functions, which render .psp templates to HTML.

WebDyne can be used directly from scripts or as a handler in persistent environments. It supports advanced features such as block
 rendering, custom handlers, caching, and integration with Apache via
 mod_perl and PSGI servers such as Plack and Starman.

Comprehensive documentation around the construction and options within .psp files, and the general usage of WebDyne within an Apache or
 PSGI server are available in the doc directory of the Perl module or from
 the Github repository.

The simplest representation of a .psp file that can be rendered is as follows. This example uses several syntactic shortcuts from brevity
 that are not standard HTML, however the output generated by WebDyne is
 alway standards compliant HTML.

    <start_html>
    The current server time is: <? localtime() ?>

 If this example is saved as the filename  C<<<< app.psp >>>>  it can be rendered to HTML from the command line utility  C<<<< wdrender >>>>  as follows:

    $ wdrender app.psp
     
    <!DOCTYPE html><html lang="en"><head><title>Untitled Document</title><meta charset="UTF-8"></head>
    <body><p>The current server time is: Sat Sep 20 17:17:13 2025</p></body></html>

=head1 METHODS

=over

=item * B<<< html($filename, \%options, ...) >>>

Renders a .psp file to HTML and returns the result as a string. This is a convenience wrapper around html_sr .

I<<< Arguments: >>> 

=over

=item * I<<< $filename >>>  - Path to the .psp template file.

=item * I<<< \%options >>>  - Hashref or hash of options and parameters to pass to the template.

=back

I<<< Options: >>> 

=over

=item * I<<< handler >>>  - Specify a custom handler class (defaults to WebDyne).

=item * I<<< outfile >>>  - Filehandle to write output to (optional).

=back

=item * B<<< html_sr($filename, \%options, ...) >>>

Renders a .psp file to HTML and returns a scalar reference to the result. This is the core rendering function for scripts.

I<<< Arguments and options are as for
          html. >>>

=item * B<<< handler($r, \%params) >>>

Main request handler for mod_perl and PSGI environments. Not typically used directly in scripts.

=back

=head1 OPTIONS

The following options can be passed to  html  and html_sr :  

=over

=item * B<<< filename >>>

application .psp filename to render (defaults to first argument).

=item * B<<< handler >>>

Custom handler class to use for rendering.

=item * B<<< outfile >>>

Filehandle to write output to (optional). 

=back

=head1 SEE ALSO

L<Plack|https://metacpan.org/pod/Plack> L<Catalyst|https://metacpan.org/pod/Catalyst> L<Dancer2|https://metacpan.org/pod/Dancer2> L<Mojolicious|https://metacpan.org/pod/Mojolicious>

=head1 AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2025 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut