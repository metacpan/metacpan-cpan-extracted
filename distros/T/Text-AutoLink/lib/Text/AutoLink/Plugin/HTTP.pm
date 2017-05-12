package Text::AutoLink::Plugin::HTTP;
use strict;
use warnings;
use base qw(Text::AutoLink::Plugin);

sub process
{
    my $self = shift;
    my $ref  = shift;

    $$ref =~ s/(https?:\/\/[A-Za-z0-9~\/._!\?\&=\-%#\+:\;,\@\']+)/
        $self->linkfy(href => $1)
    /gex;
}

1;

=head1 NAME

Text::AutoLink::Plugin::HTTP - AutoLink HTTP

=cut