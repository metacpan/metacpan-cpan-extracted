#!perl

use Test::More;

BEGIN {
    use_ok('WWW::GoDaddy::REST');
    use_ok('WWW::GoDaddy::REST::Collection');
    use_ok('WWW::GoDaddy::REST::Resource');
    use_ok('WWW::GoDaddy::REST::Schema');
    use_ok('WWW::GoDaddy::REST::Shell');
    use_ok('WWW::GoDaddy::REST::Shell::ListCommand');
    use_ok('WWW::GoDaddy::REST::Shell::GetCommand');
    use_ok('WWW::GoDaddy::REST::Shell::DocsCommand');
    use_ok('WWW::GoDaddy::REST::Shell::QueryCommand');
    use_ok('WWW::GoDaddy::REST::Shell::Util');
    use_ok('WWW::GoDaddy::REST::Util');
}

done_testing();
