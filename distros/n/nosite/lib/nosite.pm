package nosite;

use strict;
use warnings;

use Config;

our $VERSION = '0.01';

my $sitelib  = $Config{sitelib};
my $sitearch = $Config{sitearch};

sub import {
  @INC = grep { $_ ne $sitelib and $_ ne $sitearch } @INC;
  return;
}

1;
__END__

=head1 NAME

nosite - @INC without sitelib and sitearch

=head1 SYNOPSIS

    use nosite;

    perl -Mnosite script

=head1 DESCRIPTION

I use sitelib for testing new modules from CPAN, and corelib and
vendorlib for work. This little module just meets my need. May it help
you too :-)

=head1 AUTHOR

Shu Cao

=cut
