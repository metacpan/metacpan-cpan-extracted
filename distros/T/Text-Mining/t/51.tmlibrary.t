use Test::More tests => 7;

BEGIN {
use_ok( 'Text::Mining' );
}

# Create a new librarian
my $tm = Text::Mining->new();
ok( $tm, "\$tm = Text::Mining->new()" );

# Create a new corpus
my $corpus = $tm->create_corpus({ corpus_name => 'Test Corpus', 
                                         corpus_path => '/home/roger/projects/comprehension/documents/corpus_1', 
				         corpus_desc => 'Testing the software' });
ok( $corpus, "\$corpus = \$tm->create_corpus()" );

# Save the ID so we can delete it later
my $corpus_id = $corpus->get_id();
ok( $corpus_id, "\$corpus_id = \$corpus->get_id()" );

# Get all corpuses
my $corpuses = $tm->get_all_corpuses();
ok( $corpuses, "\$corpuses = \$tm->get_all_corpuses()" );

# Display the corpuses
foreach my $corpus (@$corpuses) { print "  CORPUS: " . join(', ', $corpus->get_name(), $corpus->get_path()) . "\n"; }

# Submit a document to the corpus
my $doc = $corpus->submit_document({ corpus_id            => $corpus_id,
                                     submitted_by_user_id => 1,
				     bytes                => '14042',
				     document_path        => 'testing',
				     document_file_name   => 'testing' });
ok( $doc, "\$doc = \$corpus->submit_document()" );

# Delete the submission
# $corpus->delete_submitted_document({ submitted_document_id => $doc->get_id() }); # Also works
$doc->delete();

# Delete the test corpus
$tm->delete_corpus({ corpus_id => $corpus_id }); # This also deletes submitted documents
ok( 1, "\$corpus->delete_corpus()" );

# Display the corpuses
$corpuses = $tm->get_all_corpuses();
foreach my $corpus (@$corpuses) { print "  CORPUS: " . join(', ', $corpus->get_name(), $corpus->get_path()) . "\n"; }


