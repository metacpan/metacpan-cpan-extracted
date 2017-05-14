//
//  Values are 32 bit values layed out as follows:
//
//   3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1
//   1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
//  +---+-+-+-----------------------+-------------------------------+
//  |Sev|C|R|     Facility          |               Code            |
//  +---+-+-+-----------------------+-------------------------------+
//
//  where
//
//      Sev - is the severity code
//
//          00 - Success
//          01 - Informational
//          10 - Warning
//          11 - Error
//
//      C - is the Customer code flag
//
//      R - is a reserved bit
//
//      Facility - is the facility code
//
//      Code - is the facility's status code
//
//
// Define the facility codes
//


//
// Define the severity codes
//
#define STATUS_SEVERITY_WARNING          0x2
#define STATUS_SEVERITY_SUCCESS          0x0
#define STATUS_SEVERITY_INFORMATIONAL    0x1
#define STATUS_SEVERITY_ERROR            0x3


//
// MessageId: MSG_START_OK
//
// MessageText:
//
//  The EICNDHCPD service start up correctly.
//
#define MSG_START_OK                     ((HRESULT)0x00000001L)

//
// MessageId: MSG_START_KO
//
// MessageText:
//
//  The EICNDHPCD service cannot start up correctly,
//  the server IP address in dhcpd.conf is invalid.
//  (See dhcpd.log file too)
//
#define MSG_START_KO                     ((HRESULT)0x00000002L)

//
// MessageId: MSG_START_KO2
//
// MessageText:
//
//  The EICNDHCPD service cannot start up correctly:
//  unable to open dhcpd.conf file.
//  (see dhcpd.log file too)
//
#define MSG_START_KO2                    ((HRESULT)0x00000003L)

//
// MessageId: MSG_START_KO3
//
// MessageText:
//
//  The EICNDHCPD service cannot start up correctly:
//  unable to open netdata.dat file.
//  (see dhcpd.log file too)
//
#define MSG_START_KO3                    ((HRESULT)0x00000004L)

//
// MessageId: MSG_START_KO4
//
// MessageText:
//
//  The EICNDHCPD service cannot start up correctly:
//  unable to open dhcpd.log file.
//
#define MSG_START_KO4                    ((HRESULT)0x00000005L)

//
// MessageId: MSG_START_KO5
//
// MessageText:
//
//  The EICNDHCPD service cannot start up correctly:
//  unable to make a second process for dhcpd2.pl.
//  (see dhcpd.log file too)
//
#define MSG_START_KO5                    ((HRESULT)0x00000006L)

//
// MessageId: MSG_STOP_OK
//
// MessageText:
//
//  The EICNDHCPD service stop correctly.
//
#define MSG_STOP_OK                      ((HRESULT)0x00000063L)

