use strict; use warnings;
package worky;
our $VERSION = '0.20';

use orz -base;

sub pmc_use_means_no { 1 }

sub pmc_compile {
    my $self = shift;
    my $code = $self->SUPER::pmc_compile(@_);
    $code =~ s/^# orz/# This code no worky/;
    return $code;
}

1;
