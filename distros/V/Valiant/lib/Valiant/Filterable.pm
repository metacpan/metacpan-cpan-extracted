package Valiant::Filterable;

use Moo::Role;
use Module::Runtime 'use_module';
use String::CamelCase 'camelize';
use Scalar::Util 'blessed';
use Valiant::Util 'throw_exception', 'debug';
use namespace::autoclean -also => ['throw_exception', 'debug'];
use Valiant::Filters ();

has _instance_filters => (is=>'rw', init_arg=>undef);

sub _filters {
  my ($class_or_self, $arg) = @_;
  my $class = ref($class_or_self) ? ref($class_or_self) : $class_or_self;

  my @existing = ();
  if(defined($arg)) {
    if(ref($class_or_self)) { # its $self
      my @existing = @{ $class_or_self->_instance_filters||[] };
      $class_or_self->_instance_filters([$arg, @existing]);
    } else {
      Valiant::Filters::_add_metadata($class_or_self, 'filters', $arg);
    }
  }
  @existing = @{ $class_or_self->_instance_filters||[] } if ref $class_or_self;
  my @filters = $class_or_self->filters_metadata if $class_or_self->can('filters_metadata');
  return @filters, @existing;
}

sub default_filter_namepart { 'Filter' }
sub default_filter_collection_class { 'Valiant::Filter::Collection' }

sub _filters_coderef {
  my ($self, $coderef) = @_;
  $self->_filters($coderef);
  return $self;
}

sub _prepare_filter_packages {
  my ($class, $key) = @_;
  my $camel = camelize($key);
  my @packages = $class->_normalize_filter_package($camel);

  return @packages if $camel =~/^\+/;

  push @packages, map {
    "${_}::${camel}";
  } $class->default_filter_namespaces;

  return @packages;
}

sub default_filter_namespaces {
  my ($self) = @_;
  return ('Valiant::FilterX', 'Valiant::Filter');
}

sub _filter_package {
  my ($self, $key) = @_;
  my @filter_packages = $self->_prepare_filter_packages($key);
  my ($filter_package, @rest) = grep {
    my $package_to_test = $_;
    eval { use_module $package_to_test } || do {
      # This regexp matches too much... We need to add the package
      # path here just the path delim will vary from platform to platform
      my $notional_filename = Module::Runtime::module_notional_filename($package_to_test);
      if($@=~m/^Can't locate $notional_filename/) {
        debug 1, "Can't find '$package_to_test' in \@INC";
        0;
      } else {
        throw_exception UnexpectedUseModuleError => (package => $package_to_test, err => $@);
      }
    }
  }  @filter_packages;
  throw_exception('NameNotFilter', name => $key, packages => \@filter_packages)
    unless $filter_package;
  debug 1, "Found $filter_package in \@INC";
  return $filter_package;
}

sub _create_filter {
  my ($self, $filter_package, $args) = @_;
  debug 1, "Trying to create filter from $filter_package";
  my $filter = $filter_package->new($args);
  return $filter;
}

sub filters {
  my ($self, @proto) = @_;

  # handle a list of attributes with filters
  my $attributes = shift @proto;
  $attributes = [$attributes] unless ref $attributes;
  my @options = @proto;

  my (@filter_info) = ();
  while(@options) {
    my $args;
    my $key = shift(@options);
    if((ref($key)||'') eq 'CODE') { # This bit allows for callbacks instead of a filter => \%params setup
      $args = { cb => $key };
      $key = 'with';
      if((ref($options[0])||'') eq 'HASH') {
        my $base_args = shift(@options);
        $args = +{ %$args, %$base_args };
      }
    } else { # Otherwise its a normal validator with params
      $args = shift(@options);
    }
    push @filter_info, [$key, $args];
  }
  
  my @filters = ();
  foreach my $info(@filter_info) {
    my ($package_part, $args) = @$info;
    my $filter_package = $self->_filter_package($package_part);

    unless((ref($args)||'') eq 'HASH') {
      $args = $filter_package->normalize_shortcut($args);
      throw_exception InvalidFilterArgs => ( args => $args) unless ref($args) eq 'HASH';
    }
    
    $args->{attributes} = $attributes;
    $args->{model} = $self;

    my $new_filter = $self->_create_filter($filter_package, $args);
    push @filters, $new_filter;
  }
  my $coderef = sub {
    my ($class, $attrs) = @_;
    foreach my $filter (@filters) {
      $attrs = $filter->filter($class, $attrs);
    }
    return $attrs;
  };
  $self->_filters_coderef($coderef); 
}

sub _normalize_filter_package {
  my ($self, $with) = @_;
  my ($prefix, $package) = ($with =~m/^(\+?)(.+)$/);
  return $package if $prefix eq '+';

  my $class =  ref($self) || $self;
  my @parts = ((split '::', $class), $package);
  my @project_inc = ();
  while(@parts) {
    push @project_inc, join '::', (@parts, $class->default_filter_namepart, $package);
    pop @parts;
  }
  push @project_inc, join '::', $class->default_filter_namepart, $package; # Not sure we should allow (add flag?)
  return @project_inc;
}

sub filters_with {
  my ($self, $proto, %options) = @_;
  my @with = ref($proto) eq 'ARRAY' ? 
    @{$proto} : ($proto);

  my @filters = ();
  FILTER_WITHS: foreach my $with (@with) {
    if( (ref($with)||'') eq 'CODE') {
      push @filters, [$with, \%options];
      next FILTER_WITHS;
    }
    debug 1, "Trying to find a filter for '$with'";

    my $filter_package = $self->_filter_package($with);

    my $args;
    unless((ref($args)||'') eq 'HASH') {
      $args = $filter_package->can('normalize_shortcut') ? $filter_package->normalize_shortcut(\%options) : \%options;
      throw_exception InvalidFilterArgs => ( args => $args) unless ref($args) eq 'HASH';
    }
    
    $args->{model} = $self;

    my $new_filter = $self->_create_filter($filter_package, $args);
    push @filters, $new_filter;


  }
  my $collection = use_module($self->default_filter_collection_class)
    ->new(filters=>\@filters);
  $self->_filters_coderef(sub { $collection->filter(@_) }); 
}

sub _process_filters {
  my ($class, $attrs) = @_;
  foreach my $filter ($class->_filters) {
    $attrs = $filter->($class, $attrs);
  }
  return $attrs;
}

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $attrs = $class->$orig(@args);
  return $class->_process_filters($attrs) if $attrs;
 };

1;

=head1 NAME

Valiant::Filters - Role that adds class and instance methods supporting field filters

=head1 SYNOPSIS

    package Local::Test::User;

    use Moo;

    with 'Valiant::Filterable';

    has 'name' => (is=>'ro', required=>1);
    has 'last' => (is=>'ro', required=>1);

    __PACKAGE__->filters(last => (Trim=>1));

    __PACKAGE__->filters_with(sub {
      my ($class, $attrs, $opts) = @_;
      $attrs = +{
        map {
          my $value = $attrs->{$_};
          $value =~ s/^\s+|\s+$//g;
          $_ => $value;
        } keys %$attrs
      };
      $attrs->{name} = "$opts->{a}$attrs->{name}$opts->{b}";
      return $attrs;
    }, a=>1, b=>2);

    __PACKAGE__->filters_with(Foo => (a=>1,b=>2));

    __PACKAGE__->filters(last => (
      uc_first => 1,
      with => sub {
        my ($class, $attrs, $name) = @_;
        return $attrs->{$name} . "XXX";
      },
      sub {
        my ($class, $attrs, $name) = @_;
        return $attrs->{$name} . "AAA";
      },
    ));

=head1 DESCRIPTION

This is a role that adds class level filtering to you L<Moo> or L<Moose> classes.  Generally
you may prefer to us L<Valiant::Filters> since that gives you a nice DSL for applying filters
to your classes but if you have very special or custom needs (or you need to extend the filter
API itself) you might need to use the role directly.  

=head1 CLASS METHODS

=head2 filters

Used to declare filters on an attribute.  The first argument is either a scalar or arrayref of
scalars which should be attributes on your object:

    __PACKAGE__->filters( name => (...) );
    __PACKAGE__->filters(['name', 'age'] => (...));

Following arguments should be in one of two forms: a coderef or subroutine reference that contains
filter rules or a key - value pair which is a class and its arguments:

    __PACKAGE__->filters( name => (
      trim => 1,
      with => sub { my ($class, $attrs, $name) = @_; },
      sub { my ($class, $attrs, $name) = @_; }m
    ));

When you use a Filter class (such as C<trim => { maximum => 25 }>) we resolve the class
name C<trim> in the following way.  We first camel case the name and then look for a 'Filter' package
in the current class namespace.  If we don't find a match we check each namespace up the hierarchy and
then check the two global namespaces C<Valiant::FilterX> and C<Validate::Filters>.  For example if
you declare filters as in the example class C<Local::Model::User> we would look for the following:

    Local::Model::User::Filter::Trim
    Local::Model:::Filter::Trim
    Local::Filter::Trim
    Validator::Trim
    Valiant::FilterX::Trim
    Valiant::Filter:::Trim

These get checked in the order above and loaded and instantiated once at setup time.

B<NOTE:> The namespace C<Valiant::Filter> is reserved for filters that ship with L<Valiant>.  The
C<Valiant::FilterX> namespace is reserved for additional filters on CPAN that are packaged separately
from L<Valiant>.  If you wish to share a custom fiter that you wrote the proper namespace to use on
CPAN is C<Valiant::FilterX>.

You can also prepend your filter name with '+' which will cause L<Valiant> to ignore the namespace 
resolution and try to load the class directly.  For example:

    __PACKAGE__->filters(name => ('+App::MyFilter' => {}), );

Will try to load the class C<App::MyFilter> and use it as a filter directly (or throw an exception if
it fails to load).

=head2 filters_with

C<filters_with> is intended to process filters that are on the class as a whole, or which are very
complex and can't easily be assigned to a single attribute.  It accepts either a subroutine reference
with an optional hash of key value pair options (which are passed to C<$opts>) or a scalar name which
should be a stand alone filter class (basically a class that does the C<filters> method although
you should consume the L<Validate::Filter> role to enforce the contract).

    __PACKAGE__->filters_with(sub {
      my ($self, $class, $attrs)) = @_;
      ...
    });

    __PACKAGE__->filters_with(\&check_object => (arg1=>'foo', arg2=>'bar'));

    sub filters_with {
      my ($self, $class, $attrs) = @_;
      ...
    }

    __PACKAGE__->filters_with( 'Custom' => (arg1=>'foo', arg2=>'bar'));

If you pass a string that is a filter class we resolve its namespace using the same approach as
detailed above for C<filters>.  Any arguments are passed to the C<new> method of the found class.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant::Filters>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

