package VUser::Widget;
use warnings;
use strict;

# Copyright 2005 Randy Smith
# $Id: Widget.pm,v 1.1 2005-04-05 14:59:20 perlstalker Exp $

sub new
{
    my $class = shift;
    my $self = {'size' => '20',
		'default' => ''
		};
    bless $self, $class;

    $self = $self->init;

    return $self;
}

sub init
{
    my $self = shift;
    return $self;
}

sub show { return; }

sub AUTOLOAD
{
    use vars('$AUTOLOAD');
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*::(?:(?:get|set)_)?//;

    if (exists $self->{$name}) {
	$self->{$name} = $_[0] if defined $_[0];
	return $self->{$name};
    } else {
	return undef;
    }
}

1;

__END__

=head1 NAME

VUser::Widget - Super class for all defined Widgets.

=head1 SYNOPSIS

=head1 AUTHORS

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
