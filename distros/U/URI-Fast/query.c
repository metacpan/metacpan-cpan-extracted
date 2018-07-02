#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef enum {
  KEY   = 1,
  PARAM = 2,
  DONE  = 3,
} uri_query_token_type_t;

typedef struct {
  uri_query_token_type_t type;
  const char *key;   size_t key_length;
  const char *value; size_t value_length; // only present when type=PARAM
} uri_query_token_t;

typedef struct {
  size_t  length;
  size_t  cursor;
  const char   *source;
} uri_query_scanner_t;

void query_scanner_init(
    uri_query_scanner_t *scanner,
    const char *source,
    size_t length
  )
{
  scanner->source = source;
  scanner->length = length;
  scanner->cursor = 0;
}

static
int query_scanner_done(uri_query_scanner_t *scanner) {
  return scanner->cursor >= scanner->length;
}

/*
 * Fills the token struct with the next token information. Does not decode
 * any values.
 */
static
void query_scanner_next(uri_query_scanner_t *scanner, uri_query_token_t *token) {
  size_t brk;
  const char sep[4] = {'&', ';', '=', '\0'};

SCAN_KEY:
  if (scanner->cursor >= scanner->length) {
    token->key   = NULL; token->key_length   = 0;
    token->value = NULL; token->value_length = 0;
    token->type  = DONE;
    return;
  }

  // Scan to end of token
  brk = strncspn(&scanner->source[ scanner->cursor ], scanner->length - scanner->cursor, sep);

  // Set key members in token struct
  token->key = &scanner->source[ scanner->cursor ];
  token->key_length = brk;

  // Move cursor to end of token
  scanner->cursor += brk;

  // If there is an associate value, add it to the token
  if (scanner->source[ scanner->cursor ] == '=') {
    // Advance past '='
    ++scanner->cursor;

    // Find the end of the value
    brk = strncspn(&scanner->source[ scanner->cursor ], scanner->length - scanner->cursor, sep);

    // Set the value and token type
    token->value = &scanner->source[ scanner->cursor ];
    token->value_length = brk;
    token->type = PARAM;

    // Move cursor to the end of the value, eating the separator terminating it
    scanner->cursor += brk + 1;
  }
  // No value assigned to this key
  else {
    token->type = KEY;
    ++scanner->cursor; // advance past terminating separator
  }

  // No key was found; try again
  if (token->key_length == 0) {
    goto SCAN_KEY;
  }

  return;
}
