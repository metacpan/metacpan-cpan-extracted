############################################################
#
#   $Id: Comic.pm,v 1.5 2006/01/10 15:45:44 nicolaw Exp $
#   WWW::Comic - Retrieve Comic of the day comic strip images
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package WWW::Comic;
# vim:ts=4:sw=4:tw=78

use strict;
use Carp qw(carp croak);
use WWW::Comic::Plugin qw();
use Module::Pluggable(
			search_path => [ __PACKAGE__.'::Plugin' ],
			instantiate => 'new',
			sub_name => '_plugins',
		);

use constant DEBUG => $ENV{DEBUG} ? 1 : 0;
use vars qw($VERSION $AUTOLOAD);
$VERSION = '1.06' || sprintf('%d.%02d', q$Revision$ =~ /(\d+)/g);


#################################
# Public methods

sub new {
	ref(my $class = shift) && croak 'Class name required';
	my $self = { plugins => [ __PACKAGE__->_plugins() ] };
	bless $self, $class;
	DUMP('$self',$self);
	return $self;
}

sub comics {
	my $self = shift;
	my $comics = $self->_comics_to_plugins(@_);
	return sort(keys(%{$comics}));
}

sub strip_url {
	my $self = shift;
	my %param = $self->_parse_params(@_);
	my $plugin = $self->_plugin_to_handle_comic($param{comic});
	return $plugin->strip_url(%param);
}

sub get_strip {
	my $self = shift;
	my %param = $self->_parse_params(@_);
	my $plugin = $self->_plugin_to_handle_comic($param{comic});
	return $plugin->get_strip(%param);
}

sub mirror_strip {
	my $self = shift;
	my %param = $self->_parse_params(@_);
	my $plugin = $self->_plugin_to_handle_comic($param{comic});
	return $plugin->mirror_strip(%param);
}

sub plugins {
	my $self = shift;
	my @plugins = ();
	push @plugins, map { ref($_) } @{$self->{plugins}};
	return @plugins;
}

sub AUTOLOAD {
	my $self = shift;
	my %param = $self->_parse_params(@_);
	my $plugin = $self->_plugin_to_handle_comic($param{comic});

	(my $name = $AUTOLOAD) =~ s/.*://;
	if (UNIVERSAL::can($plugin,$name)) {
		return $plugin->$name(%param);
	}

	croak "Plugin ".ref($plugin)." does not support method ${name}()";
}

sub DESTROY {}




#################################
# Private methods

sub _plugin_to_handle_comic {
	my ($self,$comic) = @_;

	my $plugin = undef;
	my $comic_plugins = $self->_comics_to_plugins(@_);
	while (my ($k,$v) = each %{$comic_plugins}) {
		if (lc($k) eq lc($comic)) {
			$plugin = $v;
			last;
		}
	}

	croak "No plugin found for comic '$comic'"
		unless (defined($plugin) && ref($plugin) &&
				UNIVERSAL::isa($plugin, __PACKAGE__.'::Plugin'));

	return $plugin;
}

sub _comics_to_plugins {
	my $self = shift;

	my %comics;
	for my $plugin (@{$self->{plugins}}) {
		for my $comic ($plugin->comics(@_)) {
			$comics{$comic} = $plugin if defined $comic;
		}
	}

	return \%comics;
}

sub _parse_params {
	my $self = shift;
	if (@_ % 2) {
		croak "Odd number of paramaters passed when even expected";
	} else {
		my %params = @_;
		croak "Missing mandatory 'comic' paramater"
			unless (exists($params{comic}) && $params{comic} =~ /\S+/);
	}
	return @_;
}

sub TRACE {
	return unless DEBUG;
	carp(shift());
}

sub DUMP {
	return unless DEBUG;
	eval {
		require Data::Dumper;
		carp(shift().': '.Data::Dumper::Dumper(shift()));
	}
}


1;


=pod

=head1 NAME

WWW::Comic - Retrieve comic strip images

=head1 SYNOPSIS

 use strict;
 use WWW::Comic qw();
 
 # Create a WWW::Comic object
 my $wc = new WWW::Comic;
 
 # Get a list of supported comics
 my @comics = $wc->comics;
 
 # Allow HTTP requests to retrieve a full list of supported
 # comics if necessary (some plugins may not know what comics
 # they support until they make an HTTP request)
 my @comics = $wc->comics(probe => 1);
 
 for my $comic (@comics) {
     # Get the most recent comic strip URL for $comic
     my $url = $comic->strip_url(comic => $comic);
      
     # Download the most recent comic strip
     # for $comic in to $blob
     my $blob = $comic->get_strip(comic => $comic);
      
     # Write the most recent comic strip for
     # $comic to disk
     my $filename = $comic->mirror_strip(comic => $comic);
 }
 
=head1 DESCRIPTION

This module will download cartoon comic strip images from various
websites and return a binary blob of the image, or write it to
disk. Multiple comic strips can be supported through subclassed
plugin modules.

A number of plugin modules are bundled as part of this distrubution.
You may want to refer to their documentation for any additional
custom methods and features. Specifically, L<WWW::Comic::Plugin::UFS>
and L<WWW::Comic::Plugin::uComics> require use of the C<probe>
paramater with the C<comics> method on order to retrieve a list
of supported commics.

To find out what plugin modules you currently have installed and
available, run the following:

 perl -MWWW::Comic -MData::Dumper -e"print Dumper([WWW::Comic->new->plugins]);"

=head1 METHODS

=head2 new

 my $wc = new WWW::Comic;

Creates a new WWW::Comic object.

=head2 comics

 my @comics = $wc->comics(probe => 1);
 
Returns a list of available comics. The C<probe> paramater is
optional. (See below).

=over 4

=item probe

This paramater is an optional boolean value supported by a few
plugins that do not automatically know what comics they support.
Specifying a boolean true value for this paramater will tell those
plugins that they should make HTTP requests to find out what comics
they can make available. Plugins should cache this information in
memory once they have performed an initial probe.

=back

=head2 strip_url

 # Get the URL of the most recent "mycomic" comic image
 my $url = $wc->strip_url(comic => "mycomic");
 
 # Get the URl of a specific "mycomic" comic image
 my $specificStripUrl = $wc->strip_url(
                             comic => "mycomic",
                             id => 990317
                         );

Returns the URL of a comic strip. The C<comic> paramater is
mandatory and must be a valid supported comic as listed by the
C<comics()> method. The most recent comic strip image URL will
be returned unless otherwise specified (see the C<id> paramater
below).

This method will return an C<undef> value upon failure.

The C<id> paramater is optional and can be used to specify a specific
comic (if supported by the plugin in question). Comic IDs are typically
date based in some way, but this is unique to each comic and follows
no special format for the purposes of this module. See each plugin
module's documentation for further information.

=over 4

=item comic

This paramater is mandatory. It specifies the comic that this method
should process. See the C<comics()> method.

=item id

This paramater is optional. It specifies a specfic comic that should
be processed.

=back

=head2 get_strip

 # Retrieve the most recent "mycomic" comic strip image
 my $imageBlob = $wc->get_strip(comic => "mycomic");
 
 # Retrieve a specific "mycomic" comic strip image
 my $image2 = $wc->get_strip(
                        comic => "mycomic",
                        id => "0042304973"
                    );

Downloads a copy of a comic strip image and returns the binary data
as a scalar. The C<comic> paramater is mandatory and must be a valid
supported comic as listed by the C<comics()> method. The most recent
comic strip image will be returned unless otherwise specified.

This method will return an C<undef> value upon failure.

=over 4

=item comic

This paramater is mandatory. It specifies the comic that this method
should process. See the C<comics()> method.

=item id

This paramater is optional. It specifies a specfic comic that should
be processed.

=item url

This paramater is optional. It specifies a specific comic that should
be processed. If specified it must be a fully qualified and valid absolute
HTTP URL. This paramater is typically only used when being called
indirectly by the C<mirror_strip()> method.

=back

=head2 mirror_strip

 # Write the most recent "mycomic" comic strip to disk
 # and return the name of the file that was written
 my $filename = $wc->mirror_strip(comic => "mycomic");
 
 # Write the "mycomic" comic strip image (reference 132)
 # to disk, specifcally to mycomic.gif, and return the
 # actual filename that was written to disk in to $file2
 my $file2 = $wc->mirror_strip(
                       comic => "mycomic",
                       id => "132",
                       filename => "mycomic.gif"
                  );

Download a copy of a comic strip image and write it to disk,
returning the name of the file that was actually written. This
method accepts the same paramaters as the C<get_strip()> method,
with the addition of the C<filename> paramater.

This method will return an C<undef> value upon failure.

=over 4

=item comic

This paramater is mandatory. It specifies the comic that this method
should process. See the C<comics()> method.

=item id

This paramater is optional. It specifies a specfic comic that should
be processed.

=item url

This paramater is optional. It specifies a specific comic that should
be processed. If specified it must be a fully qualified and valid absolute
HTTP URL.

=item filename

This paramater is optional. It specifiec the target filename that you
would like to be written to disk. If you do not supply an image file
extension, one will be added for you automatically. If you specify an
image file extension that differs to the file format of the file that
is to ultimately be written disk, it will be altered for you
automatically.

=back

=head2 plugins

 my @plugins = $wc->plugins;

Return a list of loaded plugins.

=head1 PLUGINS

Support for different comics is handled through the L<WWW::Comic::Plugin>
superclass. See the POD for L<WWW::Comic::Plugin> on how to create a new
plugin.

=head1 SEE ALSO

L<WWW::Comic::Plugin>, L<WWW::Dilbert>, L<WWW::VenusEnvy>

=head1 VERSION

$Id: Comic.pm,v 1.5 2006/01/10 15:45:44 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut


