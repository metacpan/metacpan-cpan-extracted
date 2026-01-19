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
$VERSION='2.072';


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

