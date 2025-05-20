package Web::Components::Util;

use strictures;
use parent 'Exporter::Tiny';

use Web::ComposableRequest::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Unexpected::Functions             qw( Unspecified );
use List::Util                        qw( pairs );
use Scalar::Util                      qw( blessed );
use Sys::Hostname                     qw( hostname );
use Web::ComposableRequest::Util      qw( is_hashref );
use Module::Pluggable::Object;
use Moo::Role ();

our @EXPORT_OK = qw( build_routes clear_redirect deref exception first_char
                     formpost fqdn is_arrayref load_components ns_environment
                     throw );

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

Defines the following functions;

=over 3

=item C<build_routes>

Takes a list of pairs of L<Web::Simple> routing expressions and
L<Web::Components> action paths. Returns a list of pairs of routing expressions
and subroutines used by L<Web::Simple>s C<dispatch_request> function

=cut

sub build_routes (@) {
   my @pairs  = @_;
   my @routes = ();

   for my $pair (pairs @pairs) {
      push @routes, $pair->key, sub {[$pair->value, @_]};
   }

   return @routes;
}

=item C<clear_redirect>

Deletes the stashed entry that would otherwise cause a redirect response

=cut

sub clear_redirect ($) {
   return delete shift->stash->{redirect};
}

=item C<deref>

   $value = deref $object_or_hash_ref, $key, $optional_default;

Returns the value associated with the supplied key. Accepts either an object
or hash reference as the first argument. Returns the default if the result
is otherwise undefined

=cut

sub deref ($$;$) {
   my ($x, $k, $default) = @_;

   my $r = $default;

   if    (blessed $x and $x->can($k)) { $r = $x->$k() // $default }
   elsif (is_hashref $x)              { $r = $x->{$k} // $default }

   return $r;
}

=item C<exception>

   $e = exception $error;

Expose the C<catch> method in the exception class C<EXCEPTION_CLASS> defined in
constants. Returns a new exception object

=cut

sub exception (;@) {
   return EXCEPTION_CLASS->caught( @_ );
}

=item C<first_char>

   $single_char = first_char $some_string;

Returns the first character of C<$string>

=cut

sub first_char ($) {
   return substr $_[ 0 ], 0, 1;
}

=item C<formpost>

Returns a hash references which is stashed to indicate that a link is really
a button wrapped in a form

=cut

sub formpost () {
   return { method => 'post' };
}

=item C<fqdn>

   $domain_name = fqdn $hostname;

Call C<gethostbyname> on the supplied hostname which defaults to this host

=cut

sub fqdn (;$) {
   my $x = shift // hostname; return (gethostbyname($x))[0];
}

=item C<is_arrayref>

   $bool = is_arrayref $scalar_variable;

Tests to see if the scalar variable is an array ref

=cut

sub is_arrayref (;$) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'ARRAY' ? 1 : 0;
}

=item C<load_components>

   $hash_ref_of_objects = load_components $search_path, @options_list;

Load and instantiates MVC components. The search path is appended to the
applications classname to define the package namespace that is searched for
components

The options list is a list of keys and values. Either C<application> or,
C<config> and C<log> must be specified. If C<application> is specified it
must define C<config> and C<log> attributes

The configuration object or hash reference must define the C<appclass> and
C<web_components> attributes

The C<web_components> attribute (one of the collection references held by
L<Web::Components::Loader>) is passed to the component constructor method and
is used by a component to discover it's dependencies

An adaptor pattern is possible using the C<web_components_adaptors> attribute

=cut

sub load_components ($;@) {
   my $base = shift;
   my $opts = (is_hashref $_[0]) ? $_[0] : {@_};

   throw(Unspecified, ['component base']) unless $base;

   my $app = $opts->{application};
   # If the app object is defined it must have a config attribute
   # uncoverable condition false
   my $config = $opts->{config} // $app->config;
   my $appclass = deref $config, 'appclass';
   # The config object/hash ref is required. It must have an appclass attribute
   # uncoverable branch true
   throw(Unspecified, ['config appclass']) unless $appclass;

   my $search_path;

   if (first_char $base eq '+') { $search_path = $base = substr $base, 1 }
   else { $search_path = "${appclass}::${base}" }

   my $depth = () = split m{ :: }mx, $search_path, -1;

   $depth += 1;

   my $finder = Module::Pluggable::Object->new(
      max_depth   => $depth,
      min_depth   => $depth,
      search_path => [$search_path],
      require     => TRUE,
   );
   my $compos = $opts->{components} //= {}; # Dependency injection
   my $comp_cfg = (deref $config, 'web_components') // {};

   for my $class ($finder->plugins) {
      _setup_component($compos, $comp_cfg, $opts, $appclass, $class);
   }

   my $cfgcomps = deref $config, 'web_components_adaptors';

   if ($cfgcomps) { $cfgcomps = $cfgcomps->{$base} }
   else { return $compos }

   for my $moniker (keys %{$cfgcomps}) {
      my $class = "${base}::".(ucfirst $moniker);
      my @roles = @{ _qualify($appclass, $cfgcomps->{$moniker}) };
      my $cwr   = Moo::Role->create_class_with_roles($search_path, @roles);

      _setup_component($compos, $comp_cfg, $opts, $appclass, $class, $cwr);
   }

   return $compos;
}

sub _app_prefix ($) {
   (my $v = lc ($_[0] // q())) =~ s{ :: }{_}gmx;

   return $v;
}

sub _env_prefix ($) {
   return uc _app_prefix $_[0];
}

=item C<ns_environment>

   $value = ns_environment $class, $key, [$value];

An accessor/mutator for the environment variables prefixed by the supplied
class name. Providing a value is optional, always returns the current value

=cut

sub ns_environment ($$;$) {
   my ($class, $k, $v) = @_;

   $k = (_env_prefix $class) . '_' . (uc $k);

   return defined $v ? $ENV{$k} = $v : $ENV{$k};
}

=item C<throw>

   throw 'message', [ 'arg1', 'arg2' ];

Expose L<Web::ComposableRequest::Util/throw>.
L<Web::ComposableRequest::Constants> has a class attribute I<Exception_Class>
which can be set change the class of the thrown exception

=cut

sub throw (;@) {
   EXCEPTION_CLASS->throw( @_ );
}

# Private functions
sub _qualify {
   my ($appclass, $roles) = @_; $roles //= [];

   for (my $i = 0, my $len = @{ $roles }; $i < $len; $i++) {
      if (first_char( $roles->[ $i ] ) eq '+') {
         $roles->[ $i ] = substr $roles->[ $i ], 1;
      }
      else { $roles->[ $i ] = "${appclass}::".$roles->[ $i ] }
   }

   return $roles;
}

sub _setup_component {
   my ($compos, $comp_cfg, $opts, $appclass, $class, $composite) = @_;

   $composite //= $class;

  (my $klass = $class) =~ s{ \A $appclass :: }{}mx;
   my $attr  = { %{ $comp_cfg->{ $klass } // {} }, %{ $opts } };
   my $comp  = $composite->new( $attr );

   $compos->{ $comp->moniker } = $comp;
   return;
}

1;

__END__

=back

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

Copyright (c) 2024 Peter Flanigan. All rights reserved

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
