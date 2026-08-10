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
use File::Spec;
use File::Spec::Unix;
use HTTP::Status qw(status_message HTTP_OK HTTP_NOT_FOUND HTTP_FOUND);
use URI;
use Data::Dumper;
use Plack::Request;
use Plack::Response;


#  WebDyne modules
#
use WebDyne::Util;
use WebDyne::Constant;
use WebDyne::PSGI::Constant;
use WebDyne::Request::Common qw(handler_methods_init);
use WebDyne::Request::Fake;


#  Version information
#
$VERSION='3.012';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Init
#
&init() unless defined(&method);


#  All done. Positive return
#
1;


#==================================================================================================


sub init {

    #  Setup pass through methods
    #
    my %method=(
        accept_encoding     => undef,
        accept_language     => undef,
        accept              => undef,
        args                => undef,
        as_string           => undef,
        authority           => undef,
        authorization       => undef,
        auth_type           => undef,
        base                => 'base',
        base_url            => 'base',
        body_handle         => 'input',
        #body                => sub { my $r=shift(); if (my $input_or=$r->input) { unless (exists $r->{'body'}) { $input_or->read($r->{'body'}, $r->content_length()) }; return $r->{'body'} } },
        body                => \&body,
        cache_control       => undef,
        charset             => undef,
        cleanup_register    => undef,
        client_address      => 'address',
        content             => \&body,
        content_encoding    => 'content_encoding',
        #content_length      => 'content_length',
        #content_type        => 'content_type',
        content_length      => undef,
        content_type        => undef,
        cookies             => 'cookies',
        cookie              => 'cookies',
        custom_response     => undef,
        cwd                 => undef,
        dir_config          => undef,
        document_root       => undef,
        env                 => 'env',
        etag                => undef,
        filename            => undef,
        finalize            => undef,
        finfo               => undef,
        form_parameters     => 'body_parameters',
        forwarded_for       => undef,
        fragment            => undef,
        handler             => undef,
        header              => sub { shift()->{'req'}->headers->header(@_) },
        headers             => undef,
        header_only         => undef,
        headers_in          => \&headers_in,
        headers_out         => undef,
        hostname            => undef,
        host                => undef,
        https               => undef,
        http_version        => 'protocol',
        id                  => sub { shift()->{'env'}->{'psgi.request_id'} },
        if_modified_since   => undef,
        if_none_match       => undef,
        input               => sub { shift()->{'env'}->{'psgi.input'} },
        is_ajax             => undef,
        is_main             => undef,
        location            => undef,
        log_error           => undef,
        lookup_file         => undef,
        lookup_uri          => undef,
        main                => undef,
        media_type          => undef,
        method              => 'method',
        mtime               => undef,
        multipart_parameters=> 'body_parameters',
        next                => undef,
        notes               => undef,
        origin              => undef,
        output_filters      => undef,
        path_info           => 'path_info',
        path_parameters     => undef,
        path                => 'path_info',
        pool                => undef,
        preferred_charset   => undef,
        preferred_encoding  => undef,
        preferred_language  => undef,
        preferred_media_type=> undef,
        prev                => undef,
        print               => undef,
        protocol            => 'protocol',
        query_parameters    => 'query_parameters',
        query_string        => 'query_string',
        redirect            => undef,
        referer             => 'referer',
        register_cleanup    => undef,
        remote_address      => 'address',
        remote_host         => sub { my $r=shift(); $r->{'req'}->remote_host || $r->{'env'}->{'REMOTE_ADDR'} },
        remote_port         => undef,
        remote_user         => 'user',
        request_time        => sub { shift()->{'env'}->{'psgi.start_time'} },
        route               => undef,
        run                 => undef,
        scheme              => 'scheme',
        script_name         => 'script_name',
        secure              => 'secure',
        sendfile            => undef,
        send_http_header    => undef,
        server_name         => undef,
        server_port         => undef,
        session_id          => undef,
        session             => undef,
        set_handlers        => undef,
        status_line         => undef,
        status              => undef,
        unparsed_uri        => sub { shift()->{'env'}->{'REQUEST_URI'} },
        uploads             => 'uploads',
        uri                 => 'uri',
        url                 => 'uri',
        user_agent          => 'user_agent',
        user                => undef,
        write               => undef,
        err_html            => undef,
        DESTROY             => undef,
    );


    #  Setup handlers and return
    #
    foreach my $handler (qw(req res)) {
        *{$handler}=sub { return shift()->{$handler} };
    }
    return handler_methods_init(__PACKAGE__, 'Plack::Request', \%method);
    
}


sub new {


    #  New PSGI request
    #
    my ($class, %r)=@_;
    debug("$class, r: %s, calller:%s", Dumper(\%r, [caller(0)]));
    

    #  Get PSGI env var
    #
    my $env_hr=$r{'env'} ||
        return err('no PSGI env supplied');
    

    #  Try to figure out filename user wants
    #
    unless ($r{'filename'}) {
    
    
        #  Not supplied - need to work out
        #
        debug('filename not supplied, determining from request');

    
        #  Iterate through options. If *not* supplied by SCRIPT_FILENAME keep going.
        #
        my $fn;
        my $invalid_path;
        unless (($fn=$env_hr->{'SCRIPT_FILENAME'}) && !$r{'uri'}) {
        
        
            #  Need to calc from document root in PSGI environment
            #
            debug('not supplied in SCRIPT_FILENAME or uri param. calculating');
            if (my $dn=($r{'document_root'} || $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT)) {
            
                #  Get from URI and location
                #
                my $uri=$r{'uri'} || $env_hr->{'PATH_INFO'};
                my @uri_part=grep { length($_) } split(m{/+}, $uri);
                if (grep { $_ eq '..' } @uri_part) {
                    debug("rejecting path traversal attempt in uri: $uri");
                    $fn=undef;
                    $invalid_path=1;
                }
                else {
                    $fn=File::Spec->rel2abs(File::Spec->catfile($dn, @uri_part));
                }
                debug("fn: $fn from dn: $dn, uri: $uri");
                
            }
            
            
            #  Need to add default psp file ?
            #
            #unless ($fn=~/\.psp$/) { # fastest
            unless ($invalid_path || ($fn=~WEBDYNE_PSP_EXT_RE)) { # fastest

                #  Is it a directory that exists ? Only append default document if that is the case, else let the api code
                #  handle it
                #
                debug("no .psp extenstion on fn: $fn, looking at options");
                if  (($fn=~/\/$/) || ((-d $fn) || !$fn)) {
                    
            
                    #  Append default doc to path, which appears at moment to be a directory ?
                    #
                    my $document_default=$r{'document_default'} || $DOCUMENT_DEFAULT;
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
                        $fn=File::Spec->rel2abs($fn);
                    }
                }
                else {
                    
                    #  Not .psp file, do not want
                    #
                    debug("fn: $fn does not end with /, leaving undef");
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

sub body {

    my $r=shift(); 
    if ((my $input_or=$r->input) && $r->content_length()) { 
        unless (exists $r->{'body'}) {
            $input_or->read($r->{'body'}, $r->content_length()) 
        }
        return $r->{'body'} 
    } 
}


sub headers_in {
    my $r=shift();
    if (@_) {
        return $r->{'req'}->headers()->header(@_);
    }
    else {
        return $r->{'req'}->headers();
    }
}

1;

__END__

=begin markdown

# WebDyne::Request::PSGI #

# NAME #

WebDyne::Request::PSGI - PSGI request adapter for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Request::PSGI;

my $wr = WebDyne::Request::PSGI->new(
    env => $env,
    req => Plack::Request->new($env),
    res => Plack::Response->new(200),
);
```

# DESCRIPTION #

`WebDyne::Request::PSGI` adapts PSGI request state to the normalized request API expected by WebDyne.

When no filename is supplied, the constructor derives one from the PSGI environment, document root, request path, and configured default document rules. The adapter also exposes query/body parameters, uploads, headers, and PSGI request metadata through WebDyne-friendly method names.

# METHODS #

* **new(%options)**

    Construct a PSGI-backed request adapter. The `env` hashref is required.

* **body()**

    Read and cache request body content from `psgi.input`.

* **headers_in()**

    Access request headers.

In addition, the adapter provides the normalized request surface expected by WebDyne, including methods such as `query_parameters`, `form_parameters`, `uploads`, `uri`, `scheme`, `script_name`, `request_time`, and related accessors.

# NOTES #

Most normalized methods are installed dynamically in `init()` via `WebDyne::Request::Common`. Methods not implemented locally fall back to the fake-request adapter where appropriate.

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


=head1 WebDyne::Request::PSGI


=head1 NAME

WebDyne::Request::PSGI - PSGI request adapter for WebDyne


=head1 SYNOPSIS


 use WebDyne::Request::PSGI;
 
 my $wr = WebDyne::Request::PSGI->new(
     env => $env,
     req => Plack::Request->new($env),
     res => Plack::Response->new(200),
 );

=head1 DESCRIPTION

C<WebDyne::Request::PSGI> adapts PSGI request state to the normalized request API expected by WebDyne.

When no filename is supplied, the constructor derives one from the PSGI environment, document root, request path, and configured default document rules. The adapter also exposes query/body parameters, uploads, headers, and PSGI request metadata through WebDyne-friendly method names.


=head1 METHODS

=over

=item *

B<new(%options)>

Construct a PSGI-backed request adapter. The C<env> hashref is required.



=item *

B<body()>

Read and cache request body content from C<psgi.input>.



=item *

B<headers_in()>

Access request headers.



=back

In addition, the adapter provides the normalized request surface expected by WebDyne, including methods such as C<query_parameters>, C<form_parameters>, C<uploads>, C<uri>, C<scheme>, C<script_name>, C<request_time>, and related accessors.


=head1 NOTES

Most normalized methods are installed dynamically in C<init()> via C<WebDyne::Request::Common>. Methods not implemented locally fall back to the fake-request adapter where appropriate.


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
