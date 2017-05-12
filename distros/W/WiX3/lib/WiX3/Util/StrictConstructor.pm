package                                # Hide from PAUSE.
  WiX3::Util::StrictConstructor;

# Corresponds to MooseX::StrictConstructor.
# 0.010004 = MX::SC 0.16

use 5.008003;
use Moose 2.00 qw();
use Moose::Exporter;
use Moose::Util::MetaRole;

#use WiX3::Util::Trait::StrictConstructor::Class;

our $VERSION = '0.011';

Moose::Exporter->setup_import_methods( class_metaroles =>
	  { class => ['WiX3::Util::Trait::StrictConstructor::Class'], }, );

1;
