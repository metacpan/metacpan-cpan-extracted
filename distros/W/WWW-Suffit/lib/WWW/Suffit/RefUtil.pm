package WWW::Suffit::RefUtil;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::RefUtil - Pure Perl Utility functions for checking references and data

=head1 SYNOPSIS

    use WWW::Suffit::RefUtil qw/ :all /;

=head1 DESCRIPTION

Pure Perl Utility functions for checking references and data

B<STOP!> All functions in this module have been deprecated in favor of L<Acrux::RefUtil>

=head2 AS

The 'as' functions are introduced by the C<:as> import tag, which check
the type of passed argument and returns it as required type

=over 4

=item as_array_ref

Deprecated! See L<Acrux::RefUtil>

=item as_array, as_list

Deprecated! See L<Acrux::RefUtil>

=item as_first, as_first_val

Deprecated! See L<Acrux::RefUtil>

=item as_hash_ref

Deprecated! See L<Acrux::RefUtil>

=item as_hash

Deprecated! See L<Acrux::RefUtil>

=item as_last, as_last_val, as_latest

Deprecated! See L<Acrux::RefUtil>

=back

=head2 CHECK

Check functions are introduced by the C<:check> import tag, which check
the argument type and return a bool

=over 4

=item is_ref

Deprecated! See L<Acrux::RefUtil>

=item is_scalar_ref

Deprecated! See L<Acrux::RefUtil>

=item is_array_ref

Deprecated! See L<Acrux::RefUtil>

=item is_hash_ref

Deprecated! See L<Acrux::RefUtil>

=item is_code_ref

Deprecated! See L<Acrux::RefUtil>

=item is_glob_ref

Deprecated! See L<Acrux::RefUtil>

=item is_regexp_ref, is_regex_ref, is_rx

Deprecated! See L<Acrux::RefUtil>

=item is_value

Deprecated! See L<Acrux::RefUtil>

=item is_string

Deprecated! See L<Acrux::RefUtil>

=item is_number

Deprecated! See L<Acrux::RefUtil>

=item is_integer, is_int8, is_int16, is_int32, is_int64

Deprecated! See L<Acrux::RefUtil>

=item is_undef

Deprecated! See L<Acrux::RefUtil>

=back

=head2 VOID

Void functions are introduced by the C<:void> import tag, which check
the argument type in void value and return a bool

=over 4

=item is_void

Deprecated! See L<Acrux::RefUtil>

=item isnt_void

Deprecated! See L<Acrux::RefUtil>

=back

=head2 FLAG

=over 4

=item is_false_flag

Deprecated! See L<Acrux::RefUtil>

=item is_true_flag

Deprecated! See L<Acrux::RefUtil>

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acrux::RefUtil>, L<Data::Util::PurePerl>, L<Params::Classify>,
L<Ref::Util>, L<CTK::TFVals>, L<CTK::ConfGenUtil>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.03';

use base qw/Exporter/;
our @EXPORT = (qw/
        is_ref is_undef
        is_scalar_ref is_array_ref is_hash_ref is_code_ref
        is_glob_ref is_regexp_ref is_regex_ref is_rx
        is_value is_string is_number is_integer
        is_int8 is_int16 is_int32 is_int64
    /);

# Required
our @EXPORT_OK = (qw/
        is_void isnt_void
        is_true_flag is_false_flag
        as_array as_list as_array_ref as_hash as_hash_ref
        as_first as_first_val as_last as_last_val as_latest
    /, @EXPORT);

# Tags
our %EXPORT_TAGS = (
        all      => [@EXPORT_OK],
        check    => [@EXPORT],
        void     => [qw/
            is_void isnt_void
        /],
        flag     => [qw/
            is_true_flag is_false_flag
        /],
        as       => [qw/
            as_array as_list as_array_ref as_hash as_hash_ref
            as_first as_first_val as_last as_last_val as_latest
        /],
    );

use constant MAX_DEPTH => 32;

# Base functions
sub is_ref { ref($_[0]) ? 1 : 0 }
sub is_undef { !defined($_[0]) }
sub is_scalar_ref { ref($_[0]) eq 'SCALAR' || ref($_[0]) eq 'REF' }
sub is_array_ref { ref($_[0]) eq 'ARRAY' }
sub is_hash_ref { ref($_[0]) eq 'HASH' }
sub is_code_ref { ref($_[0]) eq 'CODE' }
sub is_glob_ref { ref($_[0]) eq 'GLOB' }
sub is_regexp_ref { ref($_[0]) eq 'Regexp' }
sub is_regex_ref { goto &is_regexp_ref }
sub is_rx { goto &is_regexp_ref }
sub is_value { defined($_[0]) && !ref($_[0]) && ref(\$_[0]) ne 'GLOB' }
sub is_string { defined($_[0]) && !ref($_[0]) && (ref(\$_[0]) ne 'GLOB') && length($_[0]) }
sub is_number { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /^[+-]?(?=\d|\.\d)\d*(\.\d*)?(?:[Ee](?:[+-]?\d+))?$/) ? 1 : 0 }
sub is_integer { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /^[+-]?\d+$/) ? 1 : 0 }
sub is_int8 { (defined($_[0]) && !ref($_[0]) && ($_[0] =~ /^[0-9]{1,3}$/) && ($_[0] < 2**8)) ? 1 : 0 }
sub is_int16 { (defined($_[0]) && !ref($_[0]) && ($_[0] =~ /^[0-9]{1,5}$/) && ($_[0] < 2**16)) ? 1 : 0 }
sub is_int32 { (defined($_[0]) && !ref($_[0]) && ($_[0] =~ /^[0-9]{1,10}$/) && ($_[0] < 2**32)) ? 1 : 0 }
sub is_int64 { (defined($_[0]) && !ref($_[0]) && $_[0] =~ /^[0-9]{1,20}$/) ? 1 : 0 }

# Extended
sub is_void {
    my $struct = shift;
    my $depth = shift || 0;
    return 1 unless defined($struct); # CATCHED! THIS IS REAL UNDEFINED VALUE
    return 0 if defined($struct) && !ref($struct); # VALUE, NOT REFERENCE
    if (is_int8($depth) && $depth > 0) {
        return 1 unless is_int8($depth);
    } else {
        return 1 unless is_int8($depth);
    }
    $depth++;
    return 0 if $depth >= MAX_DEPTH; # Exit from the recursion

    my $t = ref($struct);
    if ($t eq 'SCALAR') {
        return is_void($$struct, $depth)
    } elsif ($t eq 'ARRAY') {
        for (@$struct) {
            return 0 unless is_void($_, $depth);
        }
        return 1; # DEFINED DATA NOT FOUND - VOID
    } elsif ($t eq 'HASH') {
        return 0 if keys(%$struct);
        return 1; # DEFINED DATA NOT FOUND - VOID
    }

    # CODE, REF, GLOB, LVALUE, FORMAT, IO, VSTRING and Regexp are not supported here
    return 0; # NOT VOID
}
sub isnt_void {is_void(@_) ? 0 : 1}
sub is_true_flag {
    my $f = shift || return 0;
    return $f =~ /^(on|y|true|enable|1)/i ? 1 : 0;
}
sub is_false_flag {
    my $f = shift || return 1;
    return $f =~ /^(off|n|false|disable|0)/i ? 1 : 0;
}

# As
sub as_array_ref {
    return [] unless scalar @_; # if no args
    return [@_] if scalar(@_) > 1; # if too many args
    return [] unless defined($_[0]); # if value is undef
    if (ref($_[0]) eq 'ARRAY') { return $_[0] } # Array
    elsif (ref($_[0]) eq 'HASH') { return [%{$_[0]}] } # Hash
    return [$_[0]];
}
sub as_array {
    my $r = as_array_ref(@_);
    return wantarray ? @$r : $r;
}
sub as_list { goto &as_array }
sub as_hash_ref {
    return {} unless scalar @_; # if no args passed
    return {@_} unless scalar(@_) % 2; # if even (not odd) args passed
    return {} unless defined($_[0]); # if arg is undef
    if (ref($_[0]) eq 'HASH') { return $_[0] } # Hash
    return {};
}
sub as_hash {
    my $r = as_hash_ref(@_);
    return wantarray ? %$r : $r;
}
sub as_first {
    return undef unless defined $_[0];
    my $r = as_array_ref(@_);
    return undef unless exists($r->[0]) && defined($r->[0]);
    my $v = $r->[0];
    if (!ref($v)) { return $v } # No ref
    elsif (ref($v) eq 'SCALAR' || ref($v) eq 'REF') { return $$v } # Scalar ref
    return $v;
}
sub as_first_val { goto &as_first }
sub as_last {
    return undef unless defined $_[0];
    my $r = as_array_ref(@_);
    return undef unless exists($r->[0]) && defined($r->[0]);
    my $v = $r->[-1];
    if (!ref($v)) { return $v } # No ref
    elsif (ref($v) eq 'SCALAR' || ref($v) eq 'REF') { return $$v } # Scalar ref
    return $v;
}
sub as_last_val { goto &as_last }
sub as_latest { goto &as_last }

1;

__END__
