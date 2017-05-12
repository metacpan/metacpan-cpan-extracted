

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Tutorial::DBIx::Class::Perl::ORM::Conexao::Com::Banco::de::Dados::PT',
    VERSION_FROM => 'lib/Tutorial/DBIx/Class/Perl/ORM/Conexao/Com/Banco/de/Dados/PT/BR.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernanlopes@gmail.com)',
    ABSTRACT     => 'Aprenda algo mais sobre dbix class, o melhor orm do mundo, em perl',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
