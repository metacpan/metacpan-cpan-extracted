/****************************************************************************
*****************************************************************************
FILE      : soundex.c
FUNCTION  : This module contains the two algorithms SOUNDEX and PHONIX as 
            they were defined by Gadd.
NOTES     : This is an ANSI-C version of the original C++ file.
LITERATURE: T.N. Gadd: 'Fishing fore Werds': Phonetic Retrieval of written 
            text in Information Retrieval Systems, Program 22/3, 1988, 
            p.222-237.
            T.N. Gadd: PHONIX --- The Algorithm, Program 24/4, 1990, 
            p.363-366.
*****************************************************************************
****************************************************************************/

/* #define TEST */       /* activates procedures main() and PrintCode() */
/* #define PHONIX_DEBUG */      /* activates some debug information            */

/****************************************************************************
NAME    : StrDel
INPUT   : char *DelPos --- pointer to first char to be deleted
          int  DelSize --- number of chars to be deleted
OUTPUT  : char *DelPos 
FUNCTION: This procedure deletes DelSize chars at position DelPos and moves
          the remaining chars left to DelPos.
EXAMPLE : If Del is pointing at the L of the string "DELETE" the call
          StrDel(Del, 2) will return Del pointing at "TE". 
****************************************************************************/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

void StrDel (DelPos, DelSize)
char *DelPos;
int  DelSize;
{
  /* move chars left */
  char *Help = DelPos + DelSize;
  while (*Help)
    *DelPos++ = *Help++;

  /* move trailing \0 */
  *DelPos = *Help;
}


/****************************************************************************
NAME    : StrIns
INPUT   : char *InsPos --- pointer to insert position
OUTPUT  : char *InStr  --- new string to be inserted
FUNCTION: StrIns moves the chars at position InsPos right and copies the
          string InsStr into this free space.
EXAMPLE : If Ins is pointing at the S of the string "INSERT" the call
          StrIns(Ins, "NEW") will return Ins pointing at "NEWSERT". 
****************************************************************************/
void StrIns (InsPos, InsStr)
char *InsPos;
char *InsStr;
{
  int i;
  int MoveSize = strlen(InsStr);

  /* move chars right */
  for (i = strlen(InsPos)+1; i >= 0; i--)
    InsPos[i+MoveSize] = InsPos[i];

  /* copy InsStr to InsPos */
  while (*InsStr)
    *InsPos++ = *InsStr++;
}

extern bool IsVowel();
#if 0
/****************************************************************************
NAME    : IsVowel
INPUT   : char c --- char to be examined
OUTPUT  : int    --- 1 or 0
FUNCTION: IsVowel checks if c is an uppercase vowel or an uppercase Y. If c
          is one of those chars IsVowel will return a 1, else it will return
          a 0.
****************************************************************************/
int IsVowel (c)
unsigned char c;
{
  return (c == 'A') || (c == 'E') || (c == 'I') ||
    (c == 'O') || (c == 'U') || (c == 'Y') ||
      (c == 0304) || (c == 0344) || (c == 0334) ||
        (c == 0366) || (c == 0326) || (c == 0374);
}


/****************************************************************************
NAME    : SoundexCode
INPUT   : char *Name --- string to be calculated
OUTPUT  : char *Key  --- soundex code for Name
FUNCTION: This procedure calculates a four-letter soundex code for the string 
          Name and returns this code in the string Key.
****************************************************************************/
#define SoundexLen 4      /* length of a soundex code */
#define SoundexKey "Z000" /* default key for soundex code */

char SCode(c)
unsigned char c;
{
  /* set letter values */
  static int  Code[] = {0, 1, 2, 3, 0, 1, 2, 0, 0, 2, 2, 4, 5, 5, 0, 
                          1, 2, 6, 2, 3, 0, 1, 0, 2, 0, 2};

  fprintf(stderr, "SCode(%c)\n", c);
  if (c == 0337) return(2); /* german sz */
  return(Code[toupper(c)-'A']);
}

void SoundexCode (Name, Key)
unsigned char *Name;
unsigned char *Key;
{
  unsigned char LastLetter;
  int  Index;

  fprintf(stderr, "SoundexCode(%s)\n", Name);
  /* set default key */
  strcpy(Key, SoundexKey);
  
  /* keep first letter */
  Key[0] = *Name;
  LastLetter = *Name;
  Name++;

  /* scan rest of string */
  for (Index = 1; (Index < SoundexLen) && *Name; Name++)
  {
    /* use only letters */
    if (isalpha(*Name))
    {
      /* ignore duplicate successive chars */
      if (LastLetter != *Name)
      {
        /* new LastLetter */
        LastLetter = *Name;

        /* ignore letters with code 0 */
        if (!IsVowel(*Name) && (SCode(*Name) != 0))
        {
          Key[Index] = '0' + SCode(*Name);
          Index++;
        }
      }
    }
  }
}
#endif /* 0 */

/****************************************************************************
NAME    : PhonixCode
INPUT   : char *Name --- string to be calculated
OUTPUT  : char *Key  --- phonix code for Name
FUNCTION: This procedure calculates a eight-letter phonix code for the string 
          Name and returns this code in the string Key.
****************************************************************************/
#define PhonixLen 8          /* length of a phonix code */
#define PhonixKey "Z0000000" /* default key for phonix code */

extern bool IsAlpha();
extern char PCode();

void PhonixCode (Name, Key)
char *Name;
char *Key;
{
  char LastLetter;
  int  Index;

  /* set default key */
  strcpy(Key, PhonixKey);

  /* keep first letter or replace it with '$' */
  Key[0] = IsVowel(*Name) ? '$' : *Name;
  LastLetter = *Name;
  Name++;

  /* NOTE: Gadd replaces vowels being the first letter of the  */
  /* word with a 'v'. Due to the implementation of WAIS all    */
  /* letters will be lowercased. Therefore '$' is used instead */
  /* of 'v'.                                                   */          

  /* scan rest of string */
  for (Index = 1; (Index < PhonixLen) && *Name; Name++)
  {
    /* use only letters */
    if (IsAlpha(*Name))
    {
      /* ignore duplicate successive chars */
      if (LastLetter != *Name)
      {
        LastLetter = *Name;

        /* ignore letters with code 0 except as separators */
        if (PCode(*Name) != '0')
        {
          Key[Index] = PCode(*Name);
          Index++;
        }
      }
    }
  }
}


/****************************************************************************
NAME    : PhonixReplace1
INPUT   : int  where    --- replace OldStr only if it occurs at this position
          char *Name    --- string to work
          char *OldStr  --- old letter group to delete
          char *NewStr  --- new letter group to insert
          int  CondPre  --- condition referring to letter before OldStr
          int  CondPost --- condition referring to letter after OldStr
OUTPUT  : char *Name    --- Name with replaced letter group
FUNCTION: This procedure replaces the letter group OldStr with the letter 
          group NewStr in the string Name, regarding the position of OldStr
          where (START, MIDDLE, END, ALL) and the conditions CondPre and 
          CondPost (NON, VOC, CON).
EXAMPLE : PhonixReplace1(START, "WAWA", "W", "V", NON, NON) replaces only the
          first W with a V because of the condition START.
EXAMPLE : PhonixReplace1(START, "WAWA", "W", "V", NON, CON) replaces neither
          the first W with a V (because of the condition CON, i.e. a consonant
          must follow the W) nor the second W (because of the condition START).
****************************************************************************/
#define NON    1  /* no condition     */
#define VOC    2  /* vowel needed     */ 
#define CON    3  /* consonant needed */

#define START  1  /* condition refers to beginning of Name */
#define MIDDLE 2  /* condition refers to middle of Name    */
#define END    3  /* condition refers to EndPos of Name    */
#define ALL    4  /* condition refers to whole Name        */

void PhonixReplace1 (Where, Name, OldStr, NewStr, CondPre, CondPost)
int  Where;
char *Name;
char *OldStr;
char *NewStr;
int  CondPre;
int  CondPost;
{
  char *OldStrPos;
  char *EndPos;
  char *NamePtr = Name;

  /* vowels before or after OldStr */
  char LetterPre;  /* letter before OldStr */
  char LetterPost; /* letter after OldStr  */
  int  VowelPre;   /* LetterPre is vowel?  */
  int  VowelPost;  /* LetterPost is vowel? */
  int  OkayPre;    /* pre-condition okay?  */
  int  OkayPost;   /* post-condition okay? */

  do
  { 
    /* find OldStr in NamePtr */
    OldStrPos = strstr(NamePtr, OldStr);

    /* find EndPos of Name */
    EndPos = &Name[strlen(Name)-strlen(OldStr)];

    /* check conditions if OldStrPos != NULL */
    if (OldStrPos)
    {
      /* vowel before OldStrPos */
      LetterPre = *(OldStrPos-1);
      /* vowel after OldStrPos+strlen(OldStr) */
      LetterPost = *(OldStrPos+strlen(OldStr));

      /* check conditions */
      switch (CondPre)
      {
        case NON: OkayPre = 1;
                  break;
        case VOC: OkayPre = LetterPre ? IsVowel(LetterPre) : 0;
                  break;
        case CON: OkayPre = LetterPre ? !IsVowel(LetterPre) : 0;
                  break;
        default : OkayPre = 0;
                  break;
      }
      switch (CondPost)
      {
        case NON: OkayPost = 1;
                  break;
        case VOC: OkayPost = LetterPost ? IsVowel(LetterPost) : 0;
                  break;
        case CON: OkayPost = LetterPost ? !IsVowel(LetterPost) : 0;
                  break;
        default : OkayPost = 0;
                  break;
      }
    }

    /* replace OldStr with NewStr */
    if (OldStrPos && OkayPre && OkayPost &&
       ((Where == START)  && (OldStrPos == Name) ||
        (Where == MIDDLE) && (OldStrPos != Name) && (OldStrPos != EndPos) ||
        (Where == END)    && (OldStrPos == EndPos)  ||
        (Where == ALL)))
    {
      /* replace old letter group with new letter group */
      StrDel(OldStrPos, strlen(OldStr));
      StrIns(OldStrPos, NewStr);

      /* advance NamePtr to the position of OldStr */
      NamePtr = OldStrPos;

#ifdef PHONIX_DEBUG
      printf("Replace = %s-->%s\n", OldStr, NewStr);  
#endif /* PHONIX_DEBUG */
    }
    else
      /* advance NamePtr one char */
      NamePtr++;
  }
  while (OldStrPos);
}


/****************************************************************************
NAME    : PhonixReplace2
INPUT   : int  where   --- replace OldStr only if it occurs at this position
          char *Name   --- string to work
          char *OldStr --- old letter group to delete
          char *NewStr --- new letter group to insert
OUTPUT  : char *Name   --- Name with replaced letter group
FUNCTION: This procedure replaces the letter group OldStr with the letter 
          group NewStr in the string Name, regarding the position of OldStr
          where (START, MIDDLE, END, ALL).
EXAMPLE : PhonixReplace2(START, "WAWA", "W", "V") replaces only the first W 
          with a V because of the condition START.
****************************************************************************/
void PhonixReplace2 (Where, Name, OldStr, NewStr)
int  Where;
char *Name;
char *OldStr;
char *NewStr;
{
  char *OldStrPos;
  char *EndPos;
  char *NamePtr = Name;

  do
  { 
    /* find OldStr in NamePtr */
    OldStrPos = strstr(NamePtr, OldStr);

    /* find EndPos of Name */
    EndPos = &Name[strlen(Name)-strlen(OldStr)];

    /* replace OldStr with NewStr */
    if (OldStrPos &&
       ((Where == START)  && (OldStrPos == Name) ||
        (Where == MIDDLE) && (OldStrPos != Name) && (OldStrPos != EndPos) ||
        (Where == END)    && (OldStrPos == EndPos)  ||
        (Where == ALL)))
    { 
      /* replace old letter group with new letter group */
      StrDel(OldStrPos, strlen(OldStr));
      StrIns(OldStrPos, NewStr);

      /* advance NamePtr to the position of OldStr */
      NamePtr = OldStrPos;

#ifdef PHONIX_DEBUG
      printf("Replace = %s-->%s\n", OldStr, NewStr);  
#endif /* PHONIX_DEBUG */
    }
    else
      /* advance NamePtr one char */
      NamePtr++;
  }
  while (OldStrPos);
}


/****************************************************************************
NAME    : Phonix
INPUT   : char *Name --- string to calculate phonix code for
OUTPUT  : char *Key  --- phonix code of Name
FUNCTION: Phonix calculates the phonix code for the string Name.
****************************************************************************/
void Phonix (Name, Key)
char *Name;
char *Key;
{
  /* use new variable NewName to remain Name unchanged */
  char NewName[50];
  int  i;

  strcpy(NewName, Name);

  /* uppercase NewName */
  for (i=0; i < strlen(NewName); i++)
    if (islower(NewName[i])) 
      NewName[i] = toupper(NewName[i]);

#ifdef PHONIX_DEBUG
  printf("Name    = %s\n", NewName);  
#endif /* PHONIX_DEBUG */

  /* replace letter groups according to Gadd's definition */
  PhonixReplace2(ALL   , NewName, "DG"   , "G"    );
  PhonixReplace2(ALL   , NewName, "CO"   , "KO"   );
  PhonixReplace2(ALL   , NewName, "CA"   , "KA"   );
  PhonixReplace2(ALL   , NewName, "CU"   , "KU"   );
  PhonixReplace2(ALL   , NewName, "CY"   , "SI"   );
  PhonixReplace2(ALL   , NewName, "CI"   , "SI"   );
  PhonixReplace2(ALL   , NewName, "CE"   , "SE"   );
  PhonixReplace1(START , NewName, "CL"   , "KL"   , NON, VOC);
  PhonixReplace2(ALL   , NewName, "CK"   , "K"    );
  PhonixReplace2(END   , NewName, "GC"   , "K"    );
  PhonixReplace2(END   , NewName, "JC"   , "K"    );
  PhonixReplace1(START , NewName, "CHR"  , "KR"   , NON, VOC);
  PhonixReplace1(START , NewName, "CR"   , "KR"   , NON, VOC);
  PhonixReplace2(START , NewName, "WR"   , "R"    );
  PhonixReplace2(ALL   , NewName, "NC"   , "NK"   );
  PhonixReplace2(ALL   , NewName, "CT"   , "KT"   );
  PhonixReplace2(ALL   , NewName, "PH"   , "F"    );
  PhonixReplace2(ALL   , NewName, "AA"   , "AR"   );
  PhonixReplace2(ALL   , NewName, "SCH"  , "SH"   );
  PhonixReplace2(ALL   , NewName, "BTL"  , "TL"   );
  PhonixReplace2(ALL   , NewName, "GHT"  , "T"    );
  PhonixReplace2(ALL   , NewName, "AUGH" , "ARF"  );
  PhonixReplace1(MIDDLE, NewName, "LJ"   , "LD"   , VOC, VOC);
  PhonixReplace2(ALL   , NewName, "LOUGH", "LOW"  );
  PhonixReplace2(START , NewName, "Q"    , "KW"   );
  PhonixReplace2(START , NewName, "KN"   , "N"    );
  PhonixReplace2(END   , NewName, "GN"   , "N"    );
  PhonixReplace2(ALL   , NewName, "GHN"  , "N"    );
  PhonixReplace2(END   , NewName, "GNE"  , "N"    );
  PhonixReplace2(ALL   , NewName, "GHNE" , "NE"   );
  PhonixReplace2(END   , NewName, "GNES" , "NS"   );
  PhonixReplace2(START , NewName, "GN"   , "N"    );
  PhonixReplace1(MIDDLE, NewName, "GN"   , "N"    , NON, CON);
  PhonixReplace1(END   , NewName, "GN"   , "N"    , NON, NON); /* NON,CON */
  PhonixReplace2(START , NewName, "PS"   , "S"    );
  PhonixReplace2(START , NewName, "PT"   , "T"    );
  PhonixReplace2(START , NewName, "CZ"   , "C"    );
  PhonixReplace1(MIDDLE, NewName, "WZ"   , "Z"    , VOC, NON);
  PhonixReplace2(MIDDLE, NewName, "CZ"   , "CH"   );
  PhonixReplace2(ALL   , NewName, "LZ"   , "LSH"  );
  PhonixReplace2(ALL   , NewName, "RZ"   , "RSH"  );
  PhonixReplace1(MIDDLE, NewName, "Z"    , "S"    , NON, VOC);
  PhonixReplace2(ALL   , NewName, "ZZ"   , "TS"   );
  PhonixReplace1(MIDDLE, NewName, "Z"    , "TS"   , CON, NON);
  PhonixReplace2(ALL   , NewName, "HROUG", "REW"  );
  PhonixReplace2(ALL   , NewName, "OUGH" , "OF"   );
  PhonixReplace1(MIDDLE, NewName, "Q"    , "KW"   , VOC, VOC);
  PhonixReplace1(MIDDLE, NewName, "J"    , "Y"    , VOC, VOC);
  PhonixReplace1(START , NewName, "YJ"   , "Y"    , NON, VOC);
  PhonixReplace2(START , NewName, "GH"   , "G"    );
  PhonixReplace1(END   , NewName, "E"    , "GH"   , VOC, NON);
  PhonixReplace2(START , NewName, "CY"   , "S"    );
  PhonixReplace2(ALL   , NewName, "NX"   , "NKS"  );
  PhonixReplace2(START , NewName, "PF"   , "F"    );
  PhonixReplace2(END   , NewName, "DT"   , "T"    );
  PhonixReplace2(END   , NewName, "TL"   , "TIL"  );
  PhonixReplace2(END   , NewName, "DL"   , "DIL"  );
  PhonixReplace2(ALL   , NewName, "YTH"  , "ITH"  );
  PhonixReplace1(START , NewName, "TJ"   , "CH"   , NON, VOC);
  PhonixReplace1(START , NewName, "TSJ"  , "CH"   , NON, VOC);
  PhonixReplace1(START , NewName, "TS"   , "T"    , NON, VOC);
  PhonixReplace1(ALL   , NewName, "TCH"  , "CH"   );
  PhonixReplace1(MIDDLE, NewName, "WSK"  , "VSKIE", VOC, NON);
  PhonixReplace1(END   , NewName, "WSK"  , "VSKIE", VOC, NON);
  PhonixReplace1(START , NewName, "MN"   , "N"    , NON, VOC);
  PhonixReplace1(START , NewName, "PN"   , "N"    , NON, VOC);
  PhonixReplace1(MIDDLE, NewName, "STL"  , "SL"   , VOC, NON);
  PhonixReplace1(END   , NewName, "STL"  , "SL"   , VOC, NON);
  PhonixReplace2(END   , NewName, "TNT"  , "ENT"  );
  PhonixReplace2(END   , NewName, "EAUX" , "OH"   );
  PhonixReplace2(ALL   , NewName, "EXCI" , "ECS"  );
  PhonixReplace2(ALL   , NewName, "X"    , "ECS"  );
  PhonixReplace2(END   , NewName, "NED"  , "ND"   );
  PhonixReplace2(ALL   , NewName, "JR"   , "DR"   );
  PhonixReplace2(END   , NewName, "EE"   , "EA"   );
  PhonixReplace2(ALL   , NewName, "ZS"   , "S"    );
  PhonixReplace1(MIDDLE, NewName, "R"    , "AH"   , VOC, CON);
  PhonixReplace1(END   , NewName, "R"    , "AH"   , VOC, NON); /* VOC,CON */
  PhonixReplace1(MIDDLE, NewName, "HR"   , "AH"   , VOC, CON);
  PhonixReplace1(END   , NewName, "HR"   , "AH"   , VOC, NON); /* VOC,CON */
  PhonixReplace1(END   , NewName, "HR"   , "AH"   , VOC, NON);
  PhonixReplace2(END   , NewName, "RE"   , "AR"   );
  PhonixReplace1(END   , NewName, "R"    , "AH"   , VOC, NON);
  PhonixReplace2(ALL   , NewName, "LLE"  , "LE"   );
  PhonixReplace1(END   , NewName, "LE"   , "ILE"  , CON, NON);
  PhonixReplace1(END   , NewName, "LES"  , "ILES" , CON, NON);
  PhonixReplace2(END   , NewName, "E"    , ""     );
  PhonixReplace2(END   , NewName, "ES"   , "S"    );
  PhonixReplace1(END   , NewName, "SS"  , "AS"    , VOC, NON);
  PhonixReplace1(END   , NewName, "MB"  , "M"     , VOC, NON);
  PhonixReplace2(ALL   , NewName, "MPTS" , "MPS"  );
  PhonixReplace2(ALL   , NewName, "MPS"  , "MS"   );
  PhonixReplace2(ALL   , NewName, "MPT"  , "MT"   );

  /* calculate Key for NewName */
  PhonixCode(NewName, Key);

#ifdef PHONIX_DEBUG
  printf("NewName = %s\n", NewName);  
  printf("Code    = %s\n\n", Key);  
#endif /* PHONIX_DEBUG */
}


/****************************************************************************
NAME    : Soundex
INPUT   : char *Name --- string to calculate soundex code for
OUTPUT  : char *Key  --- soundex code of Name
FUNCTION: Soundex calculates the soundex code for the string Name.
****************************************************************************/

void Soundex (Name, Key)
char *Name;
char *Key;
{
  /* use new variable NewName to remain Name unchanged */
  char NewName[50];
  int  i; 

  strcpy(NewName, Name);

  /* uppercase NewName */
  for (i=0; i < strlen(NewName); i++)
    if (islower(NewName[i])) 
      NewName[i] = toupper(NewName[i]);

  /* calculate Key for Name */
  SoundexCode(NewName, Key);
  /* fprintf(stderr, "Soundex: %s -> %s\n", Name, Key); */
}


/****************************************************************************
Now the two procedures PrintCode() and main() follow which will only be
included if TEST is defined.
****************************************************************************/

#ifdef TEST

void PrintCode (Name)
unsigned char *Name;
{
  unsigned char SoundexName[SoundexLen+1];
  unsigned char PhonixName[PhonixLen+1];

  Soundex(Name, SoundexName);
  Phonix(Name, PhonixName);
  printf("%20s --> %s %s\n", Name, SoundexName, PhonixName);
}


void main ()
{
  unsigned char s[256];
  PrintCode("CLASSEN");
  PrintCode("WRITE");
  PrintCode("WRIGHT");
  PrintCode("RITE");
  PrintCode("WHITE");
  PrintCode("WAIT");
  PrintCode("WEIGHT");
  PrintCode("KNIGHT");
  PrintCode("NIGHT");
  PrintCode("NITE");
  PrintCode("GNOME");
  PrintCode("NOAM");
  PrintCode("SMIDT");
  PrintCode("SMITH");
  PrintCode("SCHMIT");
  PrintCode("CRAFT");
  PrintCode("KRAFT");
  PrintCode("REES");
  PrintCode("REECE");
  PrintCode("YAEGER");
  PrintCode("YOGA");
  PrintCode("EAGER");
  PrintCode("AUGER");
  PrintCode("Krueger");
  PrintCode("Kruger");
  PrintCode("Krüger");
  while (1) {
    PrintCode(gets(s));
  }
}

#endif /* TEST*/
