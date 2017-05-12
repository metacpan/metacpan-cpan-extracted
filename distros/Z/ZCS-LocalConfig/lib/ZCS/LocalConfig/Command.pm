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

package ZCS::LocalConfig::Command;

use strict;
use warnings;
use IO::File ();
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use base qw(ZCS::LocalConfig::_base);

our $VERSION = 1.0;

{
    my $Command;

    sub command {
        my ( $self, $value ) = @_;
        if ( ref($self) ) {
            $self->{command} = $value if $value;
            return $self->{command} if $self->{command};
        }
        $Command = $value if $value;
        return $Command || "/opt/zimbra/bin/zmlocalconfig";
    }
}

sub load {
    my ( $self, @keys ) = ( shift, @_ );

    my $args = { opts => ["--show"] };
    $args = shift(@keys) if ( @keys and ref( $keys[0] ) eq "HASH" );

    my @opts = ( $args->{opts} ? @{ $args->{opts} } : () );
    my @cmd = ( $self->command, @opts, @keys );

    local ($!);
    my $tout = IO::File->new
      or return $self->_set_err( 1, "load: open OUT file failed: $!" );
    my $terr = IO::File->new_tmpfile
      or return $self->_set_err( 1, "load: open ERR file failed: $!" );

    local ($@);
    my $pid = open3( gensym(), $tout, $terr, @cmd );
    return $self->_set_err( 1, "load: command '@cmd' failed: $@" ) if $@;
    return $self->_set_err( 1, "load: fork '@cmd' failed" )        if !$pid;

    my %lc;
    while ( my $line = <$tout> ) {
        chomp($line);
        my ( $key, $val ) = split( /\s+=\s+/, $line, 2 );
        $lc{$key} = $val;
    }
    close($tout);

    waitpid( $pid, 0 );
    seek( $terr, 0, 0 );

    my @err;
    while ( my $line = <$terr> ) {
        chomp($line);
        push( @err, $line );
    }
    close($terr);

    return $self->_set_err( 1, "load: " . join( "; ", @err ) )
      if (@err);

    $self->_set_err( 0, "load: no data returned" ) unless (%lc);
    $self->_set_conf( \%lc );
    return $self;
}

1;
