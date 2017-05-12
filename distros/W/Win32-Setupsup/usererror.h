#ifndef __USERERROR_H
#define __USERERROR_H

// define base for application depended errors
#define USER_ERROR_BASE                 0x20000000

// generated if new dails
#define NOT_ENOUGTH_MEMORY_ERROR        USER_ERROR_BASE + 1

// generated if desired registry type does not complain with really type
#define WRONG_REGISTRY_TYPE_ERROR       USER_ERROR_BASE + 2

// generated if pointer to a function is to big
#define ARGUMENT_TO_BIG_ERROR           USER_ERROR_BASE + 3

// generated if pointer to a function is null but there is no null value expected
#define INVALID_ARGUMENT_PTR_ERROR      USER_ERROR_BASE + 4

// generated if initialization for db library fails
#define ERROR_INIT_DBLIB                USER_ERROR_BASE + 5

// generated if login in db library fails
#define ERROR_LOGIN_DBLIB               USER_ERROR_BASE + 6

// generated if setting user name for db library fails
#define ERROR_SETUSER_DBLIB             USER_ERROR_BASE + 7

// generated if setting Password for db library fails
#define ERROR_SETPASSWORD_DBLIB         USER_ERROR_BASE + 8

// generated if setting application name for db library fails
#define ERROR_SETAPPLICATION_DBLIB      USER_ERROR_BASE + 9

// generated if setting host name for db library fails
#define ERROR_SETHOST_DBLIB             USER_ERROR_BASE + 10

// generated if setting login timeout for db library fails
#define ERROR_SETLOGINTIMEOUT_DBLIB     USER_ERROR_BASE + 11

// generated if open database for db library fails
#define ERROR_ERROROPENDATABASE_DBLIB   USER_ERROR_BASE + 11

// generated if database use for db library fails
#define ERROR_ERRORUSEDATABASE_DBLIB    USER_ERROR_BASE + 11

// generated if an argument to a function is not right
#define INVALID_WRONG_ARGUMENTERROR     USER_ERROR_BASE + 12

// generated if syntax for SendKeys is wrong
#define BAD_STR_FORMAT_ERROR            USER_ERROR_BASE + 13

// generated on timeout failure
#define ERROR_TIMEOUT_ELAPSED           USER_ERROR_BASE + 14

// generated if there is an unknown property to get
#define UNKNOWN_PROPERTY_ERROR          USER_ERROR_BASE + 15

// generated if the value of an property has an invalid type
#define INVALID_PROPERTY_TYPE_ERROR     USER_ERROR_BASE + 16

// generated if a sid is not valid
#define INVALID_SID_ERROR               USER_ERROR_BASE + 17

// generated if a performance counter could not be found
#define PERF_COUNTER_NOT_FOUND_ERROR    USER_ERROR_BASE + 18

// generated if a performance counter could not be found
#define INVALID_THREAD_HANDLE_ERROR     USER_ERROR_BASE + 19

#endif
