package Web::ComposableRequest::Role::L10N;

use namespace::autoclean;

use Web::ComposableRequest::Constants qw( NUL TRUE );
use Web::ComposableRequest::Util      qw( extract_lang is_member
                                          add_config_role );
use Unexpected::Functions             qw( inflate_placeholders );
use Unexpected::Types                 qw( ArrayRef CodeRef NonEmptySimpleStr
                                          Undef );
use Moo::Role;

requires qw( query_params _config _env );

add_config_role __PACKAGE__.'::Config';

# Attribute constructors
my $_build_locale = sub {
   my $self   = shift;
   my $conf   = $self->_config;
   my $locale = $self->query_params->( 'locale', { optional => TRUE } );

   $locale and is_member $locale, $conf->locales and return $locale;

   my $lang; $locale and $lang = extract_lang( $locale )
      and $lang ne $locale and is_member $lang, $conf->locales and return $lang;

   for my $locale (@{ $self->locales }) {
      is_member $locale, $conf->locales and return $locale;
   }

   for my $lang (map { extract_lang $_ } @{ $self->locales }) {
      is_member $lang, $conf->locales and return $lang;
   }

   return $conf->locale;
};

my $_build_locales = sub {
   my $self = shift; my $lang = $self->_env->{ 'HTTP_ACCEPT_LANGUAGE' } // NUL;

   return [ map    { s{ _ \z }{}mx; $_ }
            map    { join '_', $_->[ 0 ], uc( $_->[ 1 ] // NUL ) }
            map    { [ split m{ - }mx, $_ ] }
            map    { ( split m{ ; }mx, $_ )[ 0 ] }
            split m{ , }mx, lc $lang ];
};

my $_build_localiser = sub {
   return sub {
      my ($key, $args) = @_;

      defined $key or return; $key = "${key}"; chomp $key; $args //= {};

      my $text = $key;

      if (defined $args->{params} and ref $args->{params} eq 'ARRAY') {
         0 > index $text, '[_' and return $text;

         # Expand positional parameters of the form [_<n>]
         return inflate_placeholders
            [ '[?]', '[]', $args->{no_quote_bind_values} ], $text,
            @{ $args->{params} };
      }

      0 > index $text, '{' and return $text;

      # Expand named parameters of the form {param_name}
      my %args = %{ $args }; my $re = join '|', map { quotemeta $_ } keys %args;

      $text =~ s{ \{($re)\} }{ defined $args{$1} ? $args{$1} : "{${1}?}" }egmx;

      return $text;
   };
};

# Public attributes
has 'domain'        => is => 'lazy', isa => NonEmptySimpleStr | Undef,
   builder          => sub {};

has 'domain_prefix' => is => 'lazy', isa => NonEmptySimpleStr | Undef;

has 'language'      => is => 'lazy', isa => NonEmptySimpleStr,
   builder          => sub { extract_lang $_[ 0 ]->locale };

has 'locale'        => is => 'lazy', isa => NonEmptySimpleStr,
   builder          => $_build_locale;

has 'locales'       => is => 'lazy', isa => ArrayRef[NonEmptySimpleStr],
   builder          => $_build_locales;

has 'localiser'     => is => 'lazy', isa => CodeRef,
   builder          => $_build_localiser;

# Private methods
my $_domains;

my $_get_domains = sub {
   my $self    = shift;
   my $domains = [ @{ $self->_config->l10n_attributes->{domains} // [] } ];
   my $domain  = $self->domain or return $domains;
   my $prefix  = $self->domain_prefix;

   $prefix and $domain = "${prefix}-${domain}"; push @{ $domains }, $domain;

   return $domains;
};

my $_localise_args = sub {
   my $self = shift;
   my $args =             ($_[ 0 ] && ref $_[ 0 ] eq 'HASH' ) ? { %{ $_[ 0 ] } }
            : { params => ($_[ 0 ] && ref $_[ 0 ] eq 'ARRAY') ? $_[ 0 ]
                                                              : [ @_ ] };

   not exists $args->{domains}
          and $args->{domains} = $_domains //= $_get_domains->( $self );

   $args->{no_quote_bind_values} //= not $self->_config->quote_bind_values;

   return $args;
};

# Public methods
sub loc {
   my ($self, $key, @args) = @_; my $args = $_localise_args->( $self, @args );

   $args->{locale} //= $self->locale;

   return $self->localiser->( $key, $args );
}

sub loc_default {
   my ($self, $key, @args) = @_; my $args = $_localise_args->( $self, @args );

   $args->{locale} = $self->_config->locale;

   return $self->localiser->( $key, $args );
}

package Web::ComposableRequest::Role::L10N::Config;

use namespace::autoclean;

use Web::ComposableRequest::Constants qw( LANG TRUE );
use Unexpected::Types                 qw( ArrayRef Bool HashRef
                                          NonEmptySimpleStr );
use Moo::Role;

# Public attributes
has 'l10n_attributes'   => is => 'ro', isa => HashRef,
   builder              => sub { { domains => [ 'messages' ] } };

has 'locale'            => is => 'ro', isa => NonEmptySimpleStr,
   default              => LANG;

has 'locales'           => is => 'ro', isa => ArrayRef[NonEmptySimpleStr],
   builder              => sub { [ LANG ] };

has 'quote_bind_values' => is => 'ro', isa => Bool, default => TRUE;

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::ComposableRequest::Role::L10N - Provide localisation methods

=head1 Synopsis

   package Your::Request::Class;

   use Moo;

   extends 'Web::ComposableRequest::Base';
   with    'Web::ComposableRequest::Role::L10N';

=head1 Description

Provide localisation methods

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<domain>

The domain to which this request belongs. Can be used to select assets like
translation files

=item C<locale>

The language requested by the client. Defaults to the C<LANG> constant
C<en> (for English)

=back

Defines the following configuration attributes

=over 3

=item C<l10n_attributes>

A hash reference. The C<domains> attribute is an array reference containing
the default C<gettext> domains

=item C<locale>

A non empty simple string which defaults to the constant C<LANG>. The
default locale for the application

=item C<locales>

An array reference of non empty simple strings. Defaults to a list containing
the C<LANG> constant. Defines the list of locales supported by the
application

=item C<quote_bind_values>

A boolean which defaults to true. Causes the bind values in parameter
substitutions to be quoted

=back

=head1 Subroutines/Methods

=head2 C<loc>

   $localised_string = $self->loc( $key, @args );

Translates C<$key> into the required language and substitutes the bind values

=head2 C<loc_default>

Like the C<loc> method but always translates to the default language

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-ComposableRequest.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
