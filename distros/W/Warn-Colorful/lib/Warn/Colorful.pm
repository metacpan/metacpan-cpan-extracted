package Warn::Colorful;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.01';

use Term::ANSIColor;

my %colors = (
    base => 'blue',
    body => undef,
    file => undef,
    line => undef,
);

sub import {
    my ($package, %args) = @_;

    my $config = _parse_config();

    for my $name (keys %colors) {
        $colors{$name} = $args{$name} || $config->{$name} || $colors{base};
    }
}

$SIG{__WARN__} = sub {
    my $msg = shift;

    my (undef, $file, $line) = caller;

    my ($body) = $msg =~ /(.*) at ${file} line ${line}\.\n$/;
    my $out = sprintf "%s %s %s.\n",
        colored([$colors{body}], $body),
        colored([$colors{file}], "at ${file}"),
        colored([$colors{line}], "line ${line}");

    print STDERR $out;
};

sub _parse_config {
    my $config_path = "$ENV{HOME}/.warn-colorful";
    my $config = {};

    return $config unless -e $config_path;

    open my $fh, '<', $config_path;
    my $text = do { local $/; <$fh> };
    close $fh;

    for my $line (split /\n/, $text) {
        next unless $line;
        my ($key, $value) = split '=', $line;
        $config->{$key} = $value;
    }

    return $config;
}

1;
__END__

=head1 NAME

Warn::Colorful - Perl extention to color warning messages.

=head1 VERSION

This document describes Warn::Colorful version 0.01.

=head1 SYNOPSIS

    use Warn::Colorful (
        base => 'blue',
        body => 'red',
    );

    warn 'hello';

or

    echo "base=blue" > ~/.warn-colorful
    perl -MWarn::Colorful foo.pl

=head1 DESCRIPTION

Colourful warning messages would give you a readability and free from stress.

=head1 CONFIGURATION

=over

=item * keys

=over

=item * C<base>

Default for other keys.
Its default is C<blue>.

=item * C<body>

Color for message body.

=item * C<file>

Color for filename.

=item * C<line>

Color for line number.

=back

=item * values

name of ANSI Colors.

=back

=head1 SEE ALSO

L<Term::ANSIColor>

=head1 AUTHOR

NAGATA Hiroaki <handlename> E<lt>handle _at_ cpan _dot_ orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, NAGATA Hiroaki <handlename>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
