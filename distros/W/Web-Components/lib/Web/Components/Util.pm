package Web::Components::Util;

use strictures;
use parent 'Exporter::Tiny';

use Module::Pluggable::Object;
use Scalar::Util                      qw( blessed );
use Web::ComposableRequest::Constants qw( EXCEPTION_CLASS TRUE );
use Web::ComposableRequest::Util      qw( is_hashref );
use Unexpected::Functions             qw( Unspecified );
use Moo::Role ();

our @EXPORT_OK  = qw( deref exception first_char
                      is_arrayref load_components throw );

# Private functions
my $_qualify = sub {
   my ($appclass, $roles) = @_; $roles //= [];

   for (my $i = 0, my $len = @{ $roles }; $i < $len; $i++) {
      if (first_char( $roles->[ $i ] ) eq '+') {
         $roles->[ $i ] = substr $roles->[ $i ], 1;
      }
      else { $roles->[ $i ] = "${appclass}::".$roles->[ $i ] }
   }

   return $roles;
};

my $_setup_component = sub {
   my ($compos, $comp_cfg, $opts, $appclass, $class, $composite) = @_;

   $composite //= $class;

  (my $klass = $class) =~ s{ \A $appclass :: }{}mx;
   my $attr  = { %{ $comp_cfg->{ $klass } // {} }, %{ $opts } };
   my $comp  = $composite->new( $attr );

   $compos->{ $comp->moniker } = $comp;
   return;
};

# Public functions
sub deref ($$;$) {
   my ($x, $k, $default) = @_; my $r = $default;

   if    (blessed $x and $x->can( $k )) { $r = $x->$k() // $default }
   elsif (is_hashref $x)                { $r = $x->{ $k } // $default }

   return $r;
}

sub exception (;@) {
   return EXCEPTION_CLASS->caught( @_ );
}

sub first_char ($) {
   return substr $_[ 0 ], 0, 1;
}

sub is_arrayref (;$) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'ARRAY' ? 1 : 0;
}

sub load_components ($;@) {
   my $base = shift; my $opts = (is_hashref $_[ 0 ]) ? $_[ 0 ] : { @_ };

   $base or throw( Unspecified, [ 'component base' ] );

   my $app      = $opts->{application};
   # If the app object is defined it must have a config attribute
   # uncoverable condition false
   my $config   = $opts->{config} // $app->config;
   my $appclass = deref $config, 'appclass';
   # The config object/hash ref is required. It must have an appclass attribute
   # uncoverable branch true
   $appclass or throw( Unspecified, [ 'config appclass' ] ); my $search_path;

   if (first_char $base eq '+') { $search_path = $base = substr $base, 1 }
   else { $search_path = "${appclass}::${base}" }

   my $depth    = () = split m{ :: }mx, $search_path, -1; $depth += 1;
   my $finder   = Module::Pluggable::Object->new
      ( max_depth   => $depth,           min_depth => $depth,
        search_path => [ $search_path ], require   => TRUE, );
   my $compos   = $opts->{components} //= {}; # Dependency injection
   my $comp_cfg = (deref $config, 'components') // {};

   for my $class ($finder->plugins) {
      $_setup_component->( $compos, $comp_cfg, $opts, $appclass, $class );
   }

   my $cfgcomps = deref $config, 'config_comps';

   ($cfgcomps and $cfgcomps = $cfgcomps->{ $base }) or return $compos;

   for my $moniker (keys %{ $cfgcomps }) {
      my $class = "${base}::".(ucfirst $moniker);
      my @roles = @{ $_qualify->( $appclass, $cfgcomps->{ $moniker } ) };
      my $cwr   = Moo::Role->create_class_with_roles( $search_path, @roles );

      $_setup_component->( $compos, $comp_cfg, $opts, $appclass, $class, $cwr );
   }

   return $compos;
}

sub throw (;@) {
   EXCEPTION_CLASS->throw( @_ );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Web::Components::Util - Functions used in this distribution

=head1 Synopsis

   use Web::Components::Util qw( load_components );

=head1 Description

Functions used in this distribution

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 C<deref>

   $value = deref $object_or_hash_ref, $key, $optional_default;

Returns the value associated with the supplied key. Accepts either an object
or hash reference as the first argument. Returns the default if the result
is otherwise undefined

=head2 C<exception>

   $e = exception $error;

Expose the C<catch> method in the exception
class L<Class::Usul::Exception>. Returns a new error object

=head2 C<first_char>

   $single_char = first_char $some_string;

Returns the first character of C<$string>

=head2 C<is_arrayref>

   $bool = is_arrayref $scalar_variable;

Tests to see if the scalar variable is an array ref

=head2 C<load_components>

   $hash_ref_of_objects = load_components $search_path, @options_list;

Load and instantiates MVC components. The search path is appended to the
applications classname to define the package namespace that is searched for
components

The options list is a list of keys and values. Either C<application> or,
C<config> and C<log> must be specified. If C<application> is specified it
must define C<config> and C<log> attributes

The configuration object or hash reference must define the C<appclass> and
C<components> attributes

The C<components> attribute (one of the collection references held by
L<Web::Components::Loader>) is passed to the component constructor method and
is used by a component to discover it's dependencies

An adaptor pattern is possible using the C<config_comps> attribute

=head2 C<throw>

   throw 'message', [ 'arg1', 'arg2' ];

Expose L<Web::ComposableRequest::Util/throw>.
L<Web::ComposableRequest::Constants> has a class attribute I<Exception_Class>
which can be set change the class of the thrown exception

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Module::Pluggable>

=item L<Web::ComposableRequest>

=item L<Unexpected>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components.
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
