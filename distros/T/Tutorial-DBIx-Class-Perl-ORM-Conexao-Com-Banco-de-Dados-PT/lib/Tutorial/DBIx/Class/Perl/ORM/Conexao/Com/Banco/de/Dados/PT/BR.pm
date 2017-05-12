package Tutorial::DBIx::Class::Perl::ORM::PT::BR;
use strict;
use warnings;

our $VERSION     = '0.01';

=pod

=encoding utf8 

=head1 Tutorial DBIx::Class, conexao com banco de dados com perl ORM PT BR

=head2 Resumo

    Neste artigo, dou várias dicas de como fazer determinadas coisas com dbix class. Este não vai ser fácil para iniciantes que não leram a documentação. 
    No entanto, espero que sirva como referência.

=head2 Código Fonte

    Faça o download do pacote e acesse o diretório 'app' para obter o código fonte do exemplo utilizado.

=head2 O que é o DBIx::Class ?

    DBIx::Class é um extensível e flexível objeto <-> mapeamento relacional
    Na minha opinião é o mais fantástico mapeamento objeto relacional. 

    Com ele você consegue acessar tabelas relacionadas a partir de qualquer ponto. Ou seja, vamos supor que temos um db assim:

       ______             _______              _______                ________ 
      |      |           |       |            |       |              |        |
      |  pai |----------<| filho |-----------<| amigo |--------------|namorada|
      |______|  1 ou +   |_______|  1 ou +    |_______|  apenas 1    |________|

    (pai tem 1 ou + filhos, cada filho pode ter 1 ou + amigos e cada amigo 
     pode ter 1 namorada )

    Agora vamos supor que estamos usando dbix class e queremos adicionar:
    - 1 pai, 
    - 1 filho, 
    - 2 amigos
    - 2 namordas para cada amigo inserido

    É bastante simples... veja como na seção de apêndice logo após as dicas de A a Z.


=head2 A. Como gerar os models se você já tem o banco de dados, com catalyst:

    $ script/myapp_create.pl model DB DBIC::Schema MyApp::DB create=static dbi:Pg:dbname=myapp USER pass
    $ script/myapp_create.pl model DB DBIC::Schema MyApp::DB create=static dbi:mysql:db=myapp USER pass

=head2 B. Como gerar os models se você já tem o banco de dados, sem catalyst:

    dbicdump -o dump_directory=./lib \
    -o components='["InflateColumn::DateTime"]' \   <-- *** nao obrigatorio
    -o debug=1 \
    My::Schema \
    'dbi:Pg:dbname=foo' \
     myuser \
    mypassword

=head2 C. Ex de script simplão (p/ executar via console) com dbix class (sem catalsyt):

    1. fazer um schema dump com dbix class schema loader (letra B)
     2. colocar seu projeto em pastas assim:
    /myapp
    /myapp/programa.pl
    /myapp/lib
    /myapp/lib/DBSchema

    3.editar seu programa.pl e adicionar estas linhas para ele poder utilizar o DBSchema:
     use lib ( "./lib" );
    use DBSchema;  
    my $schema = DBSchema->connect('dbi:Pg:dbname=saude', 'hernan', '123');
    my $medico = $schema->resultset('Medico')->find({ id => 1});
    print $medico->name;

=head2 D. Exemplo de cache direto no dbix class:

    http://search.cpan.org/~rkitover/Catalyst-Model-DBIC-Schema-0.41/lib/Catalyst/TraitFor/Model/DBIC/Schema/Caching.pm

    __PACKAGE__->config({
    traits => ['Caching'],
    connect_info => 
    ['dbi:mysql:db', 'user', 'pass'],
    });

    $c->model('DB::Table')->search({ foo => 'bar' }, { cache_for => 18000 });  


=head2 E. Exemplo de ResultSet (extendendo os models), nos permite jogar todas as lógicas nos models, gerando thin controllers fat models.

    Depois é só acessar como se fosse um metodo.
    infos: http://beta.metacpan.org/module/Catalyst::Model::DBIxResultSet

    sub is_my_img {
    my ($self, $c, $img_gallery_id) = @_;
     return $self->search({
    id => $img_gallery_id,
    user_id => $c->user->id,
    });

    No controller:
    my $test = $c->model('DBICSchemamodel::ImgGallery')->is_my_img($c, $pks[0])->single();


=head2 F. Deploy de banco de dados, Tendo os models em mãos, é possível criar as tabelas (após conectar) num banco de dados:

    $schema->deploy

=head2 G. Exemplo de coluna Count 

    dbic dbix class count 
    search({}, {
    order_by => { -desc => \'count(tracks.trackid)' },
    join => 'tracks',
    distinct => 1,
    });  

=head2 H.  Custom Query

    my $schema = DB->connect(...);
    my $stmt = 'create table foo ( id int );';
    $schema->storage->dbh->prepare( $stmt )->execute()

=head2 I. Exemplo HashReinflator (hashreinflator devolve um hash ao inves de um resultset), com cache:   

    my $uniqueKey = md5_hex($schemamodel);
    my $cached_data;
    unless ( $cached_data = $c->cache->get($uniqueKey) ) {
    my $result = $c->model($schemamodel)
     ->search({
      is_deleted => 0, 
     },{
     });
     $result->result_class('DBIx::Class::ResultClass::HashRefInflator'); #sets the result to be hashreinflator
     my @items_list = $result->all; #inflates the whole resultset into a array hash
      use Data::Dumper;
     $c->log->debug('Dumper ' . Dumper( \@items_list )); 
     $cached_data = \@items_list;
     $c->cache->set( $uniqueKey, $cached_data );
    }

=head2 J. Insert multiplo:

    $cd->artistname(shift @{$c->req->params->{artistname}});  
    $cd->update(); 

=head2 K. Adicionando um  metodo (no model/resultset) que retorna preço formatado

    sub preco_fmt #retorna preço formatado
    {
       my $self  = shift @_;
       return 'R$ ' . sub { my $price_fmt = $self->preco() ; $price_fmt =~ s/\./,/g; return $price_fmt; }->();
    } 

=head2 L. DBIx::Class search NOT IN, -not_in, not in

    ->search({... 
    id => { 
     'not in' => [1,2], 
     },
    ...},{}); 

=head2 M. Order by count 

    order_by => \''COUNT(\'story_id\') AS count'
    order_by => \'COUNT(\'story_id\') DESC'

=head2 N. update user session data 

    $c->user->obj->discard_changes

=head2 O.  Exemplo de um ResultSet Class para o model Company   

    package myapp::DBSchema::ResultSet::Company;
    use strict;
    use warnings;
    use base 'DBIx::Class::ResultSet';

    sub all_companys {
    my ($self) = @_;
    my @companys = $self->
     search( { 'me.is_deleted' => 0 }, { order_by => ['me.name ASC',] } )->all;
    return @companys;
    }

    1;  

=head2 P. **** ATive o trace do dbix class para debugar as querys, etc...

    sem cores:
       $ export DBIC_TRACE=1 && script/imobiliaria_software_server.pl -r -d -p 3089
    com cores:
       $ export DBIC_TRACE_PROFILE=console && export DBIC_TRACE=1 && script/imobiliaria_software_server.pl -r -d -p 3089

=head2 Q. Query no dbix class:

    $item = $schema->resultset('Medico')->find(); #retorna uma row, pode ser acessado ex. 
    $item->id, 
    $item->nome, 
    $item->nome('novo nome') 
    $item->update
    @res = $schema->resultset('Medico')->search({},{})->all #Retorna array
    $res = $schema->resultset('Medico')->search({...},{})  #Retorna varias rows e para fazer loop tem que fazer: while ( my $item = $res->next ) { ... } 

=head2 APÊNDICE

Veja como é bacana e elegante trabalhar com DBIx::Class

=head2 Crie seu banco de dados ( utilizei postgresql ) 

Eu recomento a utilização do postgres para ensinar dbix class pois o postgres salva os relacionamentos dentro do banco de dados e isso facilita pois o dbix class consegue detectar esses relacionamentos e já cria todos os models para nós incluindo esses relacionamentos.

    CREATE TABLE amigo (
        id integer NOT NULL,
        nome text,
        amigo_id integer
    );
    ALTER TABLE public.amigo OWNER TO hernan;
    CREATE SEQUENCE amigo_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;
    ALTER TABLE public.amigo_id_seq OWNER TO hernan;
    ALTER SEQUENCE amigo_id_seq OWNED BY amigo.id;
    SELECT pg_catalog.setval('amigo_id_seq', 1, false);
    CREATE TABLE filho (
        id integer NOT NULL,
        nome text,
        pai_id integer
    );
    ALTER TABLE public.filho OWNER TO hernan;
    CREATE SEQUENCE filho_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;
    ALTER TABLE public.filho_id_seq OWNER TO hernan;
    ALTER SEQUENCE filho_id_seq OWNED BY filho.id;
    SELECT pg_catalog.setval('filho_id_seq', 1, false);
    CREATE TABLE namorada (
        id integer NOT NULL,
        nome text,
        amigo_id integer
    );
    ALTER TABLE public.namorada OWNER TO hernan;
    CREATE SEQUENCE namorada_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;
    ALTER TABLE public.namorada_id_seq OWNER TO hernan;
    ALTER SEQUENCE namorada_id_seq OWNED BY namorada.id;
    SELECT pg_catalog.setval('namorada_id_seq', 1, false);
    CREATE TABLE pai (
        id integer NOT NULL,
        nome text
    );
    ALTER TABLE public.pai OWNER TO hernan;
    CREATE SEQUENCE pai_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;
    ALTER TABLE public.pai_id_seq OWNER TO hernan;
    ALTER SEQUENCE pai_id_seq OWNED BY pai.id;
    SELECT pg_catalog.setval('pai_id_seq', 1, false);
    ALTER TABLE ONLY amigo ALTER COLUMN id SET DEFAULT nextval('amigo_id_seq'::regclass);
    ALTER TABLE ONLY filho ALTER COLUMN id SET DEFAULT nextval('filho_id_seq'::regclass);
    ALTER TABLE ONLY namorada ALTER COLUMN id SET DEFAULT nextval('namorada_id_seq'::regclass);
    ALTER TABLE ONLY pai ALTER COLUMN id SET DEFAULT nextval('pai_id_seq'::regclass);
    COPY amigo (id, nome, amigo_id) FROM stdin;
    \.
    COPY filho (id, nome, pai_id) FROM stdin;
    \.
    COPY namorada (id, nome, amigo_id) FROM stdin;
    \.
    COPY pai (id, nome) FROM stdin;
    \.
    ALTER TABLE ONLY amigo
        ADD CONSTRAINT amigo_pkey PRIMARY KEY (id);
    ALTER TABLE ONLY filho
        ADD CONSTRAINT filho_pkey PRIMARY KEY (id);
    ALTER TABLE ONLY namorada
        ADD CONSTRAINT namorada_pkey PRIMARY KEY (id);
    ALTER TABLE ONLY pai
        ADD CONSTRAINT pai_pkey PRIMARY KEY (id);
    ALTER TABLE ONLY amigo
        ADD CONSTRAINT amigo_amigo_id_fkey FOREIGN KEY (amigo_id) REFERENCES filho(id);
    ALTER TABLE ONLY filho
        ADD CONSTRAINT filho_pai_id_fkey FOREIGN KEY (pai_id) REFERENCES pai(id);
    ALTER TABLE ONLY namorada
        ADD CONSTRAINT namorada_amigo_id_fkey FOREIGN KEY (amigo_id) REFERENCES amigo(id);
    REVOKE ALL ON SCHEMA public FROM PUBLIC;
    REVOKE ALL ON SCHEMA public FROM postgres;
    GRANT ALL ON SCHEMA public TO postgres;
    GRANT ALL ON SCHEMA public TO nixus;
    GRANT ALL ON SCHEMA public TO PUBLIC;


=head2 Como conectar no banco de dados com dbix class

Agora que já criamos o banco de dados, devemos criar os models em nossa app para que ela se conecte no banco de dados. 
Então vamos lá... usaremos a dica "B. Como gerar os models se você já tem o banco de dados, sem catalyst" que diz:
 
    dbicdump -o dump_directory=./lib \
    -o components='["InflateColumn::DateTime"]' \   <-- *** nao obrigatorio
    -o debug=1 \
    My::Schema \
    'dbi:Pg:dbname=foo' \
     myuser \
    mypassword

Se você não tiver permissão, pode conectar no db com 
    
    psql tut_dbixclass_perl_orm

e depois executar um grant all em todas as tabelas pra um usuario, no meu casi 'webdev'

    select 'grant all on '||schemaname||'.'||tablename||' to webdev;' from pg_tables where schemaname in ('public') order by schemaname, tablename;

faça um select em pg_tables antes para ver quais itens você vai precisar... neste caso é só public
e agora vamos criar um diretório para a aplicação

    mkdir /home/catalyst/tutorial-dbix-class-perl-orm-pt-br/app
    cd /home/catalyst/tutorial-dbix-class-perl-orm-pt-br/app
    vim /home/catalyst/tutorial-dbix-class-perl-orm-pt-br/app/app.pl

=head2 Dependências

Instale o módulos do cpan:
    
    DBIx::Class::Schema::Loader     #dbicdump (gera os models pra você, com todos os relacionamentos)
    DBD::Pg                         #para conectar no banco de dados postgres

Talvez você precise daquelas libs de -dev para poder criar o DBD::Pg... ex. 

    postgresql-server-dev-all       #ferramentas para desenvolvimento postgres

=head2 ERRO#1 - verificando se o comando dbicdump está disponível

    $ dbicdump
    The program 'dbicdump' is currently not installed.  To run 'dbicdump' please ask your administrator to install the package 'libdbix-class-schema-loader-perl'

Primeiro tentei rodar o comando dbicdump diretamente no meu terminal para ver se o mesmo está instalado.
Apareceu essa mensagem dizendo que o mesmo não está instalado, porem eu posso instalar pois ele está no repositório do ubuntu (que legal em)
Mas, acontece que eu estou utilizando minha versão de perl 5.17.1 (a mais nova) que eu instalei usando "perlbrew" (procure perlbrew) e eu utilizo junto o "cpanm" e assim eu posso instalar módulos sem root no perl. legal pois é mais seguro!!

    cpanm DBIx::Class::Schema::Loader

esse é o módulo que fornece o dbicdump

=head2 ERRO#2

Após instalar o DBIx::Class::Schema::Loader, Tentei executar o comando dbicdump mas veja o que aconteceu:

    $ dbicdump -o dump_directory=./lib -o debug=1 DB::Tutorial::DBIx::Class::PT::BR 'dbi:Pg:dbname=tut_dbixclass_perl_orm' username password
    DBIx::Class::Schema::Loader::make_schema_at(): DBI Connection failed: install_driver(Pg) failed: Can't locate DBD/Pg.pm in @INC (@INC contains: /home/webdev/perl5/perlbrew/perls/perl-5.15.9/lib/site_perl/5.15.9/x86_64-linux /home/webdev/perl5/perlbrew/perls/perl-5.15.9/lib/site_perl/5.15.9 /home/webdev/perl5/perlbrew/perls/perl-5.15.9/lib/5.15.9/x86_64-linux /home/webdev/perl5/perlbrew/perls/perl-5.15.9/lib/5.15.9 .) at (eval 95) line 3.
    Perhaps the DBD::Pg perl module hasn't been fully installed,
    or perhaps the capitalisation of 'Pg' isn't right.
    Available drivers: DBM, ExampleP, File, Gofer, Proxy, SQLite, Sponge.
     at /home/webdev/perl5/perlbrew/perls/perl-5.15.9/lib/site_perl/5.15.9/DBIx/Class/Storage/DBI.pm line 1249. at /home/webdev/perl5/perlbrew/perls/perl-5.15.9/bin/dbicdump line 178

Isto quer dizer que não tem instalado o DBD::Pg, que é o módulo que vai permitir nossa conexão com o banco de dados Postgres. O erro aparece na linha acima, nesta parte:

    Can't locate DBD/Pg.pm in @INC

Quer dizer que não localizou o módulo DBD/Pg e esse módulo é uma dependência necessária para essa ação:
   
    DBIx::Class::Schema::Loader::make_schema_at(): DBI Connection failed

Ou seja, tentou executar metodo: 
    
    make_schema 

no módulo 
    
    DBIx::Class::Schema::Loader

e resultou em: 

    DBI Connection failed 

pelo motivo 

    install_driver(Pg) failed: Can't locate DBD/Pg.pm in @INC

=head2 Arrumando ERRO#2 (Instalando DBD::Pg)

Quando tentei rodar o dbicdump, eu havia instalado minha versão perl com perlbrew recentemente e nem tinha instalado o DBD::Pg ainda... por isso resultou no erro #2. 
Então vou instalar o módulo DBD::Pg assim:

    $ cpanm DBD::Pg
    --> Working on DBD::Pg
    Fetching http://www.cpan.org/authors/id/T/TU/TURNSTEP/DBD-Pg-2.19.2.tar.gz ... OK
    Configuring DBD-Pg-2.19.2 ... OK
    Building and testing DBD-Pg-2.19.2 ... OK
    Successfully installed DBD-Pg-2.19.2
    1 distribution installed

=head2 ERRO#4 Usuário sem permissão no banco de dados

    $ dbicdump -o dump_directory=./lib -o debug=1 DB::Tutorial::DBIx::Class::PT::BR 'dbi:Pg:dbname=tut_dbixclass_perl_orm' username password
    DBIx::Class::Schema::Loader::make_schema_at(): DBI Connection failed: DBI connect('dbname=tut_dbixclass_perl_orm','username',...) failed: FATAL:  Peer authentication failed for user "username" at /home/webdev/perl5/perlbrew/perls/perl-5.15.9/lib/site_perl/5.15.9/DBIx/Class/Storage/DBI.pm line 1249. at /home/webdev/perl5/perlbrew/perls/perl-5.15.9/bin/dbicdump line 178

Dê permissão ao seu usuário no banco de dados atraves do comando grant

    grant all on database tut_dbixclass_perl_orm to username;

=head2 ERRO#5 Usuário sem permissão de select

    $ dbicdump -o dump_directory=./lib -o debug=1 DB::Tutorial::DBIx::Class::PT::BR 'dbi:Pg:dbname=tut_dbixclass_perl_orm' username webdev123
    Bad table or view 'amigo', ignoring: DBIx::Class::Schema::Loader::make_schema_at(): DBI Exception: DBD::Pg::st execute failed: ERROR:  permission denied for relation amigo [for Statement "SELECT * FROM "public"."amigo" WHERE ( 1 = 0 )"] at /home/webdev/perl5/perlbrew/perls/perl-5.15.9/bin/dbicdump line 178

dê permissão de select nas tabelas para seu usuário:

    grant all on public.pai to username;

=head2 Quando o dbicdump dá certo voce vê:

    $ dbicdump -o dump_directory=./lib -o debug=1 DB::Tutorial::DBIx::Class::PT::BR 'dbi:Pg:dbname=tut_dbixclass_perl_orm' username password
    DB::Tutorial::DBIx::Class::PT::BR::Result::Amigo->table("amigo");
    DB::Tutorial::DBIx::Class::PT::BR::Result::Amigo->add_columns(
      "id",
      {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "amigo_id_seq",
      },
      "nome",
      { data_type => "text", is_nullable => 1 },
      "amigo_id",
      { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    );
    DB::Tutorial::DBIx::Class::PT::BR::Result::Amigo->set_primary_key("id");
    DB::Tutorial::DBIx::Class::PT::BR::Result::Filho->table("filho");
    DB::Tutorial::DBIx::Class::PT::BR::Result::Filho->add_columns(
      "id",
      {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "filho_id_seq",
      },
      "nome",
      { data_type => "text", is_nullable => 1 },
      "pai_id",
      { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    );
    DB::Tutorial::DBIx::Class::PT::BR::Result::Filho->set_primary_key("id");
    DB::Tutorial::DBIx::Class::PT::BR::Result::Namorada->table("namorada");
    DB::Tutorial::DBIx::Class::PT::BR::Result::Namorada->add_columns(
      "id",
      {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "namorada_id_seq",
      },
      "nome",
      { data_type => "text", is_nullable => 1 },
      "amigo_id",
      { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    );
    DB::Tutorial::DBIx::Class::PT::BR::Result::Namorada->set_primary_key("id");
    DB::Tutorial::DBIx::Class::PT::BR::Result::Pai->table("pai");
    DB::Tutorial::DBIx::Class::PT::BR::Result::Pai->add_columns(
      "id",
      {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "pai_id_seq",
      },
      "nome",
      { data_type => "text", is_nullable => 1 },

... e nada de erros.

=head2 Agora precisamos arrumar alguns relacionamentos

O DBIx::Class fala ingles por padrao.. então quando ele detectar e criar os relacionamentos para você, ele vai colocar os plurais em ingles. Então precisamos verificar e consertar essas inconsistências.

Então vamos editar os models do dbixclass que estão dentro do diretório:

    app/lib/DB/Tutorial/DBIx/Class/PT/BR/Result/*
    app/lib/DB/Tutorial/DBIx/Class/PT/BR/Result/Amigo.pm
    app/lib/DB/Tutorial/DBIx/Class/PT/BR/Result/Filho.pm
    app/lib/DB/Tutorial/DBIx/Class/PT/BR/Result/Pai.pm

Primeiro edite o Filho.pm la no final, *após* a linha DO NOT MODIFY THIS OR ANYTHING ABOVE coloque:
Não altere essa linha e nem o conteudo acima dela. Tudo que você escrever após essa linha vai sobrepor o que foi declarado em cima. A parte que está em cima pode ser sobre-escrita/atualizada se você rodar um comando para atualizar os campos do banco de dados por exemplo. Então se você mexer ali, o dbix class vai se perder, então evite mexer ali para não ter problemas.
Sempre mexa após essa linha:

    # DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aaQcKvggMUd5YmFttR/eYw

    __PACKAGE__->has_many(
      "amigos",
      "DB::Tutorial::DBIx::Class::PT::BR::Result::Amigo",
      { "foreign.amigo_id" => "self.id" },
      { cascade_copy => 0, cascade_delete => 0 },
    );


agora o arquivo Pai.pm

    # DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B4I5N4/abdMhSMNWiYJFJQ

    __PACKAGE__->has_many(
      "filhos",
      "DB::Tutorial::DBIx::Class::PT::BR::Result::Filho",
      { "foreign.pai_id" => "self.id" },
      { cascade_copy => 0, cascade_delete => 0 },
    );


agora sim, alteramos de filhoes para filhos. E amigoes para amigos. 
bem melhor pois fica mais natural.

=head2 Como criar a aplicação com dbix class e conexão com banco de dados postgres

Veja a dica #C deste tutorial e crie um diretório para sua aplicação e edite um arquivo.pl para inserir o seguinte código de exemplo:
Este código conecta no banco de dados utilizando postgres, e insere 1 pai, 1 filho, 1 amigo e uma namorada pro amigo.
Abaixo está a saída dos comandos executados.
Para executar o script digite no terminal:

    $ export DBIC_TRACE=1 && perl app.pl

Segue o codigo fonte:

    use lib ( "./lib" );
    use DB::Tutorial::DBIx::Class::PT::BR; 
    my $schema = DB::Tutorial::DBIx::Class::PT::BR->connect(
        'dbi:Pg:dbname=tut_dbixclass_perl_orm', 
        'webdev', 
        'webdev123'
    );
    my $pai = $schema->resultset('Pai')->new({ nome => 'joao' }); 
    $pai->insert;
    warn $pai->nome;
    my $filho = $pai->add_to_filhos( { nome => 'filho 1' } );
    warn $filho->nome;
    my $amigo = $filho->add_to_amigos( {
        nome => 'Nome amigo1',
    } );

    my $namorada = $amigo->add_to_namoradas( {
        nome => 'Maria' 
    } );

    warn $namorada->nome;
    warn $namorada->id;

Saida do codigo acima:

    INSERT INTO pai ( nome) VALUES ( ? ) RETURNING id: 'joao'
    joao at app.pl line 10.
    INSERT INTO filho ( nome, pai_id) VALUES ( ?, ? ) RETURNING id: 'filho 1', '23'
    filho 1 at app.pl line 12.
    INSERT INTO amigo ( amigo_id, nome) VALUES ( ?, ? ) RETURNING id: '6', 'Nome amigo1'
    INSERT INTO namorada ( amigo_id, nome) VALUES ( ?, ? ) RETURNING id: '3', 'Maria'
    Maria at app.pl line 21.
    2 at app.pl line 22.

=head2 Autor

    Hernan Lopes < hernanlopes gmail >
    cpan: http://search.cpan.org/~hernan/
    github:  http://github.com/hernan604/

    Escrevam para eu saber se está ficando legal, ou como posso melhorar! 
    Obg, 
    -Hernan Lopes


1;
# The preceding line will help the module return a true value

