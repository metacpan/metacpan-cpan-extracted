/*
    EnvProcess.h
    Used by EnvProcess.xs and EnvProcessDll.c
    Version 0.05
*/

#ifndef ENVPROCESS_DEFINED
#define ENVPROCESS_DEFINED

#define FMONAME  "fmoPerlTempEnvVar"

#define MAXSIZE          8192
#define MAXITEMS          508

#define SETCMD           ((char)0x00)
#define GETCMD           ((char)0x01)
#define DELCMD           ((char)0x02)
#define GETALLCMD        ((char)0x03)
#define INVALID_CMD      ((char)0xf0)    // ERROR_INVALID_FLAG_NUMBER
#define VALUE_TOO_BIG    ((char)0xf1)    // ERROR_NOT_ENOUGH_MEMORY (8)
#define ENVVAR_NOT_FOUND ((char)0xf2)    // ERROR_ENVVAR_NOT_FOUND
#define ENV_TOO_MANY     ((char)0xf3)    // ERROR_OUTOFMEMORY

#endif   /* ENVPROCESS_DEFINED */
