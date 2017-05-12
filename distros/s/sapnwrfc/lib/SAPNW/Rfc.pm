package SAPNW::Rfc;
=pod

    Copyright (c) 2006 - 2010 Piers Harding.
    All rights reserved.

=cut
use strict;

use SAPNW::Base;
use base qw(SAPNW::Base);
use Data::Dumper;

require 5.008;

use vars qw(@ISA $VERSION $SAPNW_RFC_CONFIG);
$VERSION = '0.37';
@ISA = qw(SAPNW::Base);

use YAML;
use Data::Dumper;

use constant SAP_YML => 'sap.yml';

sub load_config {
    my $self = shift;
    my $file =  scalar @_ > 0 ? shift @_ : SAP_YML;

    if (-f $file) {
        # yaml
        open(YML, "<$file") || die "Cannot open RFC config: $file\n";
        my $data = join("", (<YML>));
        close(YML);
        eval { $SAPNW_RFC_CONFIG = YAML::Load($data); };
        if ($@) {
            die "Parsing YAML config file failed($file): $@\n";
        }
    } else {
        die "Cant find RFC config to load in file: $file\n";
    }
    if (exists $SAPNW_RFC_CONFIG->{debug}) {
        $SAPNW::Base::DEBUG = $SAPNW_RFC_CONFIG->{debug};
    }
}


sub unload_config {
    my $self = shift;
    $SAPNW_RFC_CONFIG = {};
}


sub rfc_connect {
    my @keys = ();
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my @rest = @_;
  
    my $config = { (map { $_ => "$SAPNW_RFC_CONFIG->{$_}" } (grep {$_ !~ /tpname|gwhost|gwserv/i } (keys %$SAPNW_RFC_CONFIG))), @rest };
    map {$config->{$_} = "$config->{$_}"} keys %$config;
    if (exists $config->{debug}) {
        $SAPNW::Base::DEBUG = $config->{debug};
    }
    debug("config passed on: ".Dumper($config));
    my $conn = new SAPNW::Connection(%{$config});
    $conn->connect();
    return $conn;
}


sub rfc_register {
    my @keys = ();
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my @rest = @_;
  
    my $config = { (map { $_ => $SAPNW_RFC_CONFIG->{$_} } (grep {$_ =~ /tpname|gwhost|gwserv|debug|trace/i } (keys %$SAPNW_RFC_CONFIG))), @rest };
    map {$config->{$_} = "$config->{$_}"} keys %$config;
    if (exists $config->{debug}) {
        $SAPNW::Base::DEBUG = $config->{debug};
    }
    debug("config passed on: ".Dumper($config));
    my $conn = new SAPNW::Connection(%{$config});
    $conn->connect();
    return $conn;
}

1;
