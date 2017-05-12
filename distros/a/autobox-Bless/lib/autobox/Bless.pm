package autobox::Bless;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.02';

use autobox;
use base 'autobox';
use Devel::Gladiator;
use Data::Dumper;
use Scalar::Util;
use Devel::Peek;
use Carp;
use Devel::Caller 'caller_cv'; # cx_type is 40 not CXt_SUB unless it's the current version

# use PadWalker;
# use B;

# could take one of three approaches; remember every field seen in every class; remember the top n closest matches as we go; take the first good match
# it's a memory vs accuracy tradeoff
# could also take a hybrid approach and if we don't find an exact match, look for a best match

sub HASH::AUTOLOAD {
    my $unblessed_hash = shift;
    return if $HASH::AUTOLOAD =~ m/::DESTROY$/;
    (my $method) = $HASH::AUTOLOAD =~ m/.*::(.*)/;
    # warn "``$method'' called";
    # my @contenders;  # ( [ package, score ], ... )
    my $keeper_type;
    for my $sv ( @{ Devel::Gladiator::walk_arena() } ) {
        next unless UNIVERSAL::isa($sv, 'HASH');
        next unless Scalar::Util::blessed $sv; 
        next unless $sv->can($method);
        # warn "considering type " . Scalar::Util::blessed $sv;
        for my $field ( %{ $unblessed_hash } ) {
            exists $sv->{$field} or next;
        }
        # use Devel::ArgNames; my @argnames = Devel::ArgNames::arg_names(@_ XXX before the shift); my $type = ref $sv; bless peek_my(0)->{'%'.$argnames[0]}, $type;
        $keeper_type = Scalar::Util::blessed $sv;
    }
    $keeper_type ||= autobox::Bless::_package_with_method($method);  # backup plan
    if( $keeper_type ) {
        # warn "won with type " . $keeper_type;
        # $keeper_type->can($method)->($unblessed_hash, @_);  # or even better:
        bless $unblessed_hash, $keeper_type; $unblessed_hash->$method(@_); 
    } else {
        Carp::confess qq{Can't call method "$method" without a package or object reference, and believe me, I tried};
    }
}

sub _package_with_method {
    # look through the package hierarchy looking for something with the given method (er, function)
    my $given_method = shift;
    sub {
        my $package = shift;
        # warn "considering package ``$package''";
        no strict 'refs';
        for my $k (keys %$package) {
            if(*{$package.$k}{CODE} and $k eq $given_method) {
                # warn "found it!";
                $package =~ s{::$}{};
                return $package; # success!
            }
        }
        for my $k (keys %$package) {
            next if $k =~ m/main::$/;
            next if $k =~ m/[^\w:]/;
            next unless $k =~ m/::$/;
            # recurse into that namespace unless it corresponds to a .pm module that got used at some point
            my $modulepath = $package.$k;
            # for($modulepath) { s{^main::}{}; s{::$}{}; s{::}{/}g; $_ .= '.pm'; }
            # next if exists $INC{$modulepath};
            my $maybe_result = caller_cv(0)->($package.$k);  # press on forward into darker depths
            return $maybe_result if $maybe_result;
        }
        return; # backtrack/failure
    }->('main::');
}



1;
__END__

=head1 NAME

autobox::Bless - Guess which package a hash or hashref probably should be and blessed it

=head1 SYNOPSIS

  package purple;

  sub new { 
      my $package = shift;
      bless { one => 1, two => 2, }, $package;
  }

  sub three {
      my $self = shift;
      $self->{one} + $self->{two};
  }

  #

  package main;

  use autobox::Bless;

  my $purple = purple->new;   # optionally comment this out

  my %foo = ( one => 5, two => 17 );
  print %foo->three, "\n";    # 22!
  print %foo->four, "\n";     # not found, but %foo is now blessed into purple (yes, really)

=head1 DESCRIPTION

Attempts to guess which package an unblessed hash or hashref should be blessed into and
bless it into that package on the fly.

Guessing is done by the fields (hash keys) present in the unblessed hash versus the fields
in instances of various objects in memory.
To be considered a match, the thing must find an object with all of the fields as the
unblessed hash.

If that heuristic fails, as it would in the SYNOPSIS example where the C<<purple->new>> line
is commented out, then a less nice strategy is attempted:  all loaded packages are exampled
for one containing the method called.

Why would anyone want this?  You have a large legacy codebase that makes heavy use of hashes
for collections of assortments of data and you want to shoehorn an OO-ish API onto it.
Or perhaps you just want to play with an ultra lazy style of programming.

=head1 TODO

=over 1

=item Mix in the C<< my Foo::Bar $foo >> trick to give it (strong) hints

=item Do whatever Devel::LeakTrace does to figure out where stuff is allocated and assume that datastructures allocated in one package should be blessed into the same package

=item Do better approximate matching; don't require a single instance of an object to exist with all of the fields but instead permit an aggregate of all examples to contain the various different fields

=back


=head1 BUGS

When used with L<autobox::Core> or similar modules that add API methods to primitive values, 
method names might clash.


=head1 SEE ALSO

L<autobox>, L<autobox::Core>, L<perl5i>, ...

L<< http://twitter.com/scrottie/status/10706254646 >>

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
