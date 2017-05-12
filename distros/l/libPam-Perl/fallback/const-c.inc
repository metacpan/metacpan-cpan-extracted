#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_ABORT PAM_RHOST PAM_RUSER */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'E':
    if (memEQ(name, "PAM_RUSER", 9)) {
    /*                      ^       */
#ifdef PAM_RUSER
      *iv_return = PAM_RUSER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "PAM_ABORT", 9)) {
    /*                      ^       */
#ifdef PAM_ABORT
      *iv_return = PAM_ABORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PAM_RHOST", 9)) {
    /*                      ^       */
#ifdef PAM_RHOST
      *iv_return = PAM_RHOST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_AUTHTOK PAM_BUF_ERR PAM_SERVICE PAM_SUCCESS */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'E':
    if (memEQ(name, "PAM_SERVIC", 10)) {
    /*                         E      */
#ifdef PAM_SERVICE
      *iv_return = PAM_SERVICE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "PAM_AUTHTO", 10)) {
    /*                         K      */
#ifdef PAM_AUTHTOK
      *iv_return = PAM_AUTHTOK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "PAM_BUF_ER", 10)) {
    /*                         R      */
#ifdef PAM_BUF_ERR
      *iv_return = PAM_BUF_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PAM_SUCCES", 10)) {
    /*                         S      */
#ifdef PAM_SUCCESS
      *iv_return = PAM_SUCCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_AUTH_ERR PAM_BAD_ITEM PAM_CONV_ERR PAM_CRED_ERR PAM_MAXTRIES
     PAM_OPEN_ERR PAM_XDISPLAY */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'D':
    if (memEQ(name, "PAM_CRED_ERR", 12)) {
    /*                      ^           */
#ifdef PAM_CRED_ERR
      *iv_return = PAM_CRED_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "PAM_AUTH_ERR", 12)) {
    /*                      ^           */
#ifdef PAM_AUTH_ERR
      *iv_return = PAM_AUTH_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "PAM_OPEN_ERR", 12)) {
    /*                      ^           */
#ifdef PAM_OPEN_ERR
      *iv_return = PAM_OPEN_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PAM_XDISPLAY", 12)) {
    /*                      ^           */
#ifdef PAM_XDISPLAY
      *iv_return = PAM_XDISPLAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "PAM_MAXTRIES", 12)) {
    /*                      ^           */
#ifdef PAM_MAXTRIES
      *iv_return = PAM_MAXTRIES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "PAM_CONV_ERR", 12)) {
    /*                      ^           */
#ifdef PAM_CONV_ERR
      *iv_return = PAM_CONV_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "PAM_BAD_ITEM", 12)) {
    /*                      ^           */
#ifdef PAM_BAD_ITEM
      *iv_return = PAM_BAD_ITEM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_ERROR_MSG PAM_TEXT_INFO PAM_TRY_AGAIN PAM_XAUTHDATA __LINUX_PAM__ */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'F':
    if (memEQ(name, "PAM_TEXT_INFO", 13)) {
    /*                          ^        */
#ifdef PAM_TEXT_INFO
      *iv_return = PAM_TEXT_INFO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "PAM_TRY_AGAIN", 13)) {
    /*                          ^        */
#ifdef PAM_TRY_AGAIN
      *iv_return = PAM_TRY_AGAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PAM_ERROR_MSG", 13)) {
    /*                          ^        */
#ifdef PAM_ERROR_MSG
      *iv_return = PAM_ERROR_MSG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "PAM_XAUTHDATA", 13)) {
    /*                          ^        */
#ifdef PAM_XAUTHDATA
      *iv_return = PAM_XAUTHDATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "__LINUX_PAM__", 13)) {
    /*                          ^        */
#ifdef __LINUX_PAM__
      *iv_return = __LINUX_PAM__;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_CONV_AGAIN PAM_FAIL_DELAY PAM_INCOMPLETE PAM_OLDAUTHTOK PAM_RADIO_TYPE
     PAM_SYMBOL_ERR PAM_SYSTEM_ERR */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "PAM_OLDAUTHTOK", 14)) {
    /*                      ^             */
#ifdef PAM_OLDAUTHTOK
      *iv_return = PAM_OLDAUTHTOK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "PAM_SYMBOL_ERR", 14)) {
    /*                      ^             */
#ifdef PAM_SYMBOL_ERR
      *iv_return = PAM_SYMBOL_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "PAM_RADIO_TYPE", 14)) {
    /*                      ^             */
#ifdef PAM_RADIO_TYPE
      *iv_return = PAM_RADIO_TYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "PAM_FAIL_DELAY", 14)) {
    /*                      ^             */
#ifdef PAM_FAIL_DELAY
      *iv_return = PAM_FAIL_DELAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "PAM_INCOMPLETE", 14)) {
    /*                      ^             */
#ifdef PAM_INCOMPLETE
      *iv_return = PAM_INCOMPLETE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "PAM_SYSTEM_ERR", 14)) {
    /*                      ^             */
#ifdef PAM_SYSTEM_ERR
      *iv_return = PAM_SYSTEM_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "PAM_CONV_AGAIN", 14)) {
    /*                      ^             */
#ifdef PAM_CONV_AGAIN
      *iv_return = PAM_CONV_AGAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_AUTHTOK_ERR PAM_DATA_SILENT PAM_DELETE_CRED PAM_MAX_NUM_MSG
     PAM_PERM_DENIED PAM_SERVICE_ERR PAM_SESSION_ERR PAM_USER_PROMPT */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "PAM_DATA_SILENT", 15)) {
    /*                      ^              */
#ifdef PAM_DATA_SILENT
      *iv_return = PAM_DATA_SILENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "PAM_DELETE_CRED", 15)) {
    /*                      ^              */
#ifdef PAM_DELETE_CRED
      *iv_return = PAM_DELETE_CRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "PAM_AUTHTOK_ERR", 15)) {
    /*                      ^              */
#ifdef PAM_AUTHTOK_ERR
      *iv_return = PAM_AUTHTOK_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "PAM_PERM_DENIED", 15)) {
    /*                      ^              */
#ifdef PAM_PERM_DENIED
      *iv_return = PAM_PERM_DENIED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "PAM_USER_PROMPT", 15)) {
    /*                      ^              */
#ifdef PAM_USER_PROMPT
      *iv_return = PAM_USER_PROMPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PAM_SESSION_ERR", 15)) {
    /*                      ^              */
#ifdef PAM_SESSION_ERR
      *iv_return = PAM_SESSION_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "PAM_SERVICE_ERR", 15)) {
    /*                      ^              */
#ifdef PAM_SERVICE_ERR
      *iv_return = PAM_SERVICE_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "PAM_MAX_NUM_MSG", 15)) {
    /*                      ^              */
#ifdef PAM_MAX_NUM_MSG
      *iv_return = PAM_MAX_NUM_MSG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_ACCT_EXPIRED PAM_AUTHTOK_TYPE PAM_CRED_EXPIRED PAM_CRED_UNAVAIL
     PAM_DATA_REPLACE PAM_MAX_MSG_SIZE PAM_PRELIM_CHECK PAM_REFRESH_CRED
     PAM_USER_UNKNOWN */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'C':
    if (memEQ(name, "PAM_REFRESH_CRED", 16)) {
    /*                           ^          */
#ifdef PAM_REFRESH_CRED
      *iv_return = PAM_REFRESH_CRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "PAM_PRELIM_CHECK", 16)) {
    /*                           ^          */
#ifdef PAM_PRELIM_CHECK
      *iv_return = PAM_PRELIM_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "PAM_ACCT_EXPIRED", 16)) {
    /*                           ^          */
#ifdef PAM_ACCT_EXPIRED
      *iv_return = PAM_ACCT_EXPIRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "PAM_CRED_EXPIRED", 16)) {
    /*                           ^          */
#ifdef PAM_CRED_EXPIRED
      *iv_return = PAM_CRED_EXPIRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "PAM_DATA_REPLACE", 16)) {
    /*                           ^          */
#ifdef PAM_DATA_REPLACE
      *iv_return = PAM_DATA_REPLACE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "PAM_USER_UNKNOWN", 16)) {
    /*                           ^          */
#ifdef PAM_USER_UNKNOWN
      *iv_return = PAM_USER_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "PAM_MAX_MSG_SIZE", 16)) {
    /*                           ^          */
#ifdef PAM_MAX_MSG_SIZE
      *iv_return = PAM_MAX_MSG_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "PAM_AUTHTOK_TYPE", 16)) {
    /*                           ^          */
#ifdef PAM_AUTHTOK_TYPE
      *iv_return = PAM_AUTHTOK_TYPE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "PAM_CRED_UNAVAIL", 16)) {
    /*                           ^          */
#ifdef PAM_CRED_UNAVAIL
      *iv_return = PAM_CRED_UNAVAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_ESTABLISH_CRED PAM_MODULE_UNKNOWN PAM_NO_MODULE_DATA
     PAM_PROMPT_ECHO_ON PAM_UPDATE_AUTHTOK _PAM_RETURN_VALUES */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'C':
    if (memEQ(name, "PAM_ESTABLISH_CRED", 18)) {
    /*                             ^          */
#ifdef PAM_ESTABLISH_CRED
      *iv_return = PAM_ESTABLISH_CRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "PAM_NO_MODULE_DATA", 18)) {
    /*                             ^          */
#ifdef PAM_NO_MODULE_DATA
      *iv_return = PAM_NO_MODULE_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "PAM_UPDATE_AUTHTOK", 18)) {
    /*                             ^          */
#ifdef PAM_UPDATE_AUTHTOK
      *iv_return = PAM_UPDATE_AUTHTOK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "_PAM_RETURN_VALUES", 18)) {
    /*                             ^          */
#ifdef _PAM_RETURN_VALUES
      *iv_return = _PAM_RETURN_VALUES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "PAM_MODULE_UNKNOWN", 18)) {
    /*                             ^          */
#ifdef PAM_MODULE_UNKNOWN
      *iv_return = PAM_MODULE_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "PAM_PROMPT_ECHO_ON", 18)) {
    /*                             ^          */
#ifdef PAM_PROMPT_ECHO_ON
      *iv_return = PAM_PROMPT_ECHO_ON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_AUTHTOK_EXPIRED PAM_PROMPT_ECHO_OFF __LINUX_PAM_MINOR__ */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'N':
    if (memEQ(name, "__LINUX_PAM_MINOR__", 19)) {
    /*                             ^           */
#ifdef __LINUX_PAM_MINOR__
      *iv_return = __LINUX_PAM_MINOR__;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "PAM_PROMPT_ECHO_OFF", 19)) {
    /*                             ^           */
#ifdef PAM_PROMPT_ECHO_OFF
      *iv_return = PAM_PROMPT_ECHO_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "PAM_AUTHTOK_EXPIRED", 19)) {
    /*                             ^           */
#ifdef PAM_AUTHTOK_EXPIRED
      *iv_return = PAM_AUTHTOK_EXPIRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     PAM_AUTHTOK_LOCK_BUSY PAM_CRED_INSUFFICIENT PAM_REINITIALIZE_CRED */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'I':
    if (memEQ(name, "PAM_REINITIALIZE_CRED", 21)) {
    /*                         ^                 */
#ifdef PAM_REINITIALIZE_CRED
      *iv_return = PAM_REINITIALIZE_CRED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "PAM_AUTHTOK_LOCK_BUSY", 21)) {
    /*                         ^                 */
#ifdef PAM_AUTHTOK_LOCK_BUSY
      *iv_return = PAM_AUTHTOK_LOCK_BUSY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "PAM_CRED_INSUFFICIENT", 21)) {
    /*                         ^                 */
#ifdef PAM_CRED_INSUFFICIENT
      *iv_return = PAM_CRED_INSUFFICIENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(PAM_ABORT PAM_ACCT_EXPIRED PAM_AUTHINFO_UNAVAIL PAM_AUTHTOK
	       PAM_AUTHTOK_DISABLE_AGING PAM_AUTHTOK_ERR PAM_AUTHTOK_EXPIRED
	       PAM_AUTHTOK_LOCK_BUSY PAM_AUTHTOK_RECOVERY_ERR PAM_AUTHTOK_TYPE
	       PAM_AUTH_ERR PAM_BAD_ITEM PAM_BINARY_PROMPT PAM_BUF_ERR
	       PAM_CHANGE_EXPIRED_AUTHTOK PAM_CONV PAM_CONV_AGAIN PAM_CONV_ERR
	       PAM_CRED_ERR PAM_CRED_EXPIRED PAM_CRED_INSUFFICIENT
	       PAM_CRED_UNAVAIL PAM_DATA_REPLACE PAM_DATA_SILENT
	       PAM_DELETE_CRED PAM_DISALLOW_NULL_AUTHTOK PAM_ERROR_MSG
	       PAM_ESTABLISH_CRED PAM_FAIL_DELAY PAM_IGNORE PAM_INCOMPLETE
	       PAM_MAXTRIES PAM_MAX_MSG_SIZE PAM_MAX_NUM_MSG PAM_MAX_RESP_SIZE
	       PAM_MODULE_UNKNOWN PAM_NEW_AUTHTOK_REQD PAM_NO_MODULE_DATA
	       PAM_OLDAUTHTOK PAM_OPEN_ERR PAM_PERM_DENIED PAM_PRELIM_CHECK
	       PAM_PROMPT_ECHO_OFF PAM_PROMPT_ECHO_ON PAM_RADIO_TYPE
	       PAM_REFRESH_CRED PAM_REINITIALIZE_CRED PAM_RHOST PAM_RUSER
	       PAM_SERVICE PAM_SERVICE_ERR PAM_SESSION_ERR PAM_SILENT
	       PAM_SUCCESS PAM_SYMBOL_ERR PAM_SYSTEM_ERR PAM_TEXT_INFO
	       PAM_TRY_AGAIN PAM_TTY PAM_UPDATE_AUTHTOK PAM_USER
	       PAM_USER_PROMPT PAM_USER_UNKNOWN PAM_XAUTHDATA PAM_XDISPLAY
	       _PAM_RETURN_VALUES __LINUX_PAM_MINOR__ __LINUX_PAM__));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Authen::PAM::Module", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Authen::PAM::Module", $types);
__END__
   */

  switch (len) {
  case 7:
    if (memEQ(name, "PAM_TTY", 7)) {
#ifdef PAM_TTY
      *iv_return = PAM_TTY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    /* Names all of length 8.  */
    /* PAM_CONV PAM_USER */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'R':
      if (memEQ(name, "PAM_USE", 7)) {
      /*                      R     */
#ifdef PAM_USER
        *iv_return = PAM_USER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'V':
      if (memEQ(name, "PAM_CON", 7)) {
      /*                      V     */
#ifdef PAM_CONV
        *iv_return = PAM_CONV;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    /* Names all of length 10.  */
    /* PAM_IGNORE PAM_SILENT */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'G':
      if (memEQ(name, "PAM_IGNORE", 10)) {
      /*                    ^           */
#ifdef PAM_IGNORE
        *iv_return = PAM_IGNORE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "PAM_SILENT", 10)) {
      /*                    ^           */
#ifdef PAM_SILENT
        *iv_return = PAM_SILENT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    /* Names all of length 17.  */
    /* PAM_BINARY_PROMPT PAM_MAX_RESP_SIZE */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case 'O':
      if (memEQ(name, "PAM_BINARY_PROMPT", 17)) {
      /*                            ^          */
#ifdef PAM_BINARY_PROMPT
        *iv_return = PAM_BINARY_PROMPT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "PAM_MAX_RESP_SIZE", 17)) {
      /*                            ^          */
#ifdef PAM_MAX_RESP_SIZE
        *iv_return = PAM_MAX_RESP_SIZE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    /* Names all of length 20.  */
    /* PAM_AUTHINFO_UNAVAIL PAM_NEW_AUTHTOK_REQD */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'T':
      if (memEQ(name, "PAM_AUTHINFO_UNAVAIL", 20)) {
      /*                     ^                    */
#ifdef PAM_AUTHINFO_UNAVAIL
        *iv_return = PAM_AUTHINFO_UNAVAIL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'W':
      if (memEQ(name, "PAM_NEW_AUTHTOK_REQD", 20)) {
      /*                     ^                    */
#ifdef PAM_NEW_AUTHTOK_REQD
        *iv_return = PAM_NEW_AUTHTOK_REQD;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 24:
    if (memEQ(name, "PAM_AUTHTOK_RECOVERY_ERR", 24)) {
#ifdef PAM_AUTHTOK_RECOVERY_ERR
      *iv_return = PAM_AUTHTOK_RECOVERY_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 25:
    /* Names all of length 25.  */
    /* PAM_AUTHTOK_DISABLE_AGING PAM_DISALLOW_NULL_AUTHTOK */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'S':
      if (memEQ(name, "PAM_DISALLOW_NULL_AUTHTOK", 25)) {
      /*                     ^                         */
#ifdef PAM_DISALLOW_NULL_AUTHTOK
        *iv_return = PAM_DISALLOW_NULL_AUTHTOK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "PAM_AUTHTOK_DISABLE_AGING", 25)) {
      /*                     ^                         */
#ifdef PAM_AUTHTOK_DISABLE_AGING
        *iv_return = PAM_AUTHTOK_DISABLE_AGING;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 26:
    if (memEQ(name, "PAM_CHANGE_EXPIRED_AUTHTOK", 26)) {
#ifdef PAM_CHANGE_EXPIRED_AUTHTOK
      *iv_return = PAM_CHANGE_EXPIRED_AUTHTOK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

