#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.
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
package WebDyne::Request::PSGI::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information
#
$VERSION='3.018';



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
    
    
    #  All other middleware. Uncomment/modify as required
    #
    WEBDYNE_PSGI_MIDDLEWARE => [
        
        #{ 'Debug' => 
        #    { panels => [ qw(Environment) ] } 
        #},
        
        #  If given as a sub code ref the $DOCUMENT_ROOT is first param 
        #
        #{ 'Static' => sub { 
        #    { path=>qr{^(?!.*\.psp$).*\.\w+$}, root=>shift() }
        #}}
        
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

# WebDyne::Request::PSGI::Constant #

# NAME #

WebDyne::Request::PSGI::Constant - request-adapter constants for the PSGI request layer

# SYNOPSIS #

```perl
use WebDyne::Request::PSGI::Constant;
```

# DESCRIPTION #

`WebDyne::Request::PSGI::Constant` defines defaults used specifically by the PSGI request adapter layer. It overlaps with `WebDyne::PSGI::Constant`, but is scoped to request interpretation and middleware behavior when building `WebDyne::Request::PSGI` objects.

# CONSTANTS #

* **DOCUMENT_ROOT**

    Optional default document root for request resolution.

* **DOCUMENT_DEFAULT ('app.psp')**

    Default page selected when a resolved request path refers to a directory.

* **WEBDYNE_PSGI_INDEX ('index.psp')**

    Index filename used by the request-side PSGI helpers.

* **WEBDYNE_PSGI_MIDDLEWARE_STATIC**

    Regular expression controlling which static asset paths may be served directly.

* **WEBDYNE_PSGI_MIDDLEWARE**

    Request-layer middleware stack definition.

* **WEBDYNE_PSGI_ENV_KEEP / WEBDYNE_PSGI_ENV_SET**

    Environment variables preserved from or injected into PSGI request processing.

* **WEBDYNE_PSGI_WARN_ON_ERROR**

    Optional warning control flag for request-layer PSGI errors.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Request::PSGI::Constant


=head1 NAME

WebDyne::Request::PSGI::Constant - request-adapter constants for the PSGI request layer


=head1 SYNOPSIS


 use WebDyne::Request::PSGI::Constant;

=head1 DESCRIPTION

C<WebDyne::Request::PSGI::Constant> defines defaults used specifically by the PSGI request adapter layer. It overlaps with C<WebDyne::PSGI::Constant>, but is scoped to request interpretation and middleware behavior when building C<WebDyne::Request::PSGI> objects.


=head1 CONSTANTS

=over

=item *

B<DOCUMENT_ROOT>

Optional default document root for request resolution.



=item *

B<DOCUMENT_DEFAULT ('app.psp')>

Default page selected when a resolved request path refers to a directory.



=item *

B<WEBDYNE_PSGI_INDEX ('index.psp')>

Index filename used by the request-side PSGI helpers.



=item *

B<WEBDYNE_PSGI_MIDDLEWARE_STATIC>

Regular expression controlling which static asset paths may be served directly.



=item *

B<WEBDYNE_PSGI_MIDDLEWARE>

Request-layer middleware stack definition.



=item *

B<WEBDYNE_PSGI_ENV_KEEP / WEBDYNE_PSGI_ENV_SET>

Environment variables preserved from or injected into PSGI request processing.



=item *

B<WEBDYNE_PSGI_WARN_ON_ERROR>

Optional warning control flag for request-layer PSGI errors.



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
