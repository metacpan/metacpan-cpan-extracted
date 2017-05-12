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
