package Wrangler::Plugin;

=pod

=head1 NAME

Wrangler::Plugin - Base class for Wrangler Plugins

=head1 DESCRIPTION

=head2 new($wrangler)

Each Plugin must implement a new() constructor, but apart from blessing this shouldn't
do much, as it is called on Wrangler startup and would slow down. Plugins should
do their init in startup().

=head2 plugin_name()

Must return the name of the Plugin, which must be unique and posssibly short,
as it is currently used for internal/config settings mapping.

=head2  plugin_info()

Should return a description of what the Plugin does. This value is shown in Settings
> Plugins > Info

=head2 plugin_enable()

Wrangler calls this at an arbitrary stage, latest when the Plugin is actually put
to use. This here is where Plugin authors should do any additional module loading,
polling settings, etc.

=head2 plugin_phases()

Each Plugin must register itself via this method for any scope the Plugin code should
be executed. This method must return a hashref where the keys are the scopes pointing
to some true value.

Currently Wrangler offers these phase hooks: "wrangler_startup", "file_context_menu",
"directory_listing", "plugin_settings".

=head2 wrangler_startup()

This is called during Wrangler's startup. Plugins usually use it to "register" their
needed metadata keys with central $wishlist in Wrangler.pm.

=head2 plugin_settings($parent)

Using the $parent that is passed in by Wrangler, the plugin must return a Wx component
that will be displayed in Settings > Plugins > <this plugin>.

=head2 file_context_menu($menu,$selection_ref)

Only required for "context_menu"-Plugins. This method will be called on each Plugin
which has registered itself for the scope "context_menu" via plugin_phases(). Passed
values are a Wx::Menu object and a ref to an richitems array of the current selection.

Plugins are expected to return an arrayref to an array of (1) a Wx::MenuItem,
and (2) a coderef { callback }, and optionally (3) a { post-add-callback } ). The
post-add-callback is code that is executed after the MenuItem has been added to
the Wx::Menu. This is needed for checkboxes which can only be checked after the
Wx::MenuItem has been added to the Wx::Menu.

=head2 directory_listing($filebrowser,$itemId,$richlist_item)

This is called from within the loop over all items of a directory/collection, in
FileBrowser's Populate() method. It allows a Plugin to do per-item manipulations.

=head1 COPYRIGHT & LICENSE

This module is part of L<Wrangler>. Please refer to the main module for further
information and licensing / usage terms.

=cut

use strict;
use warnings;

1;
