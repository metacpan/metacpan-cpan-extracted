use strict;
use Test::More;

use_ok $_ for qw(
    WWW::NHKProgram::API
    WWW::NHKProgram::API::Area
    WWW::NHKProgram::API::Date
    WWW::NHKProgram::API::Service
    WWW::NHKProgram::API::Provider
    WWW::NHKProgram::API::Provider::Common
    WWW::NHKProgram::API::Provider::List
    WWW::NHKProgram::API::Provider::Genre
    WWW::NHKProgram::API::Provider::Info
    WWW::NHKProgram::API::Provider::Now
);

done_testing;

