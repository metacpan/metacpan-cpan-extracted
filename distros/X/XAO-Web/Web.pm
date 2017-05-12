package XAO::Web;
use strict;
use Error qw(:try);
use XAO::Utils;
use XAO::Projects;
use XAO::Objects;
use XAO::SimpleHash;
use XAO::PageSupport;
use XAO::Templates;
use XAO::Errors qw(XAO::Web);

###############################################################################
# XAO::Web version number. Hand changed with every release!
#
use vars qw($VERSION);
$VERSION='1.47';

###############################################################################

=head1 NAME

XAO::Web - XAO Web Developer, dynamic content building suite

=head1 SYNOPSIS

 use XAO::Web;

 my $web=XAO::Web->new(sitename => 'test');

 $web->execute(cgi => $cgi,
               path => '/index.html');

 my $config=$web->config;

 $config->clipboard->put(foo => 'bar');

=head1 DESCRIPTION

Please read L<XAO::Web::Intro> for general overview and setup
instructions, and please read L<XAO::DO::Web::Page> for an overview
of the templating system. Check also misc/samplesite for code examples
and a generic site setup.

XAO::Web module provides a frameworks for loading site configuration and
executing objects and templates in the site context. It is used in
scripts and in Apache web server handler to generate actual web pages
content.

Normally a developer does not need to use XAO::Web directly.

=head1 SITE INITIALIZATION

When XAO::Web creates a new site (for mod_perl that happens only once
during each instance on Apache lifetime) it first loads new 'Config'
object using XAO::Objects' new() method and site name it knows. If site
overrides Config - it loads site specific Config, if not - the systme
one.

After the object is created XAO::Web embeds two standard additional
configuration objects into it:

=over

=item hash

Hash object is primarily used to keep site configuration parameters. It
is just a XAO::SimpleHash object and most of its methods get embedded -
get, put, getref, delete, defined, exists, keys, values, contains.

=item web

Web configuration embeds methods that allow cookie, clipboard and
cgi manipulations -- add_cookie, cgi, clipboard, cookies, header,
header_args.

=back

After that XAO::Web calls init() method on the Config object which
is supposed to finish configuration set up and usually stuffs some
parameters into 'hash', then connects to a database and embeds database
configuration object into the Config object as well. Refer to
L<XAO::Web::Intro> for an example of site specific Config object and
init() method.

When object initialization is completed the Config object is placed into
XAO::Projects registry and is retrieved from there on next access to the
same site in case of mod_perl.

B<Note:> that means that if you are embedding a site specific version
of an object during initialisation you need to pass 'sitename' into
XAO::Objects' new() method.

=head1 METHODS

Methods of XAO::Web objects include:

=over

=cut

###############################################################################

sub analyze ($$;$$);
sub clipboard ($);
sub config ($);
sub execute ($%);
sub new ($%);
sub set_current ($);
sub sitename ($);

###############################################################################

=item analyze ($;$$)

Checks how to display the given path (scalar or split up array
reference). Always returns valid results or throws an error if that
can't be accomplished.

Returns hash reference:

 prefix   => longest matching prefix (directory in case of template found)
 path     => path to the page after the prefix
 fullpath => full path from original query
 objname  => object name that will serve this path
 objargs  => object args hash (may be empty)

Optional second argument can be used to enforce a specific site name.

Optional third argument must be used to allow returning records of types
other than 'xaoweb'. This is used by Apache::XAO to get 'maptodir' and
'external' mappings. Default is to look for xaoweb only records.

=cut

sub analyze ($$;$$) {
    my ($self,$patharr,$sitename,$allow_other_types)=@_;

    $patharr=[ split(/\/+/,$patharr) ] unless ref $patharr;

    shift @$patharr while @$patharr && !length($patharr->[0]);
    unshift(@$patharr,'');
    my $path=join('/',@$patharr);

    ##
    # Looking for the object matching the path.
    #
    my $siteconfig=$self->config;
    my $table=$siteconfig->get('path_mapping_table');
    if($table) {
        for(my $i=@$patharr; $i>=0; $i--) {
            my $dir=$i ? join('/',@{$patharr}[0..$i-1]) : '';

            my $od=$table->{$dir} ||
                   $table->{'/'.$dir} ||
                   $table->{$dir.'/'} ||
                   $table->{'/'.$dir.'/'};
            next unless defined $od;

            ##
            # If $od is an empty string or an empty array reference --
            # this means that we need to fall back to default handler
            # for that path.
            #
            # The same happens for 'default' type in a hash reference.
            #
            my $rhash;
            if(ref($od) eq 'HASH') {
                my $type=$od->{'type'} || 'xaoweb';
                if($type eq 'default') {
                    last;
                }
                elsif($type eq 'xaoweb') {
                    if(!$od->{'objname'}) {
                        throw XAO::E::Web "analyze - no objname/objargs for '$dir'";
                    }
                    $rhash=merge_refs($od);
                }
                elsif($allow_other_types) {
                    $rhash=merge_refs($od);
                }
                elsif($od->{'xaoweb'} && ref($od->{'xaoweb'}) eq 'HASH') {
                    $rhash=merge_refs($od->{'xaoweb'});
                }
                else {
                    next;
                }
            }
            elsif(ref($od) eq 'ARRAY') {
                last unless @$od;
                my %args;
                if(scalar(@{$od})%2 == 1) {
                    %args=@{$od}[1..$#{$od}];
                }
                else {
                    throw XAO::E::Web "analyze - odd number of arguments in the mapping table, dir=$dir, objname=$od->[0]";
                }
                $rhash={
                    type        => 'xaoweb',
                    objname     => $od->[0],
                    objargs     => \%args,
                };
            }
            else {
                last unless length($od);
                $rhash={
                    type        => 'xaoweb',
                    objname     => $od,
                    objargs     => { },
                };
            }

            $rhash->{'path'}=join('/',@{$patharr}[$i..$#$patharr]);
            $rhash->{'patharr'}=$patharr;
            $rhash->{'prefix'}=$dir;
            $rhash->{'fullpath'}=$path;

            return $rhash;
        }
    }

    ##
    # Now looking for exactly matching template and returning Page
    # object if found.
    #
    my $filename=XAO::Templates::filename($path,$sitename);
    if($filename) {
        return {
            type        => 'xaoweb',
            subtype     => 'file',
            objname     => 'Page',
            objargs     => { },
            path        => $path,
            patharr     => $patharr,
            fullpath    => $path,
            prefix      => join('/',@{$patharr}[0..($#$patharr-1)]),
            filename    => $filename,
        };
    }

    ##
    # Nothing was found, returning Default object
    #
    return {
        type        => 'xaoweb',
        subtype     => 'notfound',
        objname     => 'Default',
        path        => $path,
        patharr     => $patharr,
        fullpath    => $path,
        prefix      => ''
    };
}

###############################################################################

=item clipboard ()

Returns site clipboard object.

=cut

sub clipboard ($) {
    my $self=shift;
    return $self->config->clipboard;
}

###############################################################################

=item config ()

Returns site configuration object reference.

=cut

sub config ($) {
    my $self=shift;
    return $self->{'siteconfig'} ||
        throw XAO::E::Web "config - no configuration object";
}

###############################################################################

=item execute (%)

Executes given `path' using given `cgi' environment. Prints results to
standard output and uses CGI object methods to send header.

B<Note:> Execute() changes global projects context and is not re-entry safe
currently! Meaning that if you create a XAO::Web object in any method
called inside of execute() loop and then call execute() on that newly
created XAO::Web object the system will fail and no useful results will
be produced.

=cut

sub execute ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    # Setting dprint/eprint to Apache methods if needed
    #
    my $old_logprint_handler;
    if($args->{'apache'}) {
        $old_logprint_handler=XAO::Utils::set_logprint_handler(sub {
            $args->{'apache'}->server->warn($_[0]);
        });
    }

    # Setting the current project context to our site.
    #
    $self->set_current();

    # We check if the site has a mapping for '/internal-error' in
    # path_mapping_table. If it has we wrap process() into the try block
    # and execute /internal-error if we get an error.
    #
    my $pagetext;
    try {
        $pagetext=$self->process($args);
    }
    otherwise {
        my $e=shift;

        # Under mod_perl we get apache's internal exceptions for genuine apache
        # problems (timeouts, etc). These are not re-throwable apparently,
        # so we wrap them into Error::Simple.
        #
        if($e->isa('APR::Error')) {
            $e=Error::Simple->new("$e");
        }

        $self->config->header_args(
            -Status         => '500 Internal Error',
            -expires        => 'now',
            -cache_control  => 'no-cache',
        );

        my $edata=$self->clipboard->get('/internal_error') || { };

        my $path=$edata->{'display_path'} || '/internal-error/index.html';
        my $pd=$self->analyze($path);

        if($pd && $pd->{'type'} eq 'xaoweb' && $pd->{'objname'} ne 'Default') {
            eprint "$e";

            $edata->{'message'}||="$e";
            $edata->{'code'}||='UNKNOWN';
            $edata->{'path'}||=$args->{'path'};
            $edata->{'pagedesc'}||=$self->clipboard->get('pagedesc');

            $self->clipboard->put(internal_error => $edata);

            $pagetext=$self->process($args,{
                path        => $path,
                template    => undef,
                pagedesc    => $pd,
            });
        }
        else {
            XAO::Utils::set_logprint_handler($old_logprint_handler) if $old_logprint_handler;
            throw $e;
        }
    };

    # We need to call "header" for CGI to do its magic on it. We
    # typically will get an empty string in mod_perl environment, and the
    # header will be sent to Apache by CGI.
    #
    my $header=$self->config->header;

    # If we get the header then it was not printed before and we are
    # expected to print out the page. This is almost always true except
    # when page includes something like Redirect object.
    #
    if(defined $header) {
        if(my $r=$args->{'apache'}) {
            my $h=$self->config->header_args;

            if($mod_perl::VERSION && $mod_perl::VERSION >= 1.99) {
                # This is accomplished by CGI when config->header is
                # called above, and it does not work properly anyway
                #
                ### while(my ($n,$v)=each %$h) {
                ###     dprint "n='$n' v='$v'";
                ###     $r->headers_out->set($n => $v);
                ###     $r->err_headers_out->set($n => $v);
                ### }
                $r->content_type('text/html') unless $r->content_type;
            }
            else {
                while(my ($n,$v)=each %$h) {
                    $r->header_out($n => $v);
                    $r->err_header_out($n => $v);
                }
                $r->send_http_header;
            }

            $r->print($pagetext) unless $r->header_only;
        }
        else {
            print $header,
                  $pagetext;
        }
    }

    # Cleaning up site configuration
    #
    $self->config->cleanup(mode => 'after');

    # Restoring the default dprint/eprint handling
    #
    XAO::Utils::set_logprint_handler($old_logprint_handler) if $old_logprint_handler;
}

###############################################################################

=item expand (%)

Expands given `path' using given `cgi' or 'apache' environment. Returns
just the text of the page in scalar context and page content plus header
content in array context.

This is normally used in scripts to execute only a particular template
and to get results of execution. BUT this code is also used as part of
the normal execute().

`Objargs' argument may refer to a hash of additional parameters to be
passed to the template being executed.

Example:

 my $report=$web->expand(
     cgi     => XAO::Objects->new(objname => 'CGI'),
     path    => '/bits/stat-report',
     objargs => {
         CUSTOMER_ID => '123X234Z',
         MIN_TIME    => time - 86400 * 7,
     },
 );

See also lower level process() method.

=cut

sub expand ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    $self->set_current;

    # Processing the page and getting its text. Setting dprint and
    # eprint to use Apache logging if there is a reference to Apache
    # request given to us.
    #
    my $pagetext=$self->process($args);

    # In scalar context (normal cases) we return only the resulting page
    # text. In array context (compatibility) we return header as well.
    #
    if(wantarray) {
        eprint "Calling ".ref($self)."::expand in ARRAY context is obsolete";
        my $header=$self->config->header;
        $self->config->cleanup(mode => 'after');
        return ($pagetext,$header);
    }
    else {
        $self->config->cleanup(mode => 'after');
        return $pagetext;
    }
}

###############################################################################

sub _expand_list ($$) {
    my ($self,$autolist)=@_;

    my $content='';

    if(!$autolist) {
        return '';
    }
    elsif(ref($autolist) eq 'ARRAY') {
        for(my $i=0; $i<@$autolist; $i+=2) {
            my ($objname,$objargs)=@{$autolist}[$i,$i+1];
            my $obj=XAO::Objects->new(objname => $objname);
            $content.=$obj->expand($objargs);
        }
    }
    elsif(ref($autolist) eq 'HASH') {
        foreach my $objname (keys %{$autolist}) {
            my $obj=XAO::Objects->new(objname => $objname);
            $content.=$obj->expand($autolist->{$objname});
        }
    }
    else {
        throw XAO::E::Web "process - don't know how to handle ($autolist)," .
                          " must be a hash or an array reference";
    }

    return $content;
}

###############################################################################

=item process (%)

Takes the same arguments as the expand() method returning expanded page
text. Does not clean the site context and should not be called directly
-- for normal situations either expand() or execute() methods should be
called.

=cut

sub process ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $siteconfig=$self->config;
    my $sitename=$self->sitename;

    # Making sure path starts from a slash
    #
    my $path=$args->{'path'} || throw XAO::E::Web "process - no 'path' given";
    $path='/' . $path;
    $path=~s/\/{2,}/\//g;

    # Resetting page text stack in case it was terminated abnormally
    # before and we're in the same process/memory.
    #
    XAO::PageSupport::reset();

    # Analyzing the path. We have to do that up here because the object
    # might specify that we should not touch CGI.
    #
    my $pd=$args->{'pagedesc'};
    if(!$pd) {
        my @path=split(/\//,$path);
        push(@path,"") unless @path;
        push(@path,"index.html") if $path =~ /\/$/;
        $pd=$self->analyze(\@path);
    }

    # Figuring out current active URL. It might be the same as base_url
    # and in most cases it is, but it just as well might be different.
    #
    # The URL should be full path to the start point -
    # http://host.com in case of rewrite and something like
    # http://host.com/cgi-bin/xao-apache.pl/sitename in case of plain
    # CGI usage.
    #
    my $active_url;
    my $apache=$args->{'apache'};
    my $cgi=$args->{'cgi'};
    if(!$cgi) {
        $cgi=XAO::Objects->new(objname => 'CGI', no_cgi => $pd->{'no_cgi'});
    }
    if($apache) {
        $active_url="http://" . $apache->hostname;
    }
    else {
        if(defined($CGI::VERSION) && $CGI::VERSION>=2.80) {
            $active_url=$cgi->url(-base => 1, -full => 0);
            my $pinfo=$ENV{PATH_INFO} || '';
            my $uri=$ENV{REQUEST_URI} || '';
            $uri=~s/^(.*?)\?.*$/$1/;
            if($pinfo =~ /^\/\Q$sitename\E(\/.+)?\Q$uri\E/) {
                # mod_rewrite
            }
            elsif($pinfo && $uri =~ /^(.*)\Q$pinfo\E$/) {
                # cgi
                $active_url.=$1;
            }
            # dprint ">2.8 $active_url";
        }
        else {
            $active_url=$cgi->url(-full => 1, -path_info => 0);
            $active_url=$1 if $active_url=~/^(.*)(\Q$path\E)$/;
            # dprint "<2.8 $active_url";
        }

        # Trying to understand if rewrite module was used or not. If not
        # - adding sitename to the end of guessed URL.
        #
        if($active_url =~ /cgi-bin/ || $active_url =~ /xao-[\w-]+\.pl/) {
            $active_url.="/$sitename";
        }
    }

    # Eating extra slashes
    #
    chop($active_url) while $active_url =~ /\/$/;
    $active_url=~s/(?<!:)\/\//\//g;

    # Figuring out secure URL
    #
    my $active_url_secure;
    if($active_url =~ /^http:(\/\/.*)$/) {
        $active_url_secure='https:' . $1;
    }
    elsif($active_url =~ /^https:(\/\/.*)$/) {
        $active_url_secure=$active_url;
        $active_url='http:' . $1;
    }
    else {
        dprint "Wrong active URL ($active_url)";
        $active_url_secure=$active_url;
    }

    ##
    # Storing active URLs
    #
    $siteconfig->clipboard->put(active_url => $active_url);
    $siteconfig->clipboard->put(active_url_secure => $active_url_secure);

    ##
    # Checking if we have base_url, assuming active_url if not.
    # Ensuring that URL does not end with '/'.
    #
    if($siteconfig->defined('base_url')) {
        my $url=$siteconfig->get('base_url');
        $url=~/^http:/i ||
            throw XAO::E::Web "process - bad base_url ($url) for sitename=$sitename";
        my $nu=$url;
        chop($nu) while $nu =~ /\/$/;
        $siteconfig->put(base_url => $nu) if $nu ne $url;

        $url=$siteconfig->get('base_url_secure');
        if(!$url) {
            $url=$siteconfig->get('base_url');
            $url=~s/^http:/https:/i;
        }
        $nu=$url;
        chop($nu) while $nu =~ /\/$/;
        $siteconfig->put(base_url_secure => $nu);
    }
    else {
        $siteconfig->put(base_url => $active_url);
        $siteconfig->put(base_url_secure => $active_url_secure);
        dprint "No base_url for sitename '$sitename'; assuming base_url=$active_url, base_url_secure=$active_url_secure";
    }

    # Checking if we're running under mod_perl
    #
    my $mod_perl=($apache || $ENV{'MOD_PERL'}) ? 1 : 0;
    $siteconfig->clipboard->put(mod_perl => $mod_perl);
    $siteconfig->clipboard->put(mod_perl_request => $apache);

    # Checking if a charset is known for the site. If it is, setting
    # it up for CGI-params decoding and for output.
    #
    if(my $charset=$siteconfig->get('charset')) {
        if($cgi->can('set_param_charset')) {
            $cgi->set_param_charset($charset);
        }
        else {
            eprint "CGI object we have does not support set_param_charset";
        }
        $siteconfig->header_args(
            -Charset   => $charset,
        );
    }

    # Putting CGI object into site configuration. The special case is
    # 'no_cgi' in the path_mapping_table which means that the object is
    # going to handle CGI arguments itself. It can be useful if it needs
    # raw query string.
    #
    $siteconfig->embedded('web')->enable_special_access;
    $siteconfig->cgi($cgi);
    $siteconfig->embedded('web')->disable_special_access;

    ##
    # Traditionally URLs that do not end with .foo are considered
    # directories and get an internal redirect to path/index.html
    # Sometimes it is desirable to be able to pass down any URLs without
    # a forced redirect -- this is controlled by 'urlstyle' parameter
    # set to 'raw'.
    #
    my $urlstyle=$pd->{'urlstyle'} || 'files';
    if($urlstyle eq 'files') {
        if($pd->{'patharr'}->[-1] !~ /\.\w+$/) {
            my $pd=$self->analyze([ @{$pd->{'patharr'}},'index.html' ]);
            #use Data::Dumper; dprint "pd=",Dumper($pd);
            if($pd->{'objname'} ne 'Default') {
                my $newpath=$siteconfig->get('base_url') . $path . '/';
                dprint "Redirecting $path to $newpath";
                $siteconfig->header_args(
                    -Location   => $newpath,
                    -Status     => 301,
                );
                return "Directory index redirection\n";
            }
        }
    }
    elsif($urlstyle eq 'raw') {
        # nothing
    }
    else {
        eprint "Unknown urlstyle '$urlstyle' for $path";
    }

    ##
    # Separator for the error_log :)
    #
    if(XAO::Utils::get_debug() && !$args->{'quieter'}) {
        my @d=localtime;
        my $date=sprintf("%02u:%02u:%02u %u/%02u/%04u",$d[2],$d[1],$d[0],$d[4]+1,$d[3],$d[5]+1900);
        undef(@d);
        dprint "============ date=$date, mod_perl=$mod_perl, " .
               "path='$path', translated='$pd->{path}'";
    }

    ##
    # Putting path decription into the site clipboard
    #
    $siteconfig->clipboard->put(pagedesc => $pd);

    # We accumulate page content here
    #
    my $pagetext='';

    # Setting expiration time in the page header to immediate
    # expiration. If that's not what the page wants -- it can override
    # these.
    #
    $siteconfig->header_args(
        -expires        => 'now',
        -cache_control  => 'no-cache',
    );

    # Do we need to run any objects before executing? A good place to
    # turn on debug mode if required using Debug object.
    #
    $pagetext.=$self->_expand_list($siteconfig->get('auto_before'));

    # Preparing object arguments out of standard ones, object specific
    # once from template paths and supplied hash (in that order of
    # preference).
    #
    my $objargs={
        path        => $pd->{'path'},
        fullpath    => $pd->{'fullpath'},
        prefix      => $pd->{'prefix'},
    };
    $objargs=merge_refs($objargs,$pd->{'objargs'},$args->{'objargs'});

    # Loading page displaying object and executing it.
    #
    my $obj=XAO::Objects->new(objname => 'Web::' . $pd->{'objname'});
    $pagetext.=$obj->expand($objargs);

    # Do we need to run any objects after executing? A good place to
    # dump benchmark statistics for example.
    #
    $pagetext.=$self->_expand_list($siteconfig->get('auto_after'));

    # Done!
    #
    return $pagetext;
}

###############################################################################

=item new (%)

Creates or loads a context for the named site. The only required
argument is 'sitename' which provides the name of the site.

Additionally `cgi' argument can point to a CGI object -- this is useful
mostly in test cases when one does not want to use execute(), but new()
comes handy.

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    ##
    # Getting site name
    #
    my $sitename=$args->{'sitename'} ||
        throw XAO::E::Web "new - required parameter missing (sitename)";

    ##
    # Loading or creating site configuration object.
    #
    my $siteconfig=XAO::Projects::get_project($sitename);
    if(!$siteconfig) {
        ##
        # Creating configuration.
        #
        $siteconfig=XAO::Objects->new(
            sitename => $sitename,
            objname => 'Config',
        );

        ##
        # Always embedding at least web config and a hash
        #
        $siteconfig->embed(web => new XAO::Objects objname => 'Web::Config');
        $siteconfig->embed(hash => new XAO::SimpleHash);

        ##
        # Running initialization, this is where parameters are inserted and
        # normally FS::Config gets embedded.
        #
        $siteconfig->init($args->{'init_args'} || ());

        ##
        # Creating an entry in in-memory projects repository
        #
        XAO::Projects::create_project(
            name        => $sitename,
            object      => $siteconfig,
        );
    }

    # CGI in args is not supported any more, needs to be passed in execute
    #
    $args->{'cgi'} &&
        throw XAO::E::Web "new - 'cgi' argument to 'new' is not supported, pass it to 'execute'";

    # This helps Mailer to be called outside of web context.
    # TODO: Probably need some better initialization strategy, this does
    # not feel as the Right Thing
    #
    my $url=$siteconfig->get('base_url');
    if($url) {
        $url=~/^http:/i ||
            throw XAO::E::Web "new - bad base_url ($url) for sitename=$sitename";
        my $nu=$url;
        chop($nu) while $nu =~ /\/$/;
        $siteconfig->put(base_url => $nu) if $nu ne $url;

        $url=$siteconfig->get('base_url_secure');
        if(!$url) {
            $url=$siteconfig->get('base_url');
            $url=~s/^http:/https:/i;
        }
        $nu=$url;
        chop($nu) while $nu =~ /\/$/;
        $siteconfig->put(base_url_secure => $nu);
    }

    # Done
    #
    bless {
        sitename => $sitename,
        siteconfig => $siteconfig,
    }, ref($proto) || $proto;
}

###############################################################################

sub check_uri_access ($$) {
    my ($self,$uri)=@_;

    # By convention we disallow access to /bits/ and /CVS/ for security
    # reasons. If needed the site can override these or add other
    # regex'es into path_deny_table
    #
    my $pdtc=$self->config->get('path_deny_table_compiled');
    if(!$pdtc) {
        my $pdt=merge_refs({
            '/bits/'        => 1,
            '/CVS/'         => 1,
        },$self->config->get('path_deny_table') || { });
        $pdtc=[ map { qr/$_/ } grep { $pdt->{$_} } keys %$pdt ];
        $self->config->put('path_deny_table_compiled' => $pdtc);
    }

    return ! grep { $uri =~ $_ } @$pdtc;
}

###############################################################################

=item set_current ()

Sets the current site as the current project in the sense of XAO::Projects.

=cut

sub set_current ($) {
    my $self=shift;

    XAO::Projects::set_current_project($self->sitename);

    # Cleaning up the configuration. Useful even if it was just created
    # as it will unlock tables in the database for instance.
    # We call it here because cleanup code may rely on the project being
    # active.
    #
    $self->config->cleanup(mode => 'before');
}

###############################################################################

=item sitename ()

Returns site name.

=cut

sub sitename ($) {
    my $self=shift;
    $self->{'sitename'} || throw XAO::E::Web "sitename - no site name";
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Objects>,
L<XAO::Projects>,
L<XAO::DO::Config>,
L<XAO::Web::Intro>,
L<XAO::DO::Web::Page>.
