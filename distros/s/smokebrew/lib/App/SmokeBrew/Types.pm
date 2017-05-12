package App::SmokeBrew::Types;
$App::SmokeBrew::Types::VERSION = '0.48';
#ABSTRACT: Moose types for smokebrew

use strict;
use warnings;

use MooseX::Types
    -declare => [qw(ArrayRefUri PerlVersion ArrayRefStr)];

use Moose::Util::TypeConstraints;

use MooseX::Types::Moose qw[Str ArrayRef];
use MooseX::Types::URI qw[to_Uri Uri];

use Module::CoreList;
use Perl::Version;

# Thanks to Florian Ragwitz for this magic

subtype 'ArrayRefUri', as ArrayRef[Uri];

coerce 'ArrayRefUri', from Str, via { [to_Uri($_)] };
coerce 'ArrayRefUri', from ArrayRef, via { [map { to_Uri($_) } @$_] };

# This is my own magic

subtype( 'PerlVersion', as 'Perl::Version',
   where { ( my $ver = Perl::Version->new($_)->numify ) =~ s/_//g;
            $ver >= 5.006 and
            scalar grep { $ver eq sprintf('%.6f',$_) } keys %Module::CoreList::released },
   message { "The version ($_) given is not a valid Perl version and is too old (< 5.006)" },
);

coerce( 'PerlVersion', from 'Str', via { Perl::Version->new($_) } );

subtype( 'ArrayRefStr', as ArrayRef[Str] );
coerce( 'ArrayRefStr', from 'Str', via { [ $_ ] } );

qq[Smokin'];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBrew::Types - Moose types for smokebrew

=head1 VERSION

version 0.48

=head1 SYNOPSIS

  use App::SmokeBrew::Types qw[ArrayRefUri PerlVersion ArrayRefStr];

  has 'version' => (
    is      => 'ro',
    isa     => 'PerlVersion',
    coerce  => 1,
  );

  has 'things' => (
    is      => 'ro',
    isa     => 'ArrayRefStr',
    coerce  => 1,
  );

  has 'websites' => (
    is      => 'ro',
    isa     => 'ArrayRefUri',
    coerce  => 1,
  );

=head1 DESCRIPTION

App::SmokeBrew::Types is a library of L<Moose> types for L<smokebrew>.

=head1 TYPES

It provides the following types:

=over

=item C<PerlVersion>

A L<Perl::Version> object.

Coerced from C<Str> via C<new> in L<Perl::Version>

Constrained to existing in L<Module::CoreList> C<released> and being >= C<5.006>

=item C<ArrayRefUri>

An arrayref of L<URI> objects.

Coerces from <Str> and C<ArrayRef[Str]> via L<MooseX::Types::URI>

=item C<ArrayRefStr>

An arrayref of C<Str>.

Coerces from C<Str>.

=back

=head1 KUDOS

Thanks to Florian Ragwitz for the L<MooseX::Types::URI> sugar.

=head1 SEE ALSO

L<URI>

L<Perl::Version>

L<MooseX::Types::URI>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
