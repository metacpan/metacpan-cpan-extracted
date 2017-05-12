package t::Utils;

sub escape_bytestring {
    my $str = shift;
    '\\x' . join '\\x', map { sprintf '%02X', ord $_ } split //, $str;
}

1;
