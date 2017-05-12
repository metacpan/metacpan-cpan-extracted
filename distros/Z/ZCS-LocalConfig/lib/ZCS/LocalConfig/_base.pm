# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010 Zimbra, Inc.
#
# The contents of this file are subject to the Zimbra Public License
# Version 1.3 ("License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://www.zimbra.com/license.
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied.
# ***** END LICENSE BLOCK *****

package ZCS::LocalConfig::_base;

use strict;
use warnings;

our $VERSION = 1.0;

{
    my ( $Err, $Errstr );
    sub err    { return $Err; }
    sub errstr { return $Errstr; }

    sub _set_err {
        my $self = shift;
        ( $Err, $Errstr ) = @_;
        return undef if $Err;
    }
}

sub _set_conf {
    my ( $self, $conf ) = @_;
    $self->{__conf} = $conf if ( $#_ == 1 );
    return $self->{__conf};
}

sub _conf {
    my ($self) = @_;

    # load localconf into memory first time through
    unless ( $self->{__conf} ) {
        $self->load or return undef;
    }

    return $self->{__conf};
}

sub new {
    my ( $class, @args ) = @_;
    my $self = {@args};
    bless( $self, $class );
    return $self;
}

sub get {
    my ( $self, @args ) = @_;

    my $conf = $self->_conf or return undef;
    if ( @args == 1 ) {
        return $conf->{ $args[0] };
    }
    elsif ( @args > 1 ) {
        my @ret = @{$conf}{@args};
        return wantarray ? @ret : \@ret;
    }
    elsif ( @args == 0 ) {
        return $conf;
    }
    else {
        return $self->_set_err( 1, "get: invalid arguments" );
    }
}

sub set {
    my ( $self, @args ) = @_;

    if ( @args == 2 ) {
        my ( $tag, $value ) = @args;
        my $conf = $self->_conf or return $self->err;
        return $conf->{$tag} = $value;
    }
    else {
        Carp::confess("set: invalid arguments");
    }
}

sub load {
    Carp::confess("load: not implemented!");
}

sub store {
    Carp::confess("store: not implemented!");
}

sub _dump {
    my $self = shift;
    my $conf = $self->get or return $self->err;

    my @data;
    foreach my $k ( sort keys %$conf ) {
        next if ( $k =~ /^_/ or $k =~ /password/i );
        my $v = $conf->{$k};
        if ( ref($v) eq "HASH" ) {
            $v = join(
                ", ",
                map( "$_ => "
                      . (
                        ref( $v->{$_} )
                        ? join( ",", @{ $v->{$_} } )
                        : $v->{$_}
                      ),
                    sort keys %$v )
            );
        }
        elsif ( ref($v) eq "ARRAY" ) {
            $v = join( ", ", @$v );
        }
        push( @data, "$k = $v" ) if ( defined($v) and $v !~ /^\s*$/ );
    }
    return wantarray ? @data : \@data;
}

1;
