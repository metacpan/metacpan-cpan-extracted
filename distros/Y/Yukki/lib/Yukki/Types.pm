package Yukki::Types;
{
  $Yukki::Types::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

use MooseX::Types -declare => [ qw(
    LoginName AccessLevel 
    NavigationLinks NavigationMenuMap
    BaseURL BaseURLEnum BreadcrumbLinks RepositoryMap
    PluginConfig PluginList
) ];

use MooseX::Types::Moose qw( Str Int ArrayRef Maybe HashRef );
use MooseX::Types::Structured qw( Dict );
use MooseX::Types::URI qw( Uri );

use Email::Address;
use List::Util qw( first );
use List::MoreUtils qw( all );

# ABSTRACT: standard types for use in Yukki


subtype LoginName,
    as Str,
    where { /^[a-z0-9]+$/ },
    message { "login name $_ must only contain letters and numbers" };


enum AccessLevel, [qw( read write none )];


subtype NavigationLinks,
    as ArrayRef[
        Dict[
            label => Str,
            href  => Str|Uri,
            sort  => Maybe[Int],
        ],
    ];


subtype NavigationMenuMap,
    as HashRef[ NavigationLinks ];


enum BaseURLEnum, [qw( SCRIPT_NAME REWRITE )];

subtype BaseURL, as BaseURLEnum|Uri;


subtype BreadcrumbLinks,
    as ArrayRef[
        Dict[
            label => Str,
            href  => Str,
        ],
    ];


subtype RepositoryMap,
    as HashRef['Yukki::Settings::Repository'];

coerce RepositoryMap,
    from HashRef,
    via { 
        my $source = $_;
        +{
            map { $_ => Yukki::Settings::Repository->new($source->{$_}) }
                keys %$source
        }
    };


subtype PluginConfig,
    as ArrayRef[HashRef],
    where { all { defined $_->{module} } @$_ };


class_type 'Yukki::Web::Plugin';
subtype PluginList,
    as ArrayRef['Yukki::Web::Plugin'],
    message { 
        return 'It is not an array of objects.' unless ref $_ eq 'ARRAY';
        my $bad = first { not blessed $_ or not $_->isa('Yukki::Web::Plugin') }
                        @$_;
        $bad = blessed $bad if blessed $bad;
        return "It contains $bad, which is not a Yukki::Web::Plugin.";
    };


class_type 'Email::Address';
coerce 'Email::Address',
    from Str,
    via { (Email::Address->parse($_))[0] };


class_type 'Yukki::Settings';
coerce 'Yukki::Settings',
    from HashRef,
    via { Yukki::Settings->new($_) };


class_type 'Yukki::Web::Settings';
coerce 'Yukki::Web::Settings',
    from HashRef,
    via { Yukki::Web::Settings->new($_) };


class_type 'Yukki::Settings::Anonymous';
coerce 'Yukki::Settings::Anonymous',
    from HashRef,
    via { Yukki::Settings::Anonymous->new($_) };

1;

__END__

=pod

=head1 NAME

Yukki::Types - standard types for use in Yukki

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  use Yukki::Types qw( LoginName AccessLevel );

  has login_name => ( isa => LoginName );
  has access_level => ( isa => AccessLevel );

=head1 DESCRIPTION

A standard type library for Yukki.

=head1 TYPES

=head2 LoginName

This is a valid login name. Login names may only contain letters and numbers, as of this writing.

=head2 AccessLevel

This is a valid access level. This includes any of the following values:

  read
  write
  none

=head2 NavigationLinks

This is an array of hashes formatted like:

  {
      label => 'Label',
      href  => '/link/to/somewhere',
      sort  => 40,
  }

=head2 NavigationMenuMap

This is a hash of L</NavigationLinks>.

=head2 BaseURL

This is either an absolute URL or the words C<SCRIPT_NAME> or C<REWRITE>.

=head2 BreadcrumbLinks

This is an array of hashes formatted like:

  {
      label => 'Label',
      href  => '/link/to/somewhere',
  }

=head2 RepositoryMap

This is a hash of L<Yukki::Settings::Repository> objects.

=head2 PluginConfig

A plugin configuration is an array of hashes. Each hash must have at least one key named "module" defined.

=head2 PluginList

A plugin list is a loaded set of plugin objects.

=head1 COERCIONS

In addition to the types above, these coercions are provided for other types.

=head2 Email::Address

Coerces a C<Str> into an L<Email::Address>.

=head2 Yukki::Settings

Coerces a C<HashRef> into this object by passing the value to the constructor.

=head2 Yukki::Web::Settings

Coerces a C<HashRef> into a L<Yukki::Web::Settings>.

=head2 Yukki::Settings::Anonymous

Coerces a C<HashRef> into this object by passing the value to the constructor.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
