#
#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2017 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#
package WebDyne::Cache;


#  Compiler Pragma
#
use strict qw(vars);
use vars qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules.
#
use WebDyne::Constant;
use WebDyne::Base;


#  Version information
#
$VERSION='1.248';


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
    my $self=$self_cr->() || return;
    my %param=(@param == 1) ? (cache => @param) : @param;
    my $meta_hr=$self->meta() || return err ();
    $meta_hr->{'cache'}=$param{'cache'};

}


sub handler : method {


    #  Handler is a no-op, all work is done by filter code. Need a handler so
    #  module is seen by WebDyne autoload method when tracking back through
    #  chained modules
    #
    my ($self, $r)=(shift, shift);
    my $cache=$r->dir_config('WebDyneCacheHandler') ||
        return $self->err_html(
        'unable to get cache handler name - have you set the WebDyneCacheHandler var ?'
        );
    $self->cache($cache);
    $self->SUPER::handler($r, @_);

}

