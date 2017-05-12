package Text::Wrap::Smart;

use strict;
use warnings;
use base qw(Exporter);
use boolean qw(true);

use Carp qw(croak);
use Math::BigFloat ();
use Params::Validate ':all';

our ($VERSION, @EXPORT_OK, %EXPORT_TAGS);
my @subs;

$VERSION = '0.7';
@subs = qw(exact_wrap fuzzy_wrap wrap_smart);
@EXPORT_OK = @subs;
%EXPORT_TAGS = ('all' => [ @subs ]);

use constant WRAP_AT_DEFAULT => 160;

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

my $calc_average = sub
{
    my ($text, $wrap_at) = @_;

    my $length = length $text;

    my $i = int $length / $wrap_at;
       $i++ if  $length % $wrap_at != 0;

    my $x = Math::BigFloat->new($length / $i);
    my $average = $x->bceil;

    return $average;
};

sub exact_wrap
{
    _validate(@_);
    my ($text, $wrap_at) = @_;

    $wrap_at ||= WRAP_AT_DEFAULT;
    my $average = $calc_average->($text, $wrap_at);

    return _exact_wrap($text, $average);
}

sub fuzzy_wrap
{
    _validate(@_);
    my ($text, $wrap_at) = @_;

    $wrap_at ||= WRAP_AT_DEFAULT;
    my $average = $calc_average->($text, $wrap_at);

    return _fuzzy_wrap($text, $average);
}

sub _exact_wrap
{
    my ($text, $average) = @_;

    my @chunks;

    for (my $offset = 0; $offset < length $text; $offset += $average) {
        push @chunks, substr($text, $offset, $average);
    }

    return @chunks;
}

sub _fuzzy_wrap
{
    my ($text, $average) = @_;

    $text = do {
        local $_ = $text;
        s/^\s+//;
        s/\s+$//;
        s/\s+/ /g;
        $_
    };

      my @spaces;
    push @spaces, pos $text while $text =~ /(?= )/g;

    my $pos          = $average;
    my $start_offset = 0;
    my $skip_space   = 1;

    my @offsets;

    while (true) {
        my $begin = @offsets ? ($offsets[-1] + $skip_space) : $start_offset;

        my $index = index($text, ' ', ($begin == $start_offset ? $start_offset : $begin - $skip_space) + $average);
        last if $index == -1;

        my @spaces_prev = grep $_ <= $pos, @spaces;

        my $space_prev = $spaces_prev[-1] || undef;
        my $space_next = $index;

        splice(@spaces, 0, scalar @spaces_prev);
        @spaces = grep $_ != $space_next, @spaces;

        if (defined $space_prev && substr($text, $begin, $space_prev - $begin) =~ / /) {
            push @offsets, $space_prev;
        }
        else {
            push @offsets, $space_next;
        }
        $pos = $offsets[-1] + $skip_space + $average;
    }

    my @chunks;

    my $begin = $start_offset;
    foreach my $offset (@offsets) {
        my $range = $offset - $begin;
        if ($text =~ /\G(.{$range}) (?=[^ ])/g) {
            push @chunks, $1;
        }
        $begin = $offset + $skip_space;
    }
    push @chunks, $1 if $text =~ /\G(.+)$/;

    return @chunks;
}

sub _validate
{
    validate_pos(@_,
        { type => SCALAR },
        { type => SCALAR, optional => true, regex => qr/^\d+$/ },
    );
}

# deprecated on 2016-09-06
sub wrap_smart
{
    my ($text, $conf) = @_;
    croak "wrap_smart(\$text [, { options } ])\n" unless defined $text;

    my $msg_size    =  $conf->{max_msg_size} || WRAP_AT_DEFAULT;
    my $exact_split = !$conf->{no_split};

    warn 'wrap_smart() is deprecated, use ', $exact_split ? 'exact_wrap()' : 'fuzzy_wrap()', " here instead.\n";

    my $average = $calc_average->($text, $msg_size);
    my $wrapper = $exact_split ? \&_exact_wrap : \&_fuzzy_wrap;

    return $wrapper->($text, $average);
}

1;
__END__

=head1 NAME

Text::Wrap::Smart - Wrap text into chunks of similar length

=head1 SYNOPSIS

 use Text::Wrap::Smart ':all';
 # or
 use Text::Wrap::Smart qw(exact_wrap fuzzy_wrap wrap_smart);

 @chunks = exact_wrap($text, $wrap_at);
 @chunks = fuzzy_wrap($text, $wrap_at);

 @chunks = wrap_smart($text, \%options); # DEPRECATED

=head1 DESCRIPTION

C<Text::Wrap::Smart> is the pure perl companion of C<Text::Wrap::Smart::XS>.

=head1 FUNCTIONS

=head2 exact_wrap

 @chunks = exact_wrap($text [, $wrap_at ]);

Wrap a text of varying length into exact chunks (except the last one,
which consists of the remaining text).

Optionally a wrapping length may be specified; if no length is supplied,
a default of 160 will be assumed.

=head2 fuzzy_wrap

 @chunks = fuzzy_wrap($text [, $wrap_at ]);

Wrap a text of varying length into chunks of fuzzy length (the boundary
is normally calculated from the last whitespace preceding the wrapping length,
and if no remaining whitespace could be found the end of text; if the wrapping
length is smaller than the size of a word, greedy wrapping will be applied: all
characters until the first whitespace encountered form a chunk).

Optionally a wrapping length may be specified; if no length is supplied,
a default of 160 will be assumed.

=head2 wrap_smart (DEPRECATED)

 @chunks = wrap_smart($text [, { options } ]);

The C<options> hash reference may contain the C<no_split> option which specifies
that words shall not be broken up (i.e., fuzzy wrapping); if C<no_split> is not
set, exact wrapping will be applied). The C<max_msg_size> option used to set the
character length boundary for each chunk emitted, but has been changed to set the
wrapping length now.

=head1 EXPORT

=head2 Functions

C<exact_wrap(), fuzzy_wrap() and wrap_smart()> are exportable.

=head2 Tags

C<:all - *()>

=head1 BUGS & CAVEATS

The wrapping length will not be applied directly, but is used
to calculate the average length to split text into chunks.

Text will be normalized prior to being processed, i.e. leading
and trailing whitespace will be chopped off before each remaining
whitespace is converted to a literal space.

=head1 SEE ALSO

L<Text::Wrap>, L<Text::Wrap::Smart::XS>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
