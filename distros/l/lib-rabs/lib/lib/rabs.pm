package lib::rabs;

our $VERSION = '0.01';
use lib::abs;

sub import {
    my $class = shift;
    @INC = reverse @INC;
    lib::abs->import(@_);
    @INC = reverse @INC;
    return;
}

1;
__END__

=head1 NAME

lib::rabs - lib that makes relative path absolute to caller, backwards.

=cut
