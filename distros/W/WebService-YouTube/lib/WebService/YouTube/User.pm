#
# $Id: User.pm 11 2007-04-09 04:34:01Z hironori.yoshida $
#
package WebService::YouTube::User;
use strict;
use warnings;
use version; our $VERSION = qv('1.0.3');

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
    qw(
      about_me
      age
      books
      city
      companies
      country
      currently_on
      favorite_count
      favorite_video_count
      first_name
      friend_count
      friend_count
      gender
      hobbies
      homepage
      hometown
      last_name
      movies
      occupations
      relationship
      user
      video_upload_count
      video_upload_count
      video_watch_count
      )
);

1;

__END__

=head1 NAME

WebService::YouTube::User - User class for YouTube.

=head1 VERSION

This document describes WebService::YouTube::User version 1.0.3

=head1 SYNOPSIS

    use WebService::YouTube::User;
    my $user = WebService::YouTube::User->new( { ... } );

=head1 DESCRIPTION

This is a user class for YouTube.

=head1 SUBROUTINES/METHODS

=head2 new(\%fields)

Creates and returns a new WebService::YouTube::User object.
%fields can contain parameters enumerated in L</ACCESSORS> section.

=head2 ACCESSORS

=over

=item about_me

=item age

=item books

=item city

=item companies

=item country

=item currently_on

=item favorite_count

=item favorite_video_count

=item first_name

=item friend_count

=item friend_count

=item gender

=item hobbies

=item homepage

=item hometown

=item last_name

=item movies

=item occupations

=item relationship

=item user

=item video_upload_count

=item video_upload_count

=item video_watch_count

=back

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::YouTube::User requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<WebService::YouTube>, L<Class::Accessor::Fast>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-webservice-youtube@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-YouTube>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Hironori Yoshida <yoshida@cpan.org>

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
