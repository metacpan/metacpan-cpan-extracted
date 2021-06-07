package Text::Wrap::Smart::XS;

use strict;
use warnings;
use base qw(Exporter);
use boolean qw(true);

use Carp qw(croak);
use Params::Validate ':all';

our ($VERSION, @EXPORT_OK, %EXPORT_TAGS, @subs);

$VERSION = '0.07';
@subs = qw(exact_wrap fuzzy_wrap);
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

sub exact_wrap
{
    _validate(@_);
    my ($text, $wrap_at) = @_;

    $wrap_at ||= WRAP_AT_DEFAULT;

    return xs_exact_wrap($text, $wrap_at);
}

sub fuzzy_wrap
{
    _validate(@_);
    my ($text, $wrap_at) = @_;

    $wrap_at ||= WRAP_AT_DEFAULT;

    return xs_fuzzy_wrap($text, $wrap_at);
}

sub _validate
{
    validate_pos(@_,
        { type => SCALAR },
        { type => SCALAR, optional => true, regex => qr/^\d+$/ },
    );
}

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

Text::Wrap::Smart::XS - Wrap text fast into chunks of similar length

=head1 SYNOPSIS

 use Text::Wrap::Smart::XS ':all';
 # or
 use Text::Wrap::Smart::XS qw(exact_wrap fuzzy_wrap);

 @chunks = exact_wrap($text, $wrap_at);
 @chunks = fuzzy_wrap($text, $wrap_at);

=head1 DESCRIPTION

C<Text::Wrap::Smart::XS> is the faster companion of C<Text::Wrap::Smart>.

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
and if no remaining whitespace could be find, the end of text; if the wrapping
length is smaller than the size of a word, greedy wrapping will be applied: all
characters until the first whitespace encountered form a chunk).

Optionally a wrapping length may be specified; if no length is supplied,
a default of 160 will be assumed.

=head1 EXPORT

=head2 Functions

C<exact_wrap(), fuzzy_wrap()> are exportable.

=head2 Tags

C<:all - *()>

=head1 BUGS & CAVEATS

The wrapping length will not be applied directly, but is used
to calculate the average length to split text into chunks.

Text will be normalized prior to being processed, i.e. leading
and trailing whitespace will be chopped off before each remaining
whitespace is converted to a literal space.

=head1 SEE ALSO

L<Text::Wrap>, L<Text::Wrap::Smart>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
