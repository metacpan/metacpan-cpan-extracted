use strict;
use warnings;
use 5.010;
 
use Test::Simple tests => 20;
use Word2vec::Word2phrase;

my $word2phrase = Word2vec::Word2phrase->new();


# Basic Method Testing (Test Accessor Functions)
ok( defined( $word2phrase ) );
ok( $word2phrase->GetDebugLog() == 0 );
ok( $word2phrase->GetWriteLog() == 0 );
ok( !defined( $word2phrase->GetFileHandle() ) );
ok( $word2phrase->GetTrainFilePath() eq "" );
ok( $word2phrase->GetOutputFilePath() eq "" );
ok( $word2phrase->GetMinCount() == 5 );
ok( $word2phrase->GetThreshold() == 100 );
ok( $word2phrase->GetW2PDebug() == 2 );
ok( $word2phrase->GetWorkingDir() eq Cwd::getcwd() );
ok( $word2phrase->GetWord2PhraseExeDir() ne "" );
ok( $word2phrase->GetOverwriteOldFile() == 0 );


# Basic Method Testing (Test Mutator Functions)
$word2phrase->SetTrainFilePath( "test/path" );
ok( $word2phrase->GetTrainFilePath() eq "test/path" );
$word2phrase->SetTrainFilePath( "" );

$word2phrase->SetOutputFilePath( "test/path" );
ok( $word2phrase->GetOutputFilePath() eq "test/path" );
$word2phrase->SetOutputFilePath( "" );

$word2phrase->SetMinCount( 99 );
ok( $word2phrase->GetMinCount() == 99 );
$word2phrase->SetMinCount( 5 );

$word2phrase->SetThreshold( 65535 );
ok( $word2phrase->GetThreshold() == 65535 );
$word2phrase->SetThreshold( 100 );

$word2phrase->SetW2PDebug( 0 );
ok( $word2phrase->GetW2PDebug() == 0 );

my $oldPath = $word2phrase->GetWorkingDir();
$word2phrase->SetWorkingDir( "test/path" );
ok( $word2phrase->GetWorkingDir() eq "test/path" );
$word2phrase->SetWorkingDir( $oldPath );

$oldPath = $word2phrase->GetWord2PhraseExeDir();
$word2phrase->SetWord2PhraseExeDir( "test/path" );
ok( $word2phrase->GetWord2PhraseExeDir() eq "test/path" );
$word2phrase->SetWord2PhraseExeDir( $oldPath );

$word2phrase->SetOverwriteOldFile( 1 );
ok( $word2phrase->GetOverwriteOldFile() == 1 );
$word2phrase->SetOverwriteOldFile( 0 );


# Advanced Method Testing (Word2Phrase Training)
#ok( $word2phrase->ExecuteTraining( "samples/precompoundexample.txt", "output.txt" ) == 0 );
#ok( -e "output.txt" && -s "output.txt" );
#unlink( "output.txt" ) if ( -e "output.txt" );
#
#my $trainingStr = "";
#
#open( my $fileHandle, '<:encoding(UTF-8)', "samples/precompoundexample.txt" );
#while( my $data = <$fileHandle> )
#{
#    chomp( $data );
#    $trainingStr .= $data;
#}
#close( $fileHandle );
#undef( $fileHandle );
#
#ok( $word2phrase->ExecuteStringTraining( "$trainingStr", "output.txt" ) == 0 );
#ok( -e "output.txt" && -s "output.txt" );
#unlink( "output.txt" ) if ( -e "output.txt" );
#
#
## Clean Up
#undef( $trainingStr );

undef( $word2phrase );