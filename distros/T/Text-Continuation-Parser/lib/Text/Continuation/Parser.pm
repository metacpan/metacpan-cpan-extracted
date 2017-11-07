use utf8;
package Text::Continuation::Parser;
our $VERSION = '0.2';
use warnings;
use strict;
use Carp qw(croak);

# ABSTRACT: Parse files with continuation lines

use base qw(Exporter);

our @EXPORT_OK = qw(parse_line);

my $trim = qr/(?:^\s*|\s*$)/;

sub parse_line {
    my ($fh, $line) = @_;

    my $new = $fh->getline;

    if ($line && !defined $new) {
        croak
            "Line continuation detected and reaching end of file. This is invalid";
    }
    return unless defined $new;

    chomp($new);
    $new =~ s/\r//g;
    if ($new =~ /^\s*#/) {
        if (length($line//'')) {
            return parse_line($fh, $line);
        }
        return $new;
    }
    elsif ($new =~ /^\\$/) {
        return parse_line($fh, $line);
    }
    elsif ($new =~ /\s+\\\s*$/) {
        $new =~ s#\s+\\\s*$##;
        $new =~ s/$trim//g;
        if (length($line//'')) {
            if (length($new)) {
                return parse_line($fh, join(' ', $line, $new));
            }
            return parse_line($fh, $line);
        }
        return parse_line($fh, length($new) ? $new : undef);
    }
    elsif ($new =~ /\S+\\\s*$/) {
        $new =~ s#\\\s*$##;
        $new =~ s/$trim//g;
        if (length($line//'')) {
            if (length($new)) {
                return parse_line($fh, join('', $line, $new));
            }
            return parse_line($fh, $line);
        }
        return parse_line($fh, length($new) ? $new : undef);
    }
    elsif ($new =~ /^\s+/) {
        $new =~ s/$trim//g;
        if (!length($new) && length($line//'')) {
            croak
                "Line continuation detected and empty line. This is invalid";
        }
        if (length($line//'')) {
            return length($new) ? join(' ', $line, $new) : $line;
        }
        return $new;
    }
    else {
        $new =~ s/$trim//g;
        if (!length($new) && length($line//'')) {
            croak
                "Line continuation detected and empty line. This is invalid";
        }
        return length($line//'') ? join('', $line, $new) : $new;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Continuation::Parser - Parse files with continuation lines

=head1 VERSION

version 0.2

=head1 SYNOPSIS

    package Foo;
    use Text::Continuation::Parser qw(parse_line);

    my $fh = io('?');
    $fh->print('line 1\\', $/);
    $fh->print('and 2', $/);
    $fh->print('line 3\\', $/);
    $fh->print('\\', $/);
    $fh->print('4 and 5', $/);
    $fh->seek(0,0);

    while(my $line = parse_line($fh)) {
        print $line;
        # This prints:
        # line 1 and 2
        # line 3 4 and 5
    }

=head1 DESCRIPTION

Parse files with continuation lines like shell scripts, Dockerfiles, and so forth.

=head1 METHODS

=head2 parse_line

This function work on any object that implements C<getline>.

It will return all lines, except when lines are continued when a comment
in somewhere in between:

    RUN apt-get update \
        && apt-get install -y perl \
        # This line isn't returned after parsing.
        && echo "this line is"

Lines like these will make sure the function dies:

    RUN apt-get update \
        && apt-get install -y perl \

    RUN echo "We will never get here"

While it may be possible in a shell, this is probably not what you intended and therefore
F<parse_line> dies.

=head2 CAVEATS

On older Perl versions, like 5.10 you must do the following:

    use FileHandle;
    # or..
    use IO::File;

    open my $fh, '<', 'myfile';
    parse_line($fh);

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
