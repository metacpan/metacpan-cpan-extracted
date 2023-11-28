package Test::XML::Sig;
use strict;
use warnings;

use Test::Lib;

# ABSTRACT: Test module for XML::Sig

use Import::Into;
require Test::More;
require Test::XML::Sig::Util;
require XML::Sig;

sub import {

    my $caller_level = 1;

    my @imports = qw(
        Test::XML::Sig::Util
        strict
        warnings
        Test::More
        XML::Sig
    );

    $_->import::into($caller_level) for @imports;
}

1;

__END__


=head1 DESCRIPTION

Main test module for Net::SAML2

=head1 SYNOPSIS

  use Test::Lib;
  use Test::Net::SAML2;

  # tests here

  ...;

  done_testing();
1;

__END__


=head1 DESCRIPTION

Main test module for XML::Sig

=head1 SYNOPSIS

  use Test::Lib;
  use Test::XML::Sig;

  # tests here

  ...;

  done_testing();
