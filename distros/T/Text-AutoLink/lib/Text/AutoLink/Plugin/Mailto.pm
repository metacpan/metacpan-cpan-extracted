package Text::AutoLink::Plugin::Mailto;
use strict;
use warnings;
use base qw(Text::AutoLink::Plugin);

sub process
{
    my $self = shift;
    my $ref  = shift;

    $$ref =~ s/(mailto:[^@]+\@[^\.\s]+(?:\.[^\.\s]+)+)/
        $self->linkfy(target => undef, href => $1)
    /gex;
}

1;

=head1 NAME

Text::AutoLink::Plugin::Mailto - AutoLink mailto:

=cut