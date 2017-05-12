use strict;
use warnings;
package Warnings::Version;
$Warnings::Version::VERSION = '0.003002';
# ABSTRACT: Load warnings from a specific version of perl

use 5.006;

use Import::Into;

my %warnings;
$warnings{ categories } = [ qw/ all io severe syntax utf8 experimental / ];
$warnings{ all        } = [ qw/ closure exiting glob io closed exec newline
    pipe unopened misc numeric once overflow pack portable recursion redefine
    regexp debugging inplace internal malloc signal substr syntax ambiguous
    bareword deprecated digit parenthesis precedence printf prototype qw
    reserved semicolon taint uninitialized unpack untie utf8 void / ];
$warnings{ '5.6'      } = [ @{ $warnings{all} }, qw/ chmod umask y2k / ];
$warnings{ '5.8'      } = [ @{ $warnings{all} }, qw/ layer threads y2k / ];
$warnings{ '5.10'     } = [ @{ $warnings{all} }, qw/ layer threads / ];
$warnings{ '5.12'     } = [ @{ $warnings{all} }, qw/ layer imprecision
    illegalproto threads / ];
$warnings{ '5.14'     } = [ @{ $warnings{all} }, qw/ layer imprecision
    illegalproto threads surrogate non_unicode nonchar / ];
$warnings{ '5.16'     } = [ @{ $warnings{all} }, qw/ layer imprecision
    illegalproto threads surrogate non_unicode nonchar / ];
$warnings{ '5.18'     } = [ @{ $warnings{all} }, qw/ experimental::lexical_subs
    imprecision layer illegalproto threads non_unicode nonchar surrogate / ];
$warnings{ '5.20'     } = [ @{ $warnings{all} }, qw/ experimental::autoderef
    experimental::lexical_subs experimental::lexical_topic
    experimental::postderef experimental::regex_sets experimental::signatures
    experimental::smartmatch imprecision layer syscalls illegalproto threads
    non_unicode nonchar surrogate / ];
$warnings{ '5.22'     } = [ @{ $warnings{all} }, qw/ experimental::autoderef
    experimental::bitwise experimental::const_attr experimental::lexical_subs
    experimental::lexical_topic experimental::postderef experimental::re_strict
    experimental::refaliasing experimental::regex_sets experimental::signatures
    experimental::smartmatch experimental::win32_perlio imprecision layer
    syscalls locale missing redundant illegalproto threads non_unicode nonchar
    surrogate /];


sub import {
    my $package = shift;
    my $version = shift;
    $version = 'all' if not defined $version;
    warnings->import::into(scalar caller, get_warnings($version, $]));
}

sub unimport {
    my $package = shift;
    my $version = shift;
    warnings->unimport::from(scalar caller, get_warnings($version, $]));
}

sub get_warnings {
    my $version      = massage_version(shift);
    my $perl_version = massage_version(shift);

    die "Unknown version: $version\n"           unless defined
                                                    $warnings{ $version };
    die "Unknown perl version: $perl_version\n" unless defined
                                                    $warnings{ $perl_version };

    my $wanted       = $warnings{ $version      };
    my $available    = $warnings{ $perl_version };

    return intersection( $wanted, $available );
}

sub massage_version {
    local $_ = shift;

    s/(5\.\d+)\..*/$1/;
    s/(5\.\d\d\d).*/$1/;
    s/(5\.)0*/$1/;

    return $_;
}

sub intersection {
    my ($a1, $a2) = @_;
    my %count;

    return grep { $count{$_}++ == 1 } @{ $a1 }, @{ $a2 };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Warnings::Version - Load warnings from a specific version of perl

=head1 VERSION

version 0.003002

=head1 SYNOPSIS

  use Warnings::Version '5.6';
      # All warnings that exist on both perl 5.6 and your running version of
      # perl will be enabled.
      #   For example, on perl 5.8 this will mean all 5.8 warnings except
      #   'layer' and 'threads' warnings.

  use Warnings::Version '5.6.2';
      # Same thing; Warnings::Version ignores the .2 at the end.

  use Warnings::Version '5.20';
      # All warnings that exist on both perl 5.20 and your running version of
      # perl will be enabled.
      #   For example, on perl 5.8 this will mean all 5.8 warnings except 'y2k'
      #   warnings.

  use Warnings::Version 'all';
      # This special warning category gives you only the warnings that are on
      # _all_ perls that ship with the warnings pragma.

  use Warnings::Version 'all';
  no warnings 'deprecated';      # You can disable specific warnings as usual

=head1 DESCRIPTION

Since newer versions of perl may add new warning categories, it can be annoying
getting spurious warnings for code that used to work completely fine on a
previous version of perl. This module only loads the warning categories that
exist on both the perl you're running with, as well as the perl you wrote the
module for. It is meant for module authors or people running code in
production, who don't want to get tonnes of emails and bugreports when someone
upgrades their perl version and your code starts emitting warnings. Of course
you should still keep up to date with deprecations and perl's experiments so
your code doesn't break when there's been actual changes in how things work,
but with this module, at least your I<users> don't need to worry about that
too.

=head1 SEE ALSO

=over

=item * The core L<warnings> module.

=back

=head1 BUGS

Please use the L<GitHub issue
tracker|https://github.com/pink-mist/Warnings-Version/issues> issue tracker to
report bugs to this distribution.

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
