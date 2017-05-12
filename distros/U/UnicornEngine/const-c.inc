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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ERR_ARG UC_ERR_MAP UC_MODE_16 UC_MODE_32 UC_MODE_64 UC_MODE_V8
     UC_MODE_V9 */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case '2':
    if (memEQ(name, "UC_MODE_3", 9)) {
    /*                        2     */
      *iv_return = UC_MODE_32;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "UC_MODE_6", 9)) {
    /*                        4     */
      *iv_return = UC_MODE_64;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "UC_MODE_1", 9)) {
    /*                        6     */
      *iv_return = UC_MODE_16;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "UC_MODE_V", 9)) {
    /*                        8     */
      *iv_return = UC_MODE_V8;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "UC_MODE_V", 9)) {
    /*                        9     */
      *iv_return = UC_MODE_V9;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "UC_ERR_AR", 9)) {
    /*                        G     */
      *iv_return = UC_ERR_ARG;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "UC_ERR_MA", 9)) {
    /*                        P     */
      *iv_return = UC_ERR_MAP;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARCH_ARM UC_ARCH_MAX UC_ARCH_PPC UC_ARCH_X86 UC_ERR_ARCH UC_ERR_HOOK
     UC_ERR_MODE UC_MEM_READ UC_MODE_ARM UC_MODE_QPX UC_PROT_ALL */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case '6':
    if (memEQ(name, "UC_ARCH_X8", 10)) {
    /*                         6      */
      *iv_return = UC_ARCH_X86;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "UC_ARCH_PP", 10)) {
    /*                         C      */
      *iv_return = UC_ARCH_PPC;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "UC_MEM_REA", 10)) {
    /*                         D      */
      *iv_return = UC_MEM_READ;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "UC_ERR_MOD", 10)) {
    /*                         E      */
      *iv_return = UC_ERR_MODE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "UC_ERR_ARC", 10)) {
    /*                         H      */
      *iv_return = UC_ERR_ARCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "UC_ERR_HOO", 10)) {
    /*                         K      */
      *iv_return = UC_ERR_HOOK;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "UC_PROT_AL", 10)) {
    /*                         L      */
      *iv_return = UC_PROT_ALL;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "UC_ARCH_AR", 10)) {
    /*                         M      */
      *iv_return = UC_ARCH_ARM;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_AR", 10)) {
    /*                         M      */
      *iv_return = UC_MODE_ARM;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "UC_ARCH_MA", 10)) {
    /*                         X      */
      *iv_return = UC_ARCH_MAX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_QP", 10)) {
    /*                         X      */
      *iv_return = UC_MODE_QPX;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARCH_M68K UC_ARCH_MIPS UC_ERR_NOMEM UC_HOOK_CODE UC_HOOK_INSN
     UC_HOOK_INTR UC_MEM_FETCH UC_MEM_WRITE UC_PROT_EXEC UC_PROT_NONE
     UC_PROT_READ */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case '8':
    if (memEQ(name, "UC_ARCH_M68K", 12)) {
    /*                         ^        */
      *iv_return = UC_ARCH_M68K;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "UC_PROT_READ", 12)) {
    /*                         ^        */
      *iv_return = UC_PROT_READ;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "UC_MEM_FETCH", 12)) {
    /*                         ^        */
      *iv_return = UC_MEM_FETCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "UC_HOOK_CODE", 12)) {
    /*                         ^        */
      *iv_return = UC_HOOK_CODE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "UC_ERR_NOMEM", 12)) {
    /*                         ^        */
      *iv_return = UC_ERR_NOMEM;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_PROT_EXEC", 12)) {
    /*                         ^        */
      *iv_return = UC_PROT_EXEC;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "UC_PROT_NONE", 12)) {
    /*                         ^        */
      *iv_return = UC_PROT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "UC_ARCH_MIPS", 12)) {
    /*                         ^        */
      *iv_return = UC_ARCH_MIPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "UC_HOOK_INSN", 12)) {
    /*                         ^        */
      *iv_return = UC_HOOK_INSN;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "UC_HOOK_INTR", 12)) {
    /*                         ^        */
      *iv_return = UC_HOOK_INTR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MEM_WRITE", 12)) {
    /*                         ^        */
      *iv_return = UC_MEM_WRITE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARCH_ARM64 UC_ARCH_SPARC UC_ARM_REG_D0 UC_ARM_REG_D1 UC_ARM_REG_D2
     UC_ARM_REG_D3 UC_ARM_REG_D4 UC_ARM_REG_D5 UC_ARM_REG_D6 UC_ARM_REG_D7
     UC_ARM_REG_D8 UC_ARM_REG_D9 UC_ARM_REG_FP UC_ARM_REG_IP UC_ARM_REG_LR
     UC_ARM_REG_PC UC_ARM_REG_Q0 UC_ARM_REG_Q1 UC_ARM_REG_Q2 UC_ARM_REG_Q3
     UC_ARM_REG_Q4 UC_ARM_REG_Q5 UC_ARM_REG_Q6 UC_ARM_REG_Q7 UC_ARM_REG_Q8
     UC_ARM_REG_Q9 UC_ARM_REG_R0 UC_ARM_REG_R1 UC_ARM_REG_R2 UC_ARM_REG_R3
     UC_ARM_REG_R4 UC_ARM_REG_R5 UC_ARM_REG_R6 UC_ARM_REG_R7 UC_ARM_REG_R8
     UC_ARM_REG_R9 UC_ARM_REG_S0 UC_ARM_REG_S1 UC_ARM_REG_S2 UC_ARM_REG_S3
     UC_ARM_REG_S4 UC_ARM_REG_S5 UC_ARM_REG_S6 UC_ARM_REG_S7 UC_ARM_REG_S8
     UC_ARM_REG_S9 UC_ARM_REG_SB UC_ARM_REG_SL UC_ARM_REG_SP UC_ERR_HANDLE
     UC_HOOK_BLOCK UC_MODE_MICRO UC_MODE_MIPS3 UC_MODE_PPC32 UC_MODE_PPC64
     UC_MODE_THUMB UC_PROT_WRITE UC_QUERY_MODE UC_X86_REG_AH UC_X86_REG_AL
     UC_X86_REG_AX UC_X86_REG_BH UC_X86_REG_BL UC_X86_REG_BP UC_X86_REG_BX
     UC_X86_REG_CH UC_X86_REG_CL UC_X86_REG_CS UC_X86_REG_CX UC_X86_REG_DH
     UC_X86_REG_DI UC_X86_REG_DL UC_X86_REG_DS UC_X86_REG_DX UC_X86_REG_ES
     UC_X86_REG_FS UC_X86_REG_GS UC_X86_REG_IP UC_X86_REG_K0 UC_X86_REG_K1
     UC_X86_REG_K2 UC_X86_REG_K3 UC_X86_REG_K4 UC_X86_REG_K5 UC_X86_REG_K6
     UC_X86_REG_K7 UC_X86_REG_R8 UC_X86_REG_R9 UC_X86_REG_SI UC_X86_REG_SP
     UC_X86_REG_SS UC_X86_REG_TR */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case '0':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           0      */
      *iv_return = UC_ARM_REG_D0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           0      */
      *iv_return = UC_ARM_REG_Q0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           0      */
      *iv_return = UC_ARM_REG_R0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           0      */
      *iv_return = UC_ARM_REG_S0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           0      */
      *iv_return = UC_X86_REG_K0;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           1      */
      *iv_return = UC_ARM_REG_D1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           1      */
      *iv_return = UC_ARM_REG_Q1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           1      */
      *iv_return = UC_ARM_REG_R1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           1      */
      *iv_return = UC_ARM_REG_S1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           1      */
      *iv_return = UC_X86_REG_K1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           2      */
      *iv_return = UC_ARM_REG_D2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           2      */
      *iv_return = UC_ARM_REG_Q2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           2      */
      *iv_return = UC_ARM_REG_R2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           2      */
      *iv_return = UC_ARM_REG_S2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_PPC3", 12)) {
    /*                           2      */
      *iv_return = UC_MODE_PPC32;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           2      */
      *iv_return = UC_X86_REG_K2;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           3      */
      *iv_return = UC_ARM_REG_D3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           3      */
      *iv_return = UC_ARM_REG_Q3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           3      */
      *iv_return = UC_ARM_REG_R3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           3      */
      *iv_return = UC_ARM_REG_S3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_MIPS", 12)) {
    /*                           3      */
      *iv_return = UC_MODE_MIPS3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           3      */
      *iv_return = UC_X86_REG_K3;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "UC_ARCH_ARM6", 12)) {
    /*                           4      */
      *iv_return = UC_ARCH_ARM64;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           4      */
      *iv_return = UC_ARM_REG_D4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           4      */
      *iv_return = UC_ARM_REG_Q4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           4      */
      *iv_return = UC_ARM_REG_R4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           4      */
      *iv_return = UC_ARM_REG_S4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_PPC6", 12)) {
    /*                           4      */
      *iv_return = UC_MODE_PPC64;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           4      */
      *iv_return = UC_X86_REG_K4;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           5      */
      *iv_return = UC_ARM_REG_D5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           5      */
      *iv_return = UC_ARM_REG_Q5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           5      */
      *iv_return = UC_ARM_REG_R5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           5      */
      *iv_return = UC_ARM_REG_S5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           5      */
      *iv_return = UC_X86_REG_K5;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           6      */
      *iv_return = UC_ARM_REG_D6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           6      */
      *iv_return = UC_ARM_REG_Q6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           6      */
      *iv_return = UC_ARM_REG_R6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           6      */
      *iv_return = UC_ARM_REG_S6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           6      */
      *iv_return = UC_X86_REG_K6;
      return PERL_constant_ISIV;
    }
    break;
  case '7':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           7      */
      *iv_return = UC_ARM_REG_D7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           7      */
      *iv_return = UC_ARM_REG_Q7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           7      */
      *iv_return = UC_ARM_REG_R7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           7      */
      *iv_return = UC_ARM_REG_S7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_K", 12)) {
    /*                           7      */
      *iv_return = UC_X86_REG_K7;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           8      */
      *iv_return = UC_ARM_REG_D8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           8      */
      *iv_return = UC_ARM_REG_Q8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           8      */
      *iv_return = UC_ARM_REG_R8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           8      */
      *iv_return = UC_ARM_REG_S8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R", 12)) {
    /*                           8      */
      *iv_return = UC_X86_REG_R8;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "UC_ARM_REG_D", 12)) {
    /*                           9      */
      *iv_return = UC_ARM_REG_D9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q", 12)) {
    /*                           9      */
      *iv_return = UC_ARM_REG_Q9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R", 12)) {
    /*                           9      */
      *iv_return = UC_ARM_REG_R9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           9      */
      *iv_return = UC_ARM_REG_S9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R", 12)) {
    /*                           9      */
      *iv_return = UC_X86_REG_R9;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           B      */
      *iv_return = UC_ARM_REG_SB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_THUM", 12)) {
    /*                           B      */
      *iv_return = UC_MODE_THUMB;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "UC_ARCH_SPAR", 12)) {
    /*                           C      */
      *iv_return = UC_ARCH_SPARC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_P", 12)) {
    /*                           C      */
      *iv_return = UC_ARM_REG_PC;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "UC_ERR_HANDL", 12)) {
    /*                           E      */
      *iv_return = UC_ERR_HANDLE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_PROT_WRIT", 12)) {
    /*                           E      */
      *iv_return = UC_PROT_WRITE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_QUERY_MOD", 12)) {
    /*                           E      */
      *iv_return = UC_QUERY_MODE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "UC_X86_REG_A", 12)) {
    /*                           H      */
      *iv_return = UC_X86_REG_AH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_B", 12)) {
    /*                           H      */
      *iv_return = UC_X86_REG_BH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_C", 12)) {
    /*                           H      */
      *iv_return = UC_X86_REG_CH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_D", 12)) {
    /*                           H      */
      *iv_return = UC_X86_REG_DH;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "UC_X86_REG_D", 12)) {
    /*                           I      */
      *iv_return = UC_X86_REG_DI;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_S", 12)) {
    /*                           I      */
      *iv_return = UC_X86_REG_SI;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "UC_HOOK_BLOC", 12)) {
    /*                           K      */
      *iv_return = UC_HOOK_BLOCK;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           L      */
      *iv_return = UC_ARM_REG_SL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_A", 12)) {
    /*                           L      */
      *iv_return = UC_X86_REG_AL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_B", 12)) {
    /*                           L      */
      *iv_return = UC_X86_REG_BL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_C", 12)) {
    /*                           L      */
      *iv_return = UC_X86_REG_CL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_D", 12)) {
    /*                           L      */
      *iv_return = UC_X86_REG_DL;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "UC_MODE_MICR", 12)) {
    /*                           O      */
      *iv_return = UC_MODE_MICRO;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "UC_ARM_REG_F", 12)) {
    /*                           P      */
      *iv_return = UC_ARM_REG_FP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_I", 12)) {
    /*                           P      */
      *iv_return = UC_ARM_REG_IP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S", 12)) {
    /*                           P      */
      *iv_return = UC_ARM_REG_SP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_B", 12)) {
    /*                           P      */
      *iv_return = UC_X86_REG_BP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_I", 12)) {
    /*                           P      */
      *iv_return = UC_X86_REG_IP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_S", 12)) {
    /*                           P      */
      *iv_return = UC_X86_REG_SP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "UC_ARM_REG_L", 12)) {
    /*                           R      */
      *iv_return = UC_ARM_REG_LR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_T", 12)) {
    /*                           R      */
      *iv_return = UC_X86_REG_TR;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "UC_X86_REG_C", 12)) {
    /*                           S      */
      *iv_return = UC_X86_REG_CS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_D", 12)) {
    /*                           S      */
      *iv_return = UC_X86_REG_DS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_E", 12)) {
    /*                           S      */
      *iv_return = UC_X86_REG_ES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_F", 12)) {
    /*                           S      */
      *iv_return = UC_X86_REG_FS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_G", 12)) {
    /*                           S      */
      *iv_return = UC_X86_REG_GS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_S", 12)) {
    /*                           S      */
      *iv_return = UC_X86_REG_SS;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "UC_X86_REG_A", 12)) {
    /*                           X      */
      *iv_return = UC_X86_REG_AX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_B", 12)) {
    /*                           X      */
      *iv_return = UC_X86_REG_BX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_C", 12)) {
    /*                           X      */
      *iv_return = UC_X86_REG_CX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_D", 12)) {
    /*                           X      */
      *iv_return = UC_X86_REG_DX;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARM_REG_D10 UC_ARM_REG_D11 UC_ARM_REG_D12 UC_ARM_REG_D13 UC_ARM_REG_D14
     UC_ARM_REG_D15 UC_ARM_REG_D16 UC_ARM_REG_D17 UC_ARM_REG_D18 UC_ARM_REG_D19
     UC_ARM_REG_D20 UC_ARM_REG_D21 UC_ARM_REG_D22 UC_ARM_REG_D23 UC_ARM_REG_D24
     UC_ARM_REG_D25 UC_ARM_REG_D26 UC_ARM_REG_D27 UC_ARM_REG_D28 UC_ARM_REG_D29
     UC_ARM_REG_D30 UC_ARM_REG_D31 UC_ARM_REG_Q10 UC_ARM_REG_Q11 UC_ARM_REG_Q12
     UC_ARM_REG_Q13 UC_ARM_REG_Q14 UC_ARM_REG_Q15 UC_ARM_REG_R10 UC_ARM_REG_R11
     UC_ARM_REG_R12 UC_ARM_REG_R13 UC_ARM_REG_R14 UC_ARM_REG_R15 UC_ARM_REG_S10
     UC_ARM_REG_S11 UC_ARM_REG_S12 UC_ARM_REG_S13 UC_ARM_REG_S14 UC_ARM_REG_S15
     UC_ARM_REG_S16 UC_ARM_REG_S17 UC_ARM_REG_S18 UC_ARM_REG_S19 UC_ARM_REG_S20
     UC_ARM_REG_S21 UC_ARM_REG_S22 UC_ARM_REG_S23 UC_ARM_REG_S24 UC_ARM_REG_S25
     UC_ARM_REG_S26 UC_ARM_REG_S27 UC_ARM_REG_S28 UC_ARM_REG_S29 UC_ARM_REG_S30
     UC_ARM_REG_S31 UC_ERR_VERSION UC_MODE_MCLASS UC_MODE_MIPS32 UC_MODE_MIPS64
     UC_SPARC_REG_Y UC_X86_REG_BPL UC_X86_REG_CR0 UC_X86_REG_CR1 UC_X86_REG_CR2
     UC_X86_REG_CR3 UC_X86_REG_CR4 UC_X86_REG_CR5 UC_X86_REG_CR6 UC_X86_REG_CR7
     UC_X86_REG_CR8 UC_X86_REG_CR9 UC_X86_REG_DIL UC_X86_REG_DR0 UC_X86_REG_DR1
     UC_X86_REG_DR2 UC_X86_REG_DR3 UC_X86_REG_DR4 UC_X86_REG_DR5 UC_X86_REG_DR6
     UC_X86_REG_DR7 UC_X86_REG_DR8 UC_X86_REG_DR9 UC_X86_REG_EAX UC_X86_REG_EBP
     UC_X86_REG_EBX UC_X86_REG_ECX UC_X86_REG_EDI UC_X86_REG_EDX UC_X86_REG_EIP
     UC_X86_REG_EIZ UC_X86_REG_ESI UC_X86_REG_ESP UC_X86_REG_FP0 UC_X86_REG_FP1
     UC_X86_REG_FP2 UC_X86_REG_FP3 UC_X86_REG_FP4 UC_X86_REG_FP5 UC_X86_REG_FP6
     UC_X86_REG_FP7 UC_X86_REG_MM0 UC_X86_REG_MM1 UC_X86_REG_MM2 UC_X86_REG_MM3
     UC_X86_REG_MM4 UC_X86_REG_MM5 UC_X86_REG_MM6 UC_X86_REG_MM7 UC_X86_REG_R10
     UC_X86_REG_R11 UC_X86_REG_R12 UC_X86_REG_R13 UC_X86_REG_R14 UC_X86_REG_R15
     UC_X86_REG_R8B UC_X86_REG_R8D UC_X86_REG_R8W UC_X86_REG_R9B UC_X86_REG_R9D
     UC_X86_REG_R9W UC_X86_REG_RAX UC_X86_REG_RBP UC_X86_REG_RBX UC_X86_REG_RCX
     UC_X86_REG_RDI UC_X86_REG_RDX UC_X86_REG_RIP UC_X86_REG_RIZ UC_X86_REG_RSI
     UC_X86_REG_RSP UC_X86_REG_SIL UC_X86_REG_SPL UC_X86_REG_ST0 UC_X86_REG_ST1
     UC_X86_REG_ST2 UC_X86_REG_ST3 UC_X86_REG_ST4 UC_X86_REG_ST5 UC_X86_REG_ST6
     UC_X86_REG_ST7 */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case '0':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_D10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_D20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D3", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_D30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q1", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_Q10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R1", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_R10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_S10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_S20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S3", 13)) {
    /*                            0      */
      *iv_return = UC_ARM_REG_S30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            0      */
      *iv_return = UC_X86_REG_CR0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            0      */
      *iv_return = UC_X86_REG_DR0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            0      */
      *iv_return = UC_X86_REG_FP0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            0      */
      *iv_return = UC_X86_REG_MM0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R1", 13)) {
    /*                            0      */
      *iv_return = UC_X86_REG_R10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            0      */
      *iv_return = UC_X86_REG_ST0;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_D11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_D21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D3", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_D31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q1", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_Q11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R1", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_R11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_S11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_S21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S3", 13)) {
    /*                            1      */
      *iv_return = UC_ARM_REG_S31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            1      */
      *iv_return = UC_X86_REG_CR1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            1      */
      *iv_return = UC_X86_REG_DR1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            1      */
      *iv_return = UC_X86_REG_FP1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            1      */
      *iv_return = UC_X86_REG_MM1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R1", 13)) {
    /*                            1      */
      *iv_return = UC_X86_REG_R11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            1      */
      *iv_return = UC_X86_REG_ST1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            2      */
      *iv_return = UC_ARM_REG_D12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            2      */
      *iv_return = UC_ARM_REG_D22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q1", 13)) {
    /*                            2      */
      *iv_return = UC_ARM_REG_Q12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R1", 13)) {
    /*                            2      */
      *iv_return = UC_ARM_REG_R12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            2      */
      *iv_return = UC_ARM_REG_S12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            2      */
      *iv_return = UC_ARM_REG_S22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_MIPS3", 13)) {
    /*                            2      */
      *iv_return = UC_MODE_MIPS32;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            2      */
      *iv_return = UC_X86_REG_CR2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            2      */
      *iv_return = UC_X86_REG_DR2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            2      */
      *iv_return = UC_X86_REG_FP2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            2      */
      *iv_return = UC_X86_REG_MM2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R1", 13)) {
    /*                            2      */
      *iv_return = UC_X86_REG_R12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            2      */
      *iv_return = UC_X86_REG_ST2;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            3      */
      *iv_return = UC_ARM_REG_D13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            3      */
      *iv_return = UC_ARM_REG_D23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q1", 13)) {
    /*                            3      */
      *iv_return = UC_ARM_REG_Q13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R1", 13)) {
    /*                            3      */
      *iv_return = UC_ARM_REG_R13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            3      */
      *iv_return = UC_ARM_REG_S13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            3      */
      *iv_return = UC_ARM_REG_S23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            3      */
      *iv_return = UC_X86_REG_CR3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            3      */
      *iv_return = UC_X86_REG_DR3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            3      */
      *iv_return = UC_X86_REG_FP3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            3      */
      *iv_return = UC_X86_REG_MM3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R1", 13)) {
    /*                            3      */
      *iv_return = UC_X86_REG_R13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            3      */
      *iv_return = UC_X86_REG_ST3;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            4      */
      *iv_return = UC_ARM_REG_D14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            4      */
      *iv_return = UC_ARM_REG_D24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q1", 13)) {
    /*                            4      */
      *iv_return = UC_ARM_REG_Q14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R1", 13)) {
    /*                            4      */
      *iv_return = UC_ARM_REG_R14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            4      */
      *iv_return = UC_ARM_REG_S14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            4      */
      *iv_return = UC_ARM_REG_S24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_MIPS6", 13)) {
    /*                            4      */
      *iv_return = UC_MODE_MIPS64;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            4      */
      *iv_return = UC_X86_REG_CR4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            4      */
      *iv_return = UC_X86_REG_DR4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            4      */
      *iv_return = UC_X86_REG_FP4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            4      */
      *iv_return = UC_X86_REG_MM4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R1", 13)) {
    /*                            4      */
      *iv_return = UC_X86_REG_R14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            4      */
      *iv_return = UC_X86_REG_ST4;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            5      */
      *iv_return = UC_ARM_REG_D15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            5      */
      *iv_return = UC_ARM_REG_D25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_Q1", 13)) {
    /*                            5      */
      *iv_return = UC_ARM_REG_Q15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_R1", 13)) {
    /*                            5      */
      *iv_return = UC_ARM_REG_R15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            5      */
      *iv_return = UC_ARM_REG_S15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            5      */
      *iv_return = UC_ARM_REG_S25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            5      */
      *iv_return = UC_X86_REG_CR5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            5      */
      *iv_return = UC_X86_REG_DR5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            5      */
      *iv_return = UC_X86_REG_FP5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            5      */
      *iv_return = UC_X86_REG_MM5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R1", 13)) {
    /*                            5      */
      *iv_return = UC_X86_REG_R15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            5      */
      *iv_return = UC_X86_REG_ST5;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            6      */
      *iv_return = UC_ARM_REG_D16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            6      */
      *iv_return = UC_ARM_REG_D26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            6      */
      *iv_return = UC_ARM_REG_S16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            6      */
      *iv_return = UC_ARM_REG_S26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            6      */
      *iv_return = UC_X86_REG_CR6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            6      */
      *iv_return = UC_X86_REG_DR6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            6      */
      *iv_return = UC_X86_REG_FP6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            6      */
      *iv_return = UC_X86_REG_MM6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            6      */
      *iv_return = UC_X86_REG_ST6;
      return PERL_constant_ISIV;
    }
    break;
  case '7':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            7      */
      *iv_return = UC_ARM_REG_D17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            7      */
      *iv_return = UC_ARM_REG_D27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            7      */
      *iv_return = UC_ARM_REG_S17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            7      */
      *iv_return = UC_ARM_REG_S27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            7      */
      *iv_return = UC_X86_REG_CR7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            7      */
      *iv_return = UC_X86_REG_DR7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FP", 13)) {
    /*                            7      */
      *iv_return = UC_X86_REG_FP7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_MM", 13)) {
    /*                            7      */
      *iv_return = UC_X86_REG_MM7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ST", 13)) {
    /*                            7      */
      *iv_return = UC_X86_REG_ST7;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            8      */
      *iv_return = UC_ARM_REG_D18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            8      */
      *iv_return = UC_ARM_REG_D28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            8      */
      *iv_return = UC_ARM_REG_S18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            8      */
      *iv_return = UC_ARM_REG_S28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            8      */
      *iv_return = UC_X86_REG_CR8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            8      */
      *iv_return = UC_X86_REG_DR8;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "UC_ARM_REG_D1", 13)) {
    /*                            9      */
      *iv_return = UC_ARM_REG_D19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_D2", 13)) {
    /*                            9      */
      *iv_return = UC_ARM_REG_D29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S1", 13)) {
    /*                            9      */
      *iv_return = UC_ARM_REG_S19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_S2", 13)) {
    /*                            9      */
      *iv_return = UC_ARM_REG_S29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR", 13)) {
    /*                            9      */
      *iv_return = UC_X86_REG_CR9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR", 13)) {
    /*                            9      */
      *iv_return = UC_X86_REG_DR9;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "UC_X86_REG_R8", 13)) {
    /*                            B      */
      *iv_return = UC_X86_REG_R8B;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R9", 13)) {
    /*                            B      */
      *iv_return = UC_X86_REG_R9B;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "UC_X86_REG_R8", 13)) {
    /*                            D      */
      *iv_return = UC_X86_REG_R8D;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R9", 13)) {
    /*                            D      */
      *iv_return = UC_X86_REG_R9D;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "UC_X86_REG_ED", 13)) {
    /*                            I      */
      *iv_return = UC_X86_REG_EDI;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ES", 13)) {
    /*                            I      */
      *iv_return = UC_X86_REG_ESI;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RD", 13)) {
    /*                            I      */
      *iv_return = UC_X86_REG_RDI;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RS", 13)) {
    /*                            I      */
      *iv_return = UC_X86_REG_RSI;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "UC_X86_REG_BP", 13)) {
    /*                            L      */
      *iv_return = UC_X86_REG_BPL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DI", 13)) {
    /*                            L      */
      *iv_return = UC_X86_REG_DIL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_SI", 13)) {
    /*                            L      */
      *iv_return = UC_X86_REG_SIL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_SP", 13)) {
    /*                            L      */
      *iv_return = UC_X86_REG_SPL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "UC_ERR_VERSIO", 13)) {
    /*                            N      */
      *iv_return = UC_ERR_VERSION;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "UC_X86_REG_EB", 13)) {
    /*                            P      */
      *iv_return = UC_X86_REG_EBP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_EI", 13)) {
    /*                            P      */
      *iv_return = UC_X86_REG_EIP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ES", 13)) {
    /*                            P      */
      *iv_return = UC_X86_REG_ESP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RB", 13)) {
    /*                            P      */
      *iv_return = UC_X86_REG_RBP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RI", 13)) {
    /*                            P      */
      *iv_return = UC_X86_REG_RIP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RS", 13)) {
    /*                            P      */
      *iv_return = UC_X86_REG_RSP;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "UC_MODE_MCLAS", 13)) {
    /*                            S      */
      *iv_return = UC_MODE_MCLASS;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "UC_X86_REG_R8", 13)) {
    /*                            W      */
      *iv_return = UC_X86_REG_R8W;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R9", 13)) {
    /*                            W      */
      *iv_return = UC_X86_REG_R9W;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "UC_X86_REG_EA", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_EAX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_EB", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_EBX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_EC", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_ECX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ED", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_EDX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RA", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_RAX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RB", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_RBX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RC", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_RCX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RD", 13)) {
    /*                            X      */
      *iv_return = UC_X86_REG_RDX;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "UC_SPARC_REG_", 13)) {
    /*                            Y      */
      *iv_return = UC_SPARC_REG_Y;
      return PERL_constant_ISIV;
    }
    break;
  case 'Z':
    if (memEQ(name, "UC_X86_REG_EI", 13)) {
    /*                            Z      */
      *iv_return = UC_X86_REG_EIZ;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_RI", 13)) {
    /*                            Z      */
      *iv_return = UC_X86_REG_RIZ;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARM64_REG_B0 UC_ARM64_REG_B1 UC_ARM64_REG_B2 UC_ARM64_REG_B3
     UC_ARM64_REG_B4 UC_ARM64_REG_B5 UC_ARM64_REG_B6 UC_ARM64_REG_B7
     UC_ARM64_REG_B8 UC_ARM64_REG_B9 UC_ARM64_REG_D0 UC_ARM64_REG_D1
     UC_ARM64_REG_D2 UC_ARM64_REG_D3 UC_ARM64_REG_D4 UC_ARM64_REG_D5
     UC_ARM64_REG_D6 UC_ARM64_REG_D7 UC_ARM64_REG_D8 UC_ARM64_REG_D9
     UC_ARM64_REG_FP UC_ARM64_REG_H0 UC_ARM64_REG_H1 UC_ARM64_REG_H2
     UC_ARM64_REG_H3 UC_ARM64_REG_H4 UC_ARM64_REG_H5 UC_ARM64_REG_H6
     UC_ARM64_REG_H7 UC_ARM64_REG_H8 UC_ARM64_REG_H9 UC_ARM64_REG_LR
     UC_ARM64_REG_PC UC_ARM64_REG_Q0 UC_ARM64_REG_Q1 UC_ARM64_REG_Q2
     UC_ARM64_REG_Q3 UC_ARM64_REG_Q4 UC_ARM64_REG_Q5 UC_ARM64_REG_Q6
     UC_ARM64_REG_Q7 UC_ARM64_REG_Q8 UC_ARM64_REG_Q9 UC_ARM64_REG_S0
     UC_ARM64_REG_S1 UC_ARM64_REG_S2 UC_ARM64_REG_S3 UC_ARM64_REG_S4
     UC_ARM64_REG_S5 UC_ARM64_REG_S6 UC_ARM64_REG_S7 UC_ARM64_REG_S8
     UC_ARM64_REG_S9 UC_ARM64_REG_SP UC_ARM64_REG_V0 UC_ARM64_REG_V1
     UC_ARM64_REG_V2 UC_ARM64_REG_V3 UC_ARM64_REG_V4 UC_ARM64_REG_V5
     UC_ARM64_REG_V6 UC_ARM64_REG_V7 UC_ARM64_REG_V8 UC_ARM64_REG_V9
     UC_ARM64_REG_W0 UC_ARM64_REG_W1 UC_ARM64_REG_W2 UC_ARM64_REG_W3
     UC_ARM64_REG_W4 UC_ARM64_REG_W5 UC_ARM64_REG_W6 UC_ARM64_REG_W7
     UC_ARM64_REG_W8 UC_ARM64_REG_W9 UC_ARM64_REG_X0 UC_ARM64_REG_X1
     UC_ARM64_REG_X2 UC_ARM64_REG_X3 UC_ARM64_REG_X4 UC_ARM64_REG_X5
     UC_ARM64_REG_X6 UC_ARM64_REG_X7 UC_ARM64_REG_X8 UC_ARM64_REG_X9
     UC_ARM_REG_APSR UC_ARM_REG_CPSR UC_ARM_REG_SPSR UC_ERR_RESOURCE
     UC_MODE_SPARC32 UC_MODE_SPARC64 UC_SPARC_REG_F0 UC_SPARC_REG_F1
     UC_SPARC_REG_F2 UC_SPARC_REG_F3 UC_SPARC_REG_F4 UC_SPARC_REG_F5
     UC_SPARC_REG_F6 UC_SPARC_REG_F7 UC_SPARC_REG_F8 UC_SPARC_REG_F9
     UC_SPARC_REG_FP UC_SPARC_REG_G0 UC_SPARC_REG_G1 UC_SPARC_REG_G2
     UC_SPARC_REG_G3 UC_SPARC_REG_G4 UC_SPARC_REG_G5 UC_SPARC_REG_G6
     UC_SPARC_REG_G7 UC_SPARC_REG_I0 UC_SPARC_REG_I1 UC_SPARC_REG_I2
     UC_SPARC_REG_I3 UC_SPARC_REG_I4 UC_SPARC_REG_I5 UC_SPARC_REG_I6
     UC_SPARC_REG_I7 UC_SPARC_REG_L0 UC_SPARC_REG_L1 UC_SPARC_REG_L2
     UC_SPARC_REG_L3 UC_SPARC_REG_L4 UC_SPARC_REG_L5 UC_SPARC_REG_L6
     UC_SPARC_REG_L7 UC_SPARC_REG_O0 UC_SPARC_REG_O1 UC_SPARC_REG_O2
     UC_SPARC_REG_O3 UC_SPARC_REG_O4 UC_SPARC_REG_O5 UC_SPARC_REG_O6
     UC_SPARC_REG_O7 UC_SPARC_REG_PC UC_SPARC_REG_SP UC_X86_REG_CR10
     UC_X86_REG_CR11 UC_X86_REG_CR12 UC_X86_REG_CR13 UC_X86_REG_CR14
     UC_X86_REG_CR15 UC_X86_REG_DR10 UC_X86_REG_DR11 UC_X86_REG_DR12
     UC_X86_REG_DR13 UC_X86_REG_DR14 UC_X86_REG_DR15 UC_X86_REG_FPCW
     UC_X86_REG_FPSW UC_X86_REG_GDTR UC_X86_REG_IDTR UC_X86_REG_LDTR
     UC_X86_REG_R10B UC_X86_REG_R10D UC_X86_REG_R10W UC_X86_REG_R11B
     UC_X86_REG_R11D UC_X86_REG_R11W UC_X86_REG_R12B UC_X86_REG_R12D
     UC_X86_REG_R12W UC_X86_REG_R13B UC_X86_REG_R13D UC_X86_REG_R13W
     UC_X86_REG_R14B UC_X86_REG_R14D UC_X86_REG_R14W UC_X86_REG_R15B
     UC_X86_REG_R15D UC_X86_REG_R15W UC_X86_REG_XMM0 UC_X86_REG_XMM1
     UC_X86_REG_XMM2 UC_X86_REG_XMM3 UC_X86_REG_XMM4 UC_X86_REG_XMM5
     UC_X86_REG_XMM6 UC_X86_REG_XMM7 UC_X86_REG_XMM8 UC_X86_REG_XMM9
     UC_X86_REG_YMM0 UC_X86_REG_YMM1 UC_X86_REG_YMM2 UC_X86_REG_YMM3
     UC_X86_REG_YMM4 UC_X86_REG_YMM5 UC_X86_REG_YMM6 UC_X86_REG_YMM7
     UC_X86_REG_YMM8 UC_X86_REG_YMM9 UC_X86_REG_ZMM0 UC_X86_REG_ZMM1
     UC_X86_REG_ZMM2 UC_X86_REG_ZMM3 UC_X86_REG_ZMM4 UC_X86_REG_ZMM5
     UC_X86_REG_ZMM6 UC_X86_REG_ZMM7 UC_X86_REG_ZMM8 UC_X86_REG_ZMM9 */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case '0':
    if (memEQ(name, "UC_X86_REG_R10B", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R10B;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R10D", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R10D;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R10W", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R10W;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "UC_X86_REG_CR10", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_CR10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR11", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_CR11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR12", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_CR12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR13", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_CR13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR14", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_CR14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_CR15", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_CR15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR10", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_DR10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR11", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_DR11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR12", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_DR12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR13", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_DR13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR14", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_DR14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_DR15", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_DR15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R11B", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R11B;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R11D", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R11D;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R11W", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R11W;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "UC_X86_REG_R12B", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R12B;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R12D", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R12D;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R12W", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R12W;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "UC_MODE_SPARC32", 15)) {
    /*                            ^        */
      *iv_return = UC_MODE_SPARC32;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R13B", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R13B;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R13D", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R13D;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R13W", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R13W;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "UC_X86_REG_R14B", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R14B;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R14D", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R14D;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R14W", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R14W;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "UC_X86_REG_R15B", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R15B;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R15D", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R15D;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_R15W", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_R15W;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "UC_MODE_SPARC64", 15)) {
    /*                            ^        */
      *iv_return = UC_MODE_SPARC64;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "UC_ARM64_REG_B0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_B9;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "UC_ERR_RESOURCE", 15)) {
    /*                            ^        */
      *iv_return = UC_ERR_RESOURCE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FPCW", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_FPCW;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "UC_ARM64_REG_D0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_D9;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "UC_ARM64_REG_FP", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_FP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F0", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F3", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F4", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F5", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F6", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F7", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F8", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F9", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_F9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_FP", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_FP;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "UC_SPARC_REG_G0", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_G1", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_G2", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_G3", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_G4", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_G5", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_G6", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_G7", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_G7;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "UC_ARM64_REG_H0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_H9;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "UC_SPARC_REG_I0", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_I1", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_I2", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_I3", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_I4", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_I5", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_I6", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_I7", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_I7;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "UC_ARM64_REG_LR", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_LR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L0", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L1", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L2", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L3", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L4", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L5", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L6", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_L7", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_L7;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "UC_X86_REG_XMM0", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM3", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM4", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM5", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM6", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM7", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM8", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM9", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_XMM9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM0", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM3", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM4", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM5", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM6", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM7", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM8", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM9", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_YMM9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM0", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM3", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM4", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM5", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM6", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM7", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM8", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM9", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_ZMM9;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "UC_SPARC_REG_O0", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_O1", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_O2", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_O3", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_O4", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_O5", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_O6", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_O7", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_O7;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "UC_ARM64_REG_PC", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_PC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_PC", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_PC;
      return PERL_constant_ISIV;
    }
    break;
  case 'Q':
    if (memEQ(name, "UC_ARM64_REG_Q0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_Q9;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "UC_ARM64_REG_S0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_S9;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_SP", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_SP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_APSR", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM_REG_APSR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_CPSR", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM_REG_CPSR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_SPSR", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM_REG_SPSR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_SP", 15)) {
    /*                            ^        */
      *iv_return = UC_SPARC_REG_SP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_FPSW", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_FPSW;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "UC_X86_REG_GDTR", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_GDTR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_IDTR", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_IDTR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_LDTR", 15)) {
    /*                            ^        */
      *iv_return = UC_X86_REG_LDTR;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "UC_ARM64_REG_V0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_V9;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "UC_ARM64_REG_W0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_W9;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "UC_ARM64_REG_X0", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X3", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X4", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X4;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X5", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X6", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X7", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X7;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X8", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X9", 15)) {
    /*                            ^        */
      *iv_return = UC_ARM64_REG_X9;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARM64_REG_B10 UC_ARM64_REG_B11 UC_ARM64_REG_B12 UC_ARM64_REG_B13
     UC_ARM64_REG_B14 UC_ARM64_REG_B15 UC_ARM64_REG_B16 UC_ARM64_REG_B17
     UC_ARM64_REG_B18 UC_ARM64_REG_B19 UC_ARM64_REG_B20 UC_ARM64_REG_B21
     UC_ARM64_REG_B22 UC_ARM64_REG_B23 UC_ARM64_REG_B24 UC_ARM64_REG_B25
     UC_ARM64_REG_B26 UC_ARM64_REG_B27 UC_ARM64_REG_B28 UC_ARM64_REG_B29
     UC_ARM64_REG_B30 UC_ARM64_REG_B31 UC_ARM64_REG_D10 UC_ARM64_REG_D11
     UC_ARM64_REG_D12 UC_ARM64_REG_D13 UC_ARM64_REG_D14 UC_ARM64_REG_D15
     UC_ARM64_REG_D16 UC_ARM64_REG_D17 UC_ARM64_REG_D18 UC_ARM64_REG_D19
     UC_ARM64_REG_D20 UC_ARM64_REG_D21 UC_ARM64_REG_D22 UC_ARM64_REG_D23
     UC_ARM64_REG_D24 UC_ARM64_REG_D25 UC_ARM64_REG_D26 UC_ARM64_REG_D27
     UC_ARM64_REG_D28 UC_ARM64_REG_D29 UC_ARM64_REG_D30 UC_ARM64_REG_D31
     UC_ARM64_REG_H10 UC_ARM64_REG_H11 UC_ARM64_REG_H12 UC_ARM64_REG_H13
     UC_ARM64_REG_H14 UC_ARM64_REG_H15 UC_ARM64_REG_H16 UC_ARM64_REG_H17
     UC_ARM64_REG_H18 UC_ARM64_REG_H19 UC_ARM64_REG_H20 UC_ARM64_REG_H21
     UC_ARM64_REG_H22 UC_ARM64_REG_H23 UC_ARM64_REG_H24 UC_ARM64_REG_H25
     UC_ARM64_REG_H26 UC_ARM64_REG_H27 UC_ARM64_REG_H28 UC_ARM64_REG_H29
     UC_ARM64_REG_H30 UC_ARM64_REG_H31 UC_ARM64_REG_IP0 UC_ARM64_REG_IP1
     UC_ARM64_REG_Q10 UC_ARM64_REG_Q11 UC_ARM64_REG_Q12 UC_ARM64_REG_Q13
     UC_ARM64_REG_Q14 UC_ARM64_REG_Q15 UC_ARM64_REG_Q16 UC_ARM64_REG_Q17
     UC_ARM64_REG_Q18 UC_ARM64_REG_Q19 UC_ARM64_REG_Q20 UC_ARM64_REG_Q21
     UC_ARM64_REG_Q22 UC_ARM64_REG_Q23 UC_ARM64_REG_Q24 UC_ARM64_REG_Q25
     UC_ARM64_REG_Q26 UC_ARM64_REG_Q27 UC_ARM64_REG_Q28 UC_ARM64_REG_Q29
     UC_ARM64_REG_Q30 UC_ARM64_REG_Q31 UC_ARM64_REG_S10 UC_ARM64_REG_S11
     UC_ARM64_REG_S12 UC_ARM64_REG_S13 UC_ARM64_REG_S14 UC_ARM64_REG_S15
     UC_ARM64_REG_S16 UC_ARM64_REG_S17 UC_ARM64_REG_S18 UC_ARM64_REG_S19
     UC_ARM64_REG_S20 UC_ARM64_REG_S21 UC_ARM64_REG_S22 UC_ARM64_REG_S23
     UC_ARM64_REG_S24 UC_ARM64_REG_S25 UC_ARM64_REG_S26 UC_ARM64_REG_S27
     UC_ARM64_REG_S28 UC_ARM64_REG_S29 UC_ARM64_REG_S30 UC_ARM64_REG_S31
     UC_ARM64_REG_V10 UC_ARM64_REG_V11 UC_ARM64_REG_V12 UC_ARM64_REG_V13
     UC_ARM64_REG_V14 UC_ARM64_REG_V15 UC_ARM64_REG_V16 UC_ARM64_REG_V17
     UC_ARM64_REG_V18 UC_ARM64_REG_V19 UC_ARM64_REG_V20 UC_ARM64_REG_V21
     UC_ARM64_REG_V22 UC_ARM64_REG_V23 UC_ARM64_REG_V24 UC_ARM64_REG_V25
     UC_ARM64_REG_V26 UC_ARM64_REG_V27 UC_ARM64_REG_V28 UC_ARM64_REG_V29
     UC_ARM64_REG_V30 UC_ARM64_REG_V31 UC_ARM64_REG_W10 UC_ARM64_REG_W11
     UC_ARM64_REG_W12 UC_ARM64_REG_W13 UC_ARM64_REG_W14 UC_ARM64_REG_W15
     UC_ARM64_REG_W16 UC_ARM64_REG_W17 UC_ARM64_REG_W18 UC_ARM64_REG_W19
     UC_ARM64_REG_W20 UC_ARM64_REG_W21 UC_ARM64_REG_W22 UC_ARM64_REG_W23
     UC_ARM64_REG_W24 UC_ARM64_REG_W25 UC_ARM64_REG_W26 UC_ARM64_REG_W27
     UC_ARM64_REG_W28 UC_ARM64_REG_W29 UC_ARM64_REG_W30 UC_ARM64_REG_WSP
     UC_ARM64_REG_WZR UC_ARM64_REG_X10 UC_ARM64_REG_X11 UC_ARM64_REG_X12
     UC_ARM64_REG_X13 UC_ARM64_REG_X14 UC_ARM64_REG_X15 UC_ARM64_REG_X16
     UC_ARM64_REG_X17 UC_ARM64_REG_X18 UC_ARM64_REG_X19 UC_ARM64_REG_X20
     UC_ARM64_REG_X21 UC_ARM64_REG_X22 UC_ARM64_REG_X23 UC_ARM64_REG_X24
     UC_ARM64_REG_X25 UC_ARM64_REG_X26 UC_ARM64_REG_X27 UC_ARM64_REG_X28
     UC_ARM64_REG_X29 UC_ARM64_REG_X30 UC_ARM64_REG_XZR UC_ARM_REG_FPEXC
     UC_ARM_REG_FPSCR UC_ARM_REG_FPSID UC_ARM_REG_MVFR0 UC_ARM_REG_MVFR1
     UC_ARM_REG_MVFR2 UC_ERR_EXCEPTION UC_ERR_READ_PROT UC_HOOK_MEM_READ
     UC_MEM_READ_PROT UC_MODE_MIPS32R6 UC_SPARC_REG_F10 UC_SPARC_REG_F11
     UC_SPARC_REG_F12 UC_SPARC_REG_F13 UC_SPARC_REG_F14 UC_SPARC_REG_F15
     UC_SPARC_REG_F16 UC_SPARC_REG_F17 UC_SPARC_REG_F18 UC_SPARC_REG_F19
     UC_SPARC_REG_F20 UC_SPARC_REG_F21 UC_SPARC_REG_F22 UC_SPARC_REG_F23
     UC_SPARC_REG_F24 UC_SPARC_REG_F25 UC_SPARC_REG_F26 UC_SPARC_REG_F27
     UC_SPARC_REG_F28 UC_SPARC_REG_F29 UC_SPARC_REG_F30 UC_SPARC_REG_F31
     UC_SPARC_REG_F32 UC_SPARC_REG_F34 UC_SPARC_REG_F36 UC_SPARC_REG_F38
     UC_SPARC_REG_F40 UC_SPARC_REG_F42 UC_SPARC_REG_F44 UC_SPARC_REG_F46
     UC_SPARC_REG_F48 UC_SPARC_REG_F50 UC_SPARC_REG_F52 UC_SPARC_REG_F54
     UC_SPARC_REG_F56 UC_SPARC_REG_F58 UC_SPARC_REG_F60 UC_SPARC_REG_F62
     UC_SPARC_REG_ICC UC_SPARC_REG_XCC UC_X86_REG_FPTAG UC_X86_REG_XMM10
     UC_X86_REG_XMM11 UC_X86_REG_XMM12 UC_X86_REG_XMM13 UC_X86_REG_XMM14
     UC_X86_REG_XMM15 UC_X86_REG_XMM16 UC_X86_REG_XMM17 UC_X86_REG_XMM18
     UC_X86_REG_XMM19 UC_X86_REG_XMM20 UC_X86_REG_XMM21 UC_X86_REG_XMM22
     UC_X86_REG_XMM23 UC_X86_REG_XMM24 UC_X86_REG_XMM25 UC_X86_REG_XMM26
     UC_X86_REG_XMM27 UC_X86_REG_XMM28 UC_X86_REG_XMM29 UC_X86_REG_XMM30
     UC_X86_REG_XMM31 UC_X86_REG_YMM10 UC_X86_REG_YMM11 UC_X86_REG_YMM12
     UC_X86_REG_YMM13 UC_X86_REG_YMM14 UC_X86_REG_YMM15 UC_X86_REG_YMM16
     UC_X86_REG_YMM17 UC_X86_REG_YMM18 UC_X86_REG_YMM19 UC_X86_REG_YMM20
     UC_X86_REG_YMM21 UC_X86_REG_YMM22 UC_X86_REG_YMM23 UC_X86_REG_YMM24
     UC_X86_REG_YMM25 UC_X86_REG_YMM26 UC_X86_REG_YMM27 UC_X86_REG_YMM28
     UC_X86_REG_YMM29 UC_X86_REG_YMM30 UC_X86_REG_YMM31 UC_X86_REG_ZMM10
     UC_X86_REG_ZMM11 UC_X86_REG_ZMM12 UC_X86_REG_ZMM13 UC_X86_REG_ZMM14
     UC_X86_REG_ZMM15 UC_X86_REG_ZMM16 UC_X86_REG_ZMM17 UC_X86_REG_ZMM18
     UC_X86_REG_ZMM19 UC_X86_REG_ZMM20 UC_X86_REG_ZMM21 UC_X86_REG_ZMM22
     UC_X86_REG_ZMM23 UC_X86_REG_ZMM24 UC_X86_REG_ZMM25 UC_X86_REG_ZMM26
     UC_X86_REG_ZMM27 UC_X86_REG_ZMM28 UC_X86_REG_ZMM29 UC_X86_REG_ZMM30
     UC_X86_REG_ZMM31 */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case '0':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_B10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_B20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_B30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_D10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_D20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_D30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_H10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_H20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_H30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_IP", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_IP0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_Q10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_Q20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_Q30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_S10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_S20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_S30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_V10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_V20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_V30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_W10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_W20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_W30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_X10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_X20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X3", 15)) {
    /*                              0      */
      *iv_return = UC_ARM64_REG_X30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_MVFR", 15)) {
    /*                              0      */
      *iv_return = UC_ARM_REG_MVFR0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              0      */
      *iv_return = UC_SPARC_REG_F10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              0      */
      *iv_return = UC_SPARC_REG_F20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F3", 15)) {
    /*                              0      */
      *iv_return = UC_SPARC_REG_F30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F4", 15)) {
    /*                              0      */
      *iv_return = UC_SPARC_REG_F40;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F5", 15)) {
    /*                              0      */
      *iv_return = UC_SPARC_REG_F50;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F6", 15)) {
    /*                              0      */
      *iv_return = UC_SPARC_REG_F60;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_XMM10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_XMM20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM3", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_XMM30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_YMM10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_YMM20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM3", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_YMM30;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_ZMM10;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_ZMM20;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM3", 15)) {
    /*                              0      */
      *iv_return = UC_X86_REG_ZMM30;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_B11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_B21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B3", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_B31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_D11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_D21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D3", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_D31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_H11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_H21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H3", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_H31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_IP", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_IP1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_Q11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_Q21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q3", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_Q31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_S11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_S21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S3", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_S31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_V11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_V21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V3", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_V31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_W11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_W21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_X11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              1      */
      *iv_return = UC_ARM64_REG_X21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_MVFR", 15)) {
    /*                              1      */
      *iv_return = UC_ARM_REG_MVFR1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              1      */
      *iv_return = UC_SPARC_REG_F11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              1      */
      *iv_return = UC_SPARC_REG_F21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F3", 15)) {
    /*                              1      */
      *iv_return = UC_SPARC_REG_F31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_XMM11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_XMM21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM3", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_XMM31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_YMM11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_YMM21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM3", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_YMM31;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_ZMM11;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_ZMM21;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM3", 15)) {
    /*                              1      */
      *iv_return = UC_X86_REG_ZMM31;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_B12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_B22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_D12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_D22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_H12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_H22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_Q12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_Q22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_S12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_S22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_V12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_V22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_W12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_W22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_X12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              2      */
      *iv_return = UC_ARM64_REG_X22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_MVFR", 15)) {
    /*                              2      */
      *iv_return = UC_ARM_REG_MVFR2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              2      */
      *iv_return = UC_SPARC_REG_F12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              2      */
      *iv_return = UC_SPARC_REG_F22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F3", 15)) {
    /*                              2      */
      *iv_return = UC_SPARC_REG_F32;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F4", 15)) {
    /*                              2      */
      *iv_return = UC_SPARC_REG_F42;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F5", 15)) {
    /*                              2      */
      *iv_return = UC_SPARC_REG_F52;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F6", 15)) {
    /*                              2      */
      *iv_return = UC_SPARC_REG_F62;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              2      */
      *iv_return = UC_X86_REG_XMM12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              2      */
      *iv_return = UC_X86_REG_XMM22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              2      */
      *iv_return = UC_X86_REG_YMM12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              2      */
      *iv_return = UC_X86_REG_YMM22;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              2      */
      *iv_return = UC_X86_REG_ZMM12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              2      */
      *iv_return = UC_X86_REG_ZMM22;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_B13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_B23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_D13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_D23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_H13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_H23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_Q13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_Q23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_S13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_S23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_V13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_V23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_W13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_W23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_X13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              3      */
      *iv_return = UC_ARM64_REG_X23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              3      */
      *iv_return = UC_SPARC_REG_F13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              3      */
      *iv_return = UC_SPARC_REG_F23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              3      */
      *iv_return = UC_X86_REG_XMM13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              3      */
      *iv_return = UC_X86_REG_XMM23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              3      */
      *iv_return = UC_X86_REG_YMM13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              3      */
      *iv_return = UC_X86_REG_YMM23;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              3      */
      *iv_return = UC_X86_REG_ZMM13;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              3      */
      *iv_return = UC_X86_REG_ZMM23;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_B14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_B24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_D14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_D24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_H14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_H24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_Q14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_Q24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_S14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_S24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_V14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_V24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_W14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_W24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_X14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              4      */
      *iv_return = UC_ARM64_REG_X24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              4      */
      *iv_return = UC_SPARC_REG_F14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              4      */
      *iv_return = UC_SPARC_REG_F24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F3", 15)) {
    /*                              4      */
      *iv_return = UC_SPARC_REG_F34;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F4", 15)) {
    /*                              4      */
      *iv_return = UC_SPARC_REG_F44;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F5", 15)) {
    /*                              4      */
      *iv_return = UC_SPARC_REG_F54;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              4      */
      *iv_return = UC_X86_REG_XMM14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              4      */
      *iv_return = UC_X86_REG_XMM24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              4      */
      *iv_return = UC_X86_REG_YMM14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              4      */
      *iv_return = UC_X86_REG_YMM24;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              4      */
      *iv_return = UC_X86_REG_ZMM14;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              4      */
      *iv_return = UC_X86_REG_ZMM24;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_B15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_B25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_D15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_D25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_H15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_H25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_Q15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_Q25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_S15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_S25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_V15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_V25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_W15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_W25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_X15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              5      */
      *iv_return = UC_ARM64_REG_X25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              5      */
      *iv_return = UC_SPARC_REG_F15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              5      */
      *iv_return = UC_SPARC_REG_F25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              5      */
      *iv_return = UC_X86_REG_XMM15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              5      */
      *iv_return = UC_X86_REG_XMM25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              5      */
      *iv_return = UC_X86_REG_YMM15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              5      */
      *iv_return = UC_X86_REG_YMM25;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              5      */
      *iv_return = UC_X86_REG_ZMM15;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              5      */
      *iv_return = UC_X86_REG_ZMM25;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_B16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_B26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_D16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_D26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_H16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_H26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_Q16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_Q26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_S16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_S26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_V16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_V26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_W16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_W26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_X16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              6      */
      *iv_return = UC_ARM64_REG_X26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MODE_MIPS32R", 15)) {
    /*                              6      */
      *iv_return = UC_MODE_MIPS32R6;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              6      */
      *iv_return = UC_SPARC_REG_F16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              6      */
      *iv_return = UC_SPARC_REG_F26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F3", 15)) {
    /*                              6      */
      *iv_return = UC_SPARC_REG_F36;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F4", 15)) {
    /*                              6      */
      *iv_return = UC_SPARC_REG_F46;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F5", 15)) {
    /*                              6      */
      *iv_return = UC_SPARC_REG_F56;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              6      */
      *iv_return = UC_X86_REG_XMM16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              6      */
      *iv_return = UC_X86_REG_XMM26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              6      */
      *iv_return = UC_X86_REG_YMM16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              6      */
      *iv_return = UC_X86_REG_YMM26;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              6      */
      *iv_return = UC_X86_REG_ZMM16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              6      */
      *iv_return = UC_X86_REG_ZMM26;
      return PERL_constant_ISIV;
    }
    break;
  case '7':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_B17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_B27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_D17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_D27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_H17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_H27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_Q17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_Q27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_S17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_S27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_V17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_V27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_W17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_W27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_X17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              7      */
      *iv_return = UC_ARM64_REG_X27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              7      */
      *iv_return = UC_SPARC_REG_F17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              7      */
      *iv_return = UC_SPARC_REG_F27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              7      */
      *iv_return = UC_X86_REG_XMM17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              7      */
      *iv_return = UC_X86_REG_XMM27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              7      */
      *iv_return = UC_X86_REG_YMM17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              7      */
      *iv_return = UC_X86_REG_YMM27;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              7      */
      *iv_return = UC_X86_REG_ZMM17;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              7      */
      *iv_return = UC_X86_REG_ZMM27;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_B18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_B28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_D18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_D28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_H18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_H28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_Q18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_Q28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_S18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_S28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_V18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_V28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_W18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_W28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_X18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              8      */
      *iv_return = UC_ARM64_REG_X28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              8      */
      *iv_return = UC_SPARC_REG_F18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              8      */
      *iv_return = UC_SPARC_REG_F28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F3", 15)) {
    /*                              8      */
      *iv_return = UC_SPARC_REG_F38;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F4", 15)) {
    /*                              8      */
      *iv_return = UC_SPARC_REG_F48;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F5", 15)) {
    /*                              8      */
      *iv_return = UC_SPARC_REG_F58;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              8      */
      *iv_return = UC_X86_REG_XMM18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              8      */
      *iv_return = UC_X86_REG_XMM28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              8      */
      *iv_return = UC_X86_REG_YMM18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              8      */
      *iv_return = UC_X86_REG_YMM28;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              8      */
      *iv_return = UC_X86_REG_ZMM18;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              8      */
      *iv_return = UC_X86_REG_ZMM28;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "UC_ARM64_REG_B1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_B19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_B2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_B29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_D19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_D2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_D29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_H19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_H2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_H29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_Q19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_Q2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_Q29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_S19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_S2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_S29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_V19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_V2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_V29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_W19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_W2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_W29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X1", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_X19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_X2", 15)) {
    /*                              9      */
      *iv_return = UC_ARM64_REG_X29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F1", 15)) {
    /*                              9      */
      *iv_return = UC_SPARC_REG_F19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_F2", 15)) {
    /*                              9      */
      *iv_return = UC_SPARC_REG_F29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM1", 15)) {
    /*                              9      */
      *iv_return = UC_X86_REG_XMM19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_XMM2", 15)) {
    /*                              9      */
      *iv_return = UC_X86_REG_XMM29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM1", 15)) {
    /*                              9      */
      *iv_return = UC_X86_REG_YMM19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_YMM2", 15)) {
    /*                              9      */
      *iv_return = UC_X86_REG_YMM29;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM1", 15)) {
    /*                              9      */
      *iv_return = UC_X86_REG_ZMM19;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_X86_REG_ZMM2", 15)) {
    /*                              9      */
      *iv_return = UC_X86_REG_ZMM29;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "UC_ARM_REG_FPEX", 15)) {
    /*                              C      */
      *iv_return = UC_ARM_REG_FPEXC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_IC", 15)) {
    /*                              C      */
      *iv_return = UC_SPARC_REG_ICC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_XC", 15)) {
    /*                              C      */
      *iv_return = UC_SPARC_REG_XCC;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "UC_ARM_REG_FPSI", 15)) {
    /*                              D      */
      *iv_return = UC_ARM_REG_FPSID;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_HOOK_MEM_REA", 15)) {
    /*                              D      */
      *iv_return = UC_HOOK_MEM_READ;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "UC_X86_REG_FPTA", 15)) {
    /*                              G      */
      *iv_return = UC_X86_REG_FPTAG;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "UC_ERR_EXCEPTIO", 15)) {
    /*                              N      */
      *iv_return = UC_ERR_EXCEPTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "UC_ARM64_REG_WS", 15)) {
    /*                              P      */
      *iv_return = UC_ARM64_REG_WSP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "UC_ARM64_REG_WZ", 15)) {
    /*                              R      */
      *iv_return = UC_ARM64_REG_WZR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM64_REG_XZ", 15)) {
    /*                              R      */
      *iv_return = UC_ARM64_REG_XZR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ARM_REG_FPSC", 15)) {
    /*                              R      */
      *iv_return = UC_ARM_REG_FPSCR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "UC_ERR_READ_PRO", 15)) {
    /*                              T      */
      *iv_return = UC_ERR_READ_PROT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MEM_READ_PRO", 15)) {
    /*                              T      */
      *iv_return = UC_MEM_READ_PROT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARM64_REG_NZCV UC_ARM_REG_FPINST UC_ERR_FETCH_PROT UC_ERR_HOOK_EXIST
     UC_ERR_WRITE_PROT UC_HOOK_MEM_FETCH UC_HOOK_MEM_VALID UC_HOOK_MEM_WRITE
     UC_MEM_FETCH_PROT UC_MEM_WRITE_PROT UC_SPARC_REG_FCC0 UC_SPARC_REG_FCC1
     UC_SPARC_REG_FCC2 UC_SPARC_REG_FCC3 UC_X86_REG_EFLAGS */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'A':
    if (memEQ(name, "UC_HOOK_MEM_VALID", 17)) {
    /*                            ^          */
      *iv_return = UC_HOOK_MEM_VALID;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "UC_HOOK_MEM_FETCH", 17)) {
    /*                            ^          */
      *iv_return = UC_HOOK_MEM_FETCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "UC_SPARC_REG_FCC0", 17)) {
    /*                            ^          */
      *iv_return = UC_SPARC_REG_FCC0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_FCC1", 17)) {
    /*                            ^          */
      *iv_return = UC_SPARC_REG_FCC1;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_FCC2", 17)) {
    /*                            ^          */
      *iv_return = UC_SPARC_REG_FCC2;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_SPARC_REG_FCC3", 17)) {
    /*                            ^          */
      *iv_return = UC_SPARC_REG_FCC3;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "UC_ARM_REG_FPINST", 17)) {
    /*                            ^          */
      *iv_return = UC_ARM_REG_FPINST;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "UC_X86_REG_EFLAGS", 17)) {
    /*                            ^          */
      *iv_return = UC_X86_REG_EFLAGS;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "UC_ARM64_REG_NZCV", 17)) {
    /*                            ^          */
      *iv_return = UC_ARM64_REG_NZCV;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "UC_ERR_FETCH_PROT", 17)) {
    /*                            ^          */
      *iv_return = UC_ERR_FETCH_PROT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ERR_WRITE_PROT", 17)) {
    /*                            ^          */
      *iv_return = UC_ERR_WRITE_PROT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MEM_FETCH_PROT", 17)) {
    /*                            ^          */
      *iv_return = UC_MEM_FETCH_PROT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MEM_WRITE_PROT", 17)) {
    /*                            ^          */
      *iv_return = UC_MEM_WRITE_PROT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "UC_HOOK_MEM_WRITE", 17)) {
    /*                            ^          */
      *iv_return = UC_HOOK_MEM_WRITE;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "UC_ERR_HOOK_EXIST", 17)) {
    /*                            ^          */
      *iv_return = UC_ERR_HOOK_EXIST;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARM_REG_FPINST2 UC_ARM_REG_ITSTATE UC_MODE_BIG_ENDIAN
     UC_QUERY_PAGE_SIZE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'D':
    if (memEQ(name, "UC_MODE_BIG_ENDIAN", 18)) {
    /*                             ^          */
      *iv_return = UC_MODE_BIG_ENDIAN;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "UC_ARM_REG_FPINST2", 18)) {
    /*                             ^          */
      *iv_return = UC_ARM_REG_FPINST2;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "UC_QUERY_PAGE_SIZE", 18)) {
    /*                             ^          */
      *iv_return = UC_QUERY_PAGE_SIZE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "UC_ARM_REG_ITSTATE", 18)) {
    /*                             ^          */
      *iv_return = UC_ARM_REG_ITSTATE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARM_REG_APSR_NZCV UC_ERR_READ_UNMAPPED UC_HOOK_MEM_UNMAPPED
     UC_MEM_READ_UNMAPPED */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'A':
    if (memEQ(name, "UC_ARM_REG_APSR_NZCV", 20)) {
    /*                  ^                       */
      *iv_return = UC_ARM_REG_APSR_NZCV;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "UC_ERR_READ_UNMAPPED", 20)) {
    /*                  ^                       */
      *iv_return = UC_ERR_READ_UNMAPPED;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "UC_HOOK_MEM_UNMAPPED", 20)) {
    /*                  ^                       */
      *iv_return = UC_HOOK_MEM_UNMAPPED;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "UC_MEM_READ_UNMAPPED", 20)) {
    /*                  ^                       */
      *iv_return = UC_MEM_READ_UNMAPPED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ARM_REG_FPSCR_NZCV UC_ERR_FETCH_UNMAPPED UC_ERR_READ_UNALIGNED
     UC_ERR_WRITE_UNMAPPED UC_HOOK_MEM_READ_PROT UC_MEM_FETCH_UNMAPPED
     UC_MEM_WRITE_UNMAPPED UC_MODE_LITTLE_ENDIAN */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'E':
    if (memEQ(name, "UC_ERR_WRITE_UNMAPPED", 21)) {
    /*                          ^                */
      *iv_return = UC_ERR_WRITE_UNMAPPED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MEM_WRITE_UNMAPPED", 21)) {
    /*                          ^                */
      *iv_return = UC_MEM_WRITE_UNMAPPED;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "UC_ARM_REG_FPSCR_NZCV", 21)) {
    /*                          ^                */
      *iv_return = UC_ARM_REG_FPSCR_NZCV;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "UC_ERR_FETCH_UNMAPPED", 21)) {
    /*                          ^                */
      *iv_return = UC_ERR_FETCH_UNMAPPED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_MEM_FETCH_UNMAPPED", 21)) {
    /*                          ^                */
      *iv_return = UC_MEM_FETCH_UNMAPPED;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "UC_MODE_LITTLE_ENDIAN", 21)) {
    /*                          ^                */
      *iv_return = UC_MODE_LITTLE_ENDIAN;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "UC_ERR_READ_UNALIGNED", 21)) {
    /*                          ^                */
      *iv_return = UC_ERR_READ_UNALIGNED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_HOOK_MEM_READ_PROT", 21)) {
    /*                          ^                */
      *iv_return = UC_HOOK_MEM_READ_PROT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_ERR_FETCH_UNALIGNED UC_ERR_WRITE_UNALIGNED UC_HOOK_MEM_FETCH_PROT
     UC_HOOK_MEM_WRITE_PROT */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'E':
    if (memEQ(name, "UC_HOOK_MEM_WRITE_PROT", 22)) {
    /*                               ^            */
      *iv_return = UC_HOOK_MEM_WRITE_PROT;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "UC_HOOK_MEM_FETCH_PROT", 22)) {
    /*                               ^            */
      *iv_return = UC_HOOK_MEM_FETCH_PROT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "UC_ERR_FETCH_UNALIGNED", 22)) {
    /*                               ^            */
      *iv_return = UC_ERR_FETCH_UNALIGNED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "UC_ERR_WRITE_UNALIGNED", 22)) {
    /*                               ^            */
      *iv_return = UC_ERR_WRITE_UNALIGNED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     UC_HOOK_MEM_FETCH_INVALID UC_HOOK_MEM_READ_UNMAPPED
     UC_HOOK_MEM_WRITE_INVALID */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'F':
    if (memEQ(name, "UC_HOOK_MEM_FETCH_INVALID", 25)) {
    /*                           ^                   */
      *iv_return = UC_HOOK_MEM_FETCH_INVALID;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "UC_HOOK_MEM_READ_UNMAPPED", 25)) {
    /*                           ^                   */
      *iv_return = UC_HOOK_MEM_READ_UNMAPPED;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "UC_HOOK_MEM_WRITE_INVALID", 25)) {
    /*                           ^                   */
      *iv_return = UC_HOOK_MEM_WRITE_INVALID;
      return PERL_constant_ISIV;
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
my @names = (qw(),
            {name=>"UC_ARCH_ARM", type=>"IV", macro=>"1"},
            {name=>"UC_ARCH_ARM64", type=>"IV", macro=>"1"},
            {name=>"UC_ARCH_M68K", type=>"IV", macro=>"1"},
            {name=>"UC_ARCH_MAX", type=>"IV", macro=>"1"},
            {name=>"UC_ARCH_MIPS", type=>"IV", macro=>"1"},
            {name=>"UC_ARCH_PPC", type=>"IV", macro=>"1"},
            {name=>"UC_ARCH_SPARC", type=>"IV", macro=>"1"},
            {name=>"UC_ARCH_X86", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_B9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_D9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_FP", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_H9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_IP0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_IP1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_LR", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_NZCV", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_PC", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_Q9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_S9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_SP", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_V9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_W9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_WSP", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_WZR", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_X9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM64_REG_XZR", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_APSR", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_APSR_NZCV", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_CPSR", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_D9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_FP", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_FPEXC", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_FPINST", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_FPINST2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_FPSCR", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_FPSCR_NZCV", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_FPSID", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_IP", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_ITSTATE", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_LR", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_MVFR0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_MVFR1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_MVFR2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_PC", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_Q9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_R9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S0", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S1", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S10", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S11", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S12", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S13", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S14", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S15", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S16", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S17", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S18", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S19", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S2", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S20", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S21", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S22", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S23", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S24", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S25", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S26", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S27", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S28", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S29", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S3", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S30", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S31", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S4", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S5", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S6", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S7", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S8", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_S9", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_SB", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_SL", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_SP", type=>"IV", macro=>"1"},
            {name=>"UC_ARM_REG_SPSR", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_ARCH", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_ARG", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_EXCEPTION", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_FETCH_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_FETCH_UNALIGNED", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_FETCH_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_HANDLE", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_HOOK", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_HOOK_EXIST", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_INSN_INVALID", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_MAP", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_MODE", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_NOMEM", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_OK", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_READ_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_READ_UNALIGNED", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_READ_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_RESOURCE", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_VERSION", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_WRITE_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_WRITE_UNALIGNED", type=>"IV", macro=>"1"},
            {name=>"UC_ERR_WRITE_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_BLOCK", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_CODE", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_INSN", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_INTR", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_FETCH", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_FETCH_INVALID", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_FETCH_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_FETCH_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_INVALID", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_READ", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_READ_INVALID", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_READ_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_READ_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_VALID", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_WRITE", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_WRITE_INVALID", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_WRITE_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_HOOK_MEM_WRITE_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_FETCH", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_FETCH_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_FETCH_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_READ", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_READ_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_READ_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_WRITE", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_WRITE_PROT", type=>"IV", macro=>"1"},
            {name=>"UC_MEM_WRITE_UNMAPPED", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_16", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_32", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_64", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_ARM", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_BIG_ENDIAN", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_LITTLE_ENDIAN", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_MCLASS", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_MICRO", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_MIPS3", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_MIPS32", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_MIPS32R6", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_MIPS64", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_PPC32", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_PPC64", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_QPX", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_SPARC32", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_SPARC64", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_THUMB", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_V8", type=>"IV", macro=>"1"},
            {name=>"UC_MODE_V9", type=>"IV", macro=>"1"},
            {name=>"UC_PROT_ALL", type=>"IV", macro=>"1"},
            {name=>"UC_PROT_EXEC", type=>"IV", macro=>"1"},
            {name=>"UC_PROT_NONE", type=>"IV", macro=>"1"},
            {name=>"UC_PROT_READ", type=>"IV", macro=>"1"},
            {name=>"UC_PROT_WRITE", type=>"IV", macro=>"1"},
            {name=>"UC_QUERY_MODE", type=>"IV", macro=>"1"},
            {name=>"UC_QUERY_PAGE_SIZE", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F0", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F1", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F10", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F11", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F12", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F13", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F14", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F15", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F16", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F17", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F18", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F19", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F2", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F20", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F21", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F22", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F23", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F24", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F25", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F26", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F27", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F28", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F29", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F3", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F30", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F31", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F32", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F34", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F36", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F38", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F4", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F40", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F42", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F44", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F46", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F48", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F5", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F50", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F52", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F54", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F56", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F58", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F6", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F60", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F62", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F7", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F8", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_F9", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_FCC0", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_FCC1", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_FCC2", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_FCC3", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_FP", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G0", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G1", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G2", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G3", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G4", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G5", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G6", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_G7", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I0", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I1", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I2", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I3", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I4", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I5", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I6", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_I7", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_ICC", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L0", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L1", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L2", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L3", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L4", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L5", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L6", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_L7", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O0", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O1", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O2", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O3", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O4", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O5", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O6", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_O7", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_PC", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_SP", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_XCC", type=>"IV", macro=>"1"},
            {name=>"UC_SPARC_REG_Y", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_AH", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_AL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_AX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_BH", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_BL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_BP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_BPL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_BX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CH", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR10", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR11", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR12", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR13", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR14", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR15", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR8", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CR9", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CS", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_CX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DH", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DI", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DIL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR10", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR11", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR12", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR13", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR14", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR15", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR8", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DR9", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DS", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_DX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EAX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EBP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EBX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ECX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EDI", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EDX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EFLAGS", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EIP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_EIZ", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ES", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ESI", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ESP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FP7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FPCW", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FPSW", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FPTAG", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_FS", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_GDTR", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_GS", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_IDTR", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_IP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_K7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_LDTR", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_MM7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R10", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R10B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R10D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R10W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R11", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R11B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R11D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R11W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R12", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R12B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R12D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R12W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R13", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R13B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R13D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R13W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R14", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R14B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R14D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R14W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R15", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R15B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R15D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R15W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R8", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R8B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R8D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R8W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R9", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R9B", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R9D", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_R9W", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RAX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RBP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RBX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RCX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RDI", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RDX", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RIP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RIZ", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RSI", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_RSP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_SI", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_SIL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_SP", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_SPL", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_SS", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ST7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_TR", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM10", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM11", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM12", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM13", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM14", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM15", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM16", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM17", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM18", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM19", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM20", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM21", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM22", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM23", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM24", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM25", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM26", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM27", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM28", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM29", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM30", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM31", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM8", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_XMM9", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM10", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM11", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM12", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM13", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM14", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM15", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM16", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM17", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM18", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM19", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM20", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM21", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM22", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM23", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM24", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM25", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM26", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM27", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM28", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM29", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM30", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM31", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM8", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_YMM9", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM0", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM1", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM10", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM11", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM12", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM13", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM14", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM15", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM16", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM17", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM18", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM19", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM2", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM20", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM21", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM22", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM23", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM24", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM25", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM26", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM27", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM28", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM29", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM3", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM30", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM31", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM4", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM5", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM6", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM7", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM8", type=>"IV", macro=>"1"},
            {name=>"UC_X86_REG_ZMM9", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("UnicornEngine", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("UnicornEngine", $types);
__END__
   */

  switch (len) {
  case 9:
    if (memEQ(name, "UC_ERR_OK", 9)) {
      *iv_return = UC_ERR_OK;
      return PERL_constant_ISIV;
    }
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
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
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    /* Names all of length 19.  */
    /* UC_ERR_INSN_INVALID UC_HOOK_MEM_INVALID */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'M':
      if (memEQ(name, "UC_HOOK_MEM_INVALID", 19)) {
      /*                       ^                 */
        *iv_return = UC_HOOK_MEM_INVALID;
        return PERL_constant_ISIV;
      }
      break;
    case 'N':
      if (memEQ(name, "UC_ERR_INSN_INVALID", 19)) {
      /*                       ^                 */
        *iv_return = UC_ERR_INSN_INVALID;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 24:
    if (memEQ(name, "UC_HOOK_MEM_READ_INVALID", 24)) {
      *iv_return = UC_HOOK_MEM_READ_INVALID;
      return PERL_constant_ISIV;
    }
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    /* Names all of length 26.  */
    /* UC_HOOK_MEM_FETCH_UNMAPPED UC_HOOK_MEM_WRITE_UNMAPPED */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'E':
      if (memEQ(name, "UC_HOOK_MEM_WRITE_UNMAPPED", 26)) {
      /*                               ^                */
        *iv_return = UC_HOOK_MEM_WRITE_UNMAPPED;
        return PERL_constant_ISIV;
      }
      break;
    case 'H':
      if (memEQ(name, "UC_HOOK_MEM_FETCH_UNMAPPED", 26)) {
      /*                               ^                */
        *iv_return = UC_HOOK_MEM_FETCH_UNMAPPED;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

