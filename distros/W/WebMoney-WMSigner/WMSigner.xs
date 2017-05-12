#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"

#ifdef __cplusplus
}
#endif

#include "signer.h"

char* sign( char *chLogin, char *chPwd, char *chFileName, char *chIn )
{
    char szError[80];
    szptr szSign;

    /* printf("%d, %d, %d, %d\n", chLogin, chPwd, chFileName, chIn ); */

    /* hacks to make buggy linkers happy */
    szptr szLogin( chLogin );
    szptr szPwd( chPwd );
    szptr szFileName( chFileName );
    szptr szIn( chIn );

    Signer sign(szLogin, szPwd, szFileName);
    if (sign.Sign(szIn, szSign))
    {
	const char *result = szSign;
	return strdup( result );
    }
    else
    {
	sprintf(szError, "Error %d\n", sign.ErrorCode());
	return strdup( szError );
    }
}

MODULE = WebMoney::WMSigner		PACKAGE = WebMoney::WMSigner

char*
sign( chLogin, chPwd, chFileName, chIn )
    char * chLogin
    char * chPwd
    char * chFileName
    char * chIn
