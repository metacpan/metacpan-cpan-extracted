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
package WebDyne::Filter::Constant;


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
$VERSION='3.009';


#  The guts
#
%Constant=(

    #  This is the name of the cookie the browser will receive to keep session id
    #
    WEBDYNE_FILTER_REQUEST_CR  => undef,
    WEBDYNE_FILTER_RESPONSE_CR => undef


);


#  Done
#
1;
__END__

=begin markdown

# WebDyne::Filter::Constant #

# NAME #

WebDyne::Filter::Constant - request and response filter callback constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Filter::Constant;
```

# DESCRIPTION #

`WebDyne::Filter::Constant` defines the callback slots used by the `WebDyne::Filter` subsystem. These constants allow configuration files to nominate global request and response filter code references.

# CONSTANTS #

* **WEBDYNE_FILTER_REQUEST_CR**

    Optional code reference run against request-side data before normal page handling.

* **WEBDYNE_FILTER_RESPONSE_CR**

    Optional code reference run against response-side data before output is finalized.

# NOTES #

The callbacks default to `undef`. They are intended to be populated from configuration rather than hard-coded in the module itself.

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


=head1 WebDyne::Filter::Constant


=head1 NAME

WebDyne::Filter::Constant - request and response filter callback constants for WebDyne


=head1 SYNOPSIS


 use WebDyne::Filter::Constant;

=head1 DESCRIPTION

C<WebDyne::Filter::Constant> defines the callback slots used by the C<WebDyne::Filter> subsystem. These constants allow configuration files to nominate global request and response filter code references.


=head1 CONSTANTS

=over

=item *

B<WEBDYNE_FILTER_REQUEST_CR>

Optional code reference run against request-side data before normal page handling.



=item *

B<WEBDYNE_FILTER_RESPONSE_CR>

Optional code reference run against response-side data before output is finalized.



=back


=head1 NOTES

The callbacks default to C<undef>. They are intended to be populated from configuration rather than hard-coded in the module itself.


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
