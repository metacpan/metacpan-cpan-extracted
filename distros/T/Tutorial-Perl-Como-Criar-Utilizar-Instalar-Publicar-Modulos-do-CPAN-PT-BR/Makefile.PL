

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Tutorial::Perl::Como::Criar::Utilizar::Instalar::Publicar::Modulos::do::CPAN::PT::BR',
    VERSION_FROM => 'lib/Tutorial/Perl/Como/Criar/Utilizar/Instalar/Publicar/Modulos/do/CPAN/PT/BR.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernanlopes@gmail.com)',
    ABSTRACT     => 'Aprenda a usar o cpan. Compartilhe seus códigos maravilhosos.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
