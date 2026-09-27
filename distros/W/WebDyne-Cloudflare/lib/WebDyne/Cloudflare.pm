package WebDyne::Cloudflare;

use 5.020;
use strict;
use warnings;
use Encode qw(decode FB_CROAK);
use Scalar::Util qw(refaddr);

our $VERSION='0.005';

sub json_value {
    my ($value_ref, $seen_hr)=@_;
    if (!ref($value_ref)) {
        return decode('UTF-8', $value_ref, FB_CROAK)
            if (defined($value_ref)&&!utf8::is_utf8($value_ref)&&($value_ref=~/[\x80-\xff]/));
        return $value_ref;
    }
    my $type=ref($value_ref);
    return $value_ref unless (($type eq 'HASH')||($type eq 'ARRAY'));

    #  Normalize a copy, preserving numeric flags and rejecting cyclic input.
    #
    $seen_hr={} unless $seen_hr;
    my $address=refaddr($value_ref);
    die "Cloudflare request contains a circular reference\n" if $seen_hr->{$address};
    local $seen_hr->{$address}=1;
    return [map { json_value($_, $seen_hr) } @{$value_ref}] if ($type eq 'ARRAY');
    my %value;
    foreach my $key (keys(%{$value_ref})) {
        my $name=json_value($key);
        die "Cloudflare request contains duplicate UTF-8 keys\n" if exists($value{$name});
        $value{$name}=json_value($value_ref->{$key}, $seen_hr);
    }
    return \%value;
}

1;
