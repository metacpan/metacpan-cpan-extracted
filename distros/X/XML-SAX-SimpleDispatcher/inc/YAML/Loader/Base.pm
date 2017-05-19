#line 1
package YAML::Loader::Base;
use strict; use warnings;
use YAML::Base; use base 'YAML::Base';

field load_code => 0;

field stream => '';
field document => 0;
field line => 0;
field documents => [];
field lines => [];
field eos => 0;
field done => 0;
field anchor2node => {};
field level => 0;
field offset => [];
field preface => '';
field content => '';
field indent => 0;
field major_version => 0;
field minor_version => 0;
field inline => '';

sub set_global_options {
    my $self = shift;
    $self->load_code($YAML::LoadCode || $YAML::UseCode)
      if defined $YAML::LoadCode or defined $YAML::UseCode;
}

sub load {
    die 'load() not implemented in this class.';
}

1;

__END__

#line 64
