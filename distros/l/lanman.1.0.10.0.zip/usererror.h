#ifndef __USERERROR_H
#define __USERERROR_H

// define base for application depended errors
#define USER_ERROR_BASE										0x20000000

// generated if new fails
#define NOT_ENOUGTH_MEMORY_ERROR					USER_ERROR_BASE + 1

// generated if pointer to a function is null but there is no null value expected
#define INVALID_ARGUMENT_PTR_ERROR				USER_ERROR_BASE + 2

/*

// generated if desired registry type does not complain with really type
#define WRONG_REGISTRY_TYPE_ERROR					USER_ERROR_BASE + 2

// generated if pointer to a function is to big
#define ARGUMENT_TO_BIG_ERROR							USER_ERROR_BASE + 3

// generated if initialization for db library fails
#define ERROR_INIT_DBLIB									USER_ERROR_BASE + 5

// generated if login in db library fails
#define ERROR_LOGIN_DBLIB									USER_ERROR_BASE + 6

// generated if setting user name for db library fails
#define ERROR_SETUSER_DBLIB								USER_ERROR_BASE + 7

// generated if setting Password for db library fails
#define ERROR_SETPASSWORD_DBLIB						USER_ERROR_BASE + 8

// generated if setting application name for db library fails
#define ERROR_SETAPPLICATION_DBLIB				USER_ERROR_BASE + 9

// generated if setting host name for db library fails
#define ERROR_SETHOST_DBLIB								USER_ERROR_BASE + 10

// generated if setting login timeout for db library fails
#define ERROR_SETLOGINTIMEOUT_DBLIB				USER_ERROR_BASE + 11

// generated if open database for db library fails
#define ERROR_ERROROPENDATABASE_DBLIB			USER_ERROR_BASE + 11

// generated if database use for db library fails
#define ERROR_ERRORUSEDATABASE_DBLIB			USER_ERROR_BASE + 11

// generated if an argument to a function is not right
#define INVALID_WRONG_ARGUMENTERROR				USER_ERROR_BASE + 12
*/

#endif

