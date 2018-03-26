# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::_;

use 5.010_001;
use strictures 1;

use Moose;
use WebService::Braintree::Types;

my $WARN_ABOUT_UNKNOWN_KEYS = 0;
sub BUILD {
    my ($self, $attributes) = @_;

    # Should we warn about attributes we didn't know about?
    if ($WARN_ABOUT_UNKNOWN_KEYS) {
        # This does not warn about extra attributes that aren't used. The
        # assumption is that not all keys come back on every response. If that
        # turns out to be false, then we can revisit this code.
        my %seen;
        my $meta = $self->meta;
        foreach my $attr ($meta->get_all_attributes) {
            my $name = $attr->name;
            next unless exists $attributes->{$name};

            $seen{$name} = 1;
        }

        my @unseen;
        foreach my $k (keys %$attributes) {
            next if $seen{$k};
            # Ignore this one from Subscription
            next if $k eq 'next_bill_amount';
            push @unseen, $k;
        }

        if (@unseen) {
            use DDP;
            warn $self->meta->name . ":\n\t"
                . join("\n\t", sort @unseen)
                . "\n" . np($attributes) . "\n";
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__
