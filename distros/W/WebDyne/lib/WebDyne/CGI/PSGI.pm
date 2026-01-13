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
package WebDyne::CGI::PSGI;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD @ISA);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules
#
use WebDyne::Util;


#  External modules
#
use Data::Dumper;
use CGI::Simple;
use Plack::Request;
@ISA=qw(Plack::Request CGI::Simple);


#  Version information
#
$VERSION='2.066';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#==============================================================================


sub new {


    #  New instance of Plack::Request with CGI interface
    #
    my ($class, $r, %param)=@_;
    debug("class: $class, r: $r, param: %s", Dumper(\%param));
    my $cgi_or=Plack::Request->new($r->env()) ||
        return err('unable to get Plack::Request objedt');
    my $self=bless($cgi_or, __PACKAGE__);
    while (my ($key, $value) = each %param) {
        map $self->param($key, $value)
    }
    return $self;
    
}


sub Vars {

    my $hr=shift()->parameters();
    return wantarray ? %{$hr} : $hr
    
}


sub param {


    #  Get or set param
    #
    my ($self, $key, @value)=@_;
    
    
    #  Getting or setting ? Some handlers can't handle updates 
    #  so take care of differently
    #
    if (@value) {
    
        #  Set value
        #
        debug("updating param: $key to values: %s", Dumper(\@value));
        return $self->parameters->set($key, @value);;

    }
    elsif ($key) {
    
    
        #  Get single value
        #
        debug("returning values for key: $key");
        return wantarray ? $self->Vars()->get_all ($key) : $self->Vars()->get($key);

    }
    else {
    
        #  Get all param names
        #
        debug('returning parameter names');
        return keys %{$self->Vars()};
        
    }

}


sub delete {

    #  Delete a param
    #
    my ($self, $key)=@_;
    return unless $key;
    return $self->Vars()->remove($key);

}    


sub delete_all {

    #  Delete all params
    #
    my $self=shift();
    return $self->Vars()->clear();
    
}

1;

