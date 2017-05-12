# -*- perl -*-
#
# Text::Smart::Plugin by Daniel Berrange <dan@berrange.com>
#
# Copyright (C) 2004-2006 Daniel P. Berrange <dan@berrange.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id: Plugin.pm,v 1.2 2004/05/13 10:42:37 dan Exp $

=pod

=head1 NAME

  Text::Smart::Plugin - Template Toolkit plugin for Text::Smart

=head1 SYNOPSIS

When creating the L<Template> processing object define a
plugin for smart text:

    my $tt = new Template({
	PLUGINS => {
	    'smarttext' => 'Text::Smart::Plugin'
	    }
    });

Then in a template file:

     [% USE smarttext(type => 'HTML') %]
     [% FILTER smarttext %]

     ... some smart text markup ...

     [% END %]

=head1 DESCRIPTION

This module provides a plugin for the Template-Toolkit to
enable the use of 'smart text', whose syntax is defined by
the L<Text::Smart> module. See that module's manual pages
for details of the markup allowed. See the synopsis section
above for how to use this module in combination with the
Template toolkit.

=head1 METHODS

=over 4

=cut

package Text::Smart::Plugin;

use strict;
use warnings;

use base qw(Template::Plugin);

use Text::Smart::HTML;

our $VERSION = "1.0.1";

=item my $plugin = Text::Smart::Plugin->new()

This creates a new instance of the plugin. This method is called
by the Template Toolkit engine to instantiate the plugin. See the
docs for L<Template> for details about the contract between the
engine and this plugin's constructor.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $context = shift;
    my $options = shift;

    my $filter_factory;
    my $self;
    
    my $plugin;
    if ($options) {
	# create a closure to generate filters with additional options
	$filter_factory = sub {
	    my $context = shift;
	    my $filtopt = ref $_[-1] eq 'HASH' ? pop : { };
	    @$filtopt{ keys %$options } = values %$options;
	    return sub {
		_tt_smarttext(@_, $filtopt);
	    };
	};

	# and a closure to represent the plugin
	$plugin = sub {
	    my $plugopt = ref $_[-1] eq 'HASH' ? pop : { };
	    @$plugopt{ keys %$options } = values %$options;
	    _tt_smarttext(@_, $plugopt);
	};
    }
    else {
	# simple filter factory closure (no legacy options from constructor)
	$filter_factory = sub {
	    my $context = shift;
	    my $filtopt = ref $_[-1] eq 'HASH' ? pop : { };
	    return sub {
		_tt_smarttext(@_, $filtopt);
	    };
	};

	# plugin without options can be static
	$plugin = \&_tt_smarttext;
    }

    # now define the filter and return the plugin
    $context->define_filter('smarttext', [ $filter_factory => 1 ]);
    return $plugin;
}

sub _tt_smarttext {
    my $options = ref $_[-1] eq 'HASH' ? pop : { };
    my $type = defined $options->{type} ? $options->{type} : "HTML";
    if ($type eq 'HTML') {
	my $proc = Text::Smart::HTML->new();

	return $proc->process(join('', @_));
    } else {
	die "Unknown smart text markup type '$type'. Suported types are 'HTML'";
    }
}

1 # So that the require or use succeeds.

__END__

=back

=head1 AUTHORS

Daniel Berrange <dan@berrange.com>

=head1 COPYRIGHT

Copyright (C) 2004-2006 Daniel P. Berrange <dan@berrange.com>

=head1 SEE ALSO

C<perl>, L<Text::Smart(1)>, L<Template(1)>

=cut
                                                                                                         
