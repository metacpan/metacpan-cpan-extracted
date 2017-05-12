use WebSphere::Payment;

$ordernumber = int (rand 1000);
$merchantnumber = 11;
$amount = 1000;
$yyyydd = 200309;
$cardnumber = '4111111111111111';
$cardtype = 'VISA';
$description = 'Test';
$cvv2 = 123;

$cashregister = new WebSphere::Payment($pmurl,$admin);
$paystubref = {merchantnumber => $merchantnumber,
               ordernumber => $ordernumber,
               approveflag => 1,
               depositflag => 0,
               amount => $amount,
               '%24expiry' => $yyyydd,
               '%24pan' => $cardnumber,
               '%24brand' => $cardtype,
               '%24orderdescription' => $description,
               '%24cardverifycodes' => $cvv2};

$cashregister->close();





