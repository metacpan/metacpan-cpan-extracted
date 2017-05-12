<?php
/**
 * PHP : 5.2.6-3
 * PHP-SOAP : 0.11
 *
 * $Id: website-getall.php,v 1.1 2008-09-03 18:46:02 cvscore Exp $
 */

class soap_header {
 private $apikey;
 public function __construct ( $apikey ) {
  $this->apikey = $apikey;
 }
}

$host		= 'YOUR_API_HOST';
$apikey		= 'YOUR_API_KEY';
$login_hdr	= new soap_header( $apikey );
$login_hdr_v	= new SoapVar($login_hdr, SOAP_ENC_OBJECT);
$header		= new SoapHeader("EA", "SOAP-ENV", $login_hdr_v, false);

$soap 		= new SoapClient(null, array(
 location      => $host.'/ea/v1/Website',
 uri           => 'Website' )
);

// getAll
$result  	= $soap->__soapCall("getAll", array(), null, $header);

foreach ( $result as $hash ) {
 echo "--- website_name=".$hash->website_name."\n";
}

?>
