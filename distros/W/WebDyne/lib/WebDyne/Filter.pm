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
package WebDyne::Filter;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules.
#
use WebDyne::Filter::Constant;
use WebDyne::Util;
use Data::Dumper;


#  Version information
#
$VERSION='3.006';


#  Shortcut error handler.
#
require WebDyne::Err;
*err_html=\&WebDyne::Err::err_html || *err_html;


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
    my $class=shift();
    my $self_cr=UNIVERSAL::can(scalar(caller), 'self') || return;
    my $self=$self_cr->()                              || return;

    $self->set_handler('WebDyne::Chain');
    my $meta_hr=$self->meta();
    push @{$meta_hr->{'webdynechain'}}, $class;


}


sub handler : method {


    #  Get class, request object
    #
    my ($self, $r, @param)=@_;
    debug("$self, r: $r, param: %s", Dumper(\@param));
    
    
    #  Modify request object
    #
    $self->request($r, @param);
    

    #  Pass to next handler after intercepting print() routine
    #
    my $print_cr=ref($r)->can('print');
    local *{ref($r).'::print'}=sub { $print_cr->($_[0], &response($self, @_)) };
    return $self->SUPER::handler($r, @param);

}


sub request {

    my ($self, $r, @param)=@_;
    debug("$self, r: $r, param: %s", Dumper(\@param));
    if (ref(my $cr=$r->dir_config('WebDyneFilterRequest')) eq 'CODE') {
        debug("calling dir_config request filter handler: $cr");
        return $cr->($self, $r, @param);
    }
    elsif (ref($cr=$WEBDYNE_FILTER_REQUEST_CR) eq 'CODE') {
        debug("calling global request filter handler: $cr");
        return $cr->($self, $r, @param);
    }
    else {
        debug("no request filter handler, cr: $cr");
    }
    
}


sub response {

    my ($self, $r, $html_sr)=@_;
    if (ref(my $cr=$r->dir_config('WebDyneFilterResponse')) eq 'CODE') {
        debug("calling dir_config respones filter handler: $cr");
        return $cr->($self, $r, $html_sr);
    }
    elsif (ref($cr=$WEBDYNE_FILTER_RESPONSE_CR) eq 'CODE') {
        debug("calling response filter handler: $cr");
        return $cr->($self, $r, $html_sr);
    }
    else {
        debug("no repsonse filter handler, cr: $cr");
        return $html_sr;
    }
    
}

__END__

=begin markdown

# WebDyne::Filter #

# NAME #

WebDyne::Filter - request and response filter module for the WebDyne handler chain

# SYNOPSIS #

```perl
__PERL__
use WebDyne::Filter;
```

# DESCRIPTION #

`WebDyne::Filter` is a chaining module that intercepts WebDyne request handling so request and response filter callbacks can be run around the normal page lifecycle.

When imported from a page `__PERL__` block, it switches the page to `WebDyne::Chain` handling and adds itself to the active chain.

# METHODS #

* **request($self, $r, @param)**

    Run the request-side filter callback if one is configured. The module first checks `dir_config('WebDyneFilterRequest')`, then the global `WEBDYNE_FILTER_REQUEST_CR`.

* **response($self, $r, $html_sr)**

    Run the response-side filter callback if one is configured. The module first checks `dir_config('WebDyneFilterResponse')`, then the global `WEBDYNE_FILTER_RESPONSE_CR`.

* **handler($self, $r, @param)**

    Internal chaining handler that runs the request filter, wraps the response `print()` method, and passes control to the next handler in the chain.

# OPTIONS #

`WebDyne::Filter` does not take import-time options of its own. Configure filter callbacks through `WebDyne::Filter::Constant` or directory configuration.

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


=head1 WebDyne::Filter


=head1 NAME

WebDyne::Filter - request and response filter module for the WebDyne handler chain


=head1 SYNOPSIS


 __PERL__
 use WebDyne::Filter;

=head1 DESCRIPTION

C<WebDyne::Filter> is a chaining module that intercepts WebDyne request handling so request and response filter callbacks can be run around the normal page lifecycle.

When imported from a page C<__PERL__> block, it switches the page to C<WebDyne::Chain> handling and adds itself to the active chain.


=head1 METHODS

=over

=item *

B<request($self, $r, @param)>

Run the request-side filter callback if one is configured. The module first checks C<dir_config('WebDyneFilterRequest')>, then the global C<WEBDYNE_FILTER_REQUEST_CR>.



=item *

B<response($self, $r, $html_sr)>

Run the response-side filter callback if one is configured. The module first checks C<dir_config('WebDyneFilterResponse')>, then the global C<WEBDYNE_FILTER_RESPONSE_CR>.



=item *

B<handler($self, $r, @param)>

Internal chaining handler that runs the request filter, wraps the response C<print()> method, and passes control to the next handler in the chain.



=back


=head1 OPTIONS

C<WebDyne::Filter> does not take import-time options of its own. Configure filter callbacks through C<WebDyne::Filter::Constant> or directory configuration.


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
