package Yukki::Web::Plugin::Attachment;
{
  $Yukki::Web::Plugin::Attachment::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

extends 'Yukki::Web::Plugin';

# ABSTRACT: plugin for attachments

use URI::Escape qw( uri_escape );


has format_helpers => (
    is          => 'ro',
    isa         => 'HashRef[Str]',
    required    => 1,
    default     => sub { +{
        'attachment' => 'attachment_url',
    } },
);

with 'Yukki::Web::Plugin::Role::FormatHelper';


sub attachment_url {
    my ($self, $params) = @_;

    my $ctx  = $params->{context};
    my $file = $params->{file};
    my $arg  = $params->{arg};

    if ($arg =~ m{

            ^\s*

                (?: ([\w]+) : )?    # repository: is optional
                (.+)                # link/to/page is mandatory

            \s*$

            }x) {

        my $repository = $1 // $file->repository_name;
        my $page       = $file->full_path;
        my $link       = $2;

        $link =~ s/^\s+//; $link =~ s/\s+$//;

        $page =~ s{\.yukki$}{};
        $link = join "/", map { uri_escape($_) } split m{/}, $link;

        if ($link =~ m{^/}) {
            return $ctx->rebae_url("attachment/view/$repository$link");
        }
        else {
            return $ctx->rebase_url("attachment/view/$repository/$page/$link");
        }
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Plugin::Attachment - plugin for attachments

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  {{attachment:main:Path/To/Attachment.pdf}}

=head1 DESCRIPTION

This provides a tool for generating URLs to link to attachments on the current page or from other pages.

=head1 ATTRIBUTES

=head2 format_helpers

Links the "attachment" format helper to L</attachment_url>.

=head1 METHODS

=head2 attachment_url

Generates a URL for an attachment path.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
