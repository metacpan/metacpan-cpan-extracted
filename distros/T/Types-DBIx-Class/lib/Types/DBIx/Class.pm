package Types::DBIx::Class;
BEGIN {
  $Types::DBIx::Class::VERSION = '1.000006';
}

use strict;
use warnings;
use Carp;

use Type::Library -base;
use Type::Utils -all;
use Type::Params;
use Types::Standard qw(Maybe Str RegexpRef ArrayRef Ref InstanceOf);
use Sub::Quote;

# Create anonymous base types, checks
my %base =
  map { ($_ => InstanceOf["DBIx::Class::$_"]) }
  qw[ResultSet ResultSource Row Schema];

# Grep/first shorthand
sub _eq_array {
  my($value, $other) = @_;
  for (@$other) { return 1 if $value eq $_ }
  return 0;
}


my $check_param = Type::Params::compile(ArrayRef|Str|InstanceOf['Type::Tiny']);
my $check_param_reg = Type::Params::compile(RegexpRef|Str);

my $get_rs_s_name = sub {$_[0].'->result_source->source_name'};

my %param_types=
  (ResultSource => [$base{ResultSource},sub {$_[0].'->source_name'}],
   ResultSet => [$base{ResultSet},$get_rs_s_name],
   Row => [$base{Row},$get_rs_s_name]);

while (my ($type, $specifics) = each %param_types) {
  my ($parent, $get_name) = @$specifics;
  my $pcheck = Type::Params::compile($parent);
  declare $type,
  parent => $parent,
  deep_explanation => sub
  {
    my ($maintype, $r, $varname) = @_;
    $r //= '';
    my $source_name = $maintype->type_parameter;
    [sprintf('variable %s type %s is not a '.$type.'%s', $varname,
             ( $maintype->check($r) ? $type.'[' . eval($get_name->('$r')) . ']' : "'".ref($r||'')."'" ),
             ( defined $source_name ? "[$source_name]" : '' ))
    ]
  },
  constraint_generator => sub
  {
    return $parent unless @_;
    my ($source) = eval {$check_param->(@_)};
    if ($@) {
      local $Carp::CarpInternal{'Type::Tiny'}=1;
      croak "$@ in $type parameter check called from";
    }
    my $check = $source =~ /^\w+$/ ?
      $get_name->('$_')." eq '$source'" :
   $source =~ /^[\w|]+$/ ?
      $get_name->('$_')."=~ /^(?:$source)\$/" :
      "Types::DBIx::Class::_eq_array(".$get_name->('$_').", \$source)";

    return Sub::Quote::quote_sub
      "\$pcheck->(\$_) && $check",
      { '$pcheck' => \$pcheck, '$source' => \$source } };
}


# This one was different enough to pull out of the loop
my $pcheck = Type::Params::compile($base{Schema});
declare 'Schema',
  parent => $base{Schema},
  deep_explanation => sub
  {
    my ($maintype, $s, $varname) = @_;
    $s //= '';
    my $pattern = $maintype->type_parameter;
    [sprintf('variable %s type %s is not a Schema%s', $varname,
             qq('$s'), $pattern ? qq([$pattern]) : '')
    ]
  },
  constraint_generator => sub
  {
    return $base{Schema} unless @_;
    my ($pattern) = eval {$check_param_reg->(@_)};
    if ($@) {
      local $Carp::CarpInternal{'Type::Tiny'}=1;
      croak "$@ in Schema parameter check called from";
    }
    return Sub::Quote::quote_sub
      "\$pcheck->(\$_) &&(!\$pattern || ref(\$_) =~ \$pattern)",
      { '$pattern' => \$pattern, '$pcheck' => \$pcheck }
  };

1;
__END__

=pod

=head1 NAME

Types::DBIx::Class - A Type::Library for DBIx::Class objects

=head1 VERSION

version 1.00000

=head1 SYNOPSIS

    # Standalone, no object library required
    use Types::DBIx::Class -all;

    if (! is_Schema( $some_obj ) ) { die '$some_obj is not a DBIx Schema ' }

    my $validator = (Row['my_table'])->compiled_check;
    my $is_valid = $validator->( $should_be_a_row_from_my_table );

    ResultSet['some_class']->assert_valid( $results ); # Dies if $results fails

    # in your Moo/Mouse/Moose class
    use Types::DBIx::Class qw(ResultSet Row);

    # non-parameterized usage
    has any_resultset => (
        is  => 'ro',
        isa => ResultSet
    );

    # this attribute must be a DBIx::Class::ResultSet object from your "Album" ResultSet class
    has albums_rs => (
        is  => 'ro',
        isa => ResultSet['Album']
    );

    # this attribute must be a DBIx::Class::Row object from your "Album" Result class
    has album => (
        is  => 'ro',
        isa => Row['Album']
    );

    # subtyping works as expected
    use Type::Library -declare => [qw(RockAlbum DecadeAlbum)];

    subtype RockAlbum,
        as Row['Album'],
        where { $_->genre eq 'Rock' };

    # Further parameterization!
    package Local::MyAlbumTypes;
    use Type::Library -base;
    use Type::Utils -all;

    declare 'DecadeAlbum',
      parent => Row['Album'],
      constraint_generator => sub {
        my ($decade) = @_;
        die "Decade must be an Int between 0 and 100"
          unless $decade =~ /^\d+$/ && $decade < 100;
        $decade = substr($decade,0,1);
        return sub { substr($_->year,-2,1) eq $decade }
      };

    # In another module
    use Moo;
    use Type::Tiny;
    use Local::MyAlbumTypes;

    my $EightiesRock = Type::Tiny->new(
      name       => 'EightiesRock',
      parent     => DecadeAlbum[80],
      constraint => sub { $_->genre eq 'Rock' } );

    has eighties_rock_album => (
        is  => 'ro',
        isa => $EightiesRock,
    );

=head1 DESCRIPTION

This simply provides some L<Type::Tiny> style types for often
shared L<DBIx::Class> objects. It is forked from, and still borrows
heavily from L<MooseX::Types::DBIx::Class>.

=head1 TYPES

Each of the types below first ensures the appropriate C<isa>
relationship. If the (optional) parameter is specified, it constrains
the value further in some way.  These types do not define any coercions.

Additionaly, each provieds stand-alone validation subroutines via
L<Type::Tiny>, which do not require using an object framework.

=over 4

=item ResultSet[$source_name]

This type constraint requires the object to be an instance of
L<DBIx::Class::ResultSet> and to have the specified C<$source_name> (if specified).

=item ResultSource[$source_name]

This type constraint requires the object to be an instance of
L<DBIx::Class::ResultSource> and to have the specified C<$source_name> (if specified).

=item Row[$source_name]

This type constraint requires the object to be an instance of
L<DBIx::Class::Row> and to have the specified C<$source_name> (if specified).

=item Schema[$class_name | qr/pattern_to_match/]

This type constraint is present mostly for completeness and requires the
object to be an instance of L<DBIx::Class::Schema> and to have a class
name that matches C<$class_name> or the regular expression if specified.

=back

=head1 SEE ALSO

L<Type::Tiny|Type::Tiny>, L<Type::Library|Type::Library>

=head1 AUTHOR

  Yary Hluchan <yary@cpan.org>

Authors of the original L<MooseX::Types::DBIx::Class> module, which this
module copies from copiously:

  Oliver Charles <oliver@ocharles.org.uk>
  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yary Hluchan

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
