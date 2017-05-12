#ifdef __cplusplus
extern "C" {
#endif
#include <starlet.h>
#include <descrip.h>
#include <ssdef.h>
#include <stsdef.h>
#include <impdef.h>
  
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

MODULE = VMS::Persona		PACKAGE = VMS::Persona		
PROTOTYPES: DISABLE

SV *
drop_persona()
   CODE:
{
  int Status;
  unsigned int OldPersona;
  unsigned int NewPersona = 1;
  Status = sys$persona_assume(&NewPersona, 0, &OldPersona);
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    XSRETURN_NO;
  }
  XSRETURN_YES;
}

SV *
delete_persona(Persona)
     unsigned int Persona;
   CODE:
{
  int Status;
  Status = sys$persona_delete(&Persona);
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    XSRETURN_NO;
  }
  XSRETURN_YES;
}

SV *
new_persona(...)
   CODE:
{
  int i, Status;
  char *UserName = NULL;
  unsigned short int NameLen;
  unsigned int PersonaFlags;
  unsigned int PersonaHandle;
  
  struct dsc$descriptor_s UserNameDesc;

  /* Did we get an odd number of items? */
  if (items & 1) {
    croak("Odd number of items passed");
  }

  /* Run through the passed items */
  for(i=0; i<items; i += 2) {
    if (strEQ("NAME", SvPV(ST(i), na))) {
      UserName = SvPV(ST(i + 1), na);
      NameLen = strlen(UserName);
      continue;
    }

    if (strEQ("ASSUME_DEFPRIV", SvPV(ST(i), na))) {
      if (SvTRUE(ST(i+1))) {
        PersonaFlags = PersonaFlags | IMP$M_ASSUME_DEFPRIV;
      }
      continue;
    }
  
    if (strEQ("ASSUME_DEFCLASS", SvPV(ST(i), na))) {
      if (SvTRUE(ST(i+1))) {
        PersonaFlags = PersonaFlags | IMP$M_ASSUME_DEFCLASS;
      }
      continue;
    }

    /* Something we don't recognize here */
    croak("Invalid parameter passed");
  }
    
  UserNameDesc.dsc$a_pointer = UserName;
  UserNameDesc.dsc$w_length = NameLen;
  UserNameDesc.dsc$b_dtype = DSC$K_DTYPE_T;
  UserNameDesc.dsc$b_class = DSC$K_CLASS_S;

  Status = sys$persona_create(&PersonaHandle, &UserNameDesc, PersonaFlags,
                              0, NULL);

  /* If something went wrong, then whine mightily */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    XSRETURN_UNDEF;
  }

  /* Return the handle we got */
  XSRETURN_IV(PersonaHandle);
}

SV *
assume_persona(...)
   CODE:
{
  int i, Status;
  unsigned int PersonaFlags;
  unsigned int PersonaHandle, PrevPersona;
  
  /* Did we get an odd number of items? */
  if (items & 1) {
    croak("Odd number of items passed");
  }

  /* Run through the passed items */
  for(i=0; i<items; i += 2) {
    if (strEQ("PERSONA", SvPV(ST(i), na))) {
      PersonaHandle = SvIV(ST(i + 1));
      continue;
    }

    if (strEQ("ASSUME_SECURITY", SvPV(ST(i), na))) {
      if (SvTRUE(ST(i+1))) {
        PersonaFlags = PersonaFlags | IMP$M_ASSUME_SECURITY;
      }
      continue;
    }
  
    if (strEQ("ASSUME_ACCOUNT", SvPV(ST(i), na))) {
      if (SvTRUE(ST(i+1))) {
        PersonaFlags = PersonaFlags | IMP$M_ASSUME_ACCOUNT;
      }
      continue;
    }
  
    if (strEQ("ASSUME_JOB_WIDE", SvPV(ST(i), na))) {
      if (SvTRUE(ST(i+1))) {
        PersonaFlags = PersonaFlags | IMP$M_ASSUME_JOB_WIDE;
      }
      continue;
    }
  
    /* Something we don't recognize here */
    croak("Invalid parameter passed");
  }
    
  Status = sys$persona_assume(&PersonaHandle, PersonaFlags, &PrevPersona);

  /* If something went wrong, then whine mightily */
  if (Status != SS$_NORMAL) {
    SETERRNO(EVMSERR, Status);
    XSRETURN_UNDEF;
  }

  /* Return the handle we got */
  XSRETURN_YES;
}

