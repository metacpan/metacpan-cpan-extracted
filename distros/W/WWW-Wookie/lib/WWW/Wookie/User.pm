package WWW::Wookie::User 0.102;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use utf8;
use 5.020000;

use Moose qw/around has/;
use Moose::Util::TypeConstraints qw/as coerce from where subtype via/;
use namespace::autoclean '-except' => 'meta', '-also' => qr/^_/sxm;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY     => q{};
Readonly::Scalar my $UNKNOWN   => q{UNKNOWN};
Readonly::Scalar my $MORE_ARGS => 3;
## use critic

subtype 'Trimmed' => as 'Str' => where { m{(^$|(^\S|\S$))}gsmx };

coerce 'Trimmed' => from 'Str' => via { s{^\s+(.*)\s+$}{$1}gsmx; $_ };

has 'loginName' => (
    'is'      => 'rw',
    'isa'     => 'Trimmed',
    'coerce'  => 1,
    'default' => $UNKNOWN,
    'reader'  => 'getLoginName',
    'writer'  => 'setLoginName',
);

has 'screenName' => (
    'is'      => 'rw',
    'isa'     => 'Trimmed',
    'coerce'  => 1,
    'default' => $UNKNOWN,
    'reader'  => 'getScreenName',
    'writer'  => 'setScreenName',
);

has 'thumbnailUrl' => (
    'is'      => 'ro',
    'isa'     => 'Str',
    'default' => $EMPTY,
    'reader'  => 'getThumbnailUrl',
    'writer'  => 'setThumbnailUrl',
);

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( 2 == @_ && !ref $_[0] ) {
        push @_, $EMPTY;
    }
    if ( @_ == $MORE_ARGS && !ref $_[0] ) {
        return $class->$orig(
            'loginName'    => $_[0],
            'screenName'   => $_[1],
            'thumbnailUrl' => $_[2],
        );
    }
    return $class->$orig(@_);
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords url Readonly Ipenburg login MERCHANTABILITY

=head1 NAME

WWW::Wookie::User - represent a possible user of a widget

=head1 VERSION

This document describes WWW::Wookie::User version 0.102

=head1 SYNOPSIS

    use WWW::Wookie::User;
    $u = WWW::Wookie::User->new($login, $nick);

=head1 DESCRIPTION

A user represents a possible user of a widget. This class provides a standard
way of representing users in plugins for host environments.

=head1 SUBROUTINES/METHODS

=head2 C<new>

Create a new user.

=over

=item 1. User login name as string

=item 2. User display name as string

=item 3. Optional thumbnail URL as string

=back

=head2 C<getLoginName>

Get the login name for this user. Returns the user login name as string.

=head2 C<getScreenName>

Get the screen name for this user. This is the name that is intended to be
displayed on screen. In many cases it will be the same as the login name.
Returns the user display name as a string.

=head2 C<setLoginName>

Set the login name for this user. this is the value that is used by the user
to register on the system, it is guaranteed to be unique.

=over

=item 1. New login name as string

=back

=head2 C<setScreenName>

Set the screen name for this user. This is the value that should be displayed
on screen. In many cases it will be the same as the login name.

=over

=item 1. New screen name as string

=back

=head2 C<getThumbnailUrl>

Get the URL for a thumbnail representing this user. Returns the user thumbnail
icon url as string.

=head2 C<setThumbnailUrl>

Set the URL for a thumbnail representing this user.

=over

=item 1. New thumbnail URL as string

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<Moose|Moose>

=item * L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

=item * L<Readonly|Readonly>

=item * L<namespace::autoclean|namespace::autoclean>

=back

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at L<RT for
rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-Wookie>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
