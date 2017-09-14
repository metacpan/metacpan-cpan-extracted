use strict;
use warnings;
use 5.010;
 
use Test::Simple tests => 109;
use Word2vec::Word2vec;

my $word2vec = Word2vec::Word2vec->new();


# Basic Method Testing (Test Accessor Functions)
ok( defined( $word2vec ) );
ok( $word2vec->GetDebugLog() == 0 );
ok( $word2vec->GetWriteLog() == 0 );
ok( !defined( $word2vec->GetFileHandle() ) );
ok( $word2vec->GetTrainFilePath() eq "" );
ok( $word2vec->GetOutputFilePath() eq "" );
ok( $word2vec->GetWordVecSize() == 100 );
ok( $word2vec->GetWindowSize() == 5 );
ok( $word2vec->GetSample() == 0.001 );
ok( $word2vec->GetHSoftMax() == 0 );
ok( $word2vec->GetNegative() == 5 );
ok( $word2vec->GetNumOfThreads() == 12 );
ok( $word2vec->GetNumOfIterations() == 5 );
ok( $word2vec->GetMinCount() == 5 );
ok( $word2vec->GetAlpha() == 0.05 || $word2vec->GetAlpha() == 0.025 );
ok( $word2vec->GetClasses() == 0 );
ok( $word2vec->GetDebugTraining() == 2 );
ok( $word2vec->GetBinaryOutput() == 1 );
ok( $word2vec->GetSaveVocabFilePath() eq "" );
ok( $word2vec->GetReadVocabFilePath() eq "" );
ok( $word2vec->GetUseCBOW() == 1 );
ok( $word2vec->GetWorkingDir() eq Cwd::getcwd() );
ok( $word2vec->GetWord2VecExeDir() ne "" );
ok( keys %{ $word2vec->GetVocabularyHash() } == 0 );
ok( $word2vec->GetOverwriteOldFile() == 0 );
ok( $word2vec->GetSparseVectorMode() == 0 );
ok( $word2vec->GetVectorLength() == 0 );
ok( $word2vec->GetNumberOfWords() == 0 );
ok( $word2vec->GetMinimizeMemoryUsage() == 1 );
ok( defined( $word2vec->GetTime() ) && defined( $word2vec->GetDate() ) );


# Basic Method Testing (Test Mutator Functions)
$word2vec->SetTrainFilePath( "test/path" );
ok( $word2vec->GetTrainFilePath() eq "test/path" );
$word2vec->SetTrainFilePath( "" );

$word2vec->SetOutputFilePath( "test/path" );
ok( $word2vec->GetOutputFilePath() eq "test/path" );
$word2vec->SetOutputFilePath( "" );

$word2vec->SetWordVecSize( 0 );
ok( $word2vec->GetWordVecSize() == 0 );
$word2vec->SetWordVecSize( 100 );

$word2vec->SetWindowSize( 12 );
ok( $word2vec->GetWindowSize() == 12 );
$word2vec->SetWindowSize( 5 );

$word2vec->SetSample( 12.0 );
ok( $word2vec->GetSample() == 12.0 );
$word2vec->SetSample( 0.001 );

$word2vec->SetHSoftMax( 999 );
ok( $word2vec->GetHSoftMax() == 999 );
$word2vec->SetHSoftMax( 0 );

$word2vec->SetNegative( 123 );
ok( $word2vec->GetNegative() == 123 );
$word2vec->SetNegative( 5 );

$word2vec->SetNumOfThreads( 0 );
ok( $word2vec->GetNumOfThreads() == 0 );
$word2vec->SetNumOfThreads( 12 );

$word2vec->SetNumOfIterations( 0 );
ok( $word2vec->GetNumOfIterations() == 0 );
$word2vec->SetNumOfIterations( 5 );

$word2vec->SetMinCount( 0 );
ok( $word2vec->GetMinCount() == 0 );
$word2vec->SetMinCount( 5 );

my $alpha = $word2vec->GetAlpha();
$word2vec->SetAlpha( 12 );
ok( $word2vec->GetAlpha() == 12 );
$word2vec->SetAlpha( $alpha );

$word2vec->SetClasses( 99 );
ok( $word2vec->GetClasses() == 99 );
$word2vec->SetClasses( 0 );

$word2vec->SetDebugTraining( 0 );
ok( $word2vec->GetDebugTraining() == 0 );

$word2vec->SetBinaryOutput( 0 );
ok( $word2vec->GetBinaryOutput() == 0 );

$word2vec->SetSaveVocabFilePath( "test/path" );
ok( $word2vec->GetSaveVocabFilePath() eq "test/path" );
$word2vec->SetSaveVocabFilePath( "" );

$word2vec->SetReadVocabFilePath( "test/path" );
ok( $word2vec->GetReadVocabFilePath() eq "test/path" );
$word2vec->SetReadVocabFilePath( "" );

$word2vec->SetUseCBOW( 0 );
ok( $word2vec->GetUseCBOW() == 0 );
$word2vec->SetUseCBOW( 1 );

my $oldPath = $word2vec->GetWorkingDir();
$word2vec->SetWorkingDir( "test/path" );
ok( $word2vec->GetWorkingDir() eq "test/path");
$word2vec->SetWorkingDir( $oldPath );

my $word2vecExePath = $word2vec->GetWord2VecExeDir();
$word2vec->SetWord2VecExeDir( "test/path" );
ok( $word2vec->GetWord2VecExeDir() eq "test/path" );
$word2vec->SetWord2VecExeDir( $word2vecExePath );

my %hash;
$hash{ "test" } = "test array data";
$word2vec->SetVocabularyHash( \%hash );
ok( keys( %{ $word2vec->GetVocabularyHash() } ) > 0 );
$word2vec->ClearVocabularyHash();

$word2vec->SetOverwriteOldFile( 1 );
ok( $word2vec->GetOverwriteOldFile() == 1 );

$word2vec->SetSparseVectorMode( 1 );
ok( $word2vec->GetSparseVectorMode() == 1 );
$word2vec->SetSparseVectorMode( 0 );

$word2vec->SetVectorLength( 39 );
ok( $word2vec->GetVectorLength() == 39 );
$word2vec->SetVectorLength( 0 );

$word2vec->SetNumberOfWords( 2 );
ok( $word2vec->GetNumberOfWords() == 2 );
$word2vec->SetNumberOfWords( 0 );

$word2vec->SetMinimizeMemoryUsage( 0 );
ok( $word2vec->GetMinimizeMemoryUsage() == 0 );
$word2vec->SetMinimizeMemoryUsage( 1 );


# Advanced Method Testing (Word2Vec Training From File)
ok( $word2vec->ExecuteTraining( "samples/precompoundexample.txt", "vectors.bin" ) == 0 );
ok( -e "vectors.bin" && -s "vectors.bin" );
unlink( "vectors.bin" ) if ( -e "vectors.bin" );

# Advanced Method Testing (Word2Vec Training From String)
my $trainingData = "";

open( my $fileHandle, "<:encoding(utf8)", "samples/precompoundexample.txt" );
while( my $data = <$fileHandle> )
{
    chomp( $data );
    $trainingData .= $data;
}
close( $fileHandle );
undef( $fileHandle );

ok( $word2vec->ExecuteStringTraining( $trainingData, "vectors.bin" ) == 0 );
ok( -e "vectors.bin" && -s "vectors.bin" );

# Advanced Method Testing (Dense To Sparse Vector Conversion)
ok( $word2vec->ReadTrainedVectorDataFromFile( "vectors.bin" ) == 0 );
ok( $word2vec->IsVectorDataInMemory() == 1 );
ok( $word2vec->IsWordOrCUIVectorData() eq "word" );
ok( $word2vec->SaveTrainedVectorDataToFile( "sparsevectors.bin", 2 ) == 0 );
ok( -e "sparsevectors.bin" && -s "sparsevectors.bin" );
ok( $word2vec->CheckWord2VecDataFileType( "sparsevectors.bin" ) eq "sparsetext" );

# Advanced Method Testing (Sparse To Binary Vector Conversion)
$word2vec->ClearVocabularyHash();
ok( $word2vec->IsVectorDataInMemory() == 0 );
ok( $word2vec->ReadTrainedVectorDataFromFile( "sparsevectors.bin" ) == 0 );
ok( $word2vec->IsVectorDataInMemory() == 1 );
ok( $word2vec->IsWordOrCUIVectorData() eq "word" );
ok( $word2vec->SaveTrainedVectorDataToFile( "binaryvectors.bin", 1 ) == 0 );
ok( -e "binaryvectors.bin" && -s "binaryvectors.bin" );
ok( $word2vec->CheckWord2VecDataFileType( "binaryvectors.bin" ) eq "binary" );

# Advanced Method Testing (Binary To Dense Vector Conversion)
$word2vec->ClearVocabularyHash();
ok( $word2vec->IsVectorDataInMemory() == 0 );
ok( $word2vec->ReadTrainedVectorDataFromFile( "binaryvectors.bin" ) == 0 );
ok( $word2vec->IsVectorDataInMemory() == 1 );
ok( $word2vec->IsWordOrCUIVectorData() eq "word" );
ok( $word2vec->SaveTrainedVectorDataToFile( "densevectors.bin", 0 ) == 0 );
ok( -e "densevectors.bin" && -s "densevectors.bin" );
ok( $word2vec->CheckWord2VecDataFileType( "densevectors.bin" ) eq "text" );

# Computing Cosine Similarity
$word2vec->ClearVocabularyHash();
ok( $word2vec->IsVectorDataInMemory() == 0 );
ok( $word2vec->ReadTrainedVectorDataFromFile( "vectors.bin" ) == 0 );
ok( $word2vec->IsVectorDataInMemory() == 1 );
ok( $word2vec->IsWordOrCUIVectorData() eq "word" );
ok( defined( $word2vec->GetWordVector( "of" ) ) );
ok( defined( $word2vec->ComputeCosineSimilarity( "of", "the" ) ) );
ok( defined( $word2vec->ComputeAvgOfWordsCosineSimilarity( "of the", "was and" ) ) );
ok( defined( $word2vec->ComputeMultiWordCosineSimilarity( "of the", "was in" ) ) );
ok( $word2vec->ComputeMultiWordCosineSimilarity( "of the", "the of" ) == 1 );

my $wordAData = $word2vec->GetWordVector( "of" );
my $wordBData = $word2vec->GetWordVector( "the" );

$wordAData = $word2vec->RemoveWordFromWordVectorString( $wordAData );
$wordBData = $word2vec->RemoveWordFromWordVectorString( $wordBData );

ok( defined( $word2vec->ComputeCosineSimilarityOfWordVectors( $wordAData, $wordBData ) ) );

# Average Of Words
my @tempAry = qw( of the and was in );
ok( defined( $word2vec->ComputeAverageOfWords( \@tempAry ) ) );
undef( @tempAry );

# Adding Two Word Vectors With Word Arguments
ok( defined( $word2vec->AddTwoWords( "of", "the" ) ) );

# Difference Of Two Word Vectors With Word Arguments
ok( defined( $word2vec->SubtractTwoWords( "of", "the" ) ) );

# Adding Two Word Vectors With Word Vector Data Arguments
ok( defined( $word2vec->AddTwoWordVectors( $wordAData, $wordBData ) ) );

# Subtracting Two Word Vectors With Word Vector Data Arguments
ok( defined( $word2vec->SubtractTwoWordVectors( $wordAData, $wordBData ) ) );

# Average Of Two Word Vectors With Word Vector Data Arguments
ok( defined( $word2vec->AverageOfTwoWordVectors( $wordAData, $wordBData ) ) );

ok( defined( $word2vec->GetWordVector( "of" ) ) );

ok( $word2vec->IsVectorDataInMemory() == 1 );

ok( $word2vec->StringsAreEqual( "equal", "equal" ) == 1 );
ok( $word2vec->StringsAreEqual( "yes", "no" ) == 0 );

my $data = $word2vec->GetWordVector( "of" );
ok( defined( $word2vec->RemoveWordFromWordVectorString( $data ) ) );
undef( $data );

$data = "word 0 0.235023 15 0.113663 40 0.000021 99 0.832474";
@tempAry = @{ $word2vec->ConvertRawSparseTextToVectorDataAry( $data ) };
ok( @tempAry == 100 && $tempAry[0] == 0.235023 && $tempAry[15] == 0.113663 && $tempAry[40] == 0.000021 && $tempAry[99] == 0.832474 );
undef( @tempAry );

my %tempHash = %{ $word2vec->ConvertRawSparseTextToVectorDataHash( $data ) };
ok( keys( %tempHash ) == 4 && $tempHash{0} == 0.235023 && $tempHash{15} == 0.113663 && $tempHash{40} == 0.000021 && $tempHash{99} == 0.832474 );
undef( %tempHash );

ok( defined( $word2vec->GetOSType() ) );

$word2vec->ClearVocabularyHash();

# Sparse Vector Manipulation Test
# Simulate Loading Sparse Vector File In Memory
ok( $word2vec->IsVectorDataInMemory() == 0 );
ok( $word2vec->AddWordVectorToVocabHash( $data ) );
$word2vec->SetVectorLength( 100 );
$word2vec->SetSparseVectorMode( 1 );
ok( $word2vec->IsVectorDataInMemory() == 1 );
ok( $word2vec->IsVectorDataInMemory() == 1 );

ok( defined( $word2vec->GetWordVector( "word" ) ) && length( $word2vec->GetWordVector( "word" ) ) > 0 );
ok( defined( $word2vec->GetWordVector( "word", 1 ) ) && $word2vec->GetWordVector( "word", 1 ) eq $data );
undef( $data );


# Clean Up
$word2vec->ClearVocabularyHash();
unlink( "vectors.bin" )       if ( -e "vectors.bin" );
unlink( "sparsevectors.bin" ) if ( -e "sparsevectors.bin" );
unlink( "binaryvectors.bin" ) if ( -e "binaryvectors.bin" );
unlink( "densevectors.bin" )  if ( -e "densevectors.bin" );

undef( $word2vec );