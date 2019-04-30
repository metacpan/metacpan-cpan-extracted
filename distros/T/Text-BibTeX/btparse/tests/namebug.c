#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>
#include "btparse.h"

#if DEBUG
void dump_name(bt_name*);
#else
#define dump_name(x) do {} while(0)
#endif

char * normalize_name(char * name) {
	size_t size = strlen(name);
	char * result = malloc(size + 1);
	char * optr=result, *iptr=name;
	int braces = 0;
	char inspace = 0;
	while (*iptr && isspace(*iptr)) ++iptr;
	while (*iptr) {
		printf("%c",*iptr);
		switch (*iptr) {
		case '{': {
			if (braces < 0) {
				++iptr;
				break;
			}
			if (!braces) {
				*optr++ = *iptr;
			}
			++braces;
			++iptr;
			inspace = 0;
			break;
		}
		case '}': {
			if (braces < 0) {
				++iptr;
				break;
			}
			--braces;
			if (!braces) {
				*optr++ = *iptr;
				braces = -1;
			}
			++iptr;
			inspace=0;
			break;
		}
		case '\f':
		case '\r':
		case '\v':
		case '\n':
		case '\t':
		case ' ': {
			if (!inspace) {
				*optr++ = *iptr;
				inspace = 0;
			}
			iptr++;
			break;
		}
		default:
			inspace = 0;
			*optr++ = *iptr++;
		}
	}
	if (optr != result) {
		--optr;
		while (optr != result && isspace(*optr)) --optr;
		++optr;
	}
	*optr = 0;
	result = realloc(result, (optr-result)+1);
	printf("\n");
	return result;
}


struct nametype {
	char * given; /*
                         name_split->parts[BTN_GIVEN],
                         name_split->part_len[BTN_GIVEN]);
		     */
	char * prefix; /*
                         name_split->parts[BTN_PREFIX],
                         name_split->part_len[BTN_PREFIX]);
		   */
	char * family; /*
                         name_split->parts[BTN_FAMILY],
                         name_split->part_len[BTN_FAMILY]);
		     */
	char * suffix; /*
                         name_split->parts[BTN_SUFFIX],
                         name_split->part_len[BTN_SUFFIX]);
		    */
	char * given_i;
	char * prefix_i;
	char * family_i;
	char * suffix_i;
};

char * inits (char * c) { return c; }
struct nametype parsename(char * namestr,
			    char * fieldname) {
	char * myname;
	bt_name * name, * nd_name;
	bt_name_format * l_f = bt_create_name_format("l",  0),
		*f_f = bt_create_name_format("f", 0),
		*p_f = bt_create_name_format("v", 0),
		*s_f = bt_create_name_format("j", 0),
		*li_f = bt_create_name_format("l",  0),
		*fi_f = bt_create_name_format("f", 0),
		*pi_f = bt_create_name_format("v", 0),
		*si_f = bt_create_name_format("j", 0);
	struct nametype retval;


	myname = normalize_name(namestr);
	name = bt_split_name(namestr,__FILE__,__LINE__,0);
	dump_name (name);

	bt_set_format_options(l_f,BTN_LAST,  0, BTJ_MAYTIE, BTJ_NOTHING);
	bt_set_format_options(f_f,BTN_FIRST, 0, BTJ_MAYTIE, BTJ_NOTHING);
	bt_set_format_options(p_f,BTN_VON,   0, BTJ_MAYTIE, BTJ_NOTHING);
	bt_set_format_options(s_f,BTN_JR,    0, BTJ_MAYTIE, BTJ_NOTHING);

	retval.family = bt_format_name(name,l_f);
	retval.given  = bt_format_name(name,f_f);
	retval.prefix = bt_format_name(name,p_f);
	retval.suffix = bt_format_name(name,s_f);

	nd_name = name;

	bt_set_format_text(li_f,BTN_LAST,  NULL, NULL, NULL, "");
	bt_set_format_text(fi_f,BTN_FIRST, NULL, NULL, NULL, "");
	bt_set_format_text(pi_f,BTN_VON,   NULL, NULL, NULL, "");
	bt_set_format_text(si_f,BTN_JR,    NULL, NULL, NULL, "");
	bt_set_format_options(li_f,BTN_LAST,  1, BTJ_FORCETIE, BTJ_NOTHING);
	bt_set_format_options(fi_f,BTN_FIRST, 1, BTJ_FORCETIE, BTJ_NOTHING);
	bt_set_format_options(pi_f,BTN_VON,   1, BTJ_FORCETIE, BTJ_NOTHING);
	bt_set_format_options(si_f,BTN_JR,    1, BTJ_FORCETIE, BTJ_NOTHING);

	retval.family_i = inits(bt_format_name(nd_name,li_f));
	retval.given_i  = inits(bt_format_name(nd_name,fi_f));
	retval.prefix_i = inits(bt_format_name(nd_name,pi_f));
	retval.suffix_i = inits(bt_format_name(nd_name,si_f));

	free(myname);
	bt_free_name(name);
	bt_free_name_format(l_f);
	bt_free_name_format(f_f);
	bt_free_name_format(p_f);
	bt_free_name_format(s_f);
	bt_free_name_format(li_f);
	bt_free_name_format(fi_f);
	bt_free_name_format(pi_f);
	bt_free_name_format(si_f);

	return retval;
}
char * parse_strings[] = {
	  "Ahrens, Dieter and Rottl{\"a}nder, {C.\bibtexspatium A.}",
	  "Ahrens, Dieter and Rottländer, {C.\bibtexspatium A.}",
	  "Ahrens, Dieter and Rottl{\"a}nder, {C.A."
};
#define parse_string_count 3

void print_names(struct nametype names) {
	printf("{ %s; %s; %s; %s  / %s; %s; %s; %s}\n",
	       names.given,
	       names.prefix,
	       names.family,
	       names.suffix,
	       names.given_i,
	       names.prefix_i,
	       names.family_i,
	       names.suffix_i);
}
void free_names(struct nametype * names) {
	free (names->given);
	free (names->prefix);
	free (names->family);
	free (names->suffix);
	free (names->given_i);
	free (names->prefix_i);
	free (names->family_i);
	free (names->suffix_i);
}

void test_parsename() {
    int i;
	for (i = 0; i < parse_string_count; ++i) {
		struct nametype names = parsename(parse_strings[i],"editor");
		print_names(names);
		free_names(&names);
	}
}

int main (void)
{
   char * snames[4] = { "Joe Blow", "John Smith", "Fred Rogers", "" };
   bt_name * names[4];
   int i;

   printf ("split as we go:\n");
   for (i = 0; i < 4; i++)
   {
	   char * newsname = strdup(snames[i]);
      names[i] = bt_split_name (snames[i], NULL, 0, 0);
      assert (!strcmp(snames[i], newsname));
      free (newsname);
      dump_name (names[i]);
   }

   printf ("pre-split:\n");
   for (i = 0; i < 4; i++)
   {
      dump_name (names[i]);
      bt_free_name(names[i]);
   }

   test_parsename();
   return 0;
}

