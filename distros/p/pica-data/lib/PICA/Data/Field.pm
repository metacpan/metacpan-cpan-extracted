package PICA::Data::Field;
use v5.14.1;

our $VERSION = '2.07';

use Carp qw(croak);
use Hash::MultiValue;

sub new {
    my $class = shift;
    my $tag   = shift;

    # simplify migration from PICA::Record
    return pica_field($tag->{_tag}, $tag->{_occurrence},
        @{$tag->{_subfields}})
        if ref $tag eq 'PICA::Field';

    my $field = bless [], $class;

    my $occ = '';

    if (@_ % 2) {
        $occ = shift // '';
    }
    elsif ($tag =~ m/^([0-2]\d{2}[A-Z@])(\/(\d+))?$/) {
        $tag = $1;
        $occ = $3;
    }

    $field->tag($tag);
    $field->occurrence($occ);

    croak "missing subfields" unless @_;
    my $ann = pop @_ if @_ % 2;
    $field->subfields(@_);
    $field->annotation($ann) if defined $ann && $ann ne '';

    return $field;
}

sub level {
    substr $_[0]->[0], 0, 1;
}

sub tag {
    if (@_ > 1) {
        my $tag = $_[1];
        croak "invalid tag: $tag" if $tag !~ qr/^[0-2]\d{2}[A-Z@]$/;
        $_[0]->[0] = $tag;
    }
    $_[0]->[0];
}

sub occurrence {
    if (@_ > 1) {
        my $occ = $_[1];
        if ($occ == 0) {
            $occ = undef;
        }
        else {
            croak "invalid occurrence: $occ" if $occ !~ qr/^\d+$/;
            if ($occ < 99) {
                $occ = sprintf('%02d', $occ);
            }
            elsif ($_[0]->level eq '2') {
                $occ = sprintf('%03d', $occ);
            }
        }
        $_[0]->[1] = $occ;
    }
    $_[0]->[1];
}

sub id {
    my ($tag, $occ) = @{$_[0]};
    $occ > 0 ? "$tag/$occ" : $tag;
}

sub annotation {
    my ($field, $ann) = @_;
    if (@_ > 1) {
        my $has_ann = !($#$field % 2);
        if (($ann // '') eq '') {
            pop @$field if $has_ann;
        }
        else {
            croak "invalid annotation: $ann" if $ann !~ /^[^A-Za-z0-9]$/;
            if ($has_ann) {
                $field->[-1] = $ann;
            }
            else {
                push @$field, $ann;
            }
        }
    }
    return $#$field % 2 ? undef : $field->[-1];
}

sub subfields {
    my $field = shift;

    if (@_) {
        while (@_) {
            my $code  = shift;
            my $value = shift;

            croak "invalid subfield code: $code" if $code !~ /^[A-Za-z0-9]$/;

            if (defined $value and $value ne '') {
                push @$field, $code, $value;
            }
        }
    }
    else {
        my $l = @$field % 2 ? $#$field - 1 : $#$field;
        return Hash::MultiValue->new(@$field[2 .. $l]);
    }
}

sub set {
    my ($field, $code, $value) = @_;
    croak "invalid subfield code: $code" if $code !~ /^[A-Za-z0-9]$/;

    return unless defined $value and $value ne '';

    for (my $i = 2; $i <= @$field / 2; $i++) {
        if ($field->[$i] eq $code) {
            $field->[$i + 1] = $value;
            return;
        }
    }

    push @$field, $code, $value;
}

sub TO_JSON {
    [@{$_[0]}];
}

1;

=head1 METHODS

=head2 new( $tag, [$occ,] @subfields [,$annotation] )

Create a new PICA+ field. Will die on invalid tag, occurrence, subfield
code or annotation.

=head2 level

Get the record level (0, 1, or 2).

=head2 tag( [$value] )

Get or set the tag.

=head2 occurrence( [$value] )

Get or set the occurrence.

=head2 id

Get the field identifier (tag and optional occurrence).

=head2 subfields( [ $code => $value, ...] )

Set all subfields if arguments are given. Otherwise return a
L<Hash::MultiValue> of all subfields. Use it's getter methods to access
subfield values. Changing subfields this way won't work!

=head2 set( $code => $value )

Set or append a subfield.

=cut
