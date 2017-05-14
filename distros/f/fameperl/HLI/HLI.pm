# Fame/HLI.pm
#
# Copyright 1995-1997 by Fernando Trias
#

package Fame::HLI;

use strict;
use Carp;
use Exporter;
use DynaLoader;
@Fame::HLI::ISA = qw(Exporter DynaLoader);

@Fame::HLI::EXPORT = 
qw( cfmgatt cfmsatt famestart famestop fameopen fameclose fameread
famereadn famewrite famegetinfo cfmalob cfmbwdy cfmchfr cfmcldb
cfmcpob cfmdatd cfmdatf cfmdati cfmdatl cfmdatp cfmdatt cfmddat
cfmddes cfmddoc cfmdlen cfmdlob cfmfame cfmfdat cfmfdiv cfmferr
cfmfin cfmgali cfmgaso cfmgdat cfmgdba cfmgdbd cfmglen cfmgnam
cfmgsln cfmidat cfmini cfminwc cfmisbm cfmisdm cfmislp cfmisnm
cfmispm cfmissm cfmlali cfmlaso cfmlatt cfmldat cfmlerr cfmlsts
cfmncnt cfmnlen cfmnwob cfmnxwc cfmopdb cfmopre cfmopwk cfmosiz
cfmpack cfmpdat cfmpfrq cfmpind cfmpinm cfmpiny cfmpodb cfmrdfa
cfmrdfm cfmrdnl cfmrmev cfmrnob cfmrrng cfmrsdb cfmrstr cfmsali
cfmsaso cfmsbas cfmsbm cfmsdes cfmsdm cfmsdoc cfmsfis cfmsinp
cfmsnm cfmsobs cfmsopt cfmspm cfmsrng cfmssln cfmtdat cfmtody
cfmufrq cfmver cfmwhat cfmwkdy cfmwrng cfmwstr cfmwtnl famegettype
hlierr getsta getcls gettyp getbas getobs getfrq);

sub AUTOLOAD {
    local($Fame::HLI::constname, $Fame::HLI::val);
    ($Fame::HLI::constname = $Fame::HLI::AUTOLOAD) =~ s/.*:://;
    # print STDERR "find $Fame::HLI::AUTOLOAD\n";
    $Fame::HLI::val = &Fame::HLI::constant($Fame::HLI::constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $Fame::HLI::AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
            Carp::croak("Your vendor has not defined Fame macro $Fame::HLI::constname, used");
        }
    }
    eval "sub $Fame::HLI::AUTOLOAD { $Fame::HLI::val }";
    goto &$Fame::HLI::AUTOLOAD;
}

package Fame::HLI::var_status; sub t { }
package Fame::HLI::var_version; sub t { }

package Fame::HLI;

bootstrap Fame::HLI;

tie $Fame::HLI::status, "Fame::HLI::var_status", "status";
tie $Fame::HLI::version, "Fame::HLI::var_version", "version";

package Fame::HLI;
# HLI.pm version number
sub version {2.1;}

1;
