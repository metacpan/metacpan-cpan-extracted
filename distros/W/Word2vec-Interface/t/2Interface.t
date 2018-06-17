use strict;
use warnings;
use 5.010;
 
use Test::Simple tests => 74;
use Word2vec::Interface;

my $interface = Word2vec::Interface->new();


# Basic Method Testing (Test Accessor Functions)
ok( defined( $interface ) );
ok( defined( $interface->GetWord2VecDir() ) );
ok( $interface->GetDebugLog() == 0 );
ok( $interface->GetWriteLog() == 0 );
ok( defined( $interface->GetIgnoreCompileErrors() ) );      # Default setting changes depending on OS
ok( $interface->GetIgnoreFileChecks() == 0 );
ok( $interface->GetExitFlag() == 1 );
ok( !defined( $interface->GetFileHandle() ) );
ok( defined( $interface->GetWorkingDirectory() ) );
ok( defined( $interface->GetWord2VecHandler() ) );
ok( defined( $interface->GetWord2PhraseHandler() ) );
ok( defined( $interface->GetXMLToW2VHandler() ) );
ok( $interface->GetInstanceAry() == 0 );
ok( $interface->GetSenseAry() == 0 );
ok( $interface->GetInstanceCount() == 0 );
ok( $interface->GetSenseCount() == 0 );


# Basic Method Testing ( Test Mutator Functions )
my $w2vPath = $interface->GetWord2VecDir();
$interface->SetWord2VecDir( "test/path" );
ok( $interface->GetWord2VecDir() eq "test/path" );
$interface->SetWord2VecDir( $w2vPath );
undef( $w2vPath );

$interface->SetDebugLog( 1 );
ok( $interface->GetDebugLog() == 1 );
$interface->SetDebugLog( 0 );

$interface->SetWriteLog( 1 );
ok( $interface->GetWriteLog() == 1 );
$interface->SetWriteLog( 0 );

$interface->SetIgnoreCompileErrors( 1 );
ok( $interface->GetIgnoreCompileErrors() == 1 );

$interface->SetIgnoreFileCheckErrors( 1 );
ok( $interface->GetIgnoreFileChecks() == 1 );
$interface->SetIgnoreFileCheckErrors( 0 );

$interface->SetWorkingDirectory( "test/path" );
ok( $interface->GetWorkingDirectory() eq "test/path" );
$interface->SetWorkingDirectory( Cwd::getcwd() );

# Test Getting and Setting Instance Ary w/ WSDData object
my $wsdData = new WSDData();
$wsdData->contextStr( "Cookie" );
my @tempAry = ( $wsdData );
$interface->SetInstanceAry( \@tempAry );
undef( @tempAry );
@tempAry = $interface->GetInstanceAry();
ok( @tempAry > 0 && $tempAry[0]->contextStr eq "Cookie" );
$interface->ClearInstanceAry();
@tempAry = $interface->GetInstanceAry();
ok( @tempAry == 0 );

# Test Getting and Setting Sense Ary w/ WSDData object
@tempAry = ( $wsdData );
$interface->SetSenseAry( \@tempAry );
undef( @tempAry );
@tempAry = $interface->GetSenseAry();
ok( @tempAry > 0 && $tempAry[0]->contextStr eq "Cookie" );
$interface->ClearSenseAry();
@tempAry = $interface->GetSenseAry();
ok( @tempAry == 0 );

$interface->SetInstanceCount( 12 );
ok( $interface->GetInstanceCount() == 12 );
$interface->SetInstanceCount( 0 );

$interface->SetSenseCount( 12 );
ok( $interface->GetSenseCount() == 12 );
$interface->SetSenseCount( 0 );

ok( defined( $interface->GetTime() ) );
ok( defined( $interface->GetDate() ) );


# Advanced Function Testing (Module Functions)
ok( $interface->RunFileChecks( $interface->GetWord2VecDir() ) == 1 );

my @fileNameVtr = qw( compute-accuracy distance word2phrase word2vec word-analogy );

for my $fileName ( @fileNameVtr )
{
    ok( $interface->_CompileSourceFile( $interface->GetWord2VecDir(), $fileName ) == 1 ) if ( $fileName ne "word2vec" );
}

for my $fileName ( @fileNameVtr )
{
    ok( $interface->_CheckIfSourceFileExists( $interface->GetWord2VecDir(), $fileName ) == 1 );
}

for my $fileName ( @fileNameVtr )
{
    ok( $interface->_CheckIfExecutableFileExists( $interface->GetWord2VecDir(), $fileName ) == 1 );
}

ok( defined( $interface->GetFileType( "samples/compoundword.txt" ) ) );
ok( defined( $interface->GetOSType() ) );


# Advanced Function Testing (Text Corpus Generation With Compoundify)
my %optionsHash = (
    "-workdir"      => "samples",
    "-savedir"      => "textcorpus.txt",
    "-startdate"    => "00/00/0000",
    "-enddate"      => "99/99/9999",
    "-title"        => 1,
    "-abstract"     => 1,
    "-qparse"       => 1,
    "-compwordfile" => "samples/compoundword.txt",
    "-threads"      => 2,
    "-overwrite"    => 1,
);
ok( $interface->CLCompileTextCorpus( \%optionsHash ) == 0 );
ok( -e "textcorpus.txt" && -s "textcorpus.txt" );
undef( %optionsHash );

# Advanced Function Testing (Word2Phrase Training)
%optionsHash = (
    "-trainfile"  => "textcorpus.txt",
    "-outputfile" => "phrasecorpus.txt",
    "-min-count"  => 1,
    "-threshold"  => 10,
    "-debug"      => 0,
    "-overwrite"  => 1,
);
ok( $interface->CLStartWord2PhraseTraining( \%optionsHash ) == 0 );
ok( -e "phrasecorpus.txt" && -s "phrasecorpus.txt" );
undef( %optionsHash );

# Advanced Function Testing (Word2Vec Training)
%optionsHash = (
    "-trainfile"  => "textcorpus.txt",
    "-outputfile" => "vectors.bin",
    "-binary"     => 0,
    "-debug"      => 0,
    "-overwrite"  => 1,
);
ok( $interface->CLStartWord2VecTraining( \%optionsHash ) == 0 );
ok( -e "vectors.bin" && -s "vectors.bin" );
undef( %optionsHash );

# Advanced Function Testing (Similarity Functions)
ok( defined( $interface->CLComputeCosineSimilarity( "vectors.bin", "of", "the" ) ) );
ok( defined( $interface->CLComputeMultiWordCosineSimilarity( "vectors.bin", "of", "the" ) ) );
ok( defined( $interface->CLComputeMultiWordCosineSimilarity( "vectors.bin", "of and", "the and" ) ) );
ok( defined( $interface->CLComputeAvgOfWordsCosineSimilarity( "vectors.bin", "of and", "the and" ) ) );
ok( defined( $interface->CLAddTwoWordVectors( "vectors.bin", "of", "the" ) ) );
ok( defined( $interface->CLSubtractTwoWordVectors( "vectors.bin", "of", "the" ) ) );

# Advanced Function Testing (Converting Dense Vector Data To Binary)
ok( $interface->CLConvertWord2VecVectorFileToBinary( "vectors.bin", "binaryvectors.bin" ) == 0 );
ok( $interface->CLConvertWord2VecVectorFileToSparse( "binaryvectors.bin", "sparsevectors.bin" ) == 0 );
ok( $interface->CLConvertWord2VecVectorFileToText( "sparsevectors.bin", "densevectors.bin" ) == 0 );

# Advanced Function Testing (Compoundify Text In File)
ok( $interface->CLCompoundifyTextInFile( "samples/precompoundexample.txt", "compoundedtext.txt", "samples/compoundword.txt" ) == 0 );
ok( -e "compoundedtext.txt" && -s "compoundedtext.txt" );

# Advanced Function Testing (Similarity Average, Compounds & Summed)
$interface->W2VReadTrainedVectorDataFromFile( "vectors.bin" );
ok( $interface->CLSimilarityAvg( "samples/MiniMayoSRS.terms" ) == 0 );
ok( -e "MiniMayoSRS.terms.avg_results" && -s "MiniMayoSRS.terms.avg_results" );
ok( $interface->CLSimilarityComp( "samples/MiniMayoSRS.terms" ) == 0 );
ok( -e "MiniMayoSRS.terms.comp_results" && -s "MiniMayoSRS.terms.comp_results" );
ok( $interface->CLSimilaritySum( "samples/MiniMayoSRS.terms" ) == 0 );
ok( -e "MiniMayoSRS.terms.sum_results" && -s "MiniMayoSRS.terms.sum_results" );


# Generate WSD List
my $wsdTestList =
"
########################################################
#                                                      #
# Format: instance_file sense_file                     #
#   --vectors vector_binary_file                       #
#   --stoplist stoplist_file                           #
#                                                      #
# Sample: instance1.file sense1.file                   #
#   instance2.file sense2.file                         #
#   ...                                                #
#   instanceN.file senseN.file                         #
#   --vectors vectors.bin                           #
#   --stoplist stoplist.txt                            #
#                                                      #
########################################################
#
# Real working example below.
# Note: Number/Pound '#' character ignores line.

-vectors vectors.bin
-stoplist samples/stoplist
samples/ACE.instances.sval samples/ACE.senses.sval
";

open( my $fileHandle, ">:encoding(utf8)", "wsdtestlist.txt" );
print( $fileHandle $wsdTestList );
close( $fileHandle );
undef( $fileHandle );
undef( $wsdTestList );

# Advanced Function Testing (Word Sense Disambiguation)
ok( $interface->CLWordSenseDisambiguation( "samples/ACE.instances.sval", "samples/ACE.senses.sval", "vectors.bin", "samples/stoplist", undef ) == 0 );
ok( $interface->CLWordSenseDisambiguation( undef, undef, "vectors.bin", undef, "wsdtestlist.txt" ) == 0 );

# Advanced Function Testing (WSD Read List)
ok( keys( %{ $interface->_WSDReadList( "wsdtestlist.txt" ) } ) > 0 );

# Advanced Function Testing (Stop List Generation)
ok( defined( $interface->_WSDStop( "samples/stoplist" ) ) );


# Clean Up
unlink( "textcorpus.txt"                         ) if ( -e "textcorpus.txt"                             );
unlink( "phrasecorpus.txt"                       ) if ( -e "phrasecorpus.txt"                           );
unlink( "vectors.bin"                            ) if ( -e "vectors.bin"                                );
unlink( "binaryvectors.bin"                      ) if ( -e "binaryvectors.bin"                          );
unlink( "densevectors.bin"                       ) if ( -e "densevectors.bin"                           );
unlink( "sparsevectors.bin"                      ) if ( -e "sparsevectors.bin"                          );
unlink( "compoundedtext.txt"                     ) if ( -e "compoundedtext.txt"                         );
unlink( "wsdtestlist.txt"                        ) if ( -e "wsdtestlist.txt"                            );
unlink( "MiniMayoSRS.terms.avg_results"          ) if ( -e "MiniMayoSRS.terms.avg_results"              );
unlink( "MiniMayoSRS.terms.comp_results"         ) if ( -e "MiniMayoSRS.terms.comp_results"             );
unlink( "MiniMayoSRS.terms.sum_results"          ) if ( -e "MiniMayoSRS.terms.sum_results"              );
unlink( "samples/ACE.instances.sval.results.txt" ) if ( -e "samples/ACE.instances.sval.results.txt"     );

undef( $interface );