package Valiant::Params::Role;

use Moo::Role;
use Scalar::Util 'blessed';
use Valiant::Util 'throw_exception', 'debug';
use namespace::autoclean -also => ['throw_exception', 'debug'];

requires 'ancestors';

has _found_params => (is=>'ro', required=>1);

sub _to_class {
  my $proto = shift;
  return ref($proto) ? ref($proto) : $proto;
}

my $_params = +{};

sub __add_param {
  my ($class, $attr) = (shift, shift);
  my %options_proto = @_;

  if(my $multi = $options_proto{multi}) {
    my %default_multi_options = ( limit => 10000 );
    my %normalized_multi_options = ();
    if(ref($multi)||'' eq 'HASH') {
      %normalized_multi_options = (%default_multi_options, %$multi);
    } elsif( (ref($multi)||'') eq '' && $multi == 1) {
      %normalized_multi_options = (%default_multi_options);
    } else {
      die "Invalid multi options for param $attr"; 
    }
    $options_proto{multi} = \%normalized_multi_options;
  }

  if(my $expand = $options_proto{expand}) {
    my %default_expand_options = ( preserve_index => 0 );
    my %normalized_expand_options = ();
    if(ref($expand)||'' eq 'HASH') {
      %normalized_expand_options = (%default_expand_options, %$expand);
    } elsif( (ref($expand)||'') eq '' && $expand == 1) {
      %normalized_expand_options = (%default_expand_options);
    } else {
      die "Invalid expand options for param $attr"; 
    }
    $options_proto{expand} = \%normalized_expand_options;
  }

  my $varname = "${class}::_params";
  my %options = (
    name => $attr,
    multi => 0,
    expand => +{ preserve_index => 0 },
    %options_proto);

  no strict "refs";
  $$varname->{$attr} = \%options;
  return %{ $$varname };
}

sub params_info {
  my $class = _to_class(shift);
  my $varname = "${class}::_params";

  no strict "refs";
  return %{ $$varname },
    map { $_->params_info }
    grep { $_ && $_->can('params_info') }
      $class->ancestors;
}

sub param {
  my $class = _to_class(shift);
  if(ref $_[0] eq 'ARRAY') {
    my @params = @{$_[0]};
    $class->__add_param($_) for @params;
  } else {
    $class->__add_param(@_);
  }
}

sub params {
  my $class = _to_class(shift);
  while(@_) {
    my $next = shift;
    my @args = ref($_[0])||'' eq 'HASH' ? %{shift @_} : ();
    $class->__add_param($next, @args);
  }
}

sub _normalize_param_value {
  my ($class, $param_info, $value) = @_;
  if($param_info->{multi}) {
    $value = ref($value)||'' eq 'ARRAY' ? $value : [$value];
    die "Param '$param_info->{name}' has more than '$param_info->{multi}{limit}' items"
      if scalar(@$value) > $param_info->{multi}{limit};
  } else {
    if(ref $value) {
      if(ref($value) eq 'ARRAY') {
        $value = $value->[-1];
      }
    }
  }

  if($param_info->{expand}) {

  }

  return $value;
}

sub _params_from_HASH {
  my ($class, %req) = @_;
  my %args_from_request = ();
  my %params_info = $class->params_info;
  foreach my $param (sort keys  %params_info) {  # doing sort since we need to enforce an order
    next unless exists $req{ $params_info{$param}{name} };
    my $value = $class->_normalize_param_value($params_info{$param}, $req{$params_info{$param}{name}});
    $args_from_request{$param} = $value;
  }
  return %args_from_request;
}

sub _params_from_Plack_Request {
  my ($class, $req) = @_;
  my %args_from_request = ();
  my %params_info = $class->params_info;
  foreach my $param (keys %params_info) {
    next unless exists $req->body_parameters->{ $params_info{$param}{name} };
    my $value = $class->_normalize_param_value($params_info{$param}, $req->body_parameters->{ $params_info{$param}{name} });
    $args_from_request{$param} = $value;
  }
}

sub param_keys { @{shift->_found_params} }

sub param_exists {
  my ($self, $key_to_check) = @_;
  return grep { $_ eq $key_to_check } $self->param_keys;
}

sub get_param {
  my ($self, $key_to_get) = @_;
  return unless $self->param_exists($key_to_get);
  return $self->$key_to_get;
}

sub get_params {
  my ($self, @keys) = @_;
  my %gathered = ();
  foreach my $key (@keys) {
    next unless $self->param_exists($key);
    $gathered{$key} = $self->$key;
  }
  return %gathered;
}

sub params_as_hash {
  my $self = shift;
  my %hash = ();
  foreach my $key($self->param_keys) {
    next unless $self->param_exists($key);
    my $value = $self->get_param($key);
    $hash{$key} = blessed($value) ? +{ $value->params_as_hash } : $value;
  }
  return %hash;
}

sub params_flattened { # order not the same as input
  my $self = shift;
  my @pairs = ();
  foreach my $key($self->param_keys) {
    next unless $self->param_exists($key);
    my $value_proto = $self->get_param($key);
    my @values = ref($value_proto)||'' eq 'ARRAY' ? @$value_proto : ($value_proto);
    push @pairs, $key, $_ for @values;
  }
  return @pairs;
}

  #query

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $init_args = $class->$orig(@args);
  my %params_in_request = ();

  if(my $req_proto = delete $init_args->{request}) {
    my %params_info = $class->params_info;
    foreach my $param_proto (keys %params_info) {
      my $param_info = $params_info{$param_proto};
      my $request_param = $params_info->{name};
      warn "looking for param $request_param";
      

    }
  }

  # First look in the request object / hash for params
  if()) {
    if(ref($request_proto)||'' eq 'HASH') {
      %params = $class->_params_from_HASH(%$request_proto);
    } elsif(my $request_class = blessed($request_proto)) {
      $request_class =~s/::/_/g;
      my $from_method = "_params_from_${request_class}";
      if($class->can($from_method)) {
        %params = $class->$from_method($request_proto);
      }
    } else {
      die "Can't find params in $request_proto";
    }
  }

  my @found = keys %params;
  my $new_args = +{
    %params,
    %$attrs,
    _found_params => \@found,
  };

  return $new_args;
};

1;

=head1 NAME

Valiant::Params::Role - Role to add HTTP POST Body Request mapping 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASS METHODS

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant>

=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

