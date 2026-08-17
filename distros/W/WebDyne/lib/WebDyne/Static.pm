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


package WebDyne::Static;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  Utilities, constants
#
use WebDyne::Constant;
use WebDyne::Util;


#  Version information in a format
#
$VERSION='3.015';


#  Debug
#
debug("%s loaded, version $VERSION");


#  And done
#
1;

#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    my $meta_hr=$self->meta()                         || return err();
    $meta_hr->{'static'}=1;

}


sub handler : method {


    #  Handler is a no-op, all work is done by filter code. Need a handler so
    #  module is seen by WebDyne autoload method when tracking back through
    #  chained modules
    #
    my $self=shift();
    $self->static(1);
    $self->SUPER::handler(@_);

}
__END__

=begin markdown

# WebDyne::Static #

# NAME #

WebDyne::Static - WebDyne module to flag pages as static and compile once to HTML

# SYNOPSIS #

```
#  Sample time.psp compiled to static HTML. Every time this page is requested it will show
#  the same time - the time it was first run/compiled
#
<start_html>
This page was first loaded at <? localtime ?>
__PERL__
use WebDyne::Static;
```

# DESCRIPTION #

The WebDyne::Static module will flag that all dynamic components of a page should be run at compile time, and the resulting HTML saved as a static file which will be served on subsequent requests.

The WebDyne framework will monitor for changes in the source file and recompile the page to regenerate the static HTML output if the source \.psp file is updated.

`use WebDyne::Static;` is intended to be called from within a WebDyne page `__PERL__` block. In code, the module import routine only acts when a current WebDyne page object is available, so using it outside normal WebDyne page execution has no effect.

# METHODS #

* **static()**

    Get or set the static attribute for this page. This method is inherited from the main `WebDyne` class. When setting the static attribute for a page it is only set for that instance of the page. To set a page as permanently static \(except on source file update) use the WebDyne::Static module as per synopsis, or update the meta data via `$self->meta->{&#39;static&#39;}=1`.

* **handler()**

    Internal chaining handler used by the module. It marks the current page instance as static and then passes control back to the normal WebDyne handler flow. It is not typically called directly.

# OPTIONS #

WebDyne::Static does not expose any options to the import function when called via use.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Static


=head1 NAME

WebDyne::Static - WebDyne module to flag pages as static and compile once to HTML


=head1 SYNOPSIS


 #  Sample time.psp compiled to static HTML. Every time this page is requested it will show
 #  the same time - the time it was first run/compiled
 #
 <start_html>
 This page was first loaded at <? localtime ?>
 __PERL__
 use WebDyne::Static;

=head1 DESCRIPTION

The WebDyne::Static module will flag that all dynamic components of a page should be run at compile time, and the resulting HTML saved as a static file which will be served on subsequent requests.

The WebDyne framework will monitor for changes in the source file and recompile the page to regenerate the static HTML output if the source .psp file is updated.

C<use WebDyne::Static;> is intended to be called from within a WebDyne page C<__PERL__> block. In code, the module import routine only acts when a current WebDyne page object is available, so using it outside normal WebDyne page execution has no effect.


=head1 METHODS

=over

=item *

B<static()>

Get or set the static attribute for this page. This method is inherited from the main C<WebDyne> class. When setting the static attribute for a page it is only set for that instance of the page. To set a page as permanently static (except on source file update) use the WebDyne::Static module as per synopsis, or update the meta data via C<<< $self->meta->{&#39;static&#39;}=1 >>>.



=item *

B<handler()>

Internal chaining handler used by the module. It marks the current page instance as static and then passes control back to the normal WebDyne handler flow. It is not typically called directly.



=back


=head1 OPTIONS

WebDyne::Static does not expose any options to the import function when called via use.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au> and contributors.


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer E<lt>andrew.speer@isolutions.com.auE<gt>.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

E<lt>L<http://dev.perl.org/licenses/&gt;>

=cut
