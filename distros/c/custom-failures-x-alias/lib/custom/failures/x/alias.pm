package custom::failures::x::alias;

# ABSTRACT: export aliases for custom::failures

use v5.12.0;

use strict;
use warnings;

our $VERSION = '0.04';

sub _croak {
    require Carp;
    goto \&Carp::croak;
}

sub _alias {
    my ( $failure, $opt ) = @_;
    $failure =~ s/::/_/g;
    return ($opt->{-prefix} // '')  . $failure . ($opt->{-suffix} // '') ;
}

sub import {
    my ( $class, @failures ) = @_;
    my $caller;

    # mimic what failures::import does to allow specifying the caller
    if ( 'ARRAY' eq ref $failures[1] ) {
        $caller   = shift @failures;
        @failures = @{ $failures[0] };
    }
    else {
        $caller = caller;
    }

    my $export   = 'EXPORT_OK';
    my $exporter = 'Exporter';
    my $alias    = \&_alias;
    my %opt;

    while ( @failures && substr( $failures[0], 0, 1 ) eq '-' ) {
        my $opt = shift @failures;

        if ( $opt eq '-prefix' ) {
            $opt{-prefix} = shift( @failures )
              // _croak( "missing value for -prefix" );
        }

        elsif ( $opt eq '-suffix' ) {
            $opt{-suffix} = shift( @failures )
              // _croak( "missing value for -suffix" );
        }

        elsif ( $opt eq '-alias' ) {
            $alias = shift( @failures ) // _croak( "missing value for -alias" );
            'CODE' eq ref $alias
              or _croak( "-alias must be a coderef" );
        }

        elsif ( $opt eq '-export' ) {
            $export = 'EXPORT';
        }

        elsif ( $opt eq '-exporter' ) {
            $exporter = shift( @failures )
              // _croak( "missing value for -exporter" );
            eval "use $exporter ; 1 "  ## no critic (ProhibitStringyEval)
              || _croak(
                "requested exporter '$exporter' cannot be loaded: $@" );
        }

    }


    require custom::failures;
    custom::failures->import( $caller => \@failures );

    {
        no strict 'refs';    ## no critic (ProhibitNoStrict)

        my @export;
        for my $failure ( @failures ) {
            my $alias = $alias->( $failure, \%opt );
            push @export, $alias;
            my $fqn = "${caller}::${alias}";
            ## no critic(BuiltinFunctions::ProhibitStringyEval)
            eval "package ${caller}; sub ${alias} () { '${caller}::${failure}' } 1;"
              or _croak( "error creating $fqn" );
        }

        if ( $exporter eq 'Exporter' ) {
            require Exporter;
            my $fqn  = "${caller}::import";
            *$fqn = \&Exporter::import;
        }
        else {
            my $fqn = "${caller}::ISA";
            my $ISA = *{$fqn}{ARRAY} // ( *$fqn = [] );
            push @$ISA, $exporter;
        }

        {
            my $fqn  = "${caller}::${export}";
            my $export = *{$fqn}{ARRAY} // ( *$fqn = [] );
            push @$export, @export;
        }

        {
            my $fqn = "${caller}::EXPORT_TAGS";
            my $tags = *{$fqn}{HASH} // ( *$fqn = {} );
            push @{ $tags->{all} //= [] },  @export;
        }
    }

    return;
}

1;

#
# This file is part of custom-failures-x-alias
#
# This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

custom::failures::x::alias - export aliases for custom::failures

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  package MyApp::failure;
  use custom::failures::x::alias qw/io::flie io::network/;

=head1 DESCRIPTION

This package creates importable alias subroutines for failure classes created by L<custom::failures>.

Typically, you use L<custom::failures> like this:

  package MyApp::failure;
  use custom::failures qw/io::flie io::network/;

and later

  package MyApp;
  use MyApp::failure;

  # somewhere deep in your code
  MyApp::failure::io::flie->throw();

L</custom::failures::x::alias> creates shortened aliases so that you don't have to type so much:

  package MyApp::failure;
  use custom::failures::x::alias qw/io::flie io::network/;

and later,

  package MyApp;
  use MyApp::failure ':all'

  # somewhere deep in your code
  io_flie->throw;
  io_network->throw;

=head1 USAGE

=head2 Simple usage

Use it like you would C<custom::failures>.

  package MyApp::failure;
  use custom::failures::x::alias qw/io::flie io::network/;

This will create alias subroutines C<MyApp::failure::io_flie> and C<MyApp::failure::io_network>,
and make them importable. When using C<MyApp::failure>, either import specific aliases:

  package MyApp;
  use MyApp::failure qw( io_flie );

  io_flie->throw;

Or import them all:

  package MyApp;
  use MyApp::failure ':all';

  io_flie->throw;

=head2 Modifying the alias subroutine names

The names of the alias subroutines may be modified by passing options
to C<custom::failures::x::alias> preceding the list of failure
classes, e.g.

  package MyApp::failure;
  use custom::failures::x::alias  -prefix => $pfx, @failures;

The options are:

=over

=item I<-prefix> => $prefix

The next element in the list is a string which will be prepended to
the normalized class names.  For example,

  use custom::failures::x::alias  -prefix => 'failure_, 'io::flie';

results in a alias name of

   failure_io_flie

=item I<-suffix> => $suffix

The next element in the list is a string which will be appended to
the normalized class names.  For example,

  use custom::failures::x::alias  -suffix => '_failure', 'io::flie';

results in a alias name of

   io_flie_failure

=item I<-alias> => $coderef

This hands over complete control.  C<$coderef> should return
a legal Perl subroutine name and is called as

   $alias_name = $coderef->( $class_name, \%opt);

where C<$class_name> is the name passed via the C<use> statement, and
C<%opt> has entries for C<-suffix> and C<-prefix> if specified, e.g.

  use custom::failures::x::alias
    -suffix => '_failure',
     -alias => \&mysub, 'io::flie';

results in a call to C<mysub>:

  mysub( 'io::flie', { -suffix => _failure } );

The default routine looks like this:

  sub _alias {
      my ( $failure, $opt ) = @_;
      $failure =~ s/::/_/g;
      return ($opt->{-prefix} // '')  . $failure . ($opt->{-suffix} // '') ;
  }

=item I<-export>

If this option is present (it takes no argument), aliases are unconditionally exported.

=item I<-exporter> => $class

This will change which exporter is used.  By default the standard L<Exporter> class is used.
A useful alternative is L<Exporter::Tiny>, which allows the user of your failure module to
dynamically alter the imported alias names, e.g.:

  package MyApp::failure;
  use custom::failures::x::alias
     -exporter => 'Exporter::Tiny', qw/io::flie io::network/;

and later,

  package MyApp;
  use MyApp::failure { suffix => '_failure' }, -all;

  # somewhere deep in your code
  io_flie_failure->throw;
  io_network_failure->throw;

An alternative is for the user of your failure module to use L<Importer>.

=back

=head1 HOW IT WORKS

L<custom::failures::x::alias> does the following:

=over

=item 1

It uses L<custom::failures> to create the specified classes in the caller's namespace.

=item 2

For each class it installs an alias subroutine with a shortened and
normalized name into the caller's namespace.

=item 3

It makes the caller an exporter, either by installing the C<import>
routine from L<Exporter> into the caller's namespace, or making the caller a subclass of a user
specified exporter class (e.g. L<Exporter::Tiny>).

=item 4

It adds the aliases to the caller's  C<@EXPORT_OK> or (optionally) C<@EXPORT>.

=item 5

It adds the aliases to the C<all> entry in the caller's  C<%EXPORT_TAGS>;

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-custom-failures-x-alias@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=custom-failures-x-alias

=head2 Source

Source is available at

  https://gitlab.com/djerius/custom-failures-x-alias

and may be cloned from

  https://gitlab.com/djerius/custom-failures-x-alias.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<custom::failures|custom::failures>

=item *

L<Exporter|Exporter>

=item *

L<Exporter::Tiny|Exporter::Tiny>

=item *

L<Importer|Importer>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
