package Web::Library::BackboneJS;
use Moose;
with qw(Web::Library::Provider Web::Library::SimpleAssets);
our $VERSION = '0.01';
sub latest_version { '1.1.0' }

sub version_map {

    # all versions contain the same CSS and JS files
    +{  default => {
            css        => [],
            javascript => ['/js/backbone-min.js']
        }
    };
}
1;

=pod

=head1 NAME

Web::Library::BackboneJS - Distribution wrapper around Backbone.js

=head1 SYNOPSIS

    my $library_manager = Web::Library->instance;
    $library_manager->mount_library({ name => 'BackboneJS' });

=head1 DESCRIPTION

This is a distribution wrapper around Backbone.js. It enables you to include
the client-side library in multiple Web application projects with very little
effort. See L<Web::Library> for the general concept and how to use it with
L<Catalyst>.

Backbone needs Underscore.js, so L<Web::Library::UnderscoreJS> is listed as a
dependency.

=head1 LIBRARY VERSIONS

The following versions are available. For each version all included files are
listed. Files marked with an asterisk are included in that versions' asset
list - see L<Web::Library>'s C<css_link_tags_for()> and C<script_tags_for()>
methods for an explanation of the concept.

=over 4

=item Version 1.0.0
=item Version 1.1.0 (the default)

    * js/backbone-min.js

=back

=head1 LIBRARY WEBSITE

Backbone.js can be found at L<http://backbonejs.com/>.

=head1 AUTHORS

The following person is the author of all the files provided in
this distribution EXCEPT Backbone.js files found in C<share/>.

Marcel Gruenauer C<< <marcel@cpan.org> >>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

Backbone.js is licensed under the L<MIT license|https://github.com/jashkenas/backbone/blob/master/LICENSE>.

The following copyright notice applies to all files provided in this
distribution EXCEPT Backbone.js files found in C<share/>.

This software is copyright (c) 2013 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
