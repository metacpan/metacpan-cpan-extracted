use strict;
use warnings;
use 5.010;
 
use Test::Simple tests => 82;
use Word2vec::Xmltow2v;

my $xmltow2v = Word2vec::Xmltow2v->new();


# Basic Method Testing (Test Accessor Functions)
ok( defined( $xmltow2v ) );
ok( $xmltow2v->GetDebugLog() == 0 );
ok( $xmltow2v->GetWriteLog() == 0 );
ok( $xmltow2v->GetBeginDate() eq "00/00/0000" );
ok( $xmltow2v->GetEndDate() eq "99/99/9999" );
ok( $xmltow2v->_DateCheck() == 0 );
ok( $xmltow2v->GetCompoundifyText() == 0 );
ok( $xmltow2v->GetStoreAsSentencePerLine() == 0 );
ok( defined( $xmltow2v->GetCompoundWordAry() ) && $xmltow2v->GetCompoundWordAry() == 0 );
ok( defined( $xmltow2v->GetCompoundWordBST() ) );
ok( !defined( $xmltow2v->GetFileHandle() ) );
ok( $xmltow2v->GetDate() ne "" );
ok( $xmltow2v->GetTime() ne "" );
ok( defined( $xmltow2v->GetFileType( "samples/compoundword.txt" ) ) );
ok( $xmltow2v->GetMaxCompoundWordLength() == 20 );
ok( $xmltow2v->GetNumOfThreads() == Sys::CpuAffinity::getNumCpus() );
ok( $xmltow2v->GetOverwriteExistingFile() == 0 );
ok( $xmltow2v->GetParsedCount() == 0 );
ok( $xmltow2v->GetQuickParse() == 0 );
ok( $xmltow2v->GetSavePath() ne "" );
ok( $xmltow2v->GetStoreAbstract() == 1 );
ok( $xmltow2v->GetStoreTitle() == 1 );
ok( $xmltow2v->GetTempDate() eq "" );
ok( $xmltow2v->GetTempStr() eq "" );
ok( $xmltow2v->GetTextCorpusStr() eq "" );
ok( defined( $xmltow2v->GetTwigHandler() ) );
ok( $xmltow2v->GetXMLStringToParse() eq "(null)" );
ok( $xmltow2v->IsDateInSpecifiedRange( "08/13/2016" ) == 1 );
ok( $xmltow2v->IsFileOrDirectory( ".." ) eq "dir" );
ok( $xmltow2v->IsFileOrDirectory( "samples/compoundword.txt" ) eq "file" );
ok( $xmltow2v->RemoveSpecialCharactersFromString( "!@#\$%^&*()_+=-{}[]:\"';<>?/|\\a" ) eq "a" );

# Basic Method Testing (Test Mutator Functions)
$xmltow2v->SetBeginDate( "01/01/2004" );
ok( $xmltow2v->GetBeginDate() eq "01/01/2004" );
ok( $xmltow2v->_DateCheck() == 0 );
$xmltow2v->SetBeginDate( "00/00/0000" );

$xmltow2v->SetEndDate( "08/13/2016" );
ok( $xmltow2v->GetEndDate() eq "08/13/2016" );
ok( $xmltow2v->_DateCheck() == 0 );
$xmltow2v->SetEndDate( "99/99/9999" );

$xmltow2v->SetCompoundifyText( 1 );
ok( $xmltow2v->GetCompoundifyText() == 1 );

$xmltow2v->SetStoreAsSentencePerLine( 1 );
ok( $xmltow2v->GetStoreAsSentencePerLine() == 1 );
$xmltow2v->SetStoreAsSentencePerLine( 0 );

$xmltow2v->SetMaxCompoundWordLength( 12 );
ok( $xmltow2v->GetMaxCompoundWordLength() == 12 );
$xmltow2v->SetMaxCompoundWordLength( 20 );

$xmltow2v->SetOverwriteExistingFile( 1 );
ok( $xmltow2v->GetOverwriteExistingFile() == 1 );

$xmltow2v->SetQuickParse( 1 );
ok( $xmltow2v->GetQuickParse() == 1 );

$xmltow2v->SetSavePath( "save/path" );
ok( $xmltow2v->GetSavePath() eq "save/path" );
$xmltow2v->SetSavePath( "" );

$xmltow2v->SetStoreAbstract( 1 );
ok( $xmltow2v->GetStoreAbstract() == 1 );

$xmltow2v->SetStoreTitle( 1 );
ok( $xmltow2v->GetStoreTitle() == 1 );

$xmltow2v->SetTempDate( "99/99/9999" );
ok( $xmltow2v->GetTempDate() eq "99/99/9999" );
$xmltow2v->SetTempDate( "" );

$xmltow2v->SetTempStr( "test" );
ok( $xmltow2v->GetTempStr() eq "test" );
$xmltow2v->SetTempStr( "" );

$xmltow2v->SetTextCorpusStr( "text corpus" );
ok( $xmltow2v->GetTextCorpusStr() eq "text corpus" );
$xmltow2v->SetTextCorpusStr( "" );

$xmltow2v->SetXMLStringToParse( "parse me" );
ok( $xmltow2v->GetXMLStringToParse() eq "parse me" );
$xmltow2v->SetXMLStringToParse( "" );


# Advanced Method Testing
$xmltow2v->SetBeginDate( "-01/01/2004" );
ok( $xmltow2v->GetBeginDate() eq "-01/01/2004" );
ok( $xmltow2v->_DateCheck() == -1 );

$xmltow2v->SetBeginDate( "01/-01/2004" );
ok( $xmltow2v->GetBeginDate() eq "01/-01/2004" );
ok( $xmltow2v->_DateCheck() == -1 );

$xmltow2v->SetBeginDate( "01/01/-2004" );
ok( $xmltow2v->GetBeginDate() eq "01/01/-2004" );
ok( $xmltow2v->_DateCheck() == -1 );

$xmltow2v->SetBeginDate( "01/01/2004" );
ok( $xmltow2v->GetBeginDate() eq "01/01/2004" );
$xmltow2v->SetEndDate( "08/13/2016" );
ok( $xmltow2v->GetEndDate() eq "08/13/2016" );
ok( $xmltow2v->_DateCheck() == 0 );

$xmltow2v->SetBeginDate( "01/13/2017" );
ok( $xmltow2v->GetBeginDate() eq "01/13/2017" );
ok( $xmltow2v->_DateCheck() == -1 );

$xmltow2v->SetBeginDate( "09/14/2016" );
ok( $xmltow2v->GetBeginDate() eq "09/14/2016" );
ok( $xmltow2v->_DateCheck() == -1 );

$xmltow2v->SetBeginDate( "08/14/2016" );
ok( $xmltow2v->GetBeginDate() eq "08/14/2016" );
ok( $xmltow2v->_DateCheck() == -1 );

$xmltow2v->SetBeginDate( "08/13/2016" );
ok( $xmltow2v->GetBeginDate() eq "08/13/2016" );
ok( $xmltow2v->_DateCheck() == 0 );

$xmltow2v->SetBeginDate( "00/00/0000" );
$xmltow2v->SetEndDate( "99/99/9999" );


# Advanced Method Testing (Read Compound Word Text Into Memory)
ok( $xmltow2v->ReadCompoundWordDataFromFile( "samples/compoundword.txt", 1 ) == 0 );
ok( $xmltow2v->SaveCompoundWordListToFile( "compWordFile.txt" ) == 0 );
unlink( "compWordFile.txt" ) if ( -e "compWordFile.txt" );
ok( $xmltow2v->CreateCompoundWordBST() == 0 );


# Advanced Method Testing (Compoundify String)
my $str1 = "STUDIES ON GANGRENE FOLLOWING COLD INJURY IV THE USE OF FLUORESCEIN AS AN INDICATOR OF LOCAL BLOOD FLOW DISTRIBUTION OF FLUORESCEIN IN BODY FLUIDS AFTER INTRAVENOUS INJECTION";
my $str2 = "The boot beef man American journal of obstetrics and vascular ray diseases of women and children pack riding";
my $str3 = "A Direct Demonstration of the Phosphorus Cycle in a Small Lake";
my $str4 = "dimethylbenzimidazole was transformed by a growing culture of Propionibacterium shermanii into";
my $str5 = "With this new knowledge comes better management In a very short period of time both doctors and patients have swung from a mood of deep despondency to optimism and hopefulness";
my $str6 = "A case of suspected malignant hyperthermia in a 13 month old female to whom succinylcholine was not administered is presented The patient presented for a repair of the right radial nerve under general anesthesia Induction was accomplished with halothane nitrous oxide and oxygen Tracheal intubation was facilitated with intravenous vecuronium Controlled ventilation was initiated and anesthesia was maintained with isoflurane nitrous oxide oxygen morphine sulfate and vecuronium At the conclusion of the surgical procedure an abrupt increase in ETCO2 an elevation in body temperature and a mixed acidosis was observed Resolution of symptoms followed the administration of dantrolene sodium The patient underwent an uneventful postoperative recovery and was discharged home It was felt that the patient was too young to undergo a muscle biopsy for a caffeine halothane stimulation test";
my $str7 = "both qi and blood from National Standard for Chinese Patent Drugs NSCPD enacted by Ministry of Public Health of China";
my $str8 = "in the new someone did not see me in the samus in that book in that location in the end which was not in the end";
my $str9 = "the american indian did and so he went to take to and up to the trade union close to the popular front";
my $str10 = "english revolution french revolution in place working class zeno of citium bertrand russell holy spirit arrive at english civil war modern era american indian and so pierre joseph proudhon";

$str1 = $xmltow2v->CompoundifyString( lc( $str1 ) );
$str2 = $xmltow2v->CompoundifyString( lc( $str2 ) );
$str3 = $xmltow2v->CompoundifyString( lc( $str3 ) );
$str4 = $xmltow2v->CompoundifyString( lc( $str4 ) );
$str5 = $xmltow2v->CompoundifyString( lc( $str5 ) );
$str6 = $xmltow2v->CompoundifyString( lc( $str6 ) );
$str7 = $xmltow2v->CompoundifyString( lc( $str7 ) );
$str8 = $xmltow2v->CompoundifyString( lc( $str8 ) );
$str9 = $xmltow2v->CompoundifyString( lc( $str9 ) );
$str10 = $xmltow2v->CompoundifyString( lc( $str10 ) );

ok( $str1 eq "studies on gangrene following cold injury iv the use of fluorescein as an indicator of local blood flow distribution of fluorescein in body fluids after intravenous_injection " );
ok( $str2 eq "the_boot beef_man american journal of obstetrics and vascular_ray diseases of women and children pack_riding " );
ok( $str3 eq "a direct demonstration of the phosphorus cycle in a small lake " );
ok( $str4 eq "dimethylbenzimidazole was transformed by a growing culture of propionibacterium shermanii into " );
ok( $str5 eq "with this new knowledge comes better management in a very short period_of_time both doctors and patients have swung from a mood of deep despondency to optimism and hopefulness " );
ok( $str6 eq "a case of suspected malignant_hyperthermia in a 13 month old female to whom succinylcholine was not administered is presented the patient presented for a repair of the right radial_nerve under general_anesthesia induction was accomplished with halothane nitrous_oxide and oxygen tracheal intubation was facilitated with intravenous vecuronium controlled ventilation was initiated and anesthesia was maintained with isoflurane nitrous_oxide oxygen morphine sulfate and vecuronium at the conclusion of the surgical_procedure an abrupt increase in etco2 an elevation in body_temperature and a mixed acidosis was observed resolution of symptoms followed the administration of dantrolene sodium the patient underwent an uneventful postoperative recovery and was discharged home it was felt that the patient was too young to undergo a muscle biopsy for a caffeine halothane stimulation test " );
ok( $str7 eq "both qi and blood from national standard for chinese patent drugs nscpd enacted by ministry of public health of china " );
ok( $str8 eq "in the new someone did not see me in the samus in_that book in_that_location in_the_end which was not in_the_end " );
ok( $str9 eq "the american_indian did and_so he went to take_to and up_to the trade_union close_to the popular_front " );
ok( $str10 eq "english_revolution french_revolution in_place working_class zeno_of_citium bertrand_russell holy_spirit arrive_at english_civil_war modern_era american_indian and_so pierre_joseph_proudhon " );


# Advanced Method Testing (Compoundify File)
my $fileData = $xmltow2v->ReadTextFromFile( "samples/precompoundexample.txt" );
ok( defined( $fileData ) && $fileData ne "" );
ok( $xmltow2v->SaveTextToFile( "compfile.txt", $xmltow2v->CompoundifyString( lc( $fileData ) ) ) == 0 );
ok( -e "compfile.txt" && -s "compfile.txt" );
unlink( "compfile.txt" );

# Advanced Method Testing (Compile Text Corpus w/ Compoundify)
$xmltow2v->SetSavePath( "textcorpus.txt" );
ok( $xmltow2v->ConvertMedlineXMLToW2V( "samples" ) == 0 );
ok( -e "textcorpus.txt" && -s "textcorpus.txt" );
unlink( "textcorpus.txt" ) if ( -e "textcorpus.txt" );


# Clean Up
$xmltow2v->ClearCompoundWordAry();
$xmltow2v->ClearCompoundWordBST();
undef( $xmltow2v );