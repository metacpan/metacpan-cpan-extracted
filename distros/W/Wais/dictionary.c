/*                               -*- Mode: C -*- 
 * $Basename: dictionary.c $
 * $Revision: 1.4 $
 * Author          : Ulrich Pfeifer
 * Created On      : Mon Nov  6 13:34:22 1995
 * Last Modified By: Ulrich Pfeifer
 * Last Modified On: Tue May 13 09:25:48 1997
 * Language        : C
 * Update Count    : 244
 * Status          : Unknown, Use with caution!
 * 
 * (C) Copyright 1997, Ulrich Pfeifer, all rights reserved.
 * 
 */

#define BIG 10000


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WORD
#undef WORD			/* defined in the perl parser */
#endif
#ifdef _config_h_
#undef _config_h_		/* load the freeWAIS-sf config.h also */
#endif

#include "dictionary.h"

#ifdef WAIS_USES_STDIO
/* #include <stdio.h> */
#ifdef fseek
#undef fseek
#endif
#define my_fseek(stream, offest, flag) fseek(stream, offest, flag)
#else
#define my_fseek(stream, offest, flag) PerlIO_seek(stream, offest, flag)
#endif

database       *
open_database (db_name, fields, nfields)
     char           *db_name;
     char          **fields;
     int             nfields;
{
  database       *db;
  char            field_name[80];

  db = openDatabase (db_name, false, true, nfields);
  if (db == NULL) {
    SV             *error = perl_get_sv ("Wais::errmsg", TRUE);

    sv_setpv (error, "Could not open database");
    return (NULL);
  }
  if (nfields) {
    insert_fields (fields, nfields, db);
  }
  if (nfields && !open_field_streams_for_search (field_name, nfields, db)) {
    char            buf[80];
    SV             *error = perl_get_sv ("Wais::errmsg", TRUE);

    sprintf (buf, "Invalid field name '%s'", field_name);
    sv_setpv (error, buf);
    disposeDatabase (db);
    return (NULL);
  }
  return (db);
}

int
find_partialword (db, field_name, word, offset, matches)
     database       *db;
     char           *word;
     long             offset;
     long           *matches;
     char           *field_name;
{
  register SV   **sp = stack_sp;
  long            answer;
  long            number_of_occurances;
  char           *match_word = "initial";
  int             word_len = strlen (word);
  char           *new_word = malloc (word_len + 2);

  strcpy (new_word, word);
  if (new_word[word_len - 1] != '*') {
    new_word[word_len] = '*';
    new_word[word_len + 1] = '\0';
  }
  answer =
    look_up_partialword_in_dictionary ((field_name == NULL) ? "" : field_name,
				       new_word,
				       &number_of_occurances,
				       &match_word,
				       db);
  if (TRACE)
    fprintf (stderr, "field=%s word=%s\n", (field_name == NULL) ?
	     "" : field_name, new_word);
  s_free (new_word);

  while (answer > -1) {
    if (TRACE)
      fprintf (stderr, "%d, %s\n", answer, match_word);
    if ((GIMME == G_ARRAY)) {
      EXTEND (sp, 2);
      PUSHs (sv_2mortal (newSVpv (match_word, strlen (match_word))));
      if (offset)
	PUSHs (sv_2mortal (newSViv (answer)));
      else
	PUSHs (sv_2mortal (newSViv (number_of_occurances)));
    } else {
      (*matches)++;
    }
    answer = look_up_partialword_in_dictionary ((field_name == NULL) ?
						"" : field_name,
						NULL,
						&number_of_occurances,
						&match_word, db);
  }
  if ((GIMME == G_ARRAY))
    PUTBACK;
  return (0);
}

int
find_word (database_name, field, word, offset, matches)
     char           *database_name;
     char           *field;
     char           *word;
     long           *matches;
     long            offset;

{
  char           *fna[1];
  int             all = (word == NULL);
  int             result = 0;
  database       *db;

  if (field != NULL) {
    fna[0] = (char *)strdup (field);
    if ((db = open_database (database_name, fna, 1)) == NULL) {
      s_free (fna[0]);
      return (0);
    }
    s_free (fna[0]);
  } else {
    if ((db = open_database (database_name, fna, 0)) == NULL) {
      return (0);
    }
  }

  if (all) {
    unsigned int    c;
    unsigned char  *dummy = (char *)strdup ("a*");

    for (c = 0; c < 256; c++) {
      if (isalnum (c) && islower (c)) {
	dummy[0] = c;
	result |= find_partialword (db, field,
				    dummy, offset, matches);
      }
    }
    free (dummy);
  } else {
    result = find_partialword (db, field, word, offset, matches);
  }
  disposeDatabase (db);
  return (!result);
}

#define W_ERROR(M,V) \
{\
        char           buff[80];\
        SV             *error = perl_get_sv ("Wais::errmsg", TRUE);\
\
        if (db) disposeDatabase (db);\
        s_free(index_block_header);\
        s_free (posting_list);\
        sprintf (buff, M, V);\
        sv_setpv (error, buff);\
        return (0);\
}

int
postings (database_name, field, word, number_of_postings)
     char           *database_name;
     char           *word;
     char           *field;
     long           *number_of_postings;
{
  register SV   **sp = stack_sp;
  database       *db;
  FILE           *stream;
  char           *index_block_header = NULL;
  char           *posting_list = NULL;
  char           *fna[1];
  long            index_file_block_number;
  long            number_of_occurances;
  long            not_full_flag = INDEX_BLOCK_FULL_FLAG;
  long            number_of_valid_entries;
  long            count, index_block_size;
  long            posting_list_pos = 0;
  long            char_list_size_readed = 0;
  long            char_list_size = 0;
  double          internal_weight;
  long            txt_pos;
  long            first_txt_pos;
  long            distance = 0;
  long            prev_distance = 0;
  boolean         first_char_pos_readed = false;
  unsigned char  *char_list = NULL;
  unsigned char  *tmp_char_list = NULL;
  unsigned char  *prev_char_list = NULL;

  fna[0] = NULL;
  if (field != NULL) {
    fna[0] = (char *)strdup (field);
    if ((db = open_database (database_name, fna, 1)) == NULL) {
      s_free (fna[0]);
      return (0);
    }
    s_free (fna[0]);
  } else {
    if ((db = open_database (database_name, fna, 0)) == NULL) {
      return (0);
    }
  }

  if (field == NULL) {
    index_file_block_number =
      look_up_word_in_dictionary (word, &number_of_occurances, db);
  } else {
    index_file_block_number =
      field_look_up_word_in_dictionary (field, word, &number_of_occurances, db);
  }
  if (index_file_block_number < 0) {
    disposeDatabase (db);
    return (0);
  }
  if ((field != NULL) && (*field != '\0'))
    stream = db->field_index_streams[pick_up_field_id (field, db)];
  else
    stream = db->index_stream;

  if (0 != my_fseek (stream, (long) index_file_block_number,
		  SEEK_SET)) {
    W_ERROR ("fseek failed into the inverted file to position %ld",
	     (long) index_file_block_number);
  }
  if (index_block_header == NULL) {
    index_block_header = (unsigned char *)
      calloc ((size_t) (INDEX_BLOCK_HEADER_SIZE * sizeof (char)),
	                      (size_t) 1);
  }
  if (index_block_header == NULL) {
    W_ERROR ("Out of memory", 0);
  }
  if (0 > fread_from_stream (stream, index_block_header,
			     INDEX_BLOCK_HEADER_SIZE)) {
    W_ERROR ("Could not read the index block", 1);
  }
  not_full_flag =
    read_bytes_from_memory (INDEX_BLOCK_FLAG_SIZE,
			    index_block_header);
  *number_of_postings = number_of_valid_entries =
    read_bytes_from_memory (NEXT_INDEX_BLOCK_SIZE,
			    index_block_header + INDEX_BLOCK_FLAG_SIZE);
  if (GIMME == G_ARRAY) {
    index_block_size =
      read_bytes_from_memory (INDEX_BLOCK_SIZE_SIZE,
			      index_block_header +
			      INDEX_BLOCK_FLAG_SIZE + NEXT_INDEX_BLOCK_SIZE);

    posting_list = (unsigned char *)
      calloc ((size_t) (index_block_size - INDEX_BLOCK_HEADER_SIZE)
	      * sizeof (char), (size_t) 1);

    if (posting_list != NULL) {
      if (0 > fread_from_stream (stream, posting_list,
			      index_block_size - INDEX_BLOCK_HEADER_SIZE)) {
	W_ERROR ("Could not read the index block", 1);
      }
    } else {
      W_ERROR ("Out of memory", 0);
    }
    if (EOF == index_block_size) {
      W_ERROR ("reading from the index file failed", 1)
    }
    if (not_full_flag == INDEX_BLOCK_NOT_FULL_FLAG) {
      /* not full */
      number_of_valid_entries = 0;
    } else if (not_full_flag == INDEX_BLOCK_FULL_FLAG) {
      /* full */
    } else {			/* bad news, file is corrupted. */
      W_ERROR (
	   "Expected the flag in the inverted file to be valid.  it is %ld",
		not_full_flag);
      return (0);
    }
    EXTEND (sp, number_of_valid_entries*2);
    for (count = 0; count < number_of_valid_entries; count++) {
      int             wgt = 0;
      int             did;
      AV*             POST = newAV();
      did = read_bytes_from_memory (DOCUMENT_ID_SIZE,
				    posting_list + posting_list_pos);
#if (BYTEORDER & 0xffff) == 0x1234
      char_list_size =
	htonl (read_bytes_from_memory (NUMBER_OF_OCCURANCES_SIZE,
				       posting_list +
				    (posting_list_pos + DOCUMENT_ID_SIZE)));
#else
      char_list_size =
	read_bytes_from_memory (NUMBER_OF_OCCURANCES_SIZE,
				posting_list +
				(posting_list_pos + DOCUMENT_ID_SIZE));
#endif
      internal_weight = 
	read_weight_from_memory (NEW_WEIGHT_SIZE,
				 posting_list +
				 (posting_list_pos +
				  DOCUMENT_ID_SIZE +
				  NUMBER_OF_OCCURANCES_SIZE));
      if (TRACE)
          fprintf (stderr, "did=%d weight=%lf\n", did, internal_weight);
      PUSHs (sv_2mortal (newSViv (did)));
      PUSHs (sv_2mortal (newRV_noinc((SV*)POST)));
      av_push(POST, (newSVnv (internal_weight)));
      char_list_size_readed = 0;
      first_char_pos_readed = false;
      first_txt_pos = prev_distance = distance = 0;
      while (char_list_size > char_list_size_readed) {
	if (first_char_pos_readed == false) {
	  first_char_pos_readed = true;
	  txt_pos = read_bytes_from_memory (CHARACTER_POSITION_SIZE,
					    posting_list +
					    (posting_list_pos +
					     DOCUMENT_ID_SIZE +
					     NUMBER_OF_OCCURANCES_SIZE +
					     NEW_WEIGHT_SIZE));
	  first_txt_pos = txt_pos;
	  char_list_size_readed += CHARACTER_POSITION_SIZE;
	} else {
	  tmp_char_list = posting_list + (posting_list_pos +
					  DOCUMENT_ID_SIZE +
					  NUMBER_OF_OCCURANCES_SIZE +
					  NEW_WEIGHT_SIZE +
					  char_list_size_readed);
	  prev_char_list = tmp_char_list;
	  tmp_char_list = (unsigned char *)
	    readCompressedInteger ((unsigned long *)&distance, tmp_char_list);
	  txt_pos = first_txt_pos + prev_distance + distance;
	  prev_distance += distance;
	  char_list_size_readed += tmp_char_list - prev_char_list;
	}
        av_push(POST, newSViv (txt_pos));
        if (TRACE)
            fprintf (stderr, "distance=%d\n", txt_pos);
	prev_distance += distance;
	char_list_size_readed += tmp_char_list - prev_char_list;
      }				/* while char_list */
      posting_list_pos += DOCUMENT_ID_SIZE + NUMBER_OF_OCCURANCES_SIZE +
	NEW_WEIGHT_SIZE + char_list_size;
    }				/* for count */
    PUTBACK;
  }				/* GIMME */
  if (db)
    disposeDatabase (db);
  s_free (index_block_header);
  s_free (posting_list);
  return (1);
}				/* postings */

char *
headline(database_name, docid)
     char           *database_name;
     long           docid;
{
      char           *fna[1];
      char           *result = NULL;
      database       *db;
      document_table_entry doc_entry;
      char filename[MAX_FILE_NAME_LEN];
      char  type[100];

      fna[0] = NULL;
      if ((db = open_database (database_name, fna, 0)) == NULL) {
          return (0);
      }
      if (read_document_table_entry(&doc_entry, docid, db) 
          == true) {
          read_filename_table_entry(doc_entry.filename_id, 
                                    filename,
                                    type,
                                    NULL,
                                    db);
          result = read_headline_table_entry(doc_entry.headline_id,db);
      }
      disposeDatabase (db);
      return(result);
}
#undef  W_ERROR
#define W_ERROR(M,V) \
{\
        SV             *error = perl_get_sv ("Wais::errmsg", TRUE);\
\
        if (db) disposeDatabase (db);\
        if (input_stream != NULL) s_fclose(input_stream);\
        return (0);\
}

char           *
document (database_name, docid)
     char           *database_name;
     long            docid;
{
  char           *fna[1];
  char           *buf;
  database       *db;
  document_table_entry doc_entry;
  char            filename[MAX_FILE_NAME_LEN];
  char            *tmpFileName;
  char            type[100];
  FILE           *input_stream = NULL;
  long            length, bytesRead;

  fna[0] = NULL;
  if ((db = open_database (database_name, fna, 0)) == NULL) {
    return (0);
  }
  if (read_document_table_entry (&doc_entry, docid, db)
      != true) {
    W_ERROR ("Cuold not read document table entry", 0);
  }
  read_filename_table_entry (doc_entry.filename_id,
			     filename,
			     type,
			     NULL,
			     db);
  if (probe_file (filename)) {
    input_stream = s_fopen (filename, "r");
  } else {
    if (probe_file_possibly_compressed (filename)) {
      tmpFileName = s_fzcat (filename);
      if (tmpFileName) {
	input_stream = s_fopen (tmpFileName, "r");
	unlink (tmpFileName);
	free (tmpFileName);
      }
    } else {
      W_ERROR ("File %s not readable", filename);
    }
  }

  if (NULL == input_stream) {
    W_ERROR ("File %s does not exist", filename);
  }
  if (my_fseek (input_stream, doc_entry.start_character, SEEK_SET) != 0) {
    W_ERROR ("retrieval can't seek to %ld", doc_entry.start_character);
  }
  length = doc_entry.end_character - doc_entry.start_character;
  buf = (char *)s_malloc (sizeof(char) *length);
  if (NULL == buf) {
    W_ERROR ("Out of memory", 0);
  }

  bytesRead = fread_from_stream(input_stream, buf, length);

  if (bytesRead != length) {
    W_ERROR ("Could not read document completely %d", length-bytesRead);
  }
  disposeDatabase (db);
  s_fclose (input_stream);
  return (buf);
}
