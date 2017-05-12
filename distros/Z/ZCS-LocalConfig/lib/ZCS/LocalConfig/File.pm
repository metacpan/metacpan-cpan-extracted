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

package ZCS::LocalConfig::File;

use strict;
use warnings;
use XML::Parser ();
use base qw(ZCS::LocalConfig::_base);

our $VERSION = 1.0;

{
    my $File;

    sub file {
        my ( $self, $value ) = @_;
        if ( ref($self) ) {
            $self->{file} = $value if $value;
            return $self->{file} if $self->{file};
        }
        $File = $value if $value;
        return $File || "/opt/zimbra/conf/localconfig.xml";
    }
}

sub load {
    my ($self) = @_;

    my $file   = $self->file;
    my $parser = XML::Parser->new(
        ErrorContext => 2,
        Style        => "Objects",
    );

    # parsefile may die
    local ($@);
    my $parsed = eval { $parser->parsefile($file); };
    if ($@) {
        chomp( my $err = $@ );
        return $self->_set_err( 1, "load: parsefile '$file' failed: $@" );
    }

    my @tree = @{ ( $parsed || [] ) };
    my $conf_tree = [];
    foreach my $o (@tree) {
        if ( ref($o) =~ /::localconfig$/ ) {
            $conf_tree = $o->Kids;
            last;
        }
    }

    my %lc;
    foreach my $o (@$conf_tree) {

        # inspect ZCS::LocalConfig::File::key objects
        next unless ref($o) =~ /::key$/;
        $lc{ $o->name } = $o->value;
    }

    $self->_set_err( 0, "load: no data returned" ) unless (%lc);
    $self->_set_conf( \%lc );
    return $self;
}

package ZCS::LocalConfig::File::Characters;
sub Text { return $_[0]->{Text}; }

package ZCS::LocalConfig::File::localconfig;
sub Kids { return $_[0]->{Kids}; }

package ZCS::LocalConfig::File::key;
sub Kids { return $_[0]->{Kids}; }
sub name { return $_[0]->{name}; }

sub value {
    foreach my $o ( @{ $_[0]->{Kids} } ) {
        next unless ref($o) =~ /::value$/;
        return $o->value;
    }
}

package ZCS::LocalConfig::File::value;

sub value {
    foreach my $o ( @{ $_[0]->{Kids} } ) {
        next unless ref($o) =~ /::Characters$/;
        return $o->Text;
    }
}

1;
