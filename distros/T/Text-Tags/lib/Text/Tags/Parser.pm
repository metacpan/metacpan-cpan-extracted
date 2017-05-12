package Text::Tags::Parser;

use warnings;
use strict;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub parse_tags {
    my $self   = shift;
    my $string = shift;

    return unless defined $string;

    my @tags;
    my %seen;

    # In this regexp, the actual content of the tag is in the last
    # paren-group which matches in each alternative.
    # Thus it can be accessed as $+
    while (
        $string =~ /\G [\s,]* (?:
                        (") ([^"]*) (?: " | $) |      # double-quoted string
                        (') ([^']*) (?: ' | $) |      # single-quoted string
                        ([^\s,]+)                   # other 
		     )/gx
        )
    {
        my $tag       = $+;
        my $is_quoted = $1 || $3;

        # shed explictly quoted empty strings
        next unless length $tag;

        $tag =~ s/^\s+//;
        $tag =~ s/\s+$//;
        $tag =~ s/\s+/ /g;

        # Tags should be unique, but in the right order
        push @tags, $tag unless $seen{$tag}++;
    }

    return @tags;
}

sub join_tags {
    my $self = shift;
    my @tags = @_;
    return $self->_join_tags(undef, @tags);
}

sub join_quoted_tags {
    my $self = shift;
    my @tags = @_;
    return $self->_join_tags(1, @tags);
}

sub _join_tags {
    my $self = shift;
    my $always_quote = shift;
    my @tags = @_;

    my %seen;
    my @quoted_tags;

    for my $tag (@tags) {
        $tag =~ s/^\s+//;
        $tag =~ s/\s+$//;
        $tag =~ s/\s+/ /g;

        next unless length $tag;

        my $quote;

        if ( $tag =~ /"/ and $tag =~ /'/ ) {

            # This is an illegal tag.  Normalize to just single-quotes.
            # Quote it too, though technically the new form might not need it.
            $tag =~ tr/"/'/;
            $quote = q{"};
        } elsif ( $tag =~ /"/ ) {

            # It contains a ", so either it needs to be unquoted or
            # single-quoted
            if ( $tag =~ / / or $tag =~ /,/ or $tag =~ /^"/ or $always_quote) {
                $quote = q{'};
            } else {
                $quote = q{};
            }
        } elsif ( $tag =~ /'/ ) {

            # It contains a ', so either it needs to be unquoted or
            # double-quoted
            if ( $tag =~ / / or $tag =~ /,/ or $tag =~ /^'/ or $always_quote) {
                $quote = q{"};
            } else {
                $quote = q{};
            }
        } elsif ( $tag =~ /[ ,]/ or $always_quote) {

            # By this point we know that it contains no quotes.
            # But it needs to be quoted.
            $quote = q{"};
        } else {

            # No special characters at all!
            $quote = q{};
        }

        # $tag is now fully normalized (both by whitespace and by
        # anti-illegalization).  Have we seen it?

        next if $seen{$tag}++;

        push @quoted_tags, "$quote$tag$quote";
    }

    return join ' ', @quoted_tags;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Text::Tags::Parser - parses "folksonomy" space-separated tags

=head1 SYNOPSIS

    use Text::Tags::Parser;
    my @tags = Text::Tags::Parser->new->parse_tags(q{ foo  bar  "baz bap" jenny's   'beep beep' });
    my $line = Text::Tags::Parser->new->join_tags('foo', 'bar', 'baz bap', "jenny's", 'beep beep');
  
=head1 DESCRIPTION

Parses "folksonomies", which are simple
space-or-comma-separated-but-optionally-quoted tag lists.

Specifically, tags can be any string, as long as they don't contain
both a single and a double quote.  Hopefully, this is a pretty obscure
restriction.  In addition, all whitespace inside tags is normalized to
a single space (with no leading or trailing whitespace).

In a tag list string, tags can optionally be quoted with either single
or double quotes.  B<There is no escaping of either kind of quote>,
although you can include one type of quote inside a string quoted with
the other.  Quotes can also just be included inside tags, as long as
they aren't at the beginning; thus a tag like C<joe's> can just be
entered without any extra quoting.  Tags are separated by whitespace
and/or commas, though quoted tags can run into each other without
whitespace.  Empty tags (put in explicitly with C<""> or C<''>) are
ignored.  (Note that commas are not normalized with whitespace, and
can be included in a tag if you quote them.)

Why did the previous paragraph need to be so detailed?  Because
L<Text::Tags::Parser> B<always successfully parses> every line.  That
is, every single tags line converts into a list of tags, without any
error conditions.  For general use, you can just understand the rules
as being B<separate tags with spaces or commas, and put either kind of
quotes around tags that need to have spaces>.

=head1 METHODS

=over 4

=item B<new>

Creates a new L<Text::Tags::Parser> object.  In this version of the
module, the objects do not actually hold any state, but this could
change in a future version.

=item B<parse_tags>($string)

Given a tag list string, returns a list of tags (unquoted) using the
rules described above.  Any given tag will show up at most once in the
output list.

=item B<join_tags>(@tags)

Given a list of tags, returns a tag list string containing them
(appropriately quoted).  Note that illegal tags will have all of their
double quotes converted to single quotes.  Any given tag will show up
at most once in the output string.

=item B<join_quoted_tags>(@tags)

As L</join_tags>, but every tag will be delimited by wither single or
double quotes -- unlike L</join_tags>, which only quotes when
necessary.

=back


=head1 DEPENDENCIES

None.

=head1 BUGS AND LIMITATIONS

The rules are kind of complicated, but at least they are well-defined.

Please report any bugs or feature requests to
C<bug-text-tags@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Text::Folksonomies>, a module with similar functionality but has
much more simplistic quote handling.  (Specifically, it doesn't allow
you to put any type of quote into a tag.)  But if you don't care about
that sort of support, it seems to work fine.


=head1 AUTHOR

David Glasser  C<< <glasser@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Best Practical Solutions, LLC.  All rights
reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
