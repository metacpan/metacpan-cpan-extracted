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


#  Constants file  
#
package WebDyne::Session::Constant;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information. Must be all on one line
#
$VERSION='3.029';


#  The guts
#
%Constant=(

    #  This is the name of the cookie the browser will receive to keep session id
    #
    WEBDYNE_SESSION_ID_COOKIE_NAME => 'session',

    
    #  Session cookie attributes
    #
    WEBDYNE_SESSION_COOKIE_PATH     => '/',
    WEBDYNE_SESSION_COOKIE_SECURE   => 1,
    WEBDYNE_SESSION_COOKIE_HTTPONLY => 1,
    WEBDYNE_SESSION_COOKIE_SAMESITE => 'Lax',


);


#  Done
#
1;__END__

=begin markdown

# WebDyne::Session::Constant #

# NAME #

WebDyne::Session::Constant - session-cookie constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Session::Constant;
```

# DESCRIPTION #

`WebDyne::Session::Constant` defines the session-layer constant used by `WebDyne::Session` when creating or reading the browser cookie that carries the session identifier.

# CONSTANTS #

* **WEBDYNE_SESSION_ID_COOKIE_NAME ('session')**

    Name of the cookie used to store the WebDyne session identifier on the client.

* **WEBDYNE_SESSION_COOKIE_PATH ('/')**

    Path attribute used when setting the WebDyne session cookie.

* **WEBDYNE_SESSION_COOKIE_SECURE (1)**

    Add the `Secure` attribute to newly generated session cookies. Set to `0` for plain HTTP development deployments.

* **WEBDYNE_SESSION_COOKIE_HTTPONLY (1)**

    Add the `HttpOnly` attribute to newly generated session cookies.

* **WEBDYNE_SESSION_COOKIE_SAMESITE ('Lax')**

    SameSite attribute used for newly generated session cookies. Set to an empty value to omit the attribute.

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


=head1 WebDyne::Session::Constant


=head1 NAME

WebDyne::Session::Constant - session-cookie constants for WebDyne


=head1 SYNOPSIS


 use WebDyne::Session::Constant;

=head1 DESCRIPTION

C<WebDyne::Session::Constant> defines the session-layer constant used by C<WebDyne::Session> when creating or reading the browser cookie that carries the session identifier.


=head1 CONSTANTS

=over

=item *

B<WEBDYNE_SESSION_ID_COOKIE_NAME ('session')>

Name of the cookie used to store the WebDyne session identifier on the client.



=item *

B<WEBDYNE_SESSION_COOKIE_PATH ('/')>

Path attribute used when setting the WebDyne session cookie.



=item *

B<WEBDYNE_SESSION_COOKIE_SECURE (1)>

Add the C<Secure> attribute to newly generated session cookies. Set to C<0> for plain HTTP development deployments.



=item *

B<WEBDYNE_SESSION_COOKIE_HTTPONLY (1)>

Add the C<HttpOnly> attribute to newly generated session cookies.



=item *

B<WEBDYNE_SESSION_COOKIE_SAMESITE ('Lax')>

SameSite attribute used for newly generated session cookies. Set to an empty value to omit the attribute.



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
