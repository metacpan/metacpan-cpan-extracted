package Web::Components::Navigation;

use Web::ComposableRequest::Constants qw( EXCEPTION_CLASS FALSE NUL SPC TRUE );

use HTTP::Status          qw( HTTP_OK );
use Unexpected::Types     qw( ArrayRef Bool HashRef Object PositiveInt Str );
use Web::Components::Util qw( clear_redirect formpost throw );
use Ref::Util             qw( is_hashref );
use Scalar::Util          qw( blessed );
use Type::Utils           qw( class_type );
use Unexpected::Functions qw( UnknownMethod Unspecified );
use HTML::Tiny;
use JSON::MaybeXS;
use Try::Tiny;
use Moo;

=encoding utf-8

=head1 Name

Web::Components::Navigation - Context sensitive menu builder

=head1 Synopsis

   use Web::Components::Navigation;

=head1 Description

Context sensitive menu builder

=head2 JavaScript

Files F<wcom-*.js> are included in the F<share/js> directory of the source
tree. These will be installed to the F<File::ShareDir> distribution level
shared data files. Nothing further is done with these files. They should be
concatenated in sort order by filename and the result placed under the
webservers document root. Link to this from the web applications pages. Doing
this is outside the scope of this distribution

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<confirm_message>

Immutable string. The default "Are you sure ?" message

=cut

has 'confirm_message' => is => 'ro', isa => Str, default => 'Are you sure ?';

=item C<container_class>

Lazy string combining C<container_name> and C<container_layout>. This can be
applied as a class name to the HTML container element by the application's
page layout template

=cut

has 'container_class' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;

      return $self->container_name . SPC . $self->container_layout;
   };

=item C<container_layout>

A mutable string which defaults to C<centred>. Used as a class name in the HTML
it is also shared with the JS code

=cut

has 'container_layout' => is => 'rw', isa => Str, default => 'centred';

=item C<container_name>

An immutable string which defaults to C<standard>. Used as a class name in the
HTML it is also shared with the JS code

=cut

has 'container_name' => is => 'ro', isa => Str, default => 'standard';

=item C<container_tag>

An immutable string which default to C<div>. The HTML element to render

=cut

has 'container_tag' => is => 'ro', isa => Str, default => 'div';

=item C<content_class>

A lazy immutable string which defaults to C<content_name>

=cut

has 'content_class' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { $_[0]->content_name };

=item C<content_name>

An immutable string which defaults to C<panel>. Used as an id and a class name
in the HTML it is also shared with the JS code

=cut

has 'content_name' => is => 'ro', isa => Str, default => 'panel';

=item C<context>

An immutable required weak reference to the C<context> object

=cut

has 'context' =>
   is       => 'ro',
   isa      => Object,
   required => TRUE,
   weak_ref => TRUE;

=item C<control_icon>

An immutable string which defaults to C<user-settings>. The name of the symbol
in the SVG icons file for the user settings menu

=cut

has 'control_icon' => is => 'ro', isa => Str, default => 'user-settings';

=item C<global>

An immutable array reference with an empty default. Contains a list of action
paths used to create the top level of the navigation menus. It is expected
that this will be populated at object construction time

=cut

has 'global' => is => 'ro', isa => ArrayRef, default => sub { [] };

=item C<icons>

A lazy string representation of a partial URI. This should point to an SVG file
containing named symbols. Defaults to C<< img/icons.svg >>

=cut

has 'icons' =>
   is       => 'lazy',
   isa      => Str,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return $self->context->request->uri_for($self->_icons)->as_string;
   };

has '_icons' =>
   is       => 'ro',
   isa      => Str,
   init_arg => 'icons',
   default  => 'img/icons.svg';

=item C<json_view>

An immutable string which defaults to C<json>. Stashed by C<finalise> as the
view which will serialise the response as JSON

=cut

has 'json_view' => is => 'ro', isa => Str, default => 'json';

=item C<link_display>

A lazy string which defaults to either the value is the C<session> if it
exists or the string C<both>. An enumerated type with values; C<both>, C<icon>,
or C<text>. Controls how the C<global> menu display links

=cut

has 'link_display' =>
   is       => 'lazy',
   isa      => Str,
   init_arg => undef,
   default  => sub {
      my $self = shift;
      my $session = $self->context->session;

      return $session->link_display || $self->_link_display;
   };

has '_link_display' =>
   is       => 'ro',
   isa      => Str,
   init_arg => 'link_display',
   default  => 'both';

=item C<logo>

A optional lazy string representation of a partial URI with a null
default. This should point to an image file containing the logo if one is
required

=cut

has 'logo' =>
   is       => 'lazy',
   isa      => Str,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return $self->context->request->uri_for($self->_logo)->as_string
         if $self->_logo;

      return NUL;
   };

has '_logo' => is => 'ro', isa => Str, init_arg => 'logo', default => NUL;

=item C<media_break>

An immutable positive integer with a default of C<680> pixels. When the
display window's <innerWidth> drop below this (due to a resize event)
C<link_display> is set to C<icon> which reduces the display width requirement

=cut

has 'media_break' => is => 'ro', isa => PositiveInt, default => 680;

=item C<menu_location>

A lazy string which defaults to C<header>. Can be set to C<sidebar>. Effects
where the navigation menus are rendered

=cut

has 'menu_location' =>
   is       => 'lazy',
   isa      => Str,
   init_arg => undef,
   default  => sub {
      my $self    = shift;
      my $session = $self->context->session;

      return $session->menu_location || $self->_menu_location;
   };

has '_menu_location' =>
   is       => 'ro',
   isa      => Str,
   init_arg => 'menu_location',
   default  => 'header';

=item C<message_action>

An immutable string which defaults to C<api/navigation_messages>. This is the
action path for the API call that the message object in the JS will make to
collect messages

=cut

has 'message_action' =>
   is      => 'ro',
   isa     => Str,
   default => 'api/navigation_messages';

=item C<messages>

An immutable hash reference with an empty default. The attributes are used to
configure the JS message collection and display code. Attributes are;

=over 3

=item buffer-limit

Maximum number of messages to buffer. Defaults to C<3>

=item display-time

How long in seconds to display each message for. Defaults to C<20> seconds

=back

=cut

has 'messages' => is => 'ro', isa => HashRef, default => sub { {} };

=item C<model>

An immutable required object reference to the model component that is handling
the current request

=cut

has 'model' => is => 'ro', isa => Object, required => TRUE;

=item C<title>

An immutable string which defaults to null. If set will be displayed as the
application title along with the logo in the page header

=cut

has 'title' => is => 'ro', isa => Str, default => NUL;

=item C<title_abbrev>

An immutable string which defaults to C<Nav>. Used to set the pages C<title>
attribute in the HTML head. This is used in turn is used by the browser to
create history links (the back button). Would set this from configuration to
the abbreviation for the application

=cut

has 'title_abbrev' => is => 'ro', isa => Str, default => 'Nav';

=item C<title_entry>

A lazy string. The default constructor sets it to the current pages navigation
label. This is appended to C<title_abbrev> to form the labels in the browser
history

=cut

has 'title_entry' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self  = shift;
      my @parts = split m{ / }mx, $self->context->action;
      my $label = $self->_get_nav_label($parts[0] . '/' . $parts[-1]);

      return (split m{ \| }mx, $label)[0] // NUL;
   };

# Private attributes
has '_base_url' =>
   is      => 'lazy',
   isa     => class_type('URI'),
   default => sub {
      return shift->context->request->uri_for(NUL);
   };

has '_container' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;
      my $tag  = $self->container_tag;

      return $self->_html->$tag($self->_data);
   };

has '_data' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self     = shift;
      my $location = 'navigation-'  . $self->menu_location;
      my $display  = 'link-display-' . $self->link_display;

      return {
         'id'    => 'navigation',
         'class' => "navigation ${location} ${display}",
         'data-navigation-config' => $self->_json->encode({
            'menus'      => $self->_menus,
            'messages'   => $self->_messages,
            'moniker'    => $self->model->moniker,
            'properties' => {
               'base-url'         => $self->_base_url,
               'confirm'          => $self->confirm_message,
               'container-layout' => $self->container_layout,
               'container-name'   => $self->container_name,
               'content-name'     => $self->content_name,
               'control-icon'     => $self->control_icon,
               'icons'            => $self->icons,
               'link-display'     => $self->link_display,
               'location'         => $self->menu_location,
               'logo'             => $self->logo,
               'media-break'      => $self->media_break,
               'skin'             => $self->context->session->skin,
               'title'            => $self->title,
               'title-abbrev'     => $self->title_abbrev,
               'verify-token'     => $self->context->verification_token,
               'version'          => MCat->VERSION,
            },
         }),
      };
   };

has '_html' =>
   is      => 'ro',
   isa     => class_type('HTML::Tiny'),
   default => sub { HTML::Tiny->new };

has '_json' =>
   is      => 'ro',
   isa     => class_type(JSON::MaybeXS::JSON),
   default => sub {
      return JSON::MaybeXS->new( convert_blessed => TRUE, utf8 => FALSE );
   };

has '_lists' => is => 'ro', isa => HashRef, default => sub { {} };

has '_menus' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;

      return { map { $_ => $self->_lists->{$_} } @{$self->_order} };
   };

has '_messages' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self    = shift;
      my $context = $self->context;

      return {
         %{$self->messages},
         'messages-url' => $context->uri_for_action($self->message_action)
      };
   };

has '_name' => is => 'rwp', isa => Str, default => NUL;

has '_order' => is => 'ro', isa => ArrayRef, default => sub { [] };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item C<BUILDARGS>

Wraps around the constructor call. If the C<context> object has a reference to
the C<config> object which has a reference to a C<navigation> attribute, then
that hash reference is merged into the attributes passed to the constructor

=cut

around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr    = $orig->($self, @args);
   my $context = $attr->{context};

   throw Unspecified, ['context'] unless $context;

   return $attr unless $context->can('config');

   my $config = $context->config;

   throw UnknownMethod, [blessed $config, 'navigation']
      unless $config->can('navigation');

   return { %{$attr}, %{$config->navigation} };
};

=item C<crud>

   $self = $self->crud($moniker, $existing_id, $create_id);

A convenience method which calls C<item> up to four times. If C<create_id> is
passed C<item> is called with an action path of C<moniker/create>. The
C<existing_id> is required and C<item> is called three times with the action
paths; C<moniker/delete>, C<moniker/edit> and C<moniker/view>

=cut

sub crud {
   my ($self, $moniker, $existing_id, $create_id) = @_;

   $self->item("${moniker}/create", [$create_id]) if $create_id;
   $self->item(formpost, "${moniker}/delete", [$existing_id]);
   $self->item("${moniker}/edit", [$existing_id]);
   $self->item("${moniker}/view", [$existing_id]);
   return $self;
}

=item C<finalise>

Populates the stash with the data that represents the menu which will be
serialised to JSON

=cut

sub finalise {
   my $self    = shift;
   my $context = $self->context;
   my $request = $context->request;

   return unless $self->is_script_request
      && $request->query_parameters->{navigation};

   $self->_add_global;

   my $data = {
      'container-layout' => $self->container_layout,
      'menus'            => $self->_menus,
      'title-entry'      => $self->title_entry,
      'verify-token'     => $context->verification_token,
   };

   $context->stash(
      code      => HTTP_OK,
      finalised => TRUE,
      json      => $data,
      view      => $self->json_view
   );
   return;
}

=item C<finalise_script_request>

If C<is_script_request> is true then stash an OK HTTP return code. When using
JS navigation all HTTP responses must be OK or the browser (which sniffs the
fetch responses) will automatically navigate

=cut

sub finalise_script_request {
   my $self = shift;

   $self->context->stash(code => HTTP_OK) if $self->is_script_request;

   return;
}

=item C<is_script_request>

Returns true if the request has come from the JS in the browser

=cut

sub is_script_request {
   my $self   = shift;
   my $header = $self->context->request->header('x-requested-with') // NUL;

   return lc $header eq 'xmlhttprequest' ? TRUE : FALSE;
}

=item C<item>

   $self = $self->item('action path', $args, $params);
   $self = $self->item(formpost, 'action path', $args, $params);

The first example will add a single link to the current C<list>. The display
text is set by the C<Nav> subroutine attribute of the endpoint, the C<href>
is supplied by C<context> C<uri_for_action>

In the second example C<formpost> is imported from L<Web::Components::Util>
and causes the rendered menu item to be a form with a button on it (it is
expected that this will be styled like a link). This is used for delete
operations since we don't do deletes with a GET

=cut

sub item {
   my ($self, @args) = @_;

   my $label;

   if (is_hashref $args[0]) {
      $label = shift @args;
      $label->{name} = $self->_get_nav_label($args[0]);
   }
   else { $label = $self->_get_nav_label($args[0]) }

   if ($self->model->is_authorised($self->context, $args[0])) {
      my $list = $self->_lists->{$self->_name}->[1];
      my ($text, $icon);

      if (is_hashref $label) {
         ($text, $icon) = split m{ \| }mx, $label->{name};
         $label->{name} = $text;
         $text = $label;
      }
      else { ($text, $icon) = split m{ \| }mx, $label }

      $icon = $self->context->request->uri_for($icon)
         if $icon && $icon =~ m{ / }mx;

      push @{$list}, [$text => $self->_uri(@args), $icon];
   }
   else { clear_redirect $self->context }

   return $self;
}

=item C<list>

   $self = $self->list('list name', 'optional title');

Sets the current list to the name provided. If this list does not exist it
is created. Once a list has been created C<item> is called to add entries to it

=cut

sub list {
   my ($self, $name, $title) = @_;

   $self->_set__name($name);

   unless (exists $self->_lists->{$name}) {
      $self->_lists->{$name} = [ $title // NUL, [] ];
      push @{$self->_order}, $name;
   }

   return $self;
}

=item C<menu>

   $self = $self->menu('list name');

If the named list exists add it to the current list. This is how you created
nested lists

=cut

sub menu {
   my ($self, $name) = @_;

   my $lists = $self->_lists;

   push @{$lists->{$self->_name}->[1]}, $name if exists $lists->{$name};

   return $self;
}

=item C<render>

Returns the HTML for inclusion on the web page

=cut

sub render {
   my $self = shift;
   my $output;

   $self->_add_global;

   try   { $output = $self->_container }
   catch { $output = $_ };

   return $output;
}

# Private methods
sub _add_global {
   my $self = shift;
   my $list = $self->list('_global');

   for my $action (@{$self->global}) {
      my ($moniker, $method) = split m{ / }mx, $action;

      if ($self->model->is_authorised($self->context, $action)) {
         if ($method and $method eq 'menu') {
            $self->context->models->{$moniker}->menu($self->context);
            $self->_set__name('_global');
         }

         push @{$self->_lists->{$self->_name}->[1]}, $moniker
            if exists $self->_lists->{$moniker};

         $list->item($action);
      }
      else { clear_redirect $self->context }
   }

   return;
}

sub _get_nav_label {
   my ($self, $action) = @_;

   my $attr = try { $self->context->get_attributes($action) };

   return $attr->{Nav}->[0] if $attr && defined $attr->{Nav};

   return NUL;
}

sub _uri {
   my ($self, @args) = @_;

   my $action = $args[0];

   return NUL if $action =~ m{ /menu \z }mx;

   return $self->context->uri_for_action(@args);
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
