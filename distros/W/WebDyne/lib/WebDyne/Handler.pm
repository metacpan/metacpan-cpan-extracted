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
package WebDyne::Handler;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules.
#
use WebDyne::Constant;
use WebDyne::Util;


#  Version information
#
$VERSION='3.020';


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  And done
#
1;

#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my ($class, @param)=@_;
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    my %param=(@param == 1) ? (handler => @param) : @param;
    $self->set_handler($param{'handler'});

}
__END__

=begin markdown

# WebDyne::Handler #

# NAME #

WebDyne::Handler - WebDyne handler module, forces use non-chained WebDyne handler. 

# SYNOPSIS #

SYNOPSIS

```perl
#  Basic usage in a simple file in a directory which forces WebDyne::Chain usage
#
<start_html>
Server local time is: <? localtime ?>
__PERL__
use WebDyne::Handler;

```

# DESCRIPTION #

WebDyne::Handler module forces plain \(non-chained) processing of a page. This can be useful in an environment where WebDyne::Chain has been configured to process all pages in a directory via alternate configuration options \(e.g. Dir_config or other settings).

Using this module will ensure there is no pre or post processing of results by any WebDyne::Chain modules. 

`use WebDyne::Handler;` is intended to be called from within a WebDyne page `__PERL__` block. The import routine updates the current page instance so that subsequent handling uses the nominated handler class directly.

> **WARNING**
> 
> If you use WebDyne::Chain to load an authentication or session tracking module they will not be run on any pages that use this module, which may result in inadvertently allowing unauthenticated access to pages.
>

# USAGE #

WebDyne::Handler is used as per the synopsis.

You can also nominate a specific handler class explicitly:

```perl
__PERL__
use WebDyne::Handler handler => 'WebDyne';
```

or with the single-argument shorthand:

```perl
__PERL__
use WebDyne::Handler 'WebDyne';
```

# METHODS #

WebDyne::Handler does not expose any public methods.

# OPTIONS #

WebDyne::Handler accepts an optional handler class name at import time. The following forms are supported:

* `use WebDyne::Handler;`

    Reset the page to the plain `WebDyne` handler flow.

* `use WebDyne::Handler 'Some::Handler';`

    Use the nominated handler class.

* `use WebDyne::Handler handler => 'Some::Handler';`

    Named form of the same option.

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


=head1 WebDyne::Handler


=head1 NAME

WebDyne::Handler - WebDyne handler module, forces use non-chained WebDyne handler. 


=head1 SYNOPSIS

SYNOPSIS


 #  Basic usage in a simple file in a directory which forces WebDyne::Chain usage
 #
 <start_html>
 Server local time is: <? localtime ?>
 __PERL__
 use WebDyne::Handler;


=head1 DESCRIPTION

WebDyne::Handler module forces plain (non-chained) processing of a page. This can be useful in an environment where WebDyne::Chain has been configured to process all pages in a directory via alternate configuration options (e.g. Dir_config or other settings).

Using this module will ensure there is no pre or post processing of results by any WebDyne::Chain modules. 

C<use WebDyne::Handler;> is intended to be called from within a WebDyne page C<__PERL__> block. The import routine updates the current page instance so that subsequent handling uses the nominated handler class directly.

=over 2

B<WARNING>

If you use WebDyne::Chain to load an authentication or session tracking module they will not be run on any pages that use this module, which may result in inadvertently allowing unauthenticated access to pages.

=back


=head1 USAGE

WebDyne::Handler is used as per the synopsis.

You can also nominate a specific handler class explicitly:


 __PERL__
 use WebDyne::Handler handler => 'WebDyne';
or with the single-argument shorthand:


 __PERL__
 use WebDyne::Handler 'WebDyne';

=head1 METHODS

WebDyne::Handler does not expose any public methods.


=head1 OPTIONS

WebDyne::Handler accepts an optional handler class name at import time. The following forms are supported:

=over

=item *

C<use WebDyne::Handler;>

Reset the page to the plain C<WebDyne> handler flow.



=item *

C<use WebDyne::Handler 'Some::Handler';>

Use the nominated handler class.



=item *

C<<< use WebDyne::Handler handler => 'Some::Handler'; >>>

Named form of the same option.



=back


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au> and contributors.


=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See  L<http://dev.perl.org/licenses/|http://dev.perl.org/licenses/> .

=cut
