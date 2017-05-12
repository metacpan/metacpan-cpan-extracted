package Test::WWW::LogicBoxes;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;

use WWW::LogicBoxes;

use Exporter 'import';
our @EXPORT_OK = qw( create_api );

sub create_api {
    if(    ! defined $ENV{PERL_WWW_LOGICBOXES_USERNAME}
        || ! defined $ENV{PERL_WWW_LOGICBOXES_API_KEY} ) {

        plan( skip_all => "PERL_WWW_LOGICBOXES_USERNAME and"
            . " PERL_WWW_LOGICBOXES_API_KEY must be defined in"
            . " order to run integration tests.");
    }

    my $api;
    lives_ok {
        $api = WWW::LogicBoxes->new({
            username      => $ENV{PERL_WWW_LOGICBOXES_USERNAME},
            api_key       => $ENV{PERL_WWW_LOGICBOXES_API_KEY},
            response_type => 'json',
            sandbox       => 1, # Since this is in the test suite it's always dev
        });
    } "Lives through WWW::LogicBoxes object creation";

    return $api;
}

1;
