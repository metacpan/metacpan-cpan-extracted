package VUser::Extension;
use warnings;
use strict;

# Copyright 2004 Randy Smith
# $Id: Extension.pm,v 1.5 2006-01-04 21:57:48 perlstalker Exp $

our $REVISION = (split (' ', '$Revision: 1.5 $'))[1];
our $VERSION = "0.3.0";

sub revision
{
    my $self = shift;
    my $type = ref($self) || $self;
    no strict 'refs';
    return ${$type."::REVISION"};
}

sub version
{
    my $self = shift;
    my $type = ref($self) || $self;
    no strict 'refs';
    return ${$type."::VERSION"};
}

sub init { return; }

sub unload { return; }

1;

__END__

=head1 NAME

Extension - vuser extension super class

=head1 DESCRIPTION

=head1 METHODS

=head2 depends

This optional function should return a list of extensions that it
depends on. These extensions will be loaded first.

=head2 init

Called when an extension is loaded when vuser starts.

init() will be passed an reference to an ExtHandler object which may be
used to register keywords, actions, etc. and the tied config object.

=head2 unload

Called when an extension is unloaded when vuser exits.

=head2 revision

Returns the extension's revision. This is may return an empty string;

=head2 version

Returns the extensions official version. This man not return an empty string.

=head1 AUTHOR

Randy Smith <perlstalker@gmail.com>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
