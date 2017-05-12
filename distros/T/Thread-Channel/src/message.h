#ifdef PACKED
#undef PACKED
#endif

enum message_type { EMPTY, STRING, PACKED, SEREAL };

typedef struct message {
	struct message* next;
	enum message_type type;
	STRLEN length;
	char value[0];
} message;

void S_destroy_message(pTHX_ const message*);
#define destroy_message(message) S_destroy_message(aTHX_ message)

const message* S_message_clone(pTHX_ const message* origin);
#define message_clone(origin) S_message_clone(aTHX_ origin)

void S_message_to_stack(pTHX_ const message*, U32 context);
#define message_to_stack(values, context) STMT_START { PUTBACK; S_message_to_stack(aTHX_ (values), context); SPAGAIN; } STMT_END

AV* S_message_to_array(pTHX_ const message*);
#define message_to_array(message) S_message_to_array(aTHX_ (message))

const message* S_message_from_stack(pTHX);
#define message_from_stack_pushed(message) STMT_START { PUTBACK; message = S_message_from_stack(aTHX); SPAGAIN; } STMT_END
#define message_from_stack(message, offset) STMT_START { PUSHMARK(offset); message_from_stack_pushed(message); } STMT_END

const message* S_message_store_value(pTHX_ SV* value);
#define message_store_value(value) S_message_store_value(aTHX_ value)

SV* S_message_load_value(pTHX_ const message* message);
#define message_load_value(message) S_message_load_value(aTHX_ message)
