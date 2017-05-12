package Web::Library::DataTables;
use Moose;
with qw(Web::Library::Provider Web::Library::SimpleAssets);
our $VERSION = '0.04';
sub latest_version { '1.9.4' }
sub version_map {

    # all versions contain the same CSS and JS files
    +{  default => {
            css        => ['/css/datatables.css'],
            javascript => ['/js/jquery.dataTables.min.js']
        }
    };
}
1;

=pod

=head1 NAME

Web::Library::DataTables - Distribution wrapper around DataTables

=head1 SYNOPSIS

    my $library_manager = Web::Library->instance;
    $library_manager->mount_library({ name => 'DataTables' });

=head1 DESCRIPTION

This is a distribution wrapper around the jQuery plugin DataTables. It enables
you to include the client-side library in multiple Web application projects
with very little effort. See L<Web::Library> for the general concept and how to
use it with L<Catalyst>.

DataTables is a jQuery plugin and as such requires jQuery. However, this
distribution does not define a dependency on L<Web::Library::jQuery> because
you might want to load jQuery in some other way, and in any case it can't make
an assumption about which version of jQuery you want to use. Therefore, you
might want to use it this way:

    my $library_manager = Web::Library->instance;
    $library_manager->mount_library({ name => 'jQuery' });
    $library_manager->mount_library({ name => 'DataTables' });

=head1 LIBRARY VERSIONS

The following versions are available. For each version all included files are
listed. Files marked with an asterisk are included in that versions' asset
list - see L<Web::Library>'s C<css_link_tags_for()> and C<script_tags_for()>
methods for an explanation of the concept.

=over 4

=item Version 1.9.4 (the default)

    * css/datatables.css
      images/back_disabled.png
      images/back_enabled.png
      images/back_enabled_hover.png
      images/forward_disabled.png
      images/forward_enabled.png
      images/forward_enabled_hover.png
      images/sort_asc.png
      images/sort_asc_disabled.png
      images/sort_both.png
      images/sort_desc.png
      images/sort_desc_disabled.png
      js/DT_bootstrap.js
    * js/jquery.dataTables.min.js

The file C<js/DT_bootstrap.js> makes DataTables work with Twitter Bootstrap,
but is not included in the JavaScript assets list because if you don't use
Bootstrap, you don't need this file. Therefore you have to load it manually
like this:

    <body>
        ...
        [% web_library.script_tags_for('Bootstrap', 'jQuery', 'DataTables') %]
        <script src="/js/DT_bootstrap.js" type="text/javascript"></script>
    </body>

=back

=head1 LIBRARY WEBSITE

DataTables can be found at L<http://www.datatables.net/>.

=head1 AUTHORS

The following person is the author of all the files provided in
this distribution EXCEPT DataTables files found in C<share/>.

Marcel Gruenauer C<< <marcel@cpan.org> >>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

DataTables is dual licensed under the L<GPL v2 license|http://www.datatables.net/license_gpl2>
or a L<BSD (3-point) license|http://www.datatables.net/license_bsd>.

The following copyright notice applies to all files provided in this
distribution EXCEPT DataTables files found in C<share/>.

This software is copyright (c) 2013 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

