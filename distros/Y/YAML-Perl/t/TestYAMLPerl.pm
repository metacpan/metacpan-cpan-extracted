package t::TestYAMLPerl;
use Test::Base -Base;

delimiters('===', '+++');
no_diff;

package t::TestYAMLPerl::Filter;
use Test::Base::Filter -base;

# use XXX;
sub assert_dump {
    my $values = $self->{current_block}{original_values};
    for my $key (@_) {
        my $value = $values->{$key} or next;
        next unless $value =~ /\S/;
        $value =~ s/\n+\z/\n/;
        return $value;
    }
    return '';
}

sub assert_dump_for_emit {
    return $self->assert_dump((qw(dump dump_emit yaml)));
}

sub assert_dump_for_dumper {
    return $self->assert_dump((qw(dump dump_dumper yaml)));
}
