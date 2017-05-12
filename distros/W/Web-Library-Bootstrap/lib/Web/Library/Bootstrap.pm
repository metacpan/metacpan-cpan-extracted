package Web::Library::Bootstrap;
use Moose;
with qw(Web::Library::Provider Web::Library::SimpleAssets);
our $VERSION = '0.05';
sub latest_version { '3.0.3' }

sub version_map {

    # all versions contain the same CSS and JS files
    +{  default => {
            css        => ['/css/bootstrap.min.css'],
            javascript => ['/js/bootstrap.min.js']
        }
    };
}
1;

=pod

=head1 NAME

Web::Library::Bootstrap - Distribution wrapper around Bootstrap

=head1 SYNOPSIS

    my $library_manager = Web::Library->instance;
    $library_manager->mount_library({ name => 'Bootstrap' });

=head1 DESCRIPTION

This is a distribution wrapper around Twitter Bootstrap. It enables you to
include the client-side library in multiple Web application projects with very
little effort. See L<Web::Library> for the general concept and how to use it
with L<Catalyst>.

=head1 LIBRARY VERSIONS

The following versions are available. For each version all included files are
listed. Files marked with an asterisk are included in that versions' asset
list - see L<Web::Library>'s C<css_link_tags_for()> and C<script_tags_for()>
methods for an explanation of the concept.

=over 4

=item Version 2.3.0
=item Version 2.3.1
=item Version 2.3.2

      css/bootstrap-responsive.css
      css/bootstrap-responsive.min.css
      css/bootstrap.css
    * css/bootstrap.min.css
      img/glyphicons-halflings-white.png
      img/glyphicons-halflings.png
      js/bootstrap.js
    * js/bootstrap.min.js

=item Version 3.0.3 (the default)

      css/bootstrap-theme.css
      css/bootstrap-theme.min.css
      css/bootstrap.css
    * css/bootstrap.min.css
      fonts/glyphicons-halflings-regular.eot
      fonts/glyphicons-halflings-regular.svg
      fonts/glyphicons-halflings-regular.ttf
      fonts/glyphicons-halflings-regular.woff
      js/bootstrap.js
    * js/bootstrap.min.js

=back

=head1 LIBRARY WEBSITE

Twitter Bootstrap can be found at L<http://twitter.github.io/bootstrap/>.

=head1 AUTHORS

The following person is the author of all the files provided in
this distribution EXCEPT Twitter Bootstrap files found in C<share/>.

Marcel Gruenauer C<< <marcel@cpan.org> >>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

Twitter Bootstrap is licensed under L<CC BY 3.0|http://creativecommons.org/licenses/by/3.0/>.

The following copyright notice applies to all files provided in this
distribution EXCEPT Twitter Bootstrap files found in C<share/>.

This software is copyright (c) 2013 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

