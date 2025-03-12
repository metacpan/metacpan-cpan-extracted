#include "erl_nif.h"
#include "unijp.h"
#include <string.h>

#define DEBUG(cmd) ((void)0)

/* ----------------------------------------------------------------------------
 * unijp allocator.
 * ------------------------------------------------------------------------- */
void* uja_alloc(void* baton, uj_size_t size)
{
	return malloc(size);
}
void* uja_realloc(void* baton, void* ptr, uj_size_t size)
{
	return realloc(ptr, size);
}
void uja_free(void* baton, void* ptr)
{
	free(ptr);
}

static const uj_alloc_t my_uj_alloc = {
	UJ_ALLOC_MAGIC,
	NULL, /* baton. */
	&uja_alloc,
	&uja_realloc,
	&uja_free,
};

/* ----------------------------------------------------------------------------
 * version_string/0.
 * ------------------------------------------------------------------------- */
static ERL_NIF_TERM version_string_0(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	return enif_make_string(env, UNIJP_VERSION_STRING, ERL_NIF_LATIN1);
}

/* ----------------------------------------------------------------------------
 * version_tuple/0.
 * ------------------------------------------------------------------------- */
static ERL_NIF_TERM version_tuple_0(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	ERL_NIF_TERM ver_major, ver_minor, ver_patch;
	ver_major = enif_make_int(env, UNIJP_VERSION_MAJOR);
	ver_minor = enif_make_int(env, UNIJP_VERSION_MINOR);
	ver_patch = enif_make_int(env, UNIJP_VERSION_PATCH);

	return enif_make_tuple3(env, ver_major, ver_minor, ver_patch);
}

/* ----------------------------------------------------------------------------
 * decode_charcode/1.
 * ------------------------------------------------------------------------- */
static ERL_NIF_TERM decode_charcode_1(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	ErlNifBinary in_bin;
	ERL_NIF_TERM ret;

	/* verify and decode arguments. */
	{
		if( argc < 1 )
		{
			return enif_make_badarg(env);
		}
		if( !enif_is_binary(env, argv[0]) )
		{
			return enif_make_badarg(env);
		}

		if( !enif_inspect_binary(env, argv[0], &in_bin) )
		{
			return enif_make_badarg(env);
		}
	}

	/* body. */
	{
		uj_charcode_t charcode;
		const char* charcode_str;
		charcode = uj_charcode_parse_n((const char*)in_bin.data, in_bin.size);
		if( charcode==ujc_undefined )
		{
			DEBUG(printf("charcode invalid: [%.*s]\n", in_bin.data, in_bin.size));
			return enif_make_badarg(env);
		}

		charcode_str = uj_charcode_str(charcode);
		ret = enif_make_atom(env, charcode_str);
	}

	return ret;
}
/* ----------------------------------------------------------------------------
 * conv/3.
 * ------------------------------------------------------------------------- */
static ERL_NIF_TERM conv_3(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	char from_buf[16];
	int  from_len;
	char to_buf[16];
	int  to_len;
	ErlNifBinary in_bin;
	ErlNifBinary out_bin;
	uj_uint8* ret;
	uj_size_t ret_len;

	/* verify and decode arguments. */
	{
		if( argc < 3 )
		{
			return enif_make_badarg(env);
		}
		if( !enif_is_atom(env, argv[0]) )
		{
			return enif_make_badarg(env);
		}
		if( !enif_is_atom(env, argv[1]) )
		{
			return enif_make_badarg(env);
		}
		if( !enif_is_binary(env, argv[2]) )
		{
			return enif_make_badarg(env);
		}

		from_len = enif_get_atom(env, argv[0], from_buf, sizeof(from_buf), ERL_NIF_LATIN1);
		if( from_len < 1 )
		{
			return enif_make_badarg(env);
		}
		from_len -= 1;
		to_len = enif_get_atom(env, argv[1], to_buf, sizeof(to_buf), ERL_NIF_LATIN1);
		if( to_len < 1 )
		{
			return enif_make_badarg(env);
		}
		to_len -= 1;
		if( !enif_inspect_binary(env, argv[2], &in_bin) )
		{
			return enif_make_badarg(env);
		}
	}

	/* body. */
	{
		uj_charcode_t icode;
		uj_charcode_t ocode;
		unijp_t* uj;
		icode = uj_charcode_parse_n(from_buf, from_len);
		ocode = uj_charcode_parse_n(to_buf, to_len);
		if( icode==ujc_undefined )
		{
			DEBUG(printf("icode invalid: [%.*s]\n", from_len, from_buf));
			return enif_make_badarg(env);
		}
		if( ocode==ujc_undefined )
		{
			DEBUG(printf("ocode invalid: [%.*s]\n", to_len, to_buf));
			return enif_make_badarg(env);
		}
		uj = uj_new_r(&my_uj_alloc, (uj_uint8*)in_bin.data, in_bin.size, icode);
		if( uj==NULL )
		{
			DEBUG(printf("uj_new failed: %s\n", strerror(errno)));
			return enif_make_badarg(env);
		}
		ret = uj_conv(uj, ocode, &ret_len);
		if( ret==NULL )
		{
			DEBUG(printf("uj_conv failed: %s\n", strerror(errno)));
			uj_delete(uj);
			return enif_make_badarg(env);
		}

		DEBUG(printf("conv success: ret_len=%d.\n", ret_len));
		if( !enif_alloc_binary(ret_len, &out_bin) )
		{
			uj_delete_buffer(uj, ret);
			uj_delete(uj);
			return enif_make_badarg(env);
		}
		memcpy(out_bin.data, ret, ret_len);
		uj_delete_buffer(uj, ret);
		uj_delete(uj);
	}

	return enif_make_binary(env, &out_bin);
}

static ErlNifFunc nif_funcs[] =
{
	{"decode_charcode", 1, decode_charcode_1},
	{"version_string",  0, version_string_0},
	{"version_tuple",   0, version_tuple_0},
	{"conv", 3, conv_3}
};

ERL_NIF_INIT(
	unijp_nif, /* module.  */
	nif_funcs, /* funcs.   */
	NULL,      /* load.    */
	NULL,      /* reload.  */
	NULL,      /* upgrade. */
	NULL       /* unload.  */
)
