package URL::Exists;
$URL::Exists::VERSION = '0.03';
use 5.006;
use strict;
use warnings;
use base 'Exporter';
use HTTP::Tiny 0.014;

our @EXPORT_OK = qw/ url_exists /;

my $ua;

sub url_exists
{
    my $url = shift;

    unless (defined $ua) {
        $ua = HTTP::Tiny->new();
    }

    my $response = $ua->head($url);

    return !!$response->{success};
}

1;

=head1 NAME

URL::Exists - test whether a URL exists, when you don't care about the contents

=head1 SYNOPSIS

 use URL::Exists qw/ url_exists /;

 if (url_exists($url)) {
    ...
 }

=head1 DESCRIPTION

This module is useful where you're only interested in whether the
file referenced by a URL is present, and don't actually care about
the contents.

At the moment it just supports HTTP URLs, but I may add other
schemes, if there's any demand / interest.

=head1 REPOSITORY

L<https://github.com/neilb/URL-Exists>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

