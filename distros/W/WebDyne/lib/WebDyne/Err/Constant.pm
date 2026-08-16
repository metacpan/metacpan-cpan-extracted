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
package WebDyne::Err::Constant;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Need the File::Spec module
#
use File::Spec;


#  Version information
#
$VERSION='3.014';


#  Hash of constants
#
%Constant=(


    #  Where we keep the error template
    #
    WEBDYNE_ERR_TEMPLATE => File::Spec->catfile(&class_dn(__PACKAGE__), 'error.psp'),


    #  If set to 1, error messages will be sent as text/plain, not
    #  HTML. If ERROR_EXIT set, child will quit after an error
    #
    WEBDYNE_ERROR_TEXT => 0,
    WEBDYNE_ERROR_EXIT => 0,


);


sub class_dn {


    #  Get class dir
    #
    my $class=shift();


    #  Get package file name so we can look up in inc
    #
    (my $class_fn="${class}.pm")=~s{::}{/}g;
    $class_fn=$INC{$class_fn} ||
        die("unable to find location for $class in \%INC");


    #  Split
    #
    my $class_dn=(File::Spec->splitpath($class_fn))[1];

}


#  Done
#
1;
__END__

=begin markdown

# WebDyne::Err::Constant #

# NAME #

WebDyne::Err::Constant - error-template and low-level error-mode constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Err::Constant;
```

# DESCRIPTION #

`WebDyne::Err::Constant` defines constants used by the WebDyne error subsystem. It is a small companion module for locating the bundled error template and controlling whether low-level error output should be rendered as HTML or plain text.

# CONSTANTS #

* **WEBDYNE_ERR_TEMPLATE**

    Absolute path to the bundled `error.psp` template used for HTML error rendering.

* **WEBDYNE_ERROR_TEXT (0)**

    When true, render errors as `text/plain` instead of HTML.

* **WEBDYNE_ERROR_EXIT (0)**

    When true, signal that error handling should terminate the child/request flow after output.

# METHODS #

* **class_dn($class)**

    Internal helper that resolves the installed directory for a package name by consulting `%INC`.

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


=head1 WebDyne::Err::Constant


=head1 NAME

WebDyne::Err::Constant - error-template and low-level error-mode constants for WebDyne


=head1 SYNOPSIS


 use WebDyne::Err::Constant;

=head1 DESCRIPTION

C<WebDyne::Err::Constant> defines constants used by the WebDyne error subsystem. It is a small companion module for locating the bundled error template and controlling whether low-level error output should be rendered as HTML or plain text.


=head1 CONSTANTS

=over

=item *

B<WEBDYNE_ERR_TEMPLATE>

Absolute path to the bundled C<error.psp> template used for HTML error rendering.



=item *

B<WEBDYNE_ERROR_TEXT (0)>

When true, render errors as C<text/plain> instead of HTML.



=item *

B<WEBDYNE_ERROR_EXIT (0)>

When true, signal that error handling should terminate the child/request flow after output.



=back


=head1 METHODS

=over

=item *

B<class_dn($class)>

Internal helper that resolves the installed directory for a package name by consulting C<%INC>.



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
