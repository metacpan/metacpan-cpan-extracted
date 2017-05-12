package txs_gendata;
use strict;
use warnings;
use Digest::SHA1 qw(sha1_hex);
use MIME::Base64 qw(encode_base64);
use List::MoreUtils qw(uniq);

sub GenData($\[@@]) {
    my $options = shift;
    my ($term_ref,$str_ref) = @_;
    
    my $string_count = delete $options->{StringCount};
    my $term_count = delete $options->{TermCount};
    my $min_len = delete $options->{MinLength};
    my $max_len = delete $options->{MaxLength};
    
    @$str_ref = map substr(encode_base64(sha1_hex($_)), 0, $max_len+1),
        (0..$string_count);
    
    print $str_ref->[0] . "\n";
    
    while (@$term_ref < $term_count) {
        my $str = $str_ref->[int(rand($string_count))];
        my $prefix = substr($str, 0,
            int(rand($max_len-$min_len)) + $min_len);
        push @$term_ref, $prefix;
    }
    @$term_ref = uniq(@$term_ref);
    
    @$term_ref = sort { length $b <=> length $a || $a cmp $b } @$term_ref;
}

1;