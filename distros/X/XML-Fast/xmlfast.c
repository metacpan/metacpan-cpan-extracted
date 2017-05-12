#include "xmlfast.h"

#define case_wsp   \
		case 0xa  : context->line_number++; \
		case 0x9  :\
		case 0xd  :\
		case 0x20

#ifndef XML_DEBUG
#define XML_DEBUG 0
#endif

#if XML_DEBUG
#define WHERESTR    " at %s line %d.\n"
#define WHEREARG    __FILE__, __LINE__
#define debug(...)   do{ fprintf(stderr, __VA_ARGS__); fprintf(stderr, WHERESTR, WHEREARG); } while(0)
#else
#define debug(...)
#endif

#define DOCUMENT_START 0
#define LT_OPEN        1
#define COMMENT_OPEN   2
#define CDATA_OPEN     3
#define PI             4
#define CONTENT_WAIT   5
#define TAG_OPEN       6
#define TAG_CLOSE      7
#define TEXT_READ      8
#define TEXT_DATA      9
#define TEXT_INITWSP  10
#define TEXT_WSP      11
#define DOCUMENT_ABORTED 12

static char *STATE[DOCUMENT_ABORTED+1] = {
	 "DOCUMENT_START"
	,"LT_OPEN"
	,"COMMENT_OPEN"
	,"CDATA_OPEN"
	,"PI"
	,"CONTENT_WAIT"
	,"TAG_OPEN"
	,"TAG_CLOSE"
	,"TEXT_READ"
	,"TEXT_DATA"
	,"TEXT_INITWSP"
	,"TEXT_WSP"
	,"DOCUMENT_ABORTED"
};

static inline char * eat_wsp(parser_state * context, char *p) {
	while (1) {
		switch (*p) {
			case 0: return p;
			case_wsp :
				break;
			default:
				return p;
		}
		p++;
	}
}

static inline char * eatback_wsp(parser_state * context, char *p) {
	while (1) {
		switch (*p) {
			case 0: return p;
			case_wsp :
				break;
			default:
				return p;
		}
		p--;
	}
}

static inline char *parse_entity (parser_state * context, char *p) {
	//return p+1;
	entityref_t *cur_ent;
	char *at;
	at = p;
	unsigned int i;
	if (*(p+1) == '#') {
		p+=2;
		wchar_t chr = 0;
		if (*p == 'x') {
			p++;
			while(1) {
				if (*p >= '0' && *p <= '9') {
					chr *= 16;
					chr += (*p++ - '0');
				}
				else
				if (*p >= 'a' && *p <= 'f') {
					chr *= 16;
					chr += (*p++ - 'a' + 10);
				}
				else
				if (*p >= 'A' && *p <= 'F') {
					chr *= 16;
					chr += (*p++ - 'A' + 10);
				}
				else
					break;
			}
		}
		else {
			while(*p >= '0' && *p <= '9') {
				chr *= 10;
				chr += (*p++ - '0');
			}
		}
		if ( *p == ';' ) p++;
		if (chr > 0 && chr <= 0xFFFF) {
			if (context->cb.uchar) context->cb.uchar(context->ctx, chr);
		} else {
			if (context->cb.warn) {
				char back = *p;
				*p = 0;
				context->cb.warn(context->ctx,"Bad entity value %s",at);
				*p = back;
			}
			if (context->cb.bytespart) context->cb.bytespart(context->ctx, at, p - at);
		}
		return p;
	}
	cur_ent = entities;
	next_ent:
		if (*p == 0) return 0;
		p++;
		if (*p == ';') {
			if (cur_ent && cur_ent->entity) {
				p++;
				goto ret;
			} else {
				goto no_ent;
			}
		}
		for (i=0; i < cur_ent->children; i++) {
			if (cur_ent->more[i].c == *p) {
				cur_ent = &cur_ent->more[i];
				goto next_ent;
			}
		}
		if (cur_ent && cur_ent->entity) {
			goto ret;
		}
	
	no_ent:
		if (p == at) p++;
		if (context->cb.bytespart) context->cb.bytespart(context->ctx, at, p - at);
		return p;
	
	ret:
		if (context->cb.bytespart) context->cb.bytespart(context->ctx, cur_ent->entity, cur_ent->length);
		return p;
}

/*
static void print_chain (xml_node *chain, int depth) {
	int i;
	xml_node * node;
	printf(":>> ");
	for (i=0; i < depth; i++) {
		node = &chain[i];
		printf("%s",node->name);
		if (i < depth-1 )printf(" > ");
	}
	printf("\n");
}
*/

static inline char *parse_attrs(char *p, parser_state * context) {
	void * ctx = context->ctx;
	xml_callbacks * cb = &context->cb;
		char state = 0;
		/*
		 * state=0 - default, waiting for attr name or /?>
		 * state=1 - reading attr name
		 * state=2 - reading attr value
		 */
		char wait = 0;
		char loop = 1;
		char *at,*end;
		p = eat_wsp(context, p);
		while(loop) {
			switch(state) {
				case 0: // waiting for attr name
					//printf("Want attr name, char='%c'\n",*p);
					while(state == 0) {
						switch(*p) {
							case 0   : if (context->cb.die) context->cb.die(ctx,"Document aborted"); return 0;
							case_wsp : p = eat_wsp(context, p); break;
							case '>' :
							case '?' :
							case '/' : return p;
							default  : state = 1;
						}
					}
					break;
				case 1: //reading attr name
					at = p;
					end = 0;
					//printf("Want = (%c)\n",*p);
					while(state == 1) {
						switch(*p) {
							case 0   : if (context->cb.die) context->cb.die(ctx,"Document aborted");return 0;
							case_wsp :
								end = p;
								p = eat_wsp(context, p);
								if (*p != '=') {
									if (context->cb.die) context->cb.die(ctx,"No = after whitespace while reading attr name");
									return 0;
								}
							case '=':
								if (!end) end = p;
								if (cb->attrname) cb->attrname( ctx, at, end - at );
								p = eat_wsp(context, p + 1);
								state = 2;
								break;
							default: p++;
						}
					}
					break;
				case 2:
					wait = 0;
					//printf("Want quote (%c)\n",*p);
					while(state == 2) {
						switch(*p) {
							case 0   : if (context->cb.die) context->cb.die(ctx,"Document aborted");return 0;
							case '\'':
							case '"':
								if (!wait) { // got open quote
									//printf("\tgot open quote <%c>\n",*p);
									wait = *p;
									p++;
									at = p;
									break;
								} else
								if (*p == wait) {  // got close quote
									//printf("\tgot close quote <%c>\n",*p);
									state = 0;
									if(cb->bytes) cb->bytes( ctx, at, p - at );
									p = eat_wsp(context, p+1);
									break;
								}
							case '&':
								if (wait) {
									//printf("Got entity begin (%s)\n",buffer);
									if (p > at && cb->bytespart) cb->bytespart( ctx, at, p - at );
									if( p = parse_entity(context, p) ) {
										at = p;
										break;
									}
								} else {
									if (context->cb.die) context->cb.die(ctx,"Not waiting for & in state 2");
									return 0;
								}
							default: p++;
						}
					}
					break;
				default:
					if (context->cb.warn) context->cb.warn(ctx, "default, state=%d, char='%c'\n",state, *p);
					return 0;
			}
		}
		return p;
}

void parse (char * xml, parser_state * context) {
	void * ctx = context->ctx;
	xml_callbacks * cb = &context->cb;
	context->line_number = 1;
	char *p, *at, *start, *end, *search, buffer[BUFFER];
	memset(&buffer,0,BUFFER);
	unsigned int state, len;
	unsigned char textstate;
	p = xml;
	/*
	xml_node *seek, *reverse;
	context->chain_size = 64;
	Newx( context->chain, context->chain_size, xml_node);
	context->root = context->chain;
	*/
	
	context->state = DOCUMENT_START;
	next:
	while (1) {
		switch(*p) {
			case 0: goto eod;
			case '<':
				context->state = LT_OPEN;
				p++;
				switch (*p) {
					case 0: goto eod;
					case '!':
						p++;
						if(*p == 0) goto eod;
						if ( strncmp( p, "--", 2 ) == 0 ) {
							context->state = COMMENT_OPEN;
							p+=2;
							search = strstr(p,"-->");
							if (search) {
								if (cb->comment) {
									cb->comment( ctx, p, search - p );
								}
								p = search + 3;
							} else xml_error("Comment node not terminated");
							context->state = CONTENT_WAIT;
							goto next;
						} else
						if ( strncmp( p, "[CDATA[", 7 ) == 0) {
							context->state = CDATA_OPEN;
							p+=7;
							search = strstr(p,"]]>");
							if (search) {
								if (cb->cdata) {
									cb->cdata( ctx, p, search - p);
								}
								p = search + 3;
							} else xml_error("Cdata node not terminated");
							context->state = CONTENT_WAIT;
							goto next;
						} else
						if ( strncmp(p, "DOCTYPE", 7 ) == 0 ) {
							p += 7;
							//p = eat_wsp(p);
							state = 0;
							while(state == 0) {
								switch(*p) {
									case 0  : xml_error("Doctype not properly terminated"); break;
									case '[': state = 1; p++; break;
									case '>': state = 2; p++; break;
									default : p++;
								}
							}
							if (state == 1) {
								search = strchr(p,']');
								if (search) {
									//printf("search = %s\n",search);
									p = eat_wsp(context,search+1);
									if (*p == '>') {
										p++;
										state = 2;
									} else {
										xml_error("Doctype not properly terminated");
									}
								} else {
									xml_error("Doctype intSubset not terminated");
								}
							}
							//fprintf(stderr,"after doctype: %s\n",p);
							context->state = CONTENT_WAIT;
							goto next;
						} else
						{
							xml_error("Malformed document after <!");
							goto fault;
						}
						break;
					case '?':
						context->state = PI;
						state = 0;
						p++;
						at = p;
						while(state == 0) {
							switch(*p) {
								case 0   : xml_error("Processing instruction not terminated");
								case_wsp :
									if (p > at) {
										debug("PI: want attrs");
										end = p;
										state = 1;
										break;
									} else xml_error("Bad processing instruction");
								case '?':
									end = p;
									p++;
									if (*p == '>') {
										p++;
										state = 3;
									} else xml_error("Processing instruction not terminated");
									break;
								default: p++;
							}
						}
						if (cb->piopen) cb->piopen( context->ctx, at, end - at );
						if (state == 1) {
							if (!( at = parse_attrs(p,context) ))
								xml_error("Error parsing PI attributes");
							p = at;
							state = 2;
						}
						debug("CB> Got pi name state=%d next='%c'\n",state,*p);
						if (state == 2) {
							if (*p == '?' && *(p+1) == '>') {
								debug("PI correctly closed\n");
								p+=2;
								state = 3;
							} else xml_error("Processing instruction not terminated");
						}
						if (state != 3)
							xml_error("Internal error: Bad state after processing instruction");
						if (cb->piclose) cb->piclose( context->ctx, at, end - at );
						context->state = CONTENT_WAIT;
						goto next;
					
					case '/': // </node>
						context->state = TAG_CLOSE;
						p++;
						at = p;
						search = strchr(p,'>');
						if (search) {
							p = search + 1;
							search = eatback_wsp(context, search-1)+1;
							len = search - at;
							// DISABLE BALANCING
							if (len == 0 ) xml_error("Empty close tag name");
							if(cb->tagclose) cb->tagclose(ctx, at, len);
							context->state = CONTENT_WAIT;
							goto next;
							// DISABLE BALANCING
/*
							if (context->depth == 0) {
								if (context->cb.warn)
									context->cb.warn(context->ctx,"Need to close tag upper than root. Ignored");
								context->state = CONTENT_WAIT;
								goto next;
							}
							if (strncmp(context->chain->name, at, len) == 0) {
								if(cb->tagclose) cb->tagclose(ctx, at, len);
								context->depth--;
								context->chain--;
							} else {
								if(len+1 > BUFFER) {
									snprintf(buffer,BUFFER,"%s",at);
								} else {
									snprintf(buffer,len+1,"%s",at);
								}
								//printf("NODE CLOSE '%s' (unbalanced)\n",buffer);
								reverse = seek = context->chain;
								while( seek > context->root ) {
									seek--;
									if (strncmp(seek->name, at, len) == 0) {
										if (context->cb.warn)
											context->cb.warn(context->ctx,"Found early opened node %s",seek->name);
										while(context->chain >= seek) {
											if(cb->tagclose) cb->tagclose(ctx, context->chain->name, context->chain->len);
											Safefree(context->chain->name);
											context->chain--;
											context->depth--;
										}
										//optional feature: auto-opening tags
										//for (seek = chain+2; seek <= reverse; seek++) {
										//	//printf("Auto open %s\n",seek->name);
										//	chain++;
										//	curr_depth++;
										//	*chain = *(chain+1);
										//	if(cb->tagopen) cb->tagopen(ctx, chain->name, chain->len);
										//	//print_chain(root, curr_depth);
										//}
										//optional feature: auto-opening tags
										seek = 0;
										break;
									}
								}
								if (seek) {
									if (cb->warn)
										cb->warn(context->ctx,"Found no open node until root for '%s' at line %d, char %d. Ignored",buffer, context->line_number, p - xml);
								} else {
									// TODO ??
								}
							}
							context->state = CONTENT_WAIT;
							goto next;
*/
						} else xml_error("Close tag not terminated");
					default: //<node...>
						state = 0;
						context->state = TAG_OPEN;
						debug("open tag: %.10s...",p);
						while(state < 3) {
							switch(state) {
								case 0:
									at = p;
									while(state == 0) {
										switch(*p) {
											case 0: xml_error("Unterminated node");
											case_wsp :
												if (p > at) {
													state = 1;
													break;
												} else xml_error("Bad node open");
											case '/':
											case '>':
												if (p > at) {
													state = 2;
													break;
												} else xml_error("Bad node open");
											default: p++;
										}
									}
									len = p - at;
									/*
									if (context->depth + 1 > context->chain_size) {
										seek = context->root;
										context->chain_size *= 2;
										Renew( context->root, context->chain_size, xml_node);
										context->chain = context->root + (context->chain - seek);
									}
									if (context->depth++ != 0) context->chain++;
									context->chain->len = p - at;
									context->chain->name = safemalloc( context->chain->len + 1 );
									memcpy(context->chain->name, at, context->chain->len);
									context->chain->name[context->chain->len] = '\0';
									if (cb->tagopen) cb->tagopen( ctx, at, context->chain->len );
									*/
									debug("opened tag: <%.*s>", p - at, at);
									if (cb->tagopen) cb->tagopen( ctx, at, p - at );
									break;
								case 1:
									if (search = parse_attrs(p,context)) {
										p = search;
										state = 2;
									} else xml_error("Error parsing node attributes");
								case 2:
									while(state == 2) {
										switch(*p) {
											case 0   : xml_error("Unterminated node");
											case_wsp : p = eat_wsp(context, p);
											case '/' :
												debug("close tag now: %s -> <%.*s>", at, len, at);
												if (cb->tagclose) cb->tagclose( ctx, at, len );
												/*Safefree(context->chain->name);
												context->chain--;
												context->depth--;*/
												p = eat_wsp(context, p+1);
												break;
											case '>' : state = 3; p++; break;
											default  :
												xml_error("Bad char at the end of tag");
										}
									}
									context->state = CONTENT_WAIT;
									goto next;
							}
						}
				}
				break;
			default:
				context->state = TEXT_READ;
				start = at = p;
				char *lastwsp = 0;
				if (!context->save_wsp) {
					p = eat_wsp(context, p);
					if (p > at) start = at = p;
				}
				textstate = TEXT_DATA;
				while (1) {
					switch(*p) {
						case 0  :
						case '<':
							//if (p > at) {
								if (!context->save_wsp && textstate == TEXT_WSP) {
									//printf("Skip trailing whitespace chardata=%d wspdata=%d\n", lastwsp - at, p - lastwsp);
								} else {
									lastwsp = p;
								}
								if(cb->bytes) {
									if (lastwsp  > at) {
										cb->bytes(ctx, at, lastwsp - at );
									} else {
										if (p > start) cb->bytes(ctx, "", 0 ); // explicitly terminate
									}
								}
							//}
							context->state = CONTENT_WAIT;
							if (*p == 0) goto eod;
							goto next;
						case_wsp :
							if (textstate == TEXT_DATA) { lastwsp = p; }
							textstate = TEXT_WSP;
							p++;
							break;
						default:
							textstate = TEXT_DATA;
							if (*p == '&') {
								if (p > at && cb->bytespart) cb->bytespart(ctx, at, p - at);
								if( p = parse_entity(context,p) ) {
									at = p;
									break;
								} else {
									goto fault;
								}
							}
							p++;
					}
				}
				textstate = TEXT_INITWSP;
				break;
		}
	}
	//printf("parse done\n");
	//Safefree(context->root);
	return;
	
	eod:
		//printf("End of document, context->state=%d\n",context->state);
		switch(context->state) {
			case DOCUMENT_START:
				if (context->cb.warn) context->cb.warn(ctx,"Empty document");
				return;
			case LT_OPEN:
			case COMMENT_OPEN:
			case CDATA_OPEN:
			case PI:
			case TAG_OPEN:
			case TAG_CLOSE:
				if (context->cb.die)
					context->cb.die(context->ctx,"Bad document end, state = %s",STATE[context->state]);
				break;
			case TEXT_READ:
				if (context->cb.warn) context->cb.warn(ctx,"Need to call text cb at the end of document");
				break;
			case CONTENT_WAIT:
			/*
				if (context->depth == 0) {
					//printf("END ok\n");
				} else {
					printf("Document aborted\n");
					//print_chain(chain,curr_depth);
				}
			*/
				break;
			default:
				if (context->cb.warn) context->cb.warn(ctx,"Bad context->state %d at the end of document\n",context->state);
		}
	
	fault:
	//Safefree(context->root);
	return;
}
