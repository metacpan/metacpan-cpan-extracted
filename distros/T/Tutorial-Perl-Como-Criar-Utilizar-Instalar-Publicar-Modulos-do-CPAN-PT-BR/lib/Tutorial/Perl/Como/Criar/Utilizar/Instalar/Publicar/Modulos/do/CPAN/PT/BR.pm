package Tutorial::Perl::Como::Criar::Utilizar::Instalar::Publicar::Modulos::do::CPAN::PT::BR;
use strict;
use warnings;

our $VERSION = '0.01';

=pod

=encoding utf8

=head1 Tutorial perl - Como criar, utilizar, instalar e publicar módulos no cpan

Obs o cpan é o repositório de módulos perl. é fantastico pois tem tudo ou muito do que você procura/vai precisar para construir seus sitema dos sonhos. Tudo é aberto, então você pode ver os códigos fontes de outros autores e aprender mais técnicas de como programar melhor e melhor!

Divirta-se com o CPAN e compartilhe seus códigos.. outras pessoas podem estar precisando do mesmo que você já desenvolveu.

=head2 RESUMO

Neste artigo você vai aprender:

- O que é o CPAN e PAUSE e suas vantagens e como ele funciona.

- Como se cadastrar no CPAN.

- Como criar um módulo perl.

- Como publicar seu módulo no CPAN.

=head2 O QUE É O CPAN

CPAN: 'Comprehensive Perl Archive Network', ou 'Rede de arquivos compreensíveis perl'. Tambem conhecido como repositório de módulos perl. 

Neste momento o cpan possúi 98,463 módulos perl em 23,242 distribuições, escritos por 9,170 autores e espelhado em 259 servidores. 

No cpan você encontra todo tipo de módulos perl... desde aplicações do google, do twitter, do facebook, etc, implementações de algoritmos de fórmulas bancárias, diversos frameworks, middlewares, bots, ide, servidor web, proxy, o que você imaginar alguem já deve ter implementado e adicionado ao cpan.

Para fazer uma busca no cpan é muito simples, você acessa: http://search.cpan.org e digita algo no campo de busca, ex: "google" para ver uma lista de módulos que implementam "google". 

Uma dica para escolher alguns bons módulos é seguir as recomendações do módulo Task::Kensho. o Task::Kensho tem como proposta apresentar os melhores módulos recomendados para tarefas específicas.

=head2 VANTAGENS DO CPAN

Todos os módulos enviados ao cpan passam por testes automatizados. Este procedimento chama-se 'smoke testing', que nada mais é que testes iniciais para assegurar que sua aplicação não irá falhar. O módulo responsável por automatizar estes testes é o Test::Smoke. E você tambem pode configurá-lo para executar em sua máquina. A vantagem disto, é que ao subir sua app no cpan, várias pessoas testarão seu código automaticamente.. e posteriormente você pode acessar o debug das informações em caso de falha. Sua app é testada automaticamente nos diversos sistemas operacionais e você pode ver a lista de testes... (ex. http://matrix.cpantesters.org/?dist=DBD-mysql+4.020 ). Isto ajuda muito para garantir que sua app executou conforme esperado nos diversos sistemas. Além disso, você ainda recebe um relatório por email com o status dos erros (caso existam). 

É importante mencionar a existência do email dos desenvolvedores no cpan. Cada pessoa cadastrada no cpan possúi um email. Através deste email é possível entrar em contato com o desenvolvedor de um módulo e contratá-lo para que este faça alguma melhoria que você precise... ou, para que você envie alguma alteração que você fez para melhorar  o software.. ou ainda, enviar um patch que conserta um bug que você encontrou no módulo. Poder contactar o desenvolvedor diretamente é uma grande vantagem! Um outro meio bastante utilizado pelos desenvolvedores perl é atraves do IRC no servidor: irc.perl.org (baixe o mIRC, xchat ou irssi para conectar ao irc e falar com os desenvolvedores ). 

Outro ponto importante no cpan é a documentação dos módulos.. um bom módulo deve possuir uma boa documentação. E os desenvolvedores procuram manter o alto padrão de qualidade de documentação para seus módulos perl. Lembre-se que contribuições para melhoria são sempre bem vindas e bem aceitas... ou seja, se algum ponto de alguma documentação não ficou claro e você acha que poderia documentar melhor, entre em contato com o desenvolvedor e envie um patch para ele substituir e melhorar a documentação.

Fora isto, você pode fazer o download de qualquer módulo perl e abrir o código fonte...

=head2 COMO SE CADASTRAR NO CPAN ( registre-se no PAUSE )

PAUSE significa "The [Perl programming] Authors Upload Server", ou "Servidor de upload dos autores perl". 

Para disponibilizar seu módulo no cpan, é necessário ter uma conta no PAUSE. Para tal, você precisa realizar seu cadastro no servidor PAUSE, através da url: http://pause.perl.org/pause/query?ACTION=request_id

É no PAUSE que você vai subir seus módulos. Sempre que você subir um módulo, uma pré-verificação será executada para garantir que você enviou o formato correto (tar.gz) e com os arquivos necessários para instalação. 

Para gerar o arquivo de instalação do seu módulo, você pode fazer um 'make dist' (será exemplificado abaixo). 

=head2 PONTOS IMPORTANTES ANTES DE CRIAR UM MÓDULO

Faça uma busca no cpan para ver se não existe um módulo que faz o que você preicsa.

Verifique se o namespace do seu módulo já não é existente, isto é, verifique se já não existe um módulo com o mesmo nome que você tem em mente para o seu. 

Evite fazer módulos duplicados.. é muito mais produtivo ajudar a melhorar um módulo já existente.

Mantenha a qualidade no código, veja outros códigos e aprenda a programar de maneira mais limpa.

Documente bem o seu módulo, a documentação é levada em consideração para um bom entendimento de como funciona sua app.

Crie vários testes para seu módulo e exemplifique a utilização da sua app nos testes. Isto vai garantir a qualidade e funcionalidade do mesmo. Veja: Test::Tutorial 

Evite criar um namespace raíz, ou seja, evite criar um módulo com nome de apenas uma palavra. ex. 'UmaPalavra' vs 'Uma::App::Interessante'

É recomendável que sua app tenha um nome relacionado ao que ela faz, isto é, se você criou um editor de textos para console, dê um nome ex: Text::Editor::Console

=head2 COMO CRIAR UM MÓDULO PERL

Existe mais de uma maneira para criar módulos perl. Você pode usar o Dist::Zilla (o Russoz escreveu um bom artigo sobre), ou, você pode criar módulos com ExtUtils::ModuleMaker :

Instale o ExtUtils::ModuleMaker:
  
    cpan ExtUtils::ModuleMaker

agora digite: 
  
    modulemaker

e altere os dados de acordo com seu módulo.. você deve dar um nome ao seu módulo, uma descrição e informações sobre o autor... como nome e email. Feito isto você aperta G para gerar o módulo.

    N
    Seu Nome
    S
    Descritivo do meu modulo.. faz istou ou aquilo
    A
    Hernan Lopes
    hernanlopes@blablabla.com
    G

e o modulemaker irá criar o esqueleto do seu módulo para que você inicie o desenvolvimento.

=head2 COMO GERAR UM MÓDULO PARA ENVIAR AO CPAN

Para enviar seu módulo ao cpan, você deve gerar um arquivo tar.gz. 

A maneira mais fácil para gerar o arquivo.tar.gz para seu módulo é atraves de um 'make dist'.

Então execute os passos a seguir para criar seu Modulo-0.01.tar.gz

    cd Seu-Modulo
    perl Makefile.PL
    make dist
    ls 

Você deverá ver o arquivo ModuloXYZ-0.01.tar.gz gerado. Este é o arquivo que você vai enviar ao PAUSE para publicar seu módulo.

=head2 ARQUIVO MANIFEST

O arquivo MANIFEST deve conter uma lista de arquivos que serão incluídos automaticamente quando você executar um 'make dist'. 

Uma maneira simples de incluir os arquivos no MANIFEST é executar um

    make manifest

=head2 COMO PUBLICAR SEU MÓDULO NO CPAN

Agora que você gerou seu modulo-0.01.tar.gz , você já pode enviar o mesmo ao PAUSE. Consequentemente o PAUSE irá agendar a publicação de seu módulo no CPAN.

*** Atenção, sempre utilize o número da versão atual de seu módulo no arquivo .tar.gz. 

** O PAUSE não permite que você envie duas vezes um arquivo com o mesmo nome.

=head2 COMO INSTALAR UM MÓDULO DO CPAN SEM ROOT

Existem diversas maneiras para instalar módulos do cpan. Vou apresentar uma maneira para instalação de módulos sem root:

1. Instale o perlbrew (siga as instruções na tela... mas é mais ou menos):

    curl -L http://xrl.us/perlbrewinstall | bash
    echo "source ~/perl5/perlbrew/etc/bashrc" >> ~/.bashrc
    source ~/perl5/perlbrew/etc/bashrc
    perl -v
    perlbrew install 5.14.1
    perlbrew switch perl-5.14.1
    perl -v

2. Instale o cpanm / app::cpanminus 
  
    curl -L http://cpanmin.us | perl - App::cpanminus

3. Instale os módulos facilmente com:

    cpanm Modulo::Para::Instalacao

3.1 Ou, se preferir, acesse a página do módulo e clique em Download para baixar o arquivo e:
  
    tar xvf modulo-xyz-0.01.tar.gz
    cd modulo-xyz
    perl Makefile.PL
    make test
    make install

*** Você tambem pode instalar atraves utilizando "cpan Modulo::Para::Instalacao"

=head2 COMO CRIAR TESTES PARA SEU MÓDULO PERL

Todos os módulos devem ser testados para garantir a funcionalidade dos mesmos.

Os testes da sua app ficam dentro da pasta Modulo/t/001-testes.t

Crie os testes de acordo com sua necessidade. Quanto mais testes melhor.

Acesse via cpan: Test::Tutorial e obtenha mais exemplos de como testar sua aplicação.

Ex de teste:

    use Test::More;

    BEGIN { use_ok('Meu::Modulo'); }

    my $app = Meu::Modulo->new();
    isa_ok( $app, 'Meu::Modulo' );

    ok( $app->works == 1 , 'A app está funcionando' );
    #.... teste, teste teste.... teste bastante

    done_testing;

ao final coloque done_testing;

para executar os testes da sua aplicação execute:

    cd modulo-xyz
    perl Makefile.PL
    make test

E se tudo deu certo, você verá a mensagem: 
    
    Results: PASS

=head2 ALTERANDO A DOCUMENTACAO DO MÓDULO PERL

Edite o arquivo principal do seu módulo e documente tudo que for preciso.

Se você ficar em dúvida, baixe outros módulos do cpan criados por outras pessoas e veja como elas fazem.

A parte que você deve alterar para criar documentação é a parte que está após os =head*

=head2 CONCLUSÃO

Criar módulos perl é uma tarefa que envolve vários detalhes, mas é bastante tranquilo de fazer.

O ecosistema perl permite que trabalhemos bem a questão de testes e de documentação para garantir a qualidade do software produzido.

O CPAN tem tudo!!, é um lego de várias peças que permite a você montar aplicações sem limites.

Aproveite, contribua, aprenda com os outros.

E lembre-se, o povo está de olho na qualidade... então é recomendável manter um alto padrão :)

=head2 AUTOR

Hernan Lopes < hernanlopes at gmail >

cpan: http://search.cpan.org/~hernan/

github:  http://github.com/hernan604/

Repasse este conhecimento e ajude a fortalecer linguagem perl no brasil.



1;
# The preceding line will help the module return a true value

