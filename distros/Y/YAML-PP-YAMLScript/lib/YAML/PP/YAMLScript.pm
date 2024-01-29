use strict; use warnings;
package YAML::PP::YAMLScript;

our $VERSION = '0.0.2';

use base 'YAML::PP';

use File::Spec;

use YAMLScript::Common;
use YAMLScript::RT;

sub new {
    my $class = shift;
    my (%args) = @_;
    $args{schema} //= ['Failsafe'];
    $class->SUPER::new(%args);
}

sub load_file {
    my ($self, $file) = @_;

    $self->schema->add_mapping_resolver(
        tag => '!yamlscript',
        on_create => sub { +{ file => $file }; },
        on_data => \&on_data,
    );

    $self->SUPER::load_file($file);
}

sub on_data {
    my ($self, $struct) = @_;

    my $file = $$struct->{file};

    RT->init;
    $YAMLScript::Reader::read_ys = 1;
    RT->rep(qq<
yaml-data =:
  load-file-ys: "$file"
    >);

    my $data = RT->user_ns->{'yaml-data'}->unbox;

    %{$$struct} = %$data;
}

my $ypp = YAML::PP->new( schema => ['Failsafe'] );

1;
