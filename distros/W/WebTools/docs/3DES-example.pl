###############################################
# EnCript/DeCript Test Program by Julian Lishev
###############################################
# Don`t forgot to show the right path to module!
# use lib '......';
use TripleDES;

 $crpt = EncriptData("secret_credit_card=4557024001932895","Unhackable_password");
 print "My data now is crypted like: $crpt\n";

 $decrpt = DecriptData($crpt,"Unhackable_password");
 print "Now we read decripted value via password: $decrpt\n";
 
1;