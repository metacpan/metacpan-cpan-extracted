# $Id: Mail.pm 155 2009-04-03 14:07:02Z nanardon $

package Vote::Template::Plugin::Mail;

=head1 NAME

Vote::Template::Plugin::Mail - Template Filter for email

=head1 DESCRIPTION

This filter replace '.' by 'dot' and '@' by 'at' to make email
harder to find by spam bot.

=cut

use strict;
use warnings;

use base qw( Template::Plugin::Filter );

sub init {
    my $self = shift;
    my $name = $self->{ _ARGS }->[0] || 'mail';
    $self->install_filter($name);
    return $self;
}

sub filter {
    my ($self, $text) = @_;

    $text ||= '';

    $text =~ s/\@/ at /g;
    $text =~ s/\./ dot /g;

    $text
}

=head1 AUTHORS

Olivier Thauvin

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself or CeCILL.

=cut

1;
