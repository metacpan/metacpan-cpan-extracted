//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include "PerlShellExecuteHookExt.h"
 
PerlShellExecuteHookExt::PerlShellExecuteHookExt(PerlShellExt *master) : PerlShellExecuteHookImpl(master) {}
PerlShellExecuteHookExt::~PerlShellExecuteHookExt() {}

// this is documented at http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/reference/ifaces/ishellexecutehook/Execute.asp
HRESULT PerlShellExecuteHookExt::Execute(LPSHELLEXECUTEINFOA pei) {
  
  
  return S_FALSE; // this implementation does not allow
  // actually performing the process execution, it is simply meant
  // to allow things such as logging shell activity, so we always tell
  // the shell to fall back on default processing.
}


typedef struct _SHELLEXECUTEINFO {
    DWORD  cbSize;
    ULONG  fMask;
    HWND  hwnd;
    LPCTSTR  lpVerb;
    LPCTSTR  lpFile;
    LPCTSTR  lpParameters;
    LPCTSTR  lpDirectory;
    int  nShow;
    HINSTANCE  hInstApp;
    LPVOID  lpIDList;
    LPCTSTR  lpClass;
    HKEY  hkeyClass;
    DWORD  dwHotKey;
    union {
        HANDLE  hIcon;
        HANDLE  hMonitor;
    } DUMMYUNIONNAME;
    HANDLE  hProcess;
} SHELLEXECUTEINFO, *LPSHELLEXECUTEINFO;
Members

cbSize
Size of the structure, in bytes. 
fMask
Array of flags that indicate the content and validity of the other structure members. This can be a combination of the following values. 
SEE_MASK_CLASSKEY
Use the class key given by the hkeyClass member. 
SEE_MASK_CLASSNAME
Use the class name given by the lpClass member. 
SEE_MASK_CONNECTNETDRV
Validate the share and connect to a drive letter. The lpFile member is a Universal Naming Convention (UNC) path of a file on a network. 
SEE_MASK_DOENVSUBST
Expand any environment variables specified in the string given by the lpDirectory or lpFile member. 
SEE_MASK_FLAG_DDEWAIT
Wait for the Dynamic Data Exchange (DDE) conversation to terminate before returning (if the ShellExecuteEx function causes a DDE conversation to start). For circumstances in which this flag is necessary, see the Remarks section.
SEE_MASK_FLAG_LOG_USAGE
Version 6.0. Keep track of the number of times this application has been launched. Applications that accrue sufficiently high counts appear in the Start Menu's list of most frequently used programs.
SEE_MASK_FLAG_NO_UI
Do not display an error message box if an error occurs. 
SEE_MASK_HMONITOR
Use this flag when specifying a monitor on multi-monitor systems. The monitor is specified in the hMonitor member. This flag cannot be combined with SEE_MASK_ICON.
SEE_MASK_HOTKEY
Use the hot key given by the dwHotKey member.
SEE_MASK_ICON
Use the icon given by the hIcon member. This flag cannot be combined with SEE_MASK_HMONITOR.
SEE_MASK_IDLIST
Use the item identifier list given by the lpIDList member. The lpIDList member must point to an ITEMIDLIST structure.
SEE_MASK_INVOKEIDLIST
Use the IContextMenu interface of the selected item's shortcut menu handler. Use either lpFile to identify the item by its file system path or lpIDList to identify the item by its pointer to an item identifier list (PIDL). This flag allows applications to use ShellExecuteEx to invoke verbs from shortcut menu extensions instead of the static verbs listed in the registry.

Note SEE_MASK_INVOKEIDLIST overrides SEE_MASK_IDLIST.

SEE_MASK_NOCLOSEPROCESS
Use to indicate that the hProcess member receives the process handle. This handle is typically used to allow an application to find out when a process created with ShellExecuteEx terminates. In some cases, such as when execution is satisfied through a DDE conversation, no handle will be returned. The calling application is responsible for closing the handle when it is no longer needed.
SEE_MASK_NO_CONSOLE
Use to create a console for the new process instead of having it inherit the parent's console. It is equivalent to using a CREATE_NEW_CONSOLE flag with CreateProcess.
SEE_MASK_UNICODE
Use this flag to indicate a Unicode application.
hwnd
Window handle to any message boxes that the system might produce while executing this function. 
lpVerb
String, referred to as a verb, that specifies the action to be performed. The set of available verbs depends on the particular file or folder. Generally, the actions available from an object's shortcut menu are available verbs. For more specific information about verbs, see Object Verbs. For further discussion of shortcut menus, see Extending Shortcut Menus. If you set this parameter to NULL: 
For systems prior to Microsoft® Windows® 2000, the default verb is used if it is valid and available in the registry. If not, the "open" verb is used. 
For Windows 2000 and later systems, the default verb is used if available. If not, the "open" verb is used. If neither verb is available, the system uses the first verb listed in the registry. 
The following verbs are commonly used. 
edit
Launches an editor and opens the document for editing. If lpFile is not a document file, the function will fail.
explore
Explores the folder specified by lpFile. 
find
Initiates a search starting from the specified directory.
open
Opens the file specified by the lpFile parameter. The file can be an executable file, a document file, or a folder.
print
Prints the document file specified by lpFile. If lpFile is not a document file, the function will fail.
properties
Displays the file or folder's properties.
lpFile
Address of a null-terminated string that specifies the name of the file or object on which ShellExecuteEx will perform the action specified by the lpVerb parameter. The system registry verbs that are supported by the ShellExecuteEx function include "open" for executable files and document files and "print" for document files for which a print handler has been registered. Other applications might have added Shell verbs through the system registry, such as "play" for .avi and .wav files. To specify a Shell namespace object, pass the fully qualified parse name and set the SEE_MASK_INVOKEIDLIST flag in the fMask parameter.

Note If the SEE_MASK_INVOKEIDLIST flag is set, you can use either lpFile or lpIDList to identify the item by its file system path or its PIDL respectively.

Note If the path is not included with the name, the current directory is assumed. 

lpParameters
Address of a null-terminated string that contains the application parameters. The parameters must be separated by spaces. If the lpFile member specifies a document file, lpParameters should be NULL.
lpDirectory
Address of a null-terminated string that specifies the name of the working directory. If this member is not specified, the current directory is used as the working directory. 
nShow
Flags that specify how an application is to be shown when it is opened. It can be one of the SW_ values listed for the ShellExecute function. If lpFile specifies a document file, the flag is simply passed to the associated application. It is up to the application to decide how to handle it. 
hInstApp
If the function succeeds, it sets this member to a value greater than 32. If the function fails, it is set to an SE_ERR_XXX error value that indicates the cause of the failure. Although hInstApp is declared as an HINSTANCE for compatibility with 16-bit Windows applications, it is not a true HINSTANCE. It can be cast only to an int and compared to either 32 or the following SE_ERR_XXX error codes. 
SE_ERR_FNF
File not found.
SE_ERR_PNF
Path not found.
SE_ERR_ACCESSDENIED
Access denied.
SE_ERR_OOM
Out of memory.
SE_ERR_DLLNOTFOUND
Dynamic-link library not found.
SE_ERR_SHARE
Cannot share an open file.
SE_ERR_ASSOCINCOMPLETE
File association information not complete.
SE_ERR_DDETIMEOUT
DDE operation timed out.
SE_ERR_DDEFAIL
DDE operation failed.
SE_ERR_DDEBUSY
DDE operation is busy.
SE_ERR_NOASSOC
File association not available.
lpIDList
Address of an ITEMIDLIST structure to contain an item identifier list uniquely identifying the file to execute. This member is ignored if the fMask member does not include SEE_MASK_IDLIST or SEE_MASK_INVOKEIDLIST. 
lpClass
Address of a null-terminated string that specifies the name of a file class or a globally unique identifier (GUID). This member is ignored if fMask does not include SEE_MASK_CLASSNAME. 
hkeyClass
Handle to the registry key for the file class. This member is ignored if fMask does not include SEE_MASK_CLASSKEY. 
dwHotKey
Hot key to associate with the application. The low-order word is the virtual key code, and the high-order word is a modifier flag (HOTKEYF_). For a list of modifier flags, see the description of the WM_SETHOTKEY message. This member is ignored if fMask does not include SEE_MASK_HOTKEY. 
DUMMYUNIONNAME
hIcon
Handle to the icon for the file class. This member is ignored if fMask does not include SEE_MASK_ICON. 
hMonitor
Handle to the monitor upon which the document is to be displayed. This member is ignored if fMask does not include SEE_MASK_HMONITOR. 
hProcess
Handle to the newly started application. This member is set on return and is always NULL unless fMask is set to SEE_MASK_NOCLOSEPROCESS. Even if fMask is set to SEE_MASK_NOCLOSEPROCESS, hProcess will be NULL if no process was launched. For example, if a document to be launched is a URL and an instance of Microsoft Internet Explorer is already running, it will display the document. No new process is launched, and hProcess will be NULL.

Note ShellExecuteEx does not always return an hProcess, even if a process is launched as the result of the call. For example, an hProcess does not return when you use SEE_MASK_INVOKEIDLIST to invoke IContextMenu.

Remarks

The SEE_MASK_FLAG_DDEWAIT flag must be specified if the thread calling ShellExecuteEx does not have a message loop or if the thread or process will terminate soon after ShellExecuteEx returns. Under such conditions, the calling thread will not be available to complete the DDE conversation, so it is important that ShellExecuteEx complete the conversation before returning control to the caller. Failure to complete the conversation can result in an unsuccessful launch of the document.

If the calling thread has a message loop and will exist for some time after the call to ShellExecuteEx returns, the SEE_MASK_FLAG_DDEWAIT flag is optional. If the flag is omitted, the calling thread's message pump will be used to complete the DDE conversation. The calling application regains control sooner, since the DDE conversation can be completed in the background. 

When populating the most frequently used program list using the SEE_MASK_FLAG_LOG_USAGE flag in fMask, counts are made differently for the classic and Windows XP-style Start menus. The classic style menu only counts hits to the shortcuts in the Program menu. The Windows XP-style menu counts both hits to the shortcuts in the Program menu and hits to those shortcuts' targets outside of the Program menu. Therefore, setting lpFile to myfile.exe would affect the count for the Windows XP-style menu regardless of whether that file was launched directly or through a shortcut. The classic style—which would require lpFile to contain a .lnk file name—would not be affected.

To include double quotation marks in lpParameters, enclose each mark in a pair of quotation marks, as in the following example. 

sei.lpParameters = "An example: \"\"\"quoted text\"\"\"";
In this case, the application receives three parameters: An, example:, and "quoted text".
