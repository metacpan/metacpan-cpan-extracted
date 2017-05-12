package Text::Outdent;
use 5.006;

$VERSION = 0.01;
@EXPORT_OK = qw/
    outdent
    outdent_all
    outdent_quote
    expand_leading_tabs
/;
$EXPORT_TAGS{ALL} = \@EXPORT_OK;

use strict;
use base 'Exporter';

{
    my $indent_re = qr/^([^\S\n]*(?=\S))/m;
    sub find_indention {
        my ($str) = @_;

        return '' if $str !~ /\S/;

        $str =~ /$indent_re/g;
        my $i = $1;
        return '' if not length $i;

        while ($str =~ /$indent_re/g) {
            my $i2 = $1;
            ($i) = "$i\n$i2" =~ /^(.*).*\n\1/;
            return '' if not length $i2;
        }
        return $i;
    }
}

{
    my $indent_re = qr/^(?!$)([^\S\n]*)/m;
    sub find_indention_all {
        my ($str) = @_;

        $str =~ /$indent_re/g;
        my $i = $1;
        return '' if not length $i;

        while ($str =~ /$indent_re/g) {
            my $i2 = $1;
            ($i) = "$i\n$i2" =~ /^(.*).*\n\1/;
            return '' if not length $i2;
        }
        return $i;
    }
}

sub outdent_all {
    my ($str) = @_;

    my $indent = find_indention_all($str);
    $str =~ s/^$indent//gm;

    return $str;
}

sub outdent {
    my ($str) = @_;

    my $indent = find_indention($str);
    $str =~ s/^$indent(?=.*?\S)//gm;

    return $str;
}

# Removes any leading whitespaces uptil and including the first whitespace.
# Removes any trailing whitespaces if they come directly after a newline.
# (In this paragraph "whitespace" excludes newline.)
sub heredocify {
    my ($str) = @_;

    $str =~ s/^[^\S\n]*\n//;
    $str =~ s/^[^\S\n]+\z//m;

    return $str;
}

sub outdent_quote { outdent(heredocify($_[0])) }

sub expand_leading_tabs {
    my ($tabstop, $str) = @_;

    1 while $str =~ s{
        ^ ([^\S\t\n]*?) (\t+)
    }{
        $1 . ' ' x ($tabstop * length($2) - length($1) % $tabstop)
    }gemx;

    return $str;
}

1;

__END__

=head1 NAME

Text::Outdent - Outdent chunks of text


=head1 SYNOPSIS

    my $foo = outdent($bar);

    my $baz = outdent_quote(q{
        this
            is
            a
        string
            that
            is
            indented
        with
            spaces
            or
            tab
    });


=head1 DESCRIPTION

This module was created to make it easy to have large chunks of strings in the code. If you use a quote operator that spans over several lines or a "here-doc" and have an indention of the code you get leading whitespaces that you may or may not want. If you don't want them this module easily removes them.

You can also use it for other texts that are indented.


=head1 EXPORTED FUNCTIONS

No functions are exported by default. C<:ALL> exports all.

=over

=item C<outdent($str)>

Removes the common leading whitespaces for each line. Currently lines with only whitespaces are ignored and left untouched; treated as blank lines if you like. No tab expansion is being performed; a tab is just a whitespace character.

If the indention consists of both spaces and tabs then it's a good idea to expand the tabs first, see C<&expand_leading_tabs>. If the mix of tabs and spaces is consistent, e.g. every line begins with "E<nbsp>E<nbsp>\tE<nbsp>", then that is recognized as indention.

    # common leading whitespaces are removed.
    my $str = <<'_STR_';
        this
            is
            a
        string
            that
            is
            indented
        with
            spaces
            or
            tab
    _STR_

    print '* Indented: ', $str;
    print '* Outdented: ', outdent($str);

outputs

    * Indented:
        this
            is
            a
        string
            that
            is
            indented
        with
            spaces
            or
            tab

    * Outdented:
    this
        is
        a
    string
        that
        is
        indented
    with
        spaces
        or
        tab

=item C<outdent_all($str)>

Like C<&outdent> except it doesn't treat "whitespace lines" as blank lines.

=item C<outdent_quote($str)>

Like C<&outdent> but with some twists to make it smooth to use a (possibly indented) quote operator spanning over several lines in your source. The arrows (that isn't part of the code) below point out the two issues this function takes care of.

    my $foo = q{       <--- newline and possible spaces
        foo
            bar
            baz
        zip
            zap
    };                 <--- empty line with possible spaces

First, all whitespaces uptil the first newline plus the newline itself are removed. This takes care of the first issue.

Second, if the string ends with a newline followed by non-newline whitespaces the non-newline whitespaces are removed. This takes care of the second issue.

These fixes serve to make the quote operator's semantics equivalent to a here-docs.

=item C<expand_leading_tabs($tabstop, $str)>

Expands tabs that on a line only have whitespaces before them. Handy to have if you have a file with mixed tab/space indention.

=back


=head1 AUTHOR

Johan Lodin <lodin@cpan.org>


=head1 COPYRIGHT

Copyright 2004-2005 Johan Lodin. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO


=cut
