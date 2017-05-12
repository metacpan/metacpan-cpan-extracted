# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;

BEGIN { use_ok( 'Tutorial::DBIx::Class::Perl::ORM::Conexao::Com::Banco::de::Dados::PT::BR' ); }

#my $object = Tutorial::DBIx::Class::Perl::ORM::Conexao::Com::Banco::de::Dados::PT::BR->new ();
#isa_ok ($object, 'Tutorial::DBIx::Class::Perl::ORM::Conexao::Com::Banco::de::Dados::PT::BR');


