package Test::WebService::ValidSign;

use strict;
use warnings;

# ABSTRACT: A base test package for WebService::ValidSign

use namespace::autoclean ();
use Test::Most ();
use Import::Into;

if (__has_module('JSON::XS', '4.01')) {
    Test::More::BAIL_OUT(
        "You have JSON::XS 4.01, please upgrade to JSON::XS 4.0 or lower OR 4.02 or higher."
    );
}

sub __has_module {
  my ($module, $version_or_range) = @_;
  require Module::Metadata;
  my $mmd = Module::Metadata->new_from_module($module);
  return undef if not $mmd;
  return $mmd->version($module) if not defined $version_or_range;

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->new;
  $req->exact_version($module => $version_or_range);
  return 1 if $req->accepts_module($module => $mmd->version($module));
  return 0;
}

sub import {

    my $caller_level = 1;

    # Test::Most imports *ALL* functions of Test::Deep, Test::Deep has
    # any, all, none, and some others that List::Utils also has.
    # Test::Deep has EXPORT_TAGS but they include pretty much everything
    my @TEST_DEEP_LIST_UTILS = qw(!any !all !none);
    Test::Most->import::into($caller_level, @TEST_DEEP_LIST_UTILS);

    my @imports = qw(
        strict
        warnings
        namespace::autoclean
        Sub::Override
        WebService::ValidSign
    );

    $_->import::into($caller_level) for @imports;
}

1;

__END__

=head1 DESCRIPTION

Imports all the stuff we want plus sets strict/warnings etc

=head1 SYNOPSIS

    use lib qw(t/lib); # Or use Test::Lib
    use Test::WebService::ValidSign;

    # tests here

    done_testing;
