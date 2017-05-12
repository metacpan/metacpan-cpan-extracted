package Text::Template::Inline;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw/ render /;

use Carp qw/ croak /;
use Scalar::Util qw/ blessed reftype /;

our $VERSION = '0.13';

#
# The import function accepts an alternate name for the "render" function,
# then aliases and exports that name instead of the original.
#
sub import {
    my ($package, $func_name) = @_;
    local @EXPORT = @EXPORT;
    if ($func_name) {
        # export the provided name instead of "render"
        @EXPORT = ($func_name);
        no strict 'refs';
        *{$func_name} = *render;
    }
    $package->export_to_level(1,@_);
}

#
# This function is the only external module interface.
# If you don't like the name, just import a better one!
#
sub render ($$) {
    my ($data, $template) = @_;
    return $template unless $template;

    # Trim leading whitespace, preserving relative indent.
    # There's no way to know what your tabstops are, so we have to
    # assume that you indent consistently w/ regards to tabs/spaces.
    my $indent;
    while ($template =~ m/^([\t ]+)/mg) {
        my $lead = length $1;
        $indent = (defined $indent && $lead > $indent) ? $indent : $lead;
    }
    $template =~ s/^[\t ]{$indent}//mg if defined $indent;
    $template =~ s/^\n//; # remove leading newline

    # perform the data substitutions
    $template =~ s/(\{(\w[.\w]*)\})/_traverse_ref_with_path($data,$2,$1)/ge;

    return $template;
}

#
# This function dissects a period-delimited path of keys and follows them,
# traversing $theref. If the appropriate field exists at each level the final
# value is returned. If any field is not found, $default is returned.
#
sub _traverse_ref_with_path {
    my ($theref, $path, $default) = @_;
    my @keys = split /\./, $path;
    my $ref = $theref;
    for my $key (@keys) {
        no warnings 'uninitialized'; # for comparisons involving a non-ref $ref
        if (blessed $ref) {
            return $default unless $ref->can($key);
            $ref = $ref->$key();
        }
        elsif (reftype $ref eq 'HASH') {
            return $default unless exists $ref->{$key};
            $ref = $ref->{$key};
        }
        elsif (reftype $ref eq 'ARRAY') {
            return $default unless $key =~ /^\d+$/ and exists $ref->[$key];
            $ref = $ref->[$key];
        }
        else {
            local $Carp::CarpLevel = 2;
            croak "unable to use scalar '$theref' as template data";
        }
    }
    return $ref;
}

1;
__END__

=head1 NAME

Text::Template::Inline - Easy formatting of hierarchical data

=head1 SYNOPSIS

 # you can import any name you want instead of "render"
 use Text::Template::Inline 'render';

 # yields "Replace things and stuff."
 render {
    foo => 'things',
    bar => 'stuff',
 }, q<Replace {foo} and {bar}.>;

 # yields "Three Two One Zero"
 render [qw/ Zero One Two Three /], '{3} {2} {1} {0}';

 # for a blessed $obj that has id and name accessors:
 render $obj, '{id} {name}';

 # a "fat comma" can be used as syntactic sugar:
 render $obj => '{id} {name}';

 # it's also possible to traverse heirarchies of data,
 # even of different types.
 # the following yields "one two three"
 render {
    a => { d => 'one' },
    b => { e => 'two' },
    c => { f => [qw/ zero one two three /], },
 } => '{a.d} {b.e} {c.f.3}';

 # there's also an automatic unindent feature that
 # lines up to the least-indented line in the template:
 render {
    a => { d => 'one' },
    b => { e => 'two' },
    c => { f => [qw/ zero one two three /], },
 } => q{
    {a.d}
      {b.e}
        {c.f.3}
 };
 # the above results in this:
 'one
   two
     three
 '

=head1 DESCRIPTION

This module exports a fuction C<render> that substitutes identifiers
of the form C<{key}> with corresponding values from a hashref, listref
or blessed object. It has features that work well with inline documents
like heredocs, such as automatic unindent.

The implementation is very small and simple. The small amount of code
is easy to review, and the resource cost of using this module is minimal.

=head2 EXPORTED FUNCTION

There is only one function defined by this module. It is exported
automatically.

=over

=item render ( $data, $template )

Each occurrence in C<$template> of the form C<{key}> will be substituted
with the corresponding value from C<$data>. If there is no such value,
no substitution will be performed.

First C<$template> is intelligently unindented and leading or trailing
newlines are trimmed.

If C<$data> is a blessed object, the keys in C<$template> correspond to
accessor methods. These methods should return a scalar when called without
any arguments (other than the reciever).

if C<$data> is a hash reference, the keys in C<$template> correspond to the keys
of that hash. Keys that contain non-word characters are not replaced.

if C<$data> is a list reference, the keys in C<$template> correspond to the
indices of that list. Keys that contain non-digit characters are not replaced.

The modified C<$template> string is then returned.

=back

=head1 REQUIRES

L<Scalar::Util>

L<Test::More> and L<Test::Exception> (for installation)

=head1 BUGS

If you find a bug in Text::Template::Inline please report it to the author.

=head1 AUTHOR

 Zack Hobson <zgh@cpan.org>

=head1 COPYRIGHT

Copyright 2006 Zack Hobson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=4 sts=4 et bs=2:
