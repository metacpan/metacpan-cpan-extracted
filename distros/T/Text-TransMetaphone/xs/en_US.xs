#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <assert.h>

#include "metaphone_util.h"

#define KEY_LIMIT 4


int
IsVowel(metastring * s, int pos)
{
    char c;

    if ((pos < 0) || (pos >= s->length))
	return 0;

    c = *(s->str + pos);
    if ((c == 'A') || (c == 'E') || (c == 'I') || (c =='O') || 
        (c =='U')  || (c == 'Y'))
	return 1;

    return 0;
}


int
SlavoGermanic(metastring * s)
{
    if ((char *) strstr((char*)s->str, "W"))
	return 1;
    else if ((char *) strstr((char*)s->str, "K"))
	return 1;
    else if ((char *) strstr((char*)s->str, "CZ"))
	return 1;
    else if ((char *) strstr((char*)s->str, "WITZ"))
	return 1;
    else
	return 0;
}


void
TransMetaphone_en_US(unsigned char *str, unsigned char **codes)
{
    int        length;
    metastring *original;
    metastring *primary;
    metastring *secondary;
    int        current;
    int        last;

    current = 0;
    /* we need the real length and last prior to padding */
    length  = strlen((char*)str); 
    last    = length - 1; 
    original = NewMetaString(str);
    /* Pad original so we can index beyond end */
    MetaphAdd(original, (unsigned char*)"     ");

    primary = NewMetaString((unsigned char*)"");
    secondary = NewMetaString((unsigned char*)"");
    primary->free_string_on_destroy = 0;
    secondary->free_string_on_destroy = 0;

    MakeUpper(original);

    /* skip these when at start of word */
    if (StringAt(original, 0, 2, "GN", "KN", "PN", "WR", "PS", ""))
	current += 1;

    /* Initial 'X' is pronounced 'Z' e.g. 'Xavier' */
    if (GetAt(original, 0) == 'X')
      {
	  MetaphAdd(primary, (unsigned char*)"s");	/* 'Z' maps to 'S' */
	  MetaphAdd(secondary, (unsigned char*)"s");
	  current += 1;
      }

    /* main loop */
    while ((primary->length < KEY_LIMIT) || (secondary->length < KEY_LIMIT))  
      {
	  if (current >= length)
	      break;

	  switch (GetAt(original, current))
	    {
	    case 'A':
	    case 'E':
	    case 'I':
	    case 'O':
	    case 'U':
	    case 'Y':
		if (current == 0)
                  {
		    /* all init vowels now map to 'A' */
		    MetaphAdd(primary, (unsigned char*)"a");
		    MetaphAdd(secondary, (unsigned char*)"a");
                  }
		current += 1;
		break;

	    case 'B':

		/* "-mb", e.g", "dumb", already skipped over... */
		MetaphAdd(primary, (unsigned char*)"p");
		MetaphAdd(secondary, (unsigned char*)"p");

		if (GetAt(original, current + 1) == 'B')
		    current += 2;
		else
		    current += 1;
		break;

	    case 0xc7: /* Ç */
		MetaphAdd(primary, (unsigned char*)"s");
		MetaphAdd(secondary, (unsigned char*)"s");
		current += 1;
		break;

	    case 'C':
		/* various germanic */
		if ((current > 1)
		    && !IsVowel(original, current - 2)
		    && StringAt(original, (current - 1), 3, "ACH", "")
		    && ((GetAt(original, current + 2) != 'I')
			&& ((GetAt(original, current + 2) != 'E')
			    || StringAt(original, (current - 2), 6, "BACHER",
					"MACHER", ""))))
		  {
		      MetaphAdd(primary, (unsigned char*)"k");
		      MetaphAdd(secondary, (unsigned char*)"k");
		      current += 2;
		      break;
		  }

		/* special case 'caesar' */
		if ((current == 0)
		    && StringAt(original, current, 6, "CAESAR", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"s");
		      MetaphAdd(secondary, (unsigned char*)"s");
		      current += 2;
		      break;
		  }

		/* italian 'chianti' */
		if (StringAt(original, current, 4, "CHIA", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"k");
		      MetaphAdd(secondary, (unsigned char*)"k");
		      current += 2;
		      break;
		  }

		if (StringAt(original, current, 2, "CH", ""))
		  {
		      /* find 'michael' */
		      if ((current > 0)
			  && StringAt(original, current, 4, "CHAE", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"k");
			    MetaphAdd(secondary, (unsigned char*)"ʃ");
			    current += 2;
			    break;
			}

		      /* greek roots e.g. 'chemistry', 'chorus' */
		      if ((current == 0)
			  && (StringAt(original, (current + 1), 5, "HARAC", "HARIS", "")
			   || StringAt(original, (current + 1), 3, "HOR",
				       "HYM", "HIA", "HEM", ""))
			  && !StringAt(original, 0, 5, "CHORE", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"k");
			    MetaphAdd(secondary, (unsigned char*)"k");
			    current += 2;
			    break;
			}

		      /* germanic, greek, or otherwise 'ch' for 'kh' sound */
		      if (
			  (StringAt(original, 0, 4, "VAN ", "VON ", "")
			   || StringAt(original, 0, 3, "SCH", ""))
			  /*  'architect but not 'arch', 'orchestra', 'orchid' */
			  || StringAt(original, (current - 2), 6, "ORCHES",
				      "ARCHIT", "ORCHID", "")
			  || StringAt(original, (current + 2), 1, "T", "S",
				      "")
			  || ((StringAt(original, (current - 1), 1, "A", "O", "U", "E", "") 
                          || (current == 0))
			   /* e.g., 'wachtler', 'wechsler', but not 'tichner' */
			  && StringAt(original, (current + 2), 1, "L", "R",
		                      "N", "M", "B", "H", "F", "V", "W", " ", "")))
			{
			    MetaphAdd(primary, (unsigned char*)"k");
			    MetaphAdd(secondary, (unsigned char*)"k");
			}
		      else
			{
			    if (current > 0)
			      {
				  if (StringAt(original, 0, 2, "MC", ""))
				    {
					/* e.g., "McHugh" */
					MetaphAdd(primary, (unsigned char*)"k");
					MetaphAdd(secondary, (unsigned char*)"k");
				    }
				  else
				    {
					MetaphAdd(primary, (unsigned char*)"ʧ");
					MetaphAdd(secondary, (unsigned char*)"k");
				    }
			      }
			    else
			      {
				  MetaphAdd(primary, (unsigned char*)"ʃ");
				  MetaphAdd(secondary, (unsigned char*)"ʃ");
			      }
			}
		      current += 2;
		      break;
		  }
		/* e.g, 'czerny' */
		if (StringAt(original, current, 2, "CZ", "")
		    && !StringAt(original, (current - 2), 4, "WICZ", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"s");
		      MetaphAdd(secondary, (unsigned char*)"ʃ");
		      current += 2;
		      break;
		  }

		/* e.g., 'focaccia' */
		if (StringAt(original, (current + 1), 3, "CIA", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"ʃ");
		      MetaphAdd(secondary, (unsigned char*)"ʃ");
		      current += 3;
		      break;
		  }

		/* double 'C', but not if e.g. 'McClellan' */
		if (StringAt(original, current, 2, "CC", "")
		    && !((current == 1) && (GetAt(original, 0) == 'M')))
		    /* 'bellocchio' but not 'bacchus' */
		    if (StringAt(original, (current + 2), 1, "I", "E", "H", "")
			&& !StringAt(original, (current + 2), 2, "HU", ""))
		      {
			  /* 'accident', 'accede' 'succeed' */
			  if (
			      ((current == 1)
			       && (GetAt(original, current - 1) == 'A'))
			      || StringAt(original, (current - 1), 5, "UCCEE",
					  "UCCES", ""))
			    {
				MetaphAdd(primary, (unsigned char*)"ks");
				MetaphAdd(secondary, (unsigned char*)"ks");
				/* 'bacci', 'bertucci', other italian */
			    }
			  else
			    {
				MetaphAdd(primary, (unsigned char*)"ʃ");
				MetaphAdd(secondary, (unsigned char*)"ʃ");
			    }
			  current += 3;
			  break;
		      }
		    else
		      {	  /* Pierce's rule */
			  MetaphAdd(primary, (unsigned char*)"k");
			  MetaphAdd(secondary, (unsigned char*)"k");
			  current += 2;
			  break;
		      }

		if (StringAt(original, current, 2, "CK", "CG", "CQ", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"k");
		      MetaphAdd(secondary, (unsigned char*)"k");
		      current += 2;
		      break;
		  }

		if (StringAt(original, current, 2, "CI", "CE", "CY", ""))
		  {
		      /* italian vs. english */
		      if (StringAt
			  (original, current, 3, "CIO", "CIE", "CIA", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"s");
			    MetaphAdd(secondary, (unsigned char*)"ʃ");
			}
		      else
			{
			    MetaphAdd(primary, (unsigned char*)"s");
			    MetaphAdd(secondary, (unsigned char*)"s");
			}
		      current += 2;
		      break;
		  }

		/* else */
		MetaphAdd(primary, (unsigned char*)"k");
		MetaphAdd(secondary, (unsigned char*)"k");

		/* name sent in 'mac caffrey', 'mac gregor */
		if (StringAt(original, (current + 1), 2, " C", " Q", " G", ""))
		    current += 3;
		else
		    if (StringAt(original, (current + 1), 1, "C", "K", "Q", "")
			&& !StringAt(original, (current + 1), 2, "CE", "CI", ""))
		    current += 2;
		else
		    current += 1;
		break;

	    case 'D':
		if (StringAt(original, current, 2, "DG", ""))
                  {
		      if (StringAt(original, (current + 2), 1, "I", "E", "Y", ""))
		        {
			    /* e.g. 'edge' */
			    MetaphAdd(primary, (unsigned char*)"ʤ");
			    MetaphAdd(secondary, (unsigned char*)"j");
			    current += 3;
			    break;
		        }
		      else
		        {
			    /* e.g. 'edgar' */
			    MetaphAdd(primary, (unsigned char*)"tk");
			    MetaphAdd(secondary, (unsigned char*)"tk");
			    current += 2;
			    break;
		        }
                  }

		if (StringAt(original, current, 2, "DT", "DD", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"t");
		      MetaphAdd(secondary, (unsigned char*)"t");
		      current += 2;
		      break;
		  }

		/* else */
		MetaphAdd(primary, (unsigned char*)"t");
		MetaphAdd(secondary, (unsigned char*)"t");
		current += 1;
		break;

	    case 'F':
		if (GetAt(original, current + 1) == 'F')
		    current += 2;
		else
		    current += 1;
		MetaphAdd(primary, (unsigned char*)"f");
		MetaphAdd(secondary, (unsigned char*)"f");
		break;

	    case 'G':
		if (GetAt(original, current + 1) == 'H')
		  {
		      if ((current > 0) && !IsVowel(original, current - 1))
			{
			    MetaphAdd(primary, (unsigned char*)"k");
			    MetaphAdd(secondary, (unsigned char*)"k");
			    current += 2;
			    break;
			}

		      if (current < 3)
			{
			    /* 'ghislane', ghiradelli */
			    if (current == 0)
			      {
				  if (GetAt(original, current + 2) == 'I')
				    {
					MetaphAdd(primary, (unsigned char*)"j");
					MetaphAdd(secondary, (unsigned char*)"j");
				    }
				  else
				    {
					MetaphAdd(primary, (unsigned char*)"k");
					MetaphAdd(secondary, (unsigned char*)"k");
				    }
				  current += 2;
				  break;
			      }
			}
		      /* Parker's rule (with some further refinements) - e.g., 'hugh' */
		      if (
			  ((current > 1)
			   && StringAt(original, (current - 2), 1, "B", "H", "D", ""))
			  /* e.g., 'bough' */
			  || ((current > 2)
			      && StringAt(original, (current - 3), 1, "B", "H", "D", ""))
			  /* e.g., 'broughton' */
			  || ((current > 3)
			      && StringAt(original, (current - 4), 1, "B", "H", "")))
			{
			    current += 2;
			    break;
			}
		      else
			{
			    /* e.g., 'laugh', 'McLaughlin', 'cough', 'gough', 'rough', 'tough' */
			    if ((current > 2)
				&& (GetAt(original, current - 1) == 'U')
				&& StringAt(original, (current - 3), 1, "C",
					    "G", "L", "R", "T", ""))
			      {
				  MetaphAdd(primary, (unsigned char*)"f");
				  MetaphAdd(secondary, (unsigned char*)"f");
			      }
			    else if ((current > 0)
				     && GetAt(original, current - 1) != 'I')
			      {


				  MetaphAdd(primary, (unsigned char*)"k");
				  MetaphAdd(secondary, (unsigned char*)"k");
			      }

			    current += 2;
			    break;
			}
		  }

		if (GetAt(original, current + 1) == 'N')
		  {
		      if ((current == 1) && IsVowel(original, 0)
			  && !SlavoGermanic(original))
			{
			    MetaphAdd(primary, (unsigned char*)"kn");
			    MetaphAdd(secondary, (unsigned char*)"n");
			}
		      else
			  /* not e.g. 'cagney' */
			  if (!StringAt(original, (current + 2), 2, "EY", "")
			      && (GetAt(original, current + 1) != 'Y')
			      && !SlavoGermanic(original))
			{
			    MetaphAdd(primary, (unsigned char*)"n");
			    MetaphAdd(secondary, (unsigned char*)"kn");
			}
		      else
                        {
			    MetaphAdd(primary, (unsigned char*)"kn");
		            MetaphAdd(secondary, (unsigned char*)"kn");
                        }
		      current += 2;
		      break;
		  }

		/* 'tagliaro' */
		if (StringAt(original, (current + 1), 2, "LI", "")
		    && !SlavoGermanic(original))
		  {
		      MetaphAdd(primary, (unsigned char*)"kl");
		      MetaphAdd(secondary, (unsigned char*)"l");
		      current += 2;
		      break;
		  }

		/* -ges-,-gep-,-gel-, -gie- at beginning */
		if ((current == 0)
		    && ((GetAt(original, current + 1) == 'Y')
			|| StringAt(original, (current + 1), 2, "ES", "EP",
				    "EB", "EL", "EY", "IB", "IL", "IN", "IE",
				    "EI", "ER", "")))
		  {
		      MetaphAdd(primary, (unsigned char*)"k");
		      MetaphAdd(secondary, (unsigned char*)"j");
		      current += 2;
		      break;
		  }

		/*  -ger-,  -gy- */
		if (
		    (StringAt(original, (current + 1), 2, "ER", "")
		     || (GetAt(original, current + 1) == 'Y'))
		    && !StringAt(original, 0, 6, "DANGER", "RANGER", "MANGER", "")
		    && !StringAt(original, (current - 1), 1, "E", "I", "")
		    && !StringAt(original, (current - 1), 3, "RGY", "OGY",
				 ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"k");
		      MetaphAdd(secondary, (unsigned char*)"j");
		      current += 2;
		      break;
		  }

		/*  italian e.g, 'biaggi' */
		if (StringAt(original, (current + 1), 1, "E", "I", "Y", "")
		    || StringAt(original, (current - 1), 4, "AGGI", "OGGI", ""))
		  {
		      /* obvious germanic */
		      if (
			  (StringAt(original, 0, 4, "VAN ", "VON ", "")
			   || StringAt(original, 0, 3, "SCH", ""))
			  || StringAt(original, (current + 1), 2, "ET", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"k");
			    MetaphAdd(secondary, (unsigned char*)"k");
			}
		      else
			{
			    /* always soft if french ending */
			    if (StringAt
				(original, (current + 1), 4, "IER ", ""))
			      {
				  MetaphAdd(primary, (unsigned char*)"j");
				  MetaphAdd(secondary, (unsigned char*)"j");
			      }
			    else
			      {
				  MetaphAdd(primary, (unsigned char*)"j");
				  MetaphAdd(secondary, (unsigned char*)"k");
			      }
			}
		      current += 2;
		      break;
		  }

		if (GetAt(original, current + 1) == 'G')
		    current += 2;
		else
		    current += 1;
		MetaphAdd(primary, (unsigned char*)"k");
		MetaphAdd(secondary, (unsigned char*)"k");
		break;

	    case 'H':
		/* only keep if first & before vowel or btw. 2 vowels */
		if (((current == 0) || IsVowel(original, current - 1))
		    && IsVowel(original, current + 1))
		  {
		      MetaphAdd(primary, (unsigned char*)"h");
		      MetaphAdd(secondary, (unsigned char*)"h");
		      current += 2;
		  }
		else		/* also takes care of 'HH' */
		    current += 1;
		break;

	    case 'J':
		/* obvious spanish, 'jose', 'san jacinto' */
		if (StringAt(original, current, 4, "JOSE", "")
		    || StringAt(original, 0, 4, "SAN ", ""))
		  {
		      if (((current == 0)
			   && (GetAt(original, current + 4) == ' '))
			  || StringAt(original, 0, 4, "SAN ", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"h");
			    MetaphAdd(secondary, (unsigned char*)"h");
			}
		      else
			{
			    MetaphAdd(primary, (unsigned char*)"j");
			    MetaphAdd(secondary, (unsigned char*)"h");
			}
		      current += 1;
		      break;
		  }

		if ((current == 0)
		    && !StringAt(original, current, 4, "JOSE", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"ʤ");	/* Yankelovich/Jankelowicz */
		      MetaphAdd(secondary, (unsigned char*)"a");
		  }
		else
		  {
		      /* spanish pron. of e.g. 'bajador' */
		      if (IsVowel(original, current - 1)
			  && !SlavoGermanic(original)
			  && ((GetAt(original, current + 1) == 'A')
			      || (GetAt(original, current + 1) == 'O')))
			{
			    MetaphAdd(primary, (unsigned char*)"j");
			    MetaphAdd(secondary, (unsigned char*)"h");
			}
		      else
			{
			    if (current == last)
			      {
				  MetaphAdd(primary, (unsigned char*)"ʤ");
				  MetaphAdd(secondary, (unsigned char*)"");
			      }
			    else
			      {
				  if (!StringAt(original, (current + 1), 1, "L", "T",
				                "K", "S", "N", "M", "B", "Z", "")
				      && !StringAt(original, (current - 1), 1,
						   "S", "K", "L", "")) 
                                    {
				      MetaphAdd(primary, (unsigned char*)"j");
				      MetaphAdd(secondary, (unsigned char*)"j");
                                    }
			      }
			}
		  }

		if (GetAt(original, current + 1) == 'J')	/* it could happen! */
		    current += 2;
		else
		    current += 1;
		break;

	    case 'K':
		if (GetAt(original, current + 1) != 'H') {
		    if (GetAt(original, current + 1) == 'K')
		        current += 2;
		    else
		        current += 1;

		    MetaphAdd(primary, (unsigned char*)"k");
		}
		else {
		    /* husky "kh" from arabic */
		    MetaphAdd(primary, (unsigned char*)"x");
		    current += 2;
		}
		MetaphAdd(secondary, (unsigned char*)"k");
		break;

	    case 'L':
		if (GetAt(original, current + 1) == 'L')
		  {
		      /* spanish e.g. 'cabrillo', 'gallegos' */
		      if (((current == (length - 3))
			   && StringAt(original, (current - 1), 4, "ILLO",
				       "ILLA", "ALLE", ""))
			  || ((StringAt(original, (last - 1), 2, "AS", "OS", "")
			    || StringAt(original, last, 1, "A", "O", ""))
			   && StringAt(original, (current - 1), 4, "ALLE", "")))
			{
			    MetaphAdd(primary, (unsigned char*)"l");
			    MetaphAdd(secondary, (unsigned char*)"");
			    current += 2;
			    break;
			}
		      current += 2;
		  }
		else
		    current += 1;
		MetaphAdd(primary, (unsigned char*)"l");
		MetaphAdd(secondary, (unsigned char*)"l");
		break;

	    case 'M':
		if ((StringAt(original, (current - 1), 3, "UMB", "")
		     && (((current + 1) == last)
			 || StringAt(original, (current + 2), 2, "ER", "")))
		    /* 'dumb','thumb' */
		    || (GetAt(original, current + 1) == 'M'))
		    current += 2;
		else
		    current += 1;
		MetaphAdd(primary, (unsigned char*)"m");
		MetaphAdd(secondary, (unsigned char*)"m");
		break;

	    case 'N':
		if (GetAt(original, current + 1) == 'Y')
		  {
		    MetaphAdd(primary, (unsigned char*)"ɲ");
	            current += 2;
		  }
		else
		  {
		    if (GetAt(original, current + 1) == 'N')
		        current += 2;
		    else
		        current += 1;
		    MetaphAdd(primary, (unsigned char*)"n");
		  }
		MetaphAdd(secondary, (unsigned char*)"n");
		break;

	    case 0xd1: /* Ñ */
		current += 1;
		MetaphAdd(primary, (unsigned char*)"ɲ");
		MetaphAdd(secondary, (unsigned char*)"n");
		break;

	    case 'P':
		if (GetAt(original, current + 1) == 'H')
		  {
		      MetaphAdd(primary, (unsigned char*)"f");
		      MetaphAdd(secondary, (unsigned char*)"f");
		      current += 2;
		      break;
		  }

		/* also account for "campbell", "raspberry" */
		if (StringAt(original, (current + 1), 1, "P", "B", ""))
		    current += 2;
		else
		    current += 1;
		MetaphAdd(primary, (unsigned char*)"p");
		MetaphAdd(secondary, (unsigned char*)"p");
		break;

	    case 'Q':
		if (GetAt(original, current + 1) == 'U')
                  {
		    MetaphAdd(primary, (unsigned char*)"kw");
		    current += 1;  /* total of 2 */
		  }
		else
		  {
		    if (GetAt(original, current + 1) == 'Q')
		        current += 2;
		    else
		        current += 1;

		    MetaphAdd(primary, (unsigned char*)"k'");
		  }

		MetaphAdd(secondary, (unsigned char*)"k");
		break;

	    case 'R':
		/* french e.g. 'rogier', but exclude 'hochmeier' */
		if ((current == last)
		    && !SlavoGermanic(original)
		    && StringAt(original, (current - 2), 2, "IE", "")
		    && !StringAt(original, (current - 4), 2, "ME", "MA", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"");
		      MetaphAdd(secondary, (unsigned char*)"r");
		  }
		else
		  {
		      MetaphAdd(primary, (unsigned char*)"r");
		      MetaphAdd(secondary, (unsigned char*)"r");
		  }

		if (GetAt(original, current + 1) == 'R')
		    current += 2;
		else
		    current += 1;
		break;

	    case 'S':
		/* special cases 'island', 'isle', 'carlisle', 'carlysle' */
		if (StringAt(original, (current - 1), 3, "ISL", "YSL", ""))
		  {
		      current += 1;
		      break;
		  }

		/* special case 'sugar-' */
		if ((current == 0)
		    && StringAt(original, current, 5, "SUGAR", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"ʃ");
		      MetaphAdd(secondary, (unsigned char*)"s");
		      current += 1;
		      break;
		  }

		if (StringAt(original, current, 2, "SH", ""))
		  {
		      /* germanic */
		      if (StringAt
			  (original, (current + 1), 4, "HEIM", "HOEK", "HOLM",
			   "HOLZ", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"s");
			    MetaphAdd(secondary, (unsigned char*)"s");
			}
		      else
			{
			    MetaphAdd(primary, (unsigned char*)"ʃ");
			    MetaphAdd(secondary, (unsigned char*)"ʃ");
			}
		      current += 2;
		      break;
		  }

		/* italian & armenian */
		if (StringAt(original, current, 3, "SIO", "SIA", "")
		    || StringAt(original, current, 4, "SIAN", ""))
		  {
		      if (!SlavoGermanic(original))
			{
			    MetaphAdd(primary, (unsigned char*)"s");
			    MetaphAdd(secondary, (unsigned char*)"ʃ");
			}
		      else
			{
			    MetaphAdd(primary, (unsigned char*)"s");
			    MetaphAdd(secondary, (unsigned char*)"s");
			}
		      current += 3;
		      break;
		  }

		/* german & anglicisations, e.g. 'smith' match 'schmidt', 'snider' match 'schneider' 
		   also, -sz- in slavic language altho in hungarian it is pronounced 's' */
		if (((current == 0)
		     && StringAt(original, (current + 1), 1, "M", "N", "L", "W", ""))
		    || StringAt(original, (current + 1), 1, "Z", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"s");
		      MetaphAdd(secondary, (unsigned char*)"ʃ");
		      if (StringAt(original, (current + 1), 1, "Z", ""))
			  current += 2;
		      else
			  current += 1;
		      break;
		  }

		if (StringAt(original, current, 2, "SC", ""))
		  {
		      /* Schlesinger's rule */
		      if (GetAt(original, current + 2) == 'H')
			  /* dutch origin, e.g. 'school', 'schooner' */
			  if (StringAt(original, (current + 3), 2, "OO", "ER", "EN",
			               "UY", "ED", "EM", ""))
			    {
				/* 'schermerhorn', 'schenker' */
				if (StringAt(original, (current + 3), 2, "ER", "EN", ""))
				  {
				      MetaphAdd(primary, (unsigned char*)"ʃ");
				      MetaphAdd(secondary, (unsigned char*)"sk");
				  }
				else
                                  {
				      MetaphAdd(primary, (unsigned char*)"sk");
				      MetaphAdd(secondary, (unsigned char*)"sk");
                                  }
				current += 3;
				break;
			    }
			  else
			    {
				if ((current == 0) && !IsVowel(original, 3)
				    && (GetAt(original, 3) != 'W'))
				  {
				      MetaphAdd(primary, (unsigned char*)"ʃ");
				      MetaphAdd(secondary, (unsigned char*)"s");
				  }
				else
				  {
				      MetaphAdd(primary, (unsigned char*)"ʃ");
				      MetaphAdd(secondary, (unsigned char*)"ʃ");
				  }
				current += 3;
				break;
			    }

		      if (StringAt(original, (current + 2), 1, "I", "E", "Y", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"S");
			    MetaphAdd(secondary, (unsigned char*)"s");
			    current += 3;
			    break;
			}
		      /* else */
		      MetaphAdd(primary, (unsigned char*)"sk");
		      MetaphAdd(secondary, (unsigned char*)"sk");
		      current += 3;
		      break;
		  }

		/* french e.g. 'resnais', 'artois' */
		if ((current == last)
		    && StringAt(original, (current - 2), 2, "AI", "OI", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"");
		      MetaphAdd(secondary, (unsigned char*)"s");
		  }
		else
		  {
		      MetaphAdd(primary, (unsigned char*)"s");
		      MetaphAdd(secondary, (unsigned char*)"s");
		  }

		if (StringAt(original, (current + 1), 1, "S", "Z", ""))
		    current += 2;
		else
		    current += 1;
		break;

	    case 'T':
		if (StringAt(original, current, 4, "TION", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"ʃ");
		      MetaphAdd(secondary, (unsigned char*)"ʃ");
		      current += 3;
		      break;
		  }

		if (StringAt(original, current, 3, "TIA", "TCH", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"ʃ");
		      MetaphAdd(secondary, (unsigned char*)"ʃ");
		      current += 3;
		      break;
		  }

		if (StringAt(original, current, 2, "TH", "")
		    || StringAt(original, current, 3, "TTH", ""))
		  {
		      /* special case 'thomas', 'thames' or germanic */
		      if (StringAt(original, (current + 2), 2, "OM", "AM", "")
			  || StringAt(original, 0, 4, "VAN ", "VON ", "")
			  || StringAt(original, 0, 3, "SCH", ""))
			{
			    MetaphAdd(primary, (unsigned char*)"t");
			    MetaphAdd(secondary, (unsigned char*)"t");
			}
		      else
			{
			    MetaphAdd(primary, (unsigned char*)"Θ");
			    MetaphAdd(secondary, (unsigned char*)"t");
			}
		      current += 2;
		      break;
		  }

		if (StringAt(original, (current + 1), 1, "T", "D", ""))
		    current += 2;
		else
		    current += 1;
		MetaphAdd(primary, (unsigned char*)"t");
		MetaphAdd(secondary, (unsigned char*)"t");
		break;

	    case 'V':
		if (GetAt(original, current + 1) == 'V')
		    current += 2;
		else
		    current += 1;
		MetaphAdd(primary, (unsigned char*)"f");
		MetaphAdd(secondary, (unsigned char*)"f");
		break;

	    case 'W':
		/* can also be in middle of word */
		if (StringAt(original, current, 2, "WR", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"r");
		      MetaphAdd(secondary, (unsigned char*)"r");
		      current += 2;
		      break;
		  }

		if ((current == 0)
		    && (IsVowel(original, current + 1)
			|| StringAt(original, current, 2, "WH", "")))
		  {
		      /* Wasserman should match Vasserman */
		      if (IsVowel(original, current + 1))
			{
			    MetaphAdd(primary, (unsigned char*)"a");
			    MetaphAdd(secondary, (unsigned char*)"f");
			}
		      else
			{
			    /* need Uomo to match Womo */
			    MetaphAdd(primary, (unsigned char*)"a");
			    MetaphAdd(secondary, (unsigned char*)"a");
			}
		  }

		/* Arnow should match Arnoff */
		if (((current == last) && IsVowel(original, current - 1))
		    || StringAt(original, (current - 1), 5, "EWSKI", "EWSKY",
				"OWSKI", "OWSKY", "")
		    || StringAt(original, 0, 3, "SCH", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"");
		      MetaphAdd(secondary, (unsigned char*)"f");
		      current += 1;
		      break;
		  }

		/* polish e.g. 'filipowicz' */
		if (StringAt(original, current, 4, "WICZ", "WITZ", ""))
		  {
		      MetaphAdd(primary, (unsigned char*)"ts");
		      MetaphAdd(secondary, (unsigned char*)"fx");
		      current += 4;
		      break;
		  }

		/* else skip it */
		current += 1;
		break;

	    case 'X':
		/* french e.g. breaux */
		if (!((current == last)
		      && (StringAt(original, (current - 3), 3, "IAU", "EAU", "")
		       || StringAt(original, (current - 2), 2, "AU", "OU", ""))))
                  {
		      MetaphAdd(primary, (unsigned char*)"ks");
		      MetaphAdd(secondary, (unsigned char*)"ks");
                  }
                  

		if (StringAt(original, (current + 1), 1, "C", "X", ""))
		    current += 2;
		else
		    current += 1;
		break;

	    case 'Z':
		/* chinese pinyin e.g. 'zhao' */
		if (GetAt(original, current + 1) == 'H')
		  {
		      MetaphAdd(primary, (unsigned char*)"j");
		      MetaphAdd(secondary, (unsigned char*)"j");
		      current += 2;
		      break;
		  }
		else if (StringAt(original, (current + 1), 2, "ZO", "ZI", "ZA", "")
			|| (SlavoGermanic(original)
			    && ((current > 0)
				&& GetAt(original, current - 1) != 'T')))
		  {
		      MetaphAdd(primary, (unsigned char*)"s");
		      MetaphAdd(secondary, (unsigned char*)"ts");
		  }
		else
                  {
		    MetaphAdd(primary, (unsigned char*)"s");
		    MetaphAdd(secondary, (unsigned char*)"s");
                  }

		if (GetAt(original, current + 1) == 'Z')
		    current += 2;
		else
		    current += 1;
		break;

	    default:
		current += 1;
	    }
        /* printf("PRIMARY: %s\n", primary->str);
        printf("SECONDARY: %s\n", secondary->str);  */
      }


    if (primary->length > KEY_LIMIT)
	SetAt(primary, KEY_LIMIT, '\0');

    if (secondary->length > KEY_LIMIT)
	SetAt(secondary, KEY_LIMIT, '\0');

    *codes = primary->str;
    *++codes = secondary->str;

    DestroyMetaString(original);
    DestroyMetaString(primary);
    DestroyMetaString(secondary);
}


MODULE = Text::TransMetaphone::en_US		PACKAGE = Text::TransMetaphone::en_US


void
trans_metaphone(str)
	unsigned char *	str

        PREINIT:
        unsigned char *codes[2];
	SV* sv;

        PPCODE:
        TransMetaphone_en_US(str, codes);

	// fprintf (stderr, "  Pushing %s\n", codes[0]);
        sv = newSVpv((char*)codes[0], 0); /* this could be a problem, there doesn't seem to be a newSV for unsigned chars */
	SvUTF8_on(sv);
        XPUSHs(sv_2mortal(sv));
        if ((GIMME == G_ARRAY) && strcmp((char*)codes[0], (char*)codes[1])) 
          {
		sv = newSVpv((char*)codes[1], 0);
		SvUTF8_on(sv);
		XPUSHs(sv_2mortal(sv));
          } 
        Safefree(codes[0]);
        Safefree(codes[1]);
