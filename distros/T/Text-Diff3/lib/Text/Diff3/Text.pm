package Text::Diff3::Text;
use 5.006;
use strict;
use warnings;
use base qw(Text::Diff3::ListMixin Text::Diff3::Base);

use version; our $VERSION = '0.08';

sub text { return $_[0]->{text} }
sub list { return $_[0]->{text} } # interface to ListMixin

sub first_index { return 1 }

sub last_index {
   my($self) = @_;
   return $#{$self->{text}} + $self->first_index;
}

sub range {
    my($self) = @_;
    return ($self->first_index .. $self->last_index);
}

sub at {
    my($self, $x) = @_;
    $x -= $self->first_index;
    return $x < 0 || $x > $#{$self->{text}} ? undef : $self->{text}[$x];
}

sub as_string_range {
    my($self, @range) = @_;
    my $t = q{};
    for (@range) {
        my $line = $self->at($_);
        if (defined $line) {
            $t .= $line . "\n";
        }
    }
    return $t;
}

sub as_string_at {
    my($self, $x) = @_;
    my $line = $self->at($x);
    return defined($line) ? $line . "\n" : q{};
}

sub eq_at {
    my($self, $x, $other) = @_;
    my $this = $self->at($x);
    return 0 if (defined $this) ^ (defined $other);
    return ! (defined $this) || $this eq $other;
}

sub initialize {
    my($self, @arg) = @_;
    $self->SUPER::initialize(@arg);
    my($f, $s) = @arg;
    if (ref $s eq 'ARRAY') {
        $self->{text} = $s;
    } else {
        if (ref $s) {
            $s = ${$s};
        }
        chomp $s;
        $self->{text} = [split /\n/msx, $s, -1];
    }
    return $self;
}

1;

__END__

=pod

=head1 NAME

Text::Diff3::Text - line number scheme free text buffer

=head1 VERSION

0.08

=head1 SYNOPSIS

    use Text::Diff3;
    my $f = Text::Diff3::Factory->new;
    my $t0 = $f->create_text([ map{chomp;$_} <F0> ]); # do not dup internally.
    my $t1 = $f->create_text($string); # make array references.
    # follows four take same output.
    print $_, "\n" for @{$t0->text};
    print $t0->as_string_at($_) for $t0->range;
    print $t0->as_string_range($t0->ragne);
    print $t0->as_string_at($_) for $t0->first_index .. $t0->last_index;
    print $t0->as_string_range($t0->first_index .. $t0->last_index);
    for ($t0->first_index .. $t0->last_index) {
        my $line = $t0->at($_);
        print $line, "\n" if defined($line);
    }
    # string compare
    if ($t0->eq_at($i, $string)) { .... }
    # get string size
    my $length = $t0->size;

=head1 DESCRIPTION

This is a wrapper for a Perl's array reference, improving line number
scheme free and limiting fetching from last element by minus index.
Normally line number starts 1 in compatible with diff command tools.
But you can change it another value like as 0 override first index
methods.

=over

=item create

Author recommends you to create an instance of text by using with
a factory as follows.

  use SomeFactory;
  my $f = SomeFactory->new;
  my $t = $f->create_text( string or arrayref );

Text::Diff3::Factory is a class to packaging several classes
for the build-in diff processor.

When pass a string, it is split by /\n/ before store the line buffers.
When pass an array reference, it simply assigned text properties
without duplication. In the later case, the side effects will happen
if you use same reference at another place.

=item C<< $obj->text >>

Returns the line buffer attribute. It is an array reference.

=item C<< $obj->list >>

Same as the text property, which is an interface property
for ListMixin.

=item C<< $obj->first_index >>

Returns first-index accessible by the `at' method.

=item C<< $obj->last_index >>

Returns last-index accessible by the `at' method.

=item C<< $obj->range >>

Returns a range between fist-index and last-index.

=item C<< $obj->at >>

Returns a line specified by a line number.
If line number is out of range, it returns undef.

=item C<< $obj->as_string_at($x) >>

This is short cut for line accessing through `at'.
If line number is out of range, it returns '', in otherwise returns line."\n".

=item C<< $obj->as_string_range(@range) >>

Contatinents lines in the given line number array.

=item C<< $obj->eq_at($x, $other) >>

This is short cut for comparison line and other string.

=item C<< $obj->initialize >>

Makes initial state.

=back

=head1 COMPATIBILITY

Use new function style interfaces introduced from version 0.08.
This module remained for backward compatibility before version 0.07.
This module is no longer maintenance after version 0.08.

=head1 AUTHOR

MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 MIZUTANI Tociyuki

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

=cut

