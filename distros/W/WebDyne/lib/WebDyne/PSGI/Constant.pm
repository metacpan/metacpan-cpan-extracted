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


#
#
package WebDyne::PSGI::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;
no warnings qw(once);


#  External modules
#
use File::Basename;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information
#
$VERSION='3.012';



#  Hash of constants
#  <<<
%Constant=(

    
    #  Document Root, usually supplied as env var or command line option but
    #  can be set here.
    #
    DOCUMENT_ROOT	=> undef,
    
    
    #  Document default - will be served if exists in DOCUMENT_ROOT and no other
    #  file specified.
    #
    DOCUMENT_DEFAULT	=> 'app.psp',
    
    
    #  File to use for indexing
    #
    WEBDYNE_PSGI_INDEX	=> 'index.psp',
    
    
    #  Middeware config, static module. Loaded by default for convenience if
    #  started via webdyne.psgi script directly (i.e. not invoked by plakup
    #  or starman). Activate in middleware section below if wanted with plackup
    #  or starman
    #
    #  Serve any static file except .psp
    #
    #WEBDYNE_PSGI_MIDDLEWARE_STATIC => qr{^(?!.*\.psp$).*\.\w+$},
    #
    #  Just common files
    #
    WEBDYNE_PSGI_MIDDLEWARE_STATIC => qr{\.(?:css|js|jpg|jpeg|png|gif|svg|ico|woff2?|ttf|eot|otf|webp|map|txt|inc|htm|html)$}i,
    
    
    #  Serve static files ?
    #
    WEBDYNE_PSGI_STATIC => 1,
    
    
    #  All other middleware. Uncomment/modify as required
    #
    WEBDYNE_PSGI_MIDDLEWARE => [
        
        #[ 'Debug' => 
        #    { enabled => 1 } 
        #],
        
        #  If given as a sub code ref then option hash ref is first param 
        #
        [ 'Static' => sub { 
            { path=>$WebDyne::PSGI::WEBDYNE_PSGI_MIDDLEWARE_STATIC, root=>(-f $_[0]->{'root'}) ? dirname($_[0]->{'root'}) : $_[0]->{'root'}, pass_through=>1 }
        }]
        
        
    ],
    
    
    #  Environment variables to keep, needs to be array ref
    #
    WEBDYNE_PSGI_ENV_KEEP => [qw(DOCUMENT_ROOT DOCUMENT_DEFAULT)],
    WEBDYNE_PSGI_ENV_SET  => {},
    
    
    #  Warn on error ?
    #
    WEBDYNE_PSGI_WARN_ON_ERROR => undef,


);
# >>>


#  Done
#
1;
__END__

=begin markdown

# WebDyne::PSGI::Constant #

# NAME #

WebDyne::PSGI::Constant - PSGI runtime constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PSGI::Constant;
```

# DESCRIPTION #

`WebDyne::PSGI::Constant` defines defaults used by the WebDyne PSGI stack. These constants control default document selection, static-file middleware behavior, and which environment variables are preserved into PSGI request handling.

# CONSTANTS #

* **DOCUMENT_ROOT**

    Optional default document root for PSGI execution.

* **DOCUMENT_DEFAULT ('app.psp')**

    Default WebDyne page served when a request resolves to a directory and no explicit `.psp` file is selected.

* **WEBDYNE_PSGI_INDEX ('index.psp')**

    Default index filename used by the wrapper layer.

* **WEBDYNE_PSGI_MIDDLEWARE_STATIC**

    Regular expression used by the default static middleware to decide which non-`.psp` assets may be served directly.

* **WEBDYNE_PSGI_STATIC (1)**

    Enable static-file middleware by default.

* **WEBDYNE_PSGI_MIDDLEWARE**

    Default PSGI middleware stack wrapped around the WebDyne PSGI application.

* **WEBDYNE_PSGI_ENV_KEEP / WEBDYNE_PSGI_ENV_SET**

    Environment variables preserved from or injected into the PSGI runtime.

* **WEBDYNE_PSGI_WARN_ON_ERROR**

    Optional flag controlling warning behavior on PSGI-side errors.

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


=head1 WebDyne::PSGI::Constant


=head1 NAME

WebDyne::PSGI::Constant - PSGI runtime constants for WebDyne


=head1 SYNOPSIS


 use WebDyne::PSGI::Constant;

=head1 DESCRIPTION

C<WebDyne::PSGI::Constant> defines defaults used by the WebDyne PSGI stack. These constants control default document selection, static-file middleware behavior, and which environment variables are preserved into PSGI request handling.


=head1 CONSTANTS

=over

=item *

B<DOCUMENT_ROOT>

Optional default document root for PSGI execution.



=item *

B<DOCUMENT_DEFAULT ('app.psp')>

Default WebDyne page served when a request resolves to a directory and no explicit C<.psp> file is selected.



=item *

B<WEBDYNE_PSGI_INDEX ('index.psp')>

Default index filename used by the wrapper layer.



=item *

B<WEBDYNE_PSGI_MIDDLEWARE_STATIC>

Regular expression used by the default static middleware to decide which non-C<.psp> assets may be served directly.



=item *

B<WEBDYNE_PSGI_STATIC (1)>

Enable static-file middleware by default.



=item *

B<WEBDYNE_PSGI_MIDDLEWARE>

Default PSGI middleware stack wrapped around the WebDyne PSGI application.



=item *

B<WEBDYNE_PSGI_ENV_KEEP / WEBDYNE_PSGI_ENV_SET>

Environment variables preserved from or injected into the PSGI runtime.



=item *

B<WEBDYNE_PSGI_WARN_ON_ERROR>

Optional flag controlling warning behavior on PSGI-side errors.



=back


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
