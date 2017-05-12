use Test::More tests => 6;

BEGIN {
use_ok( 'Text::Mining::Corpus::Document' );
}

my $params = { corpus_id          => 1,
               document_path      => '/home/roger/projects/corpus',
               document_file_name => 'Test Corpus' };

my $document = Text::Mining::Corpus::Document->new( $params );
ok( $document, "Text::Mining::Corpus::Document->new()" );

my $document_id = $document->get_submitted_document_id(), "\n";
ok( $document_id, "\$document->get_submitted_document_id()" );

my $name = $document->get_document_file_name();
ok( $name, "\$document->get_document_file_name()" );

my $path = $document->get_document_path(), "\n";
ok( $path, "\$document->get_document_path()" );

my $document = Text::Mining::Corpus::Document->new({ submitted_document_id => $document_id });
ok( $document, "Text::Mining::Corpus::Document->new()" );

#my $path = $document->get_document_path(), "\n";
#ok( $path, "\$document->get_document_path()" );

#$document->set_document_file_name( 'new_file' );
#my $new_name = $document->get_document_file_name();
#ok( $name ne $new_name, "\$document->set_document_file_name()" );

