package Test::XML::Enc;
use strict;
use warnings;
use namespace::autoclean ();

use Test::Lib;

# ABSTRACT: Test module for XML::Enc

use Import::Into;

use Test::XML::Enc::Util ();

sub import {

    my $caller_level = 1;

    my @imports = qw(
        Test::XML::Enc::Util
        namespace::autoclean
        strict
        warnings
    );

    $_->import::into($caller_level) for @imports;
}

=head1 DESCRIPTION

Main test module for XML::Enc

=head1 SYNOPSIS

  use Test::Lib;
  use Test::XML::Enc;

  # tests here

  ...;

  done_testing();

=cut

1;
__END__
