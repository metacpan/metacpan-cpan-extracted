package YATT::Lite::Partial;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

sub Meta () {'YATT::Lite::Partial::Meta'}

sub import {
  my $pack = shift;
  my $callpack = caller;
  $pack->Meta->define_partial_class($callpack, @_);
}

package
  YATT::Lite::Partial::Meta; sub Meta () {__PACKAGE__}
use parent qw/YATT::Lite::MFields/;
use YATT::Lite::MFields qw/cf_requires
			   has_entns/;
use YATT::Lite::Util qw/globref lexpand try_invoke fields_hash/;
use Carp;

sub Base () {'YATT::Lite::Object'};

sub define_partial_class {
  my ($pack, $callpack, @args) = @_;

  mro::set_mro($callpack => 'c3');
  $pack->add_isa_to($callpack, $pack->Base);

  my Meta $meta = $pack->get_meta($callpack);
  my $fields = fields_hash(ref $meta);
  my (@task, %define);
  while (@args) {
    my $key = shift @args;
    if ($key =~ /^-(.*)/) {
      my $sub = $meta->can("declare_$1")
	or croak "Unknown Partial decl: $1";
      push @task, [$sub, $meta];
    } else {
      my $value = shift @args;
      if (my $sub = $meta->can("declare_$key")) {
	$define{$key} = $value;
      } elsif ($fields->{"cf_$key"}) {
	$meta->{"cf_$key"} = $value;
      } else {
	croak "Unknown Partial opt: $key";
      }
    }
  }

  # These should be called in *this* order.
  foreach my $key (qw/parent parents fields/) {
    my $value = delete $define{$key}
      or next;
    $meta->can("declare_$key")->($meta, $value);
  }
  # assert(keys(%define) == 0);

  foreach my $task (@task) {
    my ($sub, @rest) = @$task;
    $sub->(@rest);
  }

  # my Meta $meta = $pack->define_fields($callpack, @_);
  *{globref($callpack, 'import')} = sub {
    shift;
    my $fullclass = caller;
    $meta->export_partial_class_to($fullclass, @_);
  };
}

sub declare_fields {
  (my Meta $meta, my $value) = @_;
  $meta->define_fields($meta->{cf_package}, lexpand($value));
}

*declare_parent = *declare_parents; *declare_parent = *declare_parents;
sub declare_parents {
  (my Meta $meta, my $value) = @_;
  $meta->add_isa_to($meta->{cf_package}, lexpand($value))
      ->define_fields($meta->{cf_package});
}

sub declare_Entity {
  (my Meta $meta) = @_;
  require YATT::Lite;
  $meta->{has_entns} = YATT::Lite->define_Entity
    ({}, $meta->{cf_package}, try_invoke($meta->{cf_package}, 'EntNS'));
}

sub declare_CON {
  (my Meta $meta) = @_;
  require YATT::Lite::Entities;
  *{globref($meta->{cf_package}, 'CON')} = YATT::Lite::Entities->symbol_CON;
}

sub declare_SYS {
  (my Meta $meta) = @_;
  require YATT::Lite::Entities;
  *{globref($meta->{cf_package}, 'SYS')} = YATT::Lite::Entities->symbol_SYS;
}

sub export_partial_class_to {
  (my Meta $partial, my $fullclass) = @_;

  # print "# partial $partial->{cf_package} is imported to $fullclass\n";

  if (my @requires = lexpand($partial->{cf_requires})) {
    my @missing = grep {not $fullclass->can($_)} @requires;
    croak "package '$fullclass' used '$partial->{cf_package}'"
      . " but not implemented required methods: "
      . join(", ", map {"$_()"} sort @missing) if @missing;
  }

  YATT::Lite::MFields->add_isa_to($fullclass, $partial->{cf_package})
      ->define_fields($fullclass);

  if (my $entns = $partial->{has_entns}) {
    #print "partial $partial->{cf_package} has EntNS $entns, "
    #  , "injected to $fullclass\n";
    YATT::Lite::MFields->add_isa_to(YATT::Lite->ensure_entns($fullclass)
				    , $partial->{has_entns});
  }

  my Meta $full = Meta->get_meta($fullclass);

  $full->import_fields_from($partial);
}

1;
