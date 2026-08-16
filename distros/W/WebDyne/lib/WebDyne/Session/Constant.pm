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
$VERSION='3.014';


#  The guts
#
%Constant=(

    #  This is the name of the cookie the browser will receive to keep session id
    #
    WEBDYNE_SESSION_ID_COOKIE_NAME => 'session',


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
