package Text::AutoLink::Plugin::FTP;
use strict;
use warnings;
use base qw(Text::AutoLink::Plugin);

sub process
{
    my $self = shift;
    my $ref = shift;
    $$ref =~ s/(ftp:\/\/[A-Za-z0-9~\/._\?\&=\-%#\+:\;,\@\']+)/
        $self->linkfy(href => $1);
    /gex;
}

1;

=head1 NAME

Text::AutoLink::Plugin::FTP - AutoLink FTP

=cut