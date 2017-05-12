use Test::More tests => 10;

BEGIN {
use_ok( 'Text::Mining::Corpus' );
}

my $params = { corpus_name => 'Test Corpus',
               corpus_desc => 'Corpus created by automated testing',
	       corpus_path => '/home/roger/projects/corpus' };

my $corpus = Text::Mining::Corpus->new( $params );
ok( $corpus, "Text::Mining::Corpus->new()" );

my $corpus_id = $corpus->get_corpus_id(), "\n";
ok( $corpus_id, "\$corpus->get_corpus_id()" );

my $name = $corpus->get_name();
ok( $name, "\$corpus->get_name()" );

my $corpus = Text::Mining::Corpus->new({ corpus_id => $corpus_id });
ok( $corpus, "Text::Mining::Corpus->new({})" );

   $old_name = $corpus->get_name();
ok( $name eq $old_name, "\$corpus->get_name()" );

my $path = $corpus->get_path(), "\n";
ok( $path, "\$corpus->get_path()" );

my $desc = $corpus->get_desc(), "\n";
ok( $desc, "\$corpus->get_desc()" );

   $corpus->update({ corpus_name => 'New name' });
   $new_name = $corpus->get_name();
ok( $name ne $new_name, "\$corpus->update()" );

   $corpus->delete();
ok( 1, "\$corpus->delete()" );

