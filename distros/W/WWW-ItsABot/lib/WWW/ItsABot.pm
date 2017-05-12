package WWW::ItsABot;

use warnings;
use strict;
use base 'Exporter';
use LWP::Simple;
use Carp qw/croak/;

=head1 NAME

WWW::ItsABot - Ask itsabot.com if a Twitter user is a bot

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $itsabot_url = 'http://www.itsabot.com/User';
our @EXPORT = ();
our @EXPORT_OK = qw(is_a_bot);

=head1 SYNOPSIS

    use WWW::ItsABot qw/is_a_bot/;
    my $username = 'foobar';
    if ( is_a_bot($username) ) {
        print "$username is a bot\n";
    } else {
        print "$username is not a bot\n";
    }

=head1 AUTHOR

Jonathan Leto, C<< <jonathan at leto.net> >>


=head2 is_a_bot($username)

Returns true is itsabot.com thinks $username is a bot, false otherwise.

=cut

sub is_a_bot($)
{
    my ($username) = @_;
    croak "is_a_bot(): Username empty" unless $username;
    my $content = get("$itsabot_url/$username.csv");
    # user,followers,friends,statuses,isabot,follow_ratio,followers_per_tweet
    if ( $content ) {
        my (@info) = split ',', $content;
        if (defined $info[4]) {
            return $info[4] =~ /true/i ? 1 : 0;
        } else {
            croak "is_a_bot(): user does not exist";
        }
    } else {
        croak "is_a_bot(): did not get a response";
    }
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-itsabot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW::ItsABot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::ItsABot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW::ItsABot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW::ItsABot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW::ItsABot>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW::ItsABot>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Leto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1.0;
