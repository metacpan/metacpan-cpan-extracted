package Example::Schema::Result;

use strict;
use warnings;
use base 'DBIx::Class';
use DBIx::Class::_Util 'quote_sub';
use Example::Syntax;

__PACKAGE__->load_components(qw/
  Valiant::Result
  BcryptColumn
  ResultClass::TrackColumns
  Core
  InflateColumn::DateTime
  /);

sub register_relationship($class, $rel, $info) {
  if (my $proxy_options = $info->{attrs}{proxy_select_options}) {
    $class->_proxy_to_options('select', $rel, $info->{source}, $proxy_options);
  }
  if (my $proxy_options = $info->{attrs}{proxy_radio_options}) {
    $class->_proxy_to_options('radio', $rel, $info->{source}, $proxy_options);
  }
  if (my $proxy_options = $info->{attrs}{proxy_checkbox_options}) {
    $class->_proxy_to_options('checkbox', $rel, $info->{source}, $proxy_options);
  }
  $class->next::method($rel, $info);
}

sub _proxy_to_options($class, $type, $rel, $source, $proxy_options) {
  quote_sub "${class}::${rel}_${type}_options", qq[
    return shift
      ->result_source
      ->schema
      ->resultset('$source')
      ->search_rs(
        +{}, 
        +{
          columns => [
            { value=>'$proxy_options->{value}' },
            { label=>'$proxy_options->{label}' },
          ]
        }
      );
  ];
}

sub debug($self) {
  $self->result_source->schema->debug;
  return $self;
}

sub debug_off($self) {
  $self->result_source->schema->debug_off;
  return $self;
}

1;
