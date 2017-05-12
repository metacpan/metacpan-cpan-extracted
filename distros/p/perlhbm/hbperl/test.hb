:lib ./perl.so

:out main
<perl.code _=code param="It works">
:

:set code
$args->adds("Argument: ".$args->arg("param")."\\n");
$args->adds("Address:  ".$args->remote_addr()."\\n");
:
