#include "cpp/wxapi.h"
#include "cpp/helpers.h"
#include "wx/dialup.h"

MODULE=Wx__DialUpManager

# Wx::Sample don't mention this
BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

MODULE=Wx PACKAGE=Wx::DialUpManager


static wxDialUpManager*
wxDialUpManager::Create()

## NO MORE ALIAS
## we need to alias, cause #wxDialUpManager*\nwxDialUpManager::Create()
## won't be treed as a constructor, it'd be ::Create(THIS) not ::Create(CLASS)

wxDialUpManager*
wxDialUpManager::new()
##    ALIAS:
##        Wx::DialUpManager::Create = 1
##        Wx::DialUpManager::new = 2
    CODE:
        RETVAL = wxDialUpManager::Create();
    OUTPUT:
        RETVAL



#http://crazyinsomniac.perlmonk.org/perl/files/Wx-DialUpManager-0.01.tar.gz


bool
wxDialUpManager::IsOk()

#if defined( __WXMSW__ ) 

void
wxDialUpManager::GetISPNames()
    PREINIT:
        wxArrayString names;
        int i, n;
    PPCODE:
        THIS->GetISPNames(names);
        n = names.GetCount();
        if( n ) {
            EXTEND( SP, n );
            for( i = 0; i < n; i++ ) {
                PUSHs( sv_2mortal( newSVpv( names[i], names[i].Length() ) ) );
            }
        }

#endif

bool
wxDialUpManager::Dial(nameOfISP = wxEmptyString, username = wxEmptyString, password = wxEmptyString, async = TRUE)
    CASE:
    wxString nameOfISP;
    wxString username;
    wxString password;
    bool async;
        CODE:
            RETVAL = THIS->Dial( nameOfISP, username, password, async );
        OUTPUT:
            RETVAL

bool
wxDialUpManager::IsDialing()

bool
wxDialUpManager::CancelDialing()

bool
wxDialUpManager::HangUp()

bool
wxDialUpManager::IsAlwaysOnline()

bool
wxDialUpManager::IsOnline()

void
wxDialUpManager::SetOnlineStatus(isOnline = TRUE)
    CASE:
        bool isOnline;
        CODE:
            THIS->SetOnlineStatus(isOnline);

bool
wxDialUpManager::EnableAutoCheckOnlineStatus(nSeconds = 60)
    CASE:
        size_t nSeconds;
        CODE:
            RETVAL = THIS->EnableAutoCheckOnlineStatus(nSeconds);
        OUTPUT:
            RETVAL

void
wxDialUpManager::DisableAutoCheckOnlineStatus()

#if defined( __UNIX__ ) 
void
wxDialUpManager::SetWellKnownHost(hostname, portno = 80)
    CASE:
        wxString hostname
        int portno
            CODE:
                THIS->SetWellKnownHost( hostname, portno );


void
wxDialUpManager::SetConnectCommand(commandDial = wxT("/usr/bin/pon"), commandHangup = wxT("/usr/bin/poff") )
    CASE:
        wxString commandDial
        wxString commandHangup 
        CODE:
            THIS->SetConnectCommand(commandDial,commandHangup);

#endif

void
wxDialUpManager::DESTROY()


INCLUDE: DialUpEvent.xs

#include "cpp/du_constants.cpp"

MODULE=Wx__DialUpManager


