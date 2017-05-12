package meon::Web::Model::ResponseXML;

use strict;
use base 'Catalyst::Model::Factory::PerRequest';

__PACKAGE__->config(
    class       => 'meon::Web::ResponseXML',
);

1;
