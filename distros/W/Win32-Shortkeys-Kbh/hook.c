#include <windows.h>
#include <WinAble.h>
#include "stdio.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "hook.h"
#include "send_string.h"

HHOOK hook;
int delayedSize = 0;
delayed * start = NULL;
delayed * last = NULL;

LRESULT CALLBACK HookCallback( int nCode, WPARAM wParam, LPARAM lParam ) {
    KBDLLHOOKSTRUCT * p = ( KBDLLHOOKSTRUCT * ) lParam;
    int kup = p->flags & LLKHF_UP;
    int alt = p->flags & LLKHF_ALTDOWN;
    int ext = p->flags & LLKHF_EXTENDED;
    processKey( kup, p->vkCode, alt, ext );
    return CallNextHookEx( hook, nCode, wParam, lParam );
}

void processKey( int kup, int vkCode, int alt, int ext ) {
    //printf ("C: processKey\n");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND( SP, 4 );
    PUSHs( sv_2mortal( newSViv(kup) ) );
    PUSHs( sv_2mortal( newSViv(vkCode) ) );
    PUSHs( sv_2mortal( newSViv(alt) ) );
    PUSHs( sv_2mortal( newSViv(ext) ) );
    PUTBACK;
    //count = call_pv( "Adder", G_SCALAR );
    //printf ("C call_PV\n");
    int count = call_pv( "Win32::Shortkeys::Kbh::process_key", G_DISCARD );
    //PUTBACK;
    FREETMPS;
    LEAVE;
    //printf("C: leaving processkey\n");
    if ( count != 0 ) croak("Big trouble\n");

}

void msg_loop() {
    MSG message;

    while ( GetMessage( &message, NULL, 0, 0 ) ) {
        TranslateMessage(&message);
        DispatchMessage(&message);
    }
}

void register_hook() {
    HMODULE hMod = (HMODULE) GetModuleHandle(NULL);
    hook = SetWindowsHookEx( WH_KEYBOARD_LL, HookCallback, hMod, 0 );

}

void unregister_hook() {
    UnhookWindowsHookEx(hook);
}

void quit () {
    //UnhookWindowsHookEx(hook);
    DWORD hookThreadId = GetCurrentThreadId();
    PostThreadMessage( hookThreadId, WM_QUIT, 0, 0L );


}



void send_string( const wchar_t * str ) {
    //printf( "send_string : %s L:%i\n", str, wcslen(str) );
    INPUT inp [2];
    memset( inp, 0, sizeof(INPUT) );
    inp [0] . type = INPUT_KEYBOARD;
    /**
    * KEYEVENTF_UNICODE flag send the string as Unicode characters. Unicode makes life easy because you don't have 
    * to synthesize capital letters using the Shift key. Without KEYEVENTF_ UNICODE, you'd have to send capital E as <Shift>
    *  followed by e, with down/up events for each, for a total of four keystrokes. 
    */
    // to avoid shift, and so on 
    inp [0].ki.dwFlags = KEYEVENTF_UNICODE;
    inp [1] = inp [0];
    inp [1].ki.dwFlags |= KEYEVENTF_KEYUP;
    int count = 0;
    // for ( LPCTSTR p = str; *p; p++ ) {
    const wchar_t * p;
        // p = *str;
    for ( p = str; *p; p++ ) {
            count++;
            // inp [0] . ki . wScan = inp [1] . ki . wScan = *p;
            // If the dwFlags member specifies KEYEVENTF_UNICODE,
            //    wVk must be 0.
   //  pour que les touches claviers envoyées après ctrl ou shift soient comprises,
   //  il faut que les touches soient indiquées avec le code dans wVk
   // comme on reprend toujours les mêmes deux éléments de vecteurs pour les envoyer avec SendInput
   // il importe de remettre wVk à 0 lorsque count > 1 sinon wVk va conserver la même valeur
   // ce qui explique qu'on obtienne aaaa pour #s01#t01abcd

      if (delayedSize > 0 && count ==1 ){
	      inp[0].ki.wVk = inp[1].ki.wVk = LOBYTE(VkKeyScan(*p));
	      //inp[0].ki.wScan = inp[1].ki.wScan = *p;
     } else {
	      inp[0].ki.wVk  = inp[1].ki.wVk = 0;
	      //inp[0].ki.wScan = inp[1].ki.wScan = *p;
     }
      //WORD code = (WORD) *p;
      inp[0].ki.wScan = inp[1].ki.wScan = *p;
      //printf("wScan has %i\n", *p);
      SendInput(2, inp, sizeof(INPUT));
      if (count ==1){ //premiere lettre apres une commande
		sendDelayedKeys();
      }
   }//for

}

//byte vkcode
void send_cmd(int time, byte vkcode){
    //Sleep(500);
    //printf ("send_cmd %i %i\n", time, vkcode);
	time*=2; //doubler le nombre de touche delete à envoyer
	int size = time;
  	INPUT i[size];
	//printf ("sendCmd : %d \n", cont++);
	ZeroMemory(&i,sizeof(i));
	int sendKey = 0;
    int j;
	for (j=0;j<time;j++){
		if (vkcode == VK_SHIFT || vkcode == VK_CONTROL || vkcode == VK_MENU){
			if (j%2==0) {
				i[j].type = INPUT_KEYBOARD;
				i[j].ki.wVk=vkcode;
				i[j].ki.dwFlags =0;
				sendKey++;
			} else {
				delayed *tmp;
				//tmp = new delayed;
				tmp = (delayed*) malloc(sizeof(struct delayed));
			    tmp->data.type = INPUT_KEYBOARD;
			    tmp->data.ki.wVk = vkcode;
			    tmp->data.ki.dwFlags = KEYEVENTF_KEYUP;
			    tmp->next = NULL;
			    delayedSize++;
			    if (start == NULL){
					start = tmp;
			    } else {
					last->next = tmp;
			    }
			    last = tmp;
			    printf("new node with %u code\n", tmp->data.ki.wVk);
			}
		} else {
			i[sendKey].type = INPUT_KEYBOARD;
			i[sendKey].ki.wVk=vkcode;
			i[sendKey].ki.dwFlags = (j%2==0?0:KEYEVENTF_KEYUP);
			sendKey++;
		}
	}
	SendInput(sendKey,i,sizeof(INPUT));
}

void sendDelayedKeys(){
	delayed *current;
	current = start;
    INPUT s[delayedSize];
	int pos =0;
	while (current != NULL) {  
		delayed *temp;
		s[pos++]= current->data;
		printf("sendDelayedKeys code  %u \n", s[pos].ki.wScan );
		temp = current;
		free(current);
        current = temp->next;
  	}
	start = NULL;
	last = NULL;
	if (delayedSize > 0){
		SendInput(delayedSize, s, sizeof(INPUT) );
		delayedSize=0;
	}
}

void paste_from_clpb(int dk) {
		  dk*=2; //doubler le nombre de touche delete à envoyer
		  int size = 4+dk;
  		 INPUT i[size];
		 ZeroMemory(&i,sizeof(i));
         int j;
		  for (j=0;j<dk;j++){
			i[j].type = INPUT_KEYBOARD;
			i[j].ki.wVk=VK_BACK;
			i[j].ki.dwFlags = (j%2==0?0:KEYEVENTF_KEYUP);
		  }
		  i[0+dk].type = INPUT_KEYBOARD;
		  i[0+dk].ki.wVk =VK_CONTROL;
		  
		  i[1+dk].type = INPUT_KEYBOARD;
		  i[1+dk].ki.wVk = LOBYTE(VkKeyScan('v'));
		  
		  i[2+dk].type = INPUT_KEYBOARD;
		  i[2+dk].ki.dwFlags = KEYEVENTF_KEYUP;
		  i[2+dk].ki.wVk =LOBYTE(VkKeyScan('v'));
		  
		  i[3+dk].type = INPUT_KEYBOARD;
		  i[3+dk].ki.dwFlags = KEYEVENTF_KEYUP;
		  i[3+dk].ki.wVk = VK_CONTROL;
		  
		  SendInput(size,i,sizeof(INPUT)); 
	//}
	//AttachThreadInput(hookThreadId, otherThreadId, false ); 
}

