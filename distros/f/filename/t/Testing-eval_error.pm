# A valid Perl file that sets $@ and returns false
$@ = "Something went very wrong";
undef;
