use XML::BMEcat;
use File::Basename;


my $BMEcat = XML::BMEcat->new();

$BMEcat->setOutfile("catalog.xml");


my $Header = $BMEcat->creatHeader();

$Header->setTransaction('T_NEW_CATALOG', [ 'prev_version' => '1.0' ]);

my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);

$Header->setGeneralInfo(
			'GENERATOR_INFO'	=> "created by " . basename($0),
         		'LANGUAGE'		=> 'DEU',
         		'CATALOG_ID'		=> 6,
         		'CATALOG_VERSION'	=> 100,
         		'CATALOG_NAME'		=> "fischer BEFESTIGUNGSSYSTEME",
         		'DATE'			=> sprintf ("%4d-%02d-%02d",1900+$year,++$mon,$mday),
         		'TIME'			=> sprintf ("%02d:%02d:%02d",$hour,$min,$sec),
         		'CURRENCY'		=> 'DEM',
         		'MIME_ROOT'		=> "/images"
		   );

$Header->setBuyerInfo(
			'BUYER_ID'		=> "0815",
         		'BUYER_NAME'		=> 'FOO',
         		'NAME'			=> "FOO CORPORATION",
         		'STREET'		=> "Business Street 17",
         		'ZIP'			=> 01234,
         		'CITY'			=> 'New York',
         		'COUNTRY'		=> 'USA',
         		'EMAIL'			=> "info\@foo-bussines.com",
         		'URL'			=> "http://www.foo-bussines.com"
		   );

$Header->setAgreementInfo(
			'AGREEMENT_ID'		=> '4711',
         		'AGREEMENT_start_date'	=> "2000-01-01",
         		'AGREEMENT_end_date'	=> "2000-12-31"
		   );

$Header->setSupplierInfo(
			'SUPPLIER_ID'		=> "1",
         		'SUPPLIER_NAME'		=> "fischer",
         		'NAME'			=> "fischerwerke",
         		'NAME2'			=> "Artur Fischer Gmbh & Co KG",
         		'CONTACT'		=> "",
         		'STREET'		=> "Weinhalde 14 - 18",
         		'ZIP'			=> 72178,
         		'CITY'			=> Waldachtal,
         		'COUNTRY'		=> Germany,
         		'PHONE'			=> "+49 7443 12 0",
         		'FAX'			=> "+49 7443 12 42 22",
         		'EMAIL'			=> "info\@fischerwerke.com",
         		'URL'			=> "http://www.fischerwerke.com"
		   );

$Header->setConfigInfo( 'VERSION'               => '1.2',
			'FEATURE_SYSTEM_NAME'	=> 'ECLASS-4.0',
			'VERBOSE'		=> 0,
			'CHAR_SET'		=> 'ISO-8859-1',
			'DTD'			=> 'bmecat_new_catalog.dtd'
		   );

$BMEcat->writeHeader();


$Header->setConfigInfo('FEATURE_SYSTEM_NAME'	=> 'Generic');

my $FeatureSystem = $BMEcat->creatFeatureSystem();

$FeatureSystem->addFeatureGroup( '116',
			'URL'						=> "",
			'Länge'						=> "mm",
			'min. Dicke bis zu ersten Trägerschichten'	=> "mm",
			'Typ'						=> ""
		   );

$BMEcat->writeFeatureSystem();


$Header->setConfigInfo('GROUP_SYSTEM_ID'	=> '01-1-00/01');

my $GroupSystem = $BMEcat->creatGroupSystem();

my $CatalogGroup = $GroupSystem->creatCatalogGroup('02');
$CatalogGroup->setData(	'PARENT'	=>	0,
			'NAME'		=>	"fischer Befestigungskatalog",
			'SORT'		=>	5 );

$CatalogGroup = $GroupSystem->creatCatalogGroup('04');
$CatalogGroup->setData(	'PARENT'	=>	2,
		   	'NAME'		=>	"Allgemeine Befestigungen",
			'SORT'		=>	5 );

$CatalogGroup = $GroupSystem->creatCatalogGroup('06');
$CatalogGroup->setData(	'PARENT'	=>	2,
		   	'NAME'		=>	"Hohlraumbefestigungen",
			'SORT'		=>	10 );

$CatalogGroup = $GroupSystem->creatCatalogGroup('08');
$CatalogGroup->setData(	'PARENT'	=>	4,
			'NAME'		=>	"fischer Gipskartondübel GK",
			'SORT'		=>	5,
			'LEAF'		=>      1 );
$CatalogGroup->addDescription("inkl. 1 Setzwerkzeug");
$CatalogGroup->addMime('image/jpg', "fis101274.jpg", "normal");

$CatalogGroup = $GroupSystem->creatCatalogGroup('10');
$CatalogGroup->setData(	'PARENT'	=>	4,
			'NAME'		=>	"fischer Gipskartondübel GKM",
			'SORT'		=>	10,
			'LEAF'		=>      1 );

$BMEcat->writeGroupSystem();


my $ArticleSystem = $BMEcat->creatArticleSystem();

my $Article = $ArticleSystem->creatArticle('52389');

$Article->setMainInfo(  'mode'		=>	'new',
			'SUPPLIER_AID'  =>	'52389' );

$Article->setFeatureGroup('116');

$Article->setFeatureValues(
		'http://www.fischerwerke.de/kioskdt/nn3/produkte_frame.asp?id=54&amp;u=befestigung.asp&amp;m=Hohlraum-Befestigungen&amp;m2=fischer-Gipskartondübel GK&amp;pgrpid=8&amp;g=Innovative Befestigungslsg.',
		'22', 
		'25',
		'GK'
	);

$Article->addMime('image/jpg', '4006209523896.jpg', 'normal');


$DESCRIPTION_LONG = <<'--end--';
Der fischer Gipskartondübel GK ist ein Spezialdübel, der
mit dem beigefügten Setzwerkzeug nicht hinter der Platte,
sondern formschlüssig in die Gipskartonplatte eingedreht
wird. Dadurch wird hinter der Platte nur wenig Platz benötigt.
--end--

$Article->setDetails(
		'DESCRIPTION_SHORT'	=> 'Der Schnellmontagedübel für Gipskarton',
		'DESCRIPTION_LONG'	=> $DESCRIPTION_LONG,
		'EAN'			=> '4006209523896'
	   );

$Article->setOrderDetails(
		'ORDER_UNIT'		=> "Pkg.",
		'CONTENT_UNIT'		=> "Stk.",
		'NO_CU_PER_OU'		=> 100
	   );

$Article->setPriceDetails(
		'valid_start_date'	=> '1999-10-01',
		'valid_end_date'	=> '2000-09-31'
	   );


$Article->addPrice(
		'price_type'		=> 'net_list',
		'PRICE_AMOUNT'		=> '50,00',
		'PRICE_CURRENCY'	=> 'EUR'
	   );

$BMEcat->writeArticleSystem();


$Article->map2Group("08");

$BMEcat->writeArticleGroupMap();


$BMEcat->writeTail();