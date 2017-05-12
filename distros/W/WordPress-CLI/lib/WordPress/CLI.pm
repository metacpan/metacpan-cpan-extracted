package WordPress::CLI;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)/g;

1;

__END__

=pod

=head1 NAME

WordPress::CLI - command line access to wordpress

=head1 DESCRIPTION

This is a set of collected scripts to enable command line access to wordpress, remotely,
via xml rpc.
None of this is meant as API. You have been warned.

=head1 SEE ALSO

Main documentation..

=over 4

=item L<bin/wordpress-upload-post> - create a new post in wordpress

=item L<bin/wordpress-upload-media> - upload a file to wordpress

=item L<bin/wordpress-info> - get info on posts and files etc

=back

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut



