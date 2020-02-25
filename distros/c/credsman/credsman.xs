#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "windows.h"
#include <stdio.h>
#include <wincred.h>
#include <errno.h>
#include <wchar.h>

/*----------------------------------------------------------------------------*/
char *work_name(char *Program, char *Target){
    /* Create Credentials Work Name */
    char *TargetName = malloc(CREDUI_MAX_GENERIC_TARGET_LENGTH + 1);
    memset( TargetName, 0, CREDUI_MAX_GENERIC_TARGET_LENGTH );
    snprintf(TargetName, CREDUI_MAX_GENERIC_TARGET_LENGTH - 1,
             "*[%s]~[%s]*", Program, Target );
    return TargetName;
}
/*----------------------------------------------------------------------------*/
AV *LoadCredentials(char *TargetName){
    PCREDENTIALA pCred;
    AV* ReturnArray;
    ReturnArray = newAV();
    sv_2mortal((SV*)ReturnArray);
    if (CredReadA(TargetName, CRED_TYPE_GENERIC, 0, &pCred)){
        av_push(ReturnArray, newSVpvf("%s",pCred->UserName));
        av_push(ReturnArray, newSVpvf("%s",(char *)pCred->CredentialBlob));
        
    }
    else{
        av_push(ReturnArray,&PL_sv_undef);
        av_push(ReturnArray,&PL_sv_undef);
    }
    return ReturnArray;
}
/*----------------------------------------------------------------------------*/
AV *GuiCredentials(char *title, char *Target, char *TargetName, int Attempt)
{
    CREDUI_INFOA cui;
    char pszPswd[CREDUI_MAX_PASSWORD_LENGTH + 1] = {0};
    char pszName[CREDUI_MAX_USERNAME_LENGTH + 1] = {0};
    char pszCapt[CREDUI_MAX_CAPTION_LENGTH + 1] = {0};
    char pszMess[CREDUI_MAX_MESSAGE_LENGTH + 1] = {0};

    snprintf(pszMess, CREDUI_MAX_MESSAGE_LENGTH,
             "Enter Credentials for: %s",
             Target);

    snprintf(pszCapt,
             CREDUI_MAX_CAPTION_LENGTH,
             "%s Credentials",
             title);

    BOOL fSave;
    DWORD dwErr;

    cui.cbSize = sizeof(CREDUI_INFOA);
    cui.hwndParent = NULL;
    //  Ensure that MessageText and CaptionText identify what credentials
    //  to use and which application requires them.
    cui.pszMessageText = pszMess;
    cui.pszCaptionText = pszCapt;
    cui.hbmBanner = NULL;
    fSave = TRUE;

    SecureZeroMemory(pszPswd, sizeof(pszPswd));
    SecureZeroMemory(pszName, sizeof(pszName));

    dwErr = CredUIPromptForCredentialsA(
        &cui,                              // CREDUI_INFOA structure
        TargetName,                        // (name of the Credential Stored)
        NULL,                              // Reserved
        0,                                 // Reason
        pszName,                           // User name
        CREDUI_MAX_USERNAME_LENGTH + 1,    // Max number of char for user name
        pszPswd,                           // Password
        CREDUI_MAX_PASSWORD_LENGTH + 1,    // Max number of char for password
        &fSave,                            // State of save check box
        CREDUI_FLAGS_GENERIC_CREDENTIALS | // flags
            CREDUI_FLAGS_ALWAYS_SHOW_UI |
            CREDUI_FLAGS_DO_NOT_PERSIST |
            (Attempt ? CREDUI_FLAGS_INCORRECT_PASSWORD : 0));

    
    /* Prepare Output Perl Array */

    AV* ReturnArray;
    ReturnArray = newAV();
    sv_2mortal((SV*)ReturnArray);

    if (dwErr)
    {
        av_push(ReturnArray,&PL_sv_undef);
        av_push(ReturnArray,&PL_sv_undef);
    }
    else
    {
        av_push(ReturnArray, newSVpvf("%s",pszName));
        av_push(ReturnArray, newSVpvf("%s",pszPswd));
    }
    return ReturnArray;
}
/*----------------------------------------------------------------------------*/
int SaveCredentials(char *TargetName, char *user, char *password)
{
    CREDENTIALA cred = {0};
    cred.Type = CRED_TYPE_GENERIC;
    cred.TargetName = TargetName;
    cred.CredentialBlobSize = strlen(password) + 1;
    cred.CredentialBlob = (LPBYTE)password;
    cred.Persist = CRED_PERSIST_LOCAL_MACHINE;
    cred.UserName = user;

    BOOL ok = CredWriteA(&cred, 0);
    if (!ok)
        exit(1);
    return 0;
}
/*----------------------------------------------------------------------------*/
int RemoveCredentials(char *TargetName){
    return CredDeleteA(TargetName, CRED_TYPE_GENERIC, 0);
}


MODULE = credsman		PACKAGE = credsman		

PROTOTYPES: DISABLE


char *
work_name (Program, Target)
	char *	Program
	char *	Target

AV *
LoadCredentials (TargetName)
	char *	TargetName

AV *
GuiCredentials (title, Target, TargetName, Attempt)
	char *	title
	char *	Target
	char *	TargetName
	int	Attempt

int
SaveCredentials (TargetName, user, password)
	char *	TargetName
	char *	user
	char *	password

int
RemoveCredentials (TargetName)
	char *	TargetName