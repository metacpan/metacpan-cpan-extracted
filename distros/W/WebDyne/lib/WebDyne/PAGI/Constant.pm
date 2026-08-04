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
package WebDyne::PAGI::Constant;


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
$VERSION='3.007';


#  Hash of constants
#  <<<
%Constant=(


    #  Document Root, usually supplied as env var or command line option but
    #  can be set here.
    #
    DOCUMENT_ROOT	    => undef,
    
    
    #  Document default - will be served if exists in DOCUMENT_ROOT and no other
    #  file specified.
    #
    DOCUMENT_DEFAULT	=> 'app.psp',

    
    #  Middeware config, static module. Loaded by default for convenience, comment out if
    #  not wanted
    #


    #  Serve any static file except .psp
    #
    #WEBDYNE_PSGI_MIDDLEWARE_STATIC => qr{^(?!.*\.psp$).*\.\w+$},
    #
    #  Just common files
    #
    WEBDYNE_PAGI_MIDDLEWARE_STATIC => qr{\.(?:css|js|jpg|jpeg|png|gif|svg|ico|woff2?|ttf|eot|otf|webp|map|txt|inc|htm|html)$}i,
    
    
    #  Serve static files ?
    #
    WEBDYNE_PAGI_STATIC => 1,
    
    
    #  All other middleware. Uncomment/modify as required
    #
    WEBDYNE_PAGI_MIDDLEWARE => [
        
        #[ 'Debug' => 
        #    { enabled => 1 } 
        #],
        
        #  If given as a sub code ref then option hash ref is first param 
        #
        [ 'Static' => sub { 
            { path=>$WebDyne::PAGI::WEBDYNE_PAGI_MIDDLEWARE_STATIC, root=>(-f $_[0]->{'root'}) ? dirname($_[0]->{'root'}) : $_[0]->{'root'}, pass_through=>1 }
        }]
        
        
    ],
    
    
    #  Environment variables to keep, needs to be array ref
    #
    WEBDYNE_PAGI_ENV_KEEP => [qw(DOCUMENT_ROOT DOCUMENT_DEFAULT)],
    WEBDYNE_PAGI_ENV_SET  => {},
    
    
    #  Warn on error ?
    #
    WEBDYNE_PAGI_WARN_ON_ERROR => undef,
    
    
    #  Modules to load on eval
    #
    WEBDYNE_PAGI_EVAL_PREPEND => << 'END'
use Future::AsyncAwait;
#use Future::IO;
END
,


);
# >>>


#  Done
#
1;
__END__

=begin markdown

# WebDyne::PAGI::Constant #

# NAME #

WebDyne::PAGI::Constant - PAGI runtime constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::PAGI::Constant;
```

# DESCRIPTION #

`WebDyne::PAGI::Constant` defines defaults used by the WebDyne PAGI stack. These values control document-root defaults, default document selection, static-file middleware behavior, environment propagation, and PAGI-specific eval preparation.

# CONSTANTS #

* **DOCUMENT_ROOT**

    Optional default document root for PAGI execution.

* **DOCUMENT_DEFAULT ('app.psp')**

    Default WebDyne page served when a request resolves to a directory and no explicit `.psp` file is selected.

* **WEBDYNE_PAGI_MIDDLEWARE_STATIC**

    Regular expression used by the default static middleware to decide which non-`.psp` assets may be served directly.

* **WEBDYNE_PAGI_STATIC (1)**

    Enable static-file middleware by default.

* **WEBDYNE_PAGI_MIDDLEWARE**

    Default PAGI middleware stack wrapped around the WebDyne PAGI application.

* **WEBDYNE_PAGI_ENV_KEEP / WEBDYNE_PAGI_ENV_SET**

    Environment variables preserved from or injected into the runtime environment.

* **WEBDYNE_PAGI_WARN_ON_ERROR**

    Optional flag controlling warning behavior on PAGI-side errors.

* **WEBDYNE_PAGI_EVAL_PREPEND**

    Perl source prepended for PAGI eval contexts. In the current code this loads `Future::AsyncAwait`.

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


=head1 WebDyne::PAGI::Constant


=head1 NAME

WebDyne::PAGI::Constant - PAGI runtime constants for WebDyne


=head1 SYNOPSIS


 use WebDyne::PAGI::Constant;

=head1 DESCRIPTION

C<WebDyne::PAGI::Constant> defines defaults used by the WebDyne PAGI stack. These values control document-root defaults, default document selection, static-file middleware behavior, environment propagation, and PAGI-specific eval preparation.


=head1 CONSTANTS

=over

=item *

B<DOCUMENT_ROOT>

Optional default document root for PAGI execution.



=item *

B<DOCUMENT_DEFAULT ('app.psp')>

Default WebDyne page served when a request resolves to a directory and no explicit C<.psp> file is selected.



=item *

B<WEBDYNE_PAGI_MIDDLEWARE_STATIC>

Regular expression used by the default static middleware to decide which non-C<.psp> assets may be served directly.



=item *

B<WEBDYNE_PAGI_STATIC (1)>

Enable static-file middleware by default.



=item *

B<WEBDYNE_PAGI_MIDDLEWARE>

Default PAGI middleware stack wrapped around the WebDyne PAGI application.



=item *

B<WEBDYNE_PAGI_ENV_KEEP / WEBDYNE_PAGI_ENV_SET>

Environment variables preserved from or injected into the runtime environment.



=item *

B<WEBDYNE_PAGI_WARN_ON_ERROR>

Optional flag controlling warning behavior on PAGI-side errors.



=item *

B<WEBDYNE_PAGI_EVAL_PREPEND>

Perl source prepended for PAGI eval contexts. In the current code this loads C<Future::AsyncAwait>.



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
