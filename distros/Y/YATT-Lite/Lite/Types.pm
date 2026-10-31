package YATT::Lite::Types;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use parent qw(YATT::Lite::Object);
use Carp;
require YATT::Lite::Inc;

sub Desc () {'YATT::Lite::Types::TypeDesc'}
{
  package YATT::Lite::Types::TypeDesc; sub Desc () {__PACKAGE__}
  use parent qw(YATT::Lite::Object);
  BEGIN {
    our %FIELDS = map {$_ => 1}
      qw/name ns fields overloads alias base eval
	 _fullname
	 no_require
	 constants export_default/
  }
  sub pkg {
    my Desc $self = shift;
    join '::', $self->{ns}, $self->{name};
  }
}

use YATT::Lite::Util qw(globref look_for_globref lexpand ckeval pkg2pm
			define_const
		     );

sub import {
  my $pack = shift;
  my $callpack = caller;
  $pack->buildns($callpack, @_)
}

sub create {
  my $pack = shift;
  my $callpack = shift;
  my Desc $root = $pack->Desc->new(ns => $callpack);
  while (@_ >= 2 and not ref $_[0]) {
    $root->configure(splice @_, 0, 2);
  }
  wantarray ? ($root, $pack->parse_desc($root, @_)) : $root;
}

sub buildns {
  (my Desc $root, my @desc) = shift->create(@_);
  my $debug = $ENV{DEBUG_YATT_TYPES};
  my (@script, @task);
  my $export_ok = do {
    my $sym = globref($$root{ns}, 'EXPORT_OK');
    *{$sym}{ARRAY} // (*$sym = []);
  };
  if (my $sub = $$root{ns}->can('export_ok')) {
    push @$export_ok, $sub->($$root{ns});
  }
  {
    my $sym = globref($$root{ns}, 'export_ok');
    *$sym = sub { @$export_ok } unless *{$sym}{CODE};
  }
  foreach my Desc $obj (@desc) {
    push @$export_ok, $obj->{name};
    $obj->{_fullname} = join '::', $$root{ns}, $obj->{name};
    $INC{pkg2pm($obj->{_fullname})} = 1; # To make require happy.
    push @script, qq|package $obj->{_fullname};|;
    push @script, q|use YATT::Lite::Inc;|;
    my $base = $obj->{base} || $root->{base}
      || safe_invoke($$root{ns}, $obj->{name})
	|| 'YATT::Lite::Object';
    #
    # I finally found base::has_fields() is broken
    # so there is no merit for fields mania to use base.pm over parent.pm.
    #
    push @script, sprintf q|use parent qw(%s);|, $base;
    push @script, sprintf q|use YATT::Lite::MFields %s;|, do {
      if ($obj->{fields}) {
	sprintf(q|qw(%s)|, join " ", @{$obj->{fields}});
      } else {
	# To avoid generating 'use YATT::Lite::MFields qw()';
	'';
      }
    };
    push @script, sprintf q|use overload qw(%s);|
      , join " ", @{$obj->{overloads}} if $obj->{overloads};
    push @script, $obj->{eval} if $obj->{eval};
    push @script, "\n";

    push @task, [\&add_alias, $$root{ns}, $obj->{name}, $obj->{name}];
    foreach my $alias (lexpand($obj->{alias})) {
      push @task, [\&add_alias, $$root{ns}, $alias, $obj->{name}];
      push @$export_ok, $alias;
    }
    foreach my $spec (lexpand($obj->{constants})) {
      push @task, [\&add_const, $obj->{_fullname}, @$spec];
    }
  }
  my $script = join(" ", @script, "; 1");
  print $script, "\n" if $debug;
  ckeval($script);
  foreach my $task (@task) {
    my ($sub, @args) = @$task;
    $sub->(@args);
  }
  if ($root->{export_default}) {
    my $export = do {
      my $sym = globref($$root{ns}, 'EXPORT');
      *{$sym}{ARRAY} // (*$sym = []);
    };
    @$export = @$export_ok;
  }
  foreach my Desc $obj (@desc) {
    my $sym = look_for_globref($obj->{_fullname}, 'FIELDS');
    if ($sym and my $fields = *{$sym}{HASH}) {
      print "Fields in type $obj->{_fullname}: "
	, join(" ", sort keys %$fields), "\n" if $debug;
    } elsif ($obj->{fields}) {
      croak "Failed to define type fields for '$obj->{_fullname}': "
	. join(" ", @{$obj->{fields}});
    }
  }
}

sub add_alias {
  my ($pack, $alias, $name) = @_;
  add_const($pack, $alias, join('::', $pack, $name));
}

sub add_const {
  my ($pack, $alias, $const) = @_;
  define_const(globref($pack, $alias), $const);
}

sub safe_invoke {
  my ($obj, $method) = splice @_, 0, 2;
  my $sub = $obj->can($method)
    or return;
  $sub->($obj, @_);
}

sub parse_desc {
  (my $pack, my Desc $parent) = splice @_, 0, 2;
  my (@desc);
  while (@_) {
    unless (defined (my $item = shift)) {
      croak "Undefined type desc!";
    } elsif (ref $item) {
      my @base = (base => $parent->pkg) if $parent->{name};
      push @desc, my Desc $sub = $pack->Desc->new
	(name => shift @$item, ns => $parent->{ns}, @base);
      push @desc, $pack->parse_desc($sub, @$item);
    } elsif (@_) {
      $item =~ s/^-//;
      $parent->configure($item, shift);
    } else {
      croak "Missing parameter for type desc $item";
    }
  }
  @desc;
}

1;

__END__

=head1 NAME

YATT::Lite::Types - define inner types at compile time.

=head1 SYNOPSIS

In module I<MyClass.pm>:

  package MyClass;
  use YATT::Lite::Types
    (base => 'MyBaseClass'
     , [Album => fields => [qw/albumid artist title/]]
     , [CD    => fields => [qw/cdid    artist title/]]
     , [Track => fields => [qw/trackid cd     title/]]
   );
  
  # Now you have MyClass::Album, MyClass::CD and MyClass::Track.
  # also, alias (constant sub) of them are defined.
  
  my Album $album = Album->new;
  
  # my Albumm $album;
  #  => No such class Albumm
  
  my CD $cd = CD->new;
  
  # $cd->{artistt};
  #  => No such class field "artistt" in variable $cd of type MyClass::CD
  
  my Track $track = {};
  
  $track->{cd} = $cd;
  
  # $track->{cdd} = $cd;
  # => No such class field "cdd" in variable $track of type MyClass::Track
  
  1;

=head1 DESCRIPTION

YATT::Lite::Types is a class builder, especially suitable to defining
many inner classes at once.

Basic usage is like this:

  use YATT::Lite::Types
    (OPTION => VALUE, ...
    , [SPEC]
    , [SPEC]
    ,  :
    );

where SPEC array for single type is written (TYPENAME + OPT VAL pair list) as:

   [TYPENAME => OPTION => VALUE, ...]

Also you can write type hierachy in nested style as:

   [BASETYPE => OPT => VAL, ...
     , [SUBTYPE1 => OPT => VAL, ...]
     , [SUBTYPE2 => OPT => VAL, ...
       , [SUBSUBTYPE1 => OPT => VAL, ...]
       , [SUBSUBTYPE2 => OPT => VAL, ...]
       ]
   ]

=head2 options

=over 4

=item * base

Base class for newly created type.
This name is preloaded before type definition
(unless you specify C<< no_require => 1 >>).

=item * no_require

=item * alias

To define alias(synonym) too, use this.

=head1 SEE ALSO

L<fields>
