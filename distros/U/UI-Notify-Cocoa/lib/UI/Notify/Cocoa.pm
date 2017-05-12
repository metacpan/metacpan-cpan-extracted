use strict;
use warnings;
package UI::Notify::Cocoa;

# ABSTRACT: Posts a Cocoa notification
our $VERSION = '0.002'; # VERSION

use Carp;

sub show {
    my $type = shift;
    my $message  = pop   || '';
    my $title    = shift || $0;
    my $subtitle = shift;
    return !system 'osascript', '-e',
        qq'display notification "$message" with title "$title"'
        . (defined $subtitle ? qq' subtitle "$subtitle"':'')
        ;
}

1;
__END__

=head1 NAME

UI::Notify::Cocoa - Posts a Cocoa Notification


=head1 SYNOPSIS

    use UI::Notify::Cocoa;

    UI::Notify::Cocoa->show("Message");
    UI::Notify::Cocoa->show("Title", "Message");
    UI::Notify::Cocoa->show("Title", "Subtitle", "Message");

=head1 DESCRIPTION

Displays a Cocoa Notification. Eventually will use XS but for now shells out to osascript. Module is OS X only.

=head1 GIT REPOSITORY

L<http://github.com/athreef/UI-Notify-Cocoa>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
