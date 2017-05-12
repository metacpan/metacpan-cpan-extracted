package Text::Lossy;

use 5.008;
use strict;
use warnings;
use utf8;

use Carp;

=head1 NAME

Text::Lossy - Lossy text compression

=head1 VERSION

Version 0.40.2

=cut

use version 0.77; our $VERSION = version->declare('v0.40.2');


=head1 SYNOPSIS

    use Text::Lossy;

    my $lossy = Text::Lossy->new;
    $lossy->add('whitespace');
    my $short = $lossy->process($long);

    my $lossy = Text::Lossy->new->add('lower', 'punctuation');  # Chaining usage

    $lossy->process($long); # In place
    $lossy->process();      # Filters $_ in place

=head1 DESCRIPTION

C<Text::Lossy> is a collection of text filters for lossy compression.
"Lossy compression" changes the data in a way which is irreversible,
but results in a smaller file size after compression. One of the best
known lossy compression uses is the JPEG image format.

Note that this module does not perform the actual compression itself,
it merely changes the text so that it may be compressed better.

=head2 Alpha software

This code is currently B<alpha software>. Anything can and will change,
most likely in a backwards-incompatible manner. You have been warned.

=head2 Usage

C<Text::Lossy> uses an object oriented interface. You create a new
C<Text::Lossy> object, set the filters you wish to use (described below),
and call the L</process> method on the object. You can call this
method as often as you like. In addition, there is a method which produces
a closure, an anonymous subroutine, that acts like the process method on
the given object.

=head2 Adding new filters

New filters can be added with the L</register_filters> class method.
Each filter is a subroutine which takes a single string and returns this
string filtered.

=cut

our %filtermap;

=head1 CONSTRUCTORS

=head2 new

    my $lossy = Text::Lossy->new();

The constructor for a new lossy text compressor. The constructor is quite
light-weight; the only purpose of a compressor object is to accept and remember
a sequence of filters to apply to text.

The constructor takes no arguments.

=cut

sub new {
    my $class = shift;
    my $self = {
        filters => [],
    };
    return bless $self, $class;
}

=head1 METHODS

=head2 process

    my $new_text = $lossy->process( $old_text );

This method takes a single text string, applies all the selected filters
to it, and returns the filtered string. Filters are selected via
L</add>; see L<FILTERS>.

The text is upgraded to character semantics via a call to
C<utf8::upgrade>, see L<utf8>. This will not change the text you passed
in, nor should it have too surprising an effect on the output.

If no text is passed in, nothing is returned (the empty list or C<undef>,
depending on context).
If an explicit C<undef> is passed in, an explicit C<undef> is returned, even in
list context.

=cut

sub process {
    my ($self, $text) = @_;
    return unless @_ > 1;
    return undef unless defined $text;
    utf8::upgrade($text);
    foreach my $f (@{$self->{'filters'}}) {
        $text = $f->{'code'}->($text);
    }
    return $text;
}

=head2 add

    $lossy->add( 'lower', 'whitespace' );

This method takes a list of filter names and adds them to the filter list
of the filter object, in the order given. This allows a programmatic
selection of filters, for example via command line. Returns the object
for method chaining.

If the filter is unknown, an exception is thrown. This may happen when you
misspell the name, or forgot to use a module which registers the filter,
or forgot to register it yourself.

=cut

sub add {
    my ($self, @filters) = @_;
    foreach my $name (@filters) {
        my $code = $filtermap{$name};
        if (not $code) {
            croak "Unknown filter $name (did you forget to use the right module?)";
        }
        push @{$self->{'filters'}}, { code => $code, name => $name };
    }
    return $self;
}

=head2 clear

    $lossy->clear();

Remove the filters from the filter object. The object will behave as
if newly constructed. Returns the object for method chaining.

=cut

sub clear {
    my ($self) = @_;
    @{$self->{'filters'}} = ();
    return $self;
}

=head2 list

    my @names = $lossy->list();

List the filters added to this object, in order. The names (not the
code) are returned in a list.

=cut

sub list {
    my ($self) = @_;
    return map $_->{'name'}, @{$self->{'filters'}};
}

=head2 as_coderef

    my $code = $lossy->as_coderef();
    $new_text = $code->( $old_text );

Returns a code reference that closes over the object. This code reference
acts like a bound L</process> method on the constructed object. It
can be used in places like L<Text::Filter> that expect a code reference that
filters text.

The code reference is bound to the object, not a particular object state.
Adding filters to the object after calling C<as_coderef> will also change
the behaviour of the code reference.

=cut

sub as_coderef {
    my ($self) = @_;
    return sub {
        return $self->process(@_);
    }
}

=head1 FILTERS

The following filters are defined by this module. Other modules may define
more filters.
Each of these filters can be added to the set via the L</add> method.

=head2 lower

Corresponds exactly to the L<lc|perlfun/lc> builtin in Perl, up
to and including its Unicode handling.

=cut

sub lower {
    my ($text) = @_;
    return lc($text);
}

=head2 whitespace

Collapses any whitespace (C<\s> in regular expressions) to a single space, C<U+0020>.
Whitespace at the beginning of the text is stripped completely. Whitespace at the end
is also collapsed to a single space, to help separate lines. Text consisting only
of whitespace results in an empty string.

=cut

sub whitespace {
    my ($text) = @_;
    $text =~ s{ \s+ }{ }xmsg;
    # the above line also works for the end of the text
    $text =~ s{ \A \s+ }{}xms;
    return $text;
}

=head2 whitespace_nl

A variant of the L</whitespace> filter that leaves newlines on the end of the text
alone. Other whitespace at the end will get collapsed into a single newline.
If the text ends in whitespace that does not contain a new line, it is replaced
by a space, as before.

This filter is most useful if you are creating a Unix-style text filter, and do not
want to buffer the entire input before writing the (only) line to C<stdout>. The
newline at the end will allow downstream processes to work on new lines, too.
Otherwise, this filter is not quite as efficient as the L<whitespace> filter.

Any newlines in the middle of text are collapsed to a space, too. This is especially
useful if you are reading in "paragraph mode", e.g. C<$/ = ''>, as you will get
one long line per former paragraph.

=cut

sub whitespace_nl {
    my ($text) = @_;
    # Remember whether a newline was present
    my $has_nl = ($text =~ m{ \n \s* \z }xms) ? 1 : 0;
    $text =~ s{ \s+ }{ }xmsg;
    $text =~ s{ \A \s+ }{}xms;
    # whitespace-at-end is now a space
    if ($has_nl) {
        # replace this space with a newline
        $text =~ s{ \s+ \z }{\n}xms;
    }
    return $text;
}

=head2 punctuation

Strips punctuation, that is anything matching C<\p{Punctuation}>. It is replaced by
nothing, removing it completely.

=cut

sub punctuation {
    my ($text) = @_;
    # Turns out '\p{Punctuation}' fails on Perl 5.6, use the abbreviation '\pP' instead
    $text =~ s{ \pP }{}xmsg;
    return $text;
}

=head2 punctuation_sp

A variant of L</punctuation> that replaces punctuation with a space character, C<U+0020>,
instead of removing it completely. This is usually less efficient for compression, but
retains more readability, for example in the presence of URLs or email addresses.

=cut

sub punctuation_sp {
    my ($text) = @_;
    # Turns out '\p{Punctuation}' fails on Perl 5.6, use the abbreviation '\pP' instead
    $text =~ s{ \pP }{ }xmsg;
    return $text;
}

=head2 alphabetize

Leaves the first and last letters of a word alone, but replaces the interior letters with
the same set, sorted by the L<sort|perlfun/sort> function. This is done on the observation
(source uncertain at the time) that words can still be made out if the letters are present, but
in a different order, as long as the outer ones remain the same.

This filter may not work as proposed with every language or writing system. Specifically, it
uses end-of-word matches C<\b> to determine which letters to leave alone.

=cut

sub alphabetize {
    my ($text) = @_;
    $text =~ s{ \b (\p{Alpha}) (\p{Alpha}+) (\p{Alpha}) \b }{ $1 . join('', sort split(//,$2)) . $3 }xmseg;
    return $text;
}

# TODO:
# - unidecode (separate module)
# - normalize (separate module)

=head1 CLASS METHODS

These methods are not called on a filter object, but on the class C<Text::Lossy>
itself. They are typically concerned with the filters that can be added to filter
objects.

=head2 register_filters

  Text::Lossy->register_filters(
      change_stuff => \&Other::Module::change_text,
      remove_ps    => sub { my ($text) = @_; $text =~ s{[Pp]}{}; return $text; },
  );

Adds one or more named filters to the set of available filters. Filters are
passed in an anonymous hash.
Previously defined mappings may be overwritten by this function.
Specifically, passing C<undef> as the code reference removes the filter.

=cut

%filtermap = (
    'lower' => \&lower,
    'whitespace' => \&whitespace,
    'whitespace_nl' => \&whitespace_nl,
    'punctuation' => \&punctuation,
    'punctuation_sp' => \&punctuation_sp,
    'alphabetize' => \&alphabetize,
);

sub register_filters {
    my ($class, %mapping) = @_;
    foreach my $name (keys %mapping) {
        if (defined $mapping{$name}) {
            $filtermap{$name} = $mapping{$name};
        } else {
            delete $filtermap{$name};
        }
    }
    return;
}

=head2 available_filters

    my @filters = Text::Lossy->available_filters();

Lists the available filters at this point in time, specifically their names
as used by L</add> and L</register_filters>. The list is sorted alphabetically.

=cut

sub available_filters {
    my ($class) = @_;
    return sort keys %filtermap;
}

=head1 CREATING FILTERS

A filter is a subroutine which takes a single parameter (the text to be converted) and
returns the filtered text. The text may also be changed in-place, as long as it is
returned again.

These filters are then made available to the rest of the system via the
L</register_filters> function.

=head1 USAGE WITH Text::Filter

The L<Text::Filter> module provides an infrastructure for filtering text, but no actual filters.
It can be used with C<Text::Lossy> by passing the result of L</as_coderef> as the C<filter>
parameter.

It is recommended to set L<Text::Filter> to leave line endings alone when using the L</whitespace>
filter, i.e. the L<input_postread|Text::Filter/input_postread> and
L<output_prewrite|Text::Filter/output_prewrite> should be C<0>. This is the default
for L<Text::Filter>. It will allow L</whitespace> to perform its assigned task on line endings.

One thing to note is that the C<Text::Lossy> filters do not follow the L<Text::Filter>'s convention
that lines "to be skipped" should result in an C<undef>.
This means you need to expect completely empty lines (C<q{}>, not even a newline character) in
your output.
This should be no problem if you print to a file handle or append to a string, but may be surprising
if you are filtering an array of lines.

=head1 EXPORT

Nothing exported or exportable; use the OO interface instead.

=head1 UNICODE

This code strives to be completely Unicode compatible. All filters aim to "do the right thing" on non-ASCII strings.
Any failure to handle Unicode should be considered a bug; please report it.

=head1 AUTHOR

Ben Deutsch, C<< <ben at bendeutsch.de> >>

=head1 BUGS

None known so far.

Please report any bugs or feature requests to C<bug-text-lossy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Lossy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Lossy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Lossy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Lossy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Lossy>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Lossy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ben Deutsch.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Text::Lossy
