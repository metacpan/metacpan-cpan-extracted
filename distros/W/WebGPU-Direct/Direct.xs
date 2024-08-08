#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <webgpu/webgpu.h>

// Call new if possible, otherwise return fields
SV *_coerce_obj( SV *CLASS, SV *fields );
SV *_new( SV *CLASS, SV *fields );

SV * _get_mg_obj(pTHX_ SV *obj, SV *base)
{
  if ( !SvOK(obj) )
  {
    return NULL;
  }

  obj = _coerce_obj(base, obj);

  if ( !sv_isobject(obj) )
  {
    croak("%s is not an object", SvPVbyte_nolen(obj));
  }
  if ( base )
  {
    if (!sv_derived_from(obj, SvPVbyte_nolen(base)))
    {
      croak("_get_struct_ptr: %s is not of type %s", SvPVbyte_nolen(obj), SvPVbyte_nolen(base));
    }
  }

  return obj;
}

SV * _get_mg_hash(pTHX_ SV *obj, SV *base)
{
  SV *result = _get_mg_obj(aTHX_ obj, base);
  return result == NULL ? NULL : SvRV(result);
}

void * _get_mg(pTHX_ SV *obj, SV *base)
{
  SV *h = _get_mg_hash(aTHX_ obj, base);
  MAGIC *mg = mg_find(h, PERL_MAGIC_ext);

  return mg;
}

void * _get_struct_ptr(pTHX_ SV *obj, SV *base)
{
  MAGIC *mg = _get_mg(aTHX_ obj, base);

  if ( mg == NULL )
  {
    return NULL;
  }
  return mg->mg_ptr;
}

PERL_STATIC_INLINE
SV **nn_hv_store(pTHX_ HV *h, const char *key, I32 klen, SV *obj, SV *base)
{
  SvREFCNT_inc(obj);
  SV ** f = hv_store(h, key, klen, obj, 0);

  if ( !f )
  {
    SvREFCNT_dec(obj);
    croak("Could not save value to hash for %s in type %s", key, SvPV_nolen(base));
  }

  return f;
}

PERL_STATIC_INLINE
SV **nn_av_store(pTHX_ AV *h, const Size_t idx, SV *obj, SV *base)
{
  SvREFCNT_inc(obj);
  SV ** f = av_store(h, idx, obj);

  if ( !f )
  {
    SvREFCNT_dec(obj);
    croak("Could not save value to array for item %zd in type %s", idx, SvPV_nolen(base));
  }

  return f;
}

SV *_void__wrap( const void *n )
{
  SV *h = newSViv( *(IV *)n);
  SV *RETVAL = sv_2mortal(newRV(h));

  sv_magicext((SV *)h, NULL, PERL_MAGIC_ext, NULL, (const char *)n, 0);
  sv_bless(RETVAL, gv_stashpv("WebGPU::Direct::Opaque", GV_ADD));
  return SvREFCNT_inc(RETVAL);
}

SV *_coerce_obj( SV *CLASS, SV *fields )
{
  // If its already an object, don't bother
  if ( sv_isobject(fields) )
  {
    return fields;
  }

  // If it's null or not a hashref, don't bother either
  if ( CLASS == NULL )
  {
    return fields;
  }
  if ( !SvROK(fields) )
  {
    return fields;
  }
  if (   SvTYPE(SvRV(fields)) != SVt_PVHV
      && SvTYPE(SvRV(fields)) != SVt_PVAV )
  {
    return fields;
  }

  return _new(CLASS, fields);
}

SV *_new( SV *CLASS, SV *fields )
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(CLASS);
  if ( fields != NULL )
  {
    EXTEND(SP, 1);
    PUSHs(fields);
  }
  PUTBACK;

  int count = call_method("new", G_SCALAR);

  SPAGAIN;

  if (count != 1)
  {
    croak("Could not call new on %s\n", SvPV_nolen(CLASS));
  }

  SV *THIS = SvREFCNT_inc(POPs);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return THIS;
}

void _unpack( SV *THIS )
{
  // Do not attempt to call unpack on undef
  if ( !SvOK(THIS) )
  {
    return;
  }

  dSP;
  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(THIS);
  PUTBACK;

  int count = call_method("unpack", G_SCALAR);

  if (count != 1)
  {
    croak("Could not call unpack on %s\n", SvPV_nolen(THIS));
  }

  return;
}

void _pack( SV *THIS )
{
  // Do not attempt to call unpack on undef
  if ( !SvOK(THIS) )
  {
    return;
  }

  dSP;
  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(THIS);
  PUTBACK;

  int count = call_method("pack", G_SCALAR);

  if (count != 1)
  {
    croak("Could not call pack on %s\n", SvPV_nolen(THIS));
  }

  return;
}

// Generate a new, empty blessed hashref that can be unpacked into
SV *_empty_with( SV *CLASS, void *n)
{
  if ( n == NULL )
  {
    return SvREFCNT_inc(newSV(0));
  }

  SV *h = (SV *)newHV();
  SV *RETVAL = sv_2mortal(newRV(h));

  sv_magicext((SV *)h, NULL, PERL_MAGIC_ext, NULL, (const char *)n, 0);
  sv_bless(RETVAL, gv_stashpv(SvPV_nolen(CLASS), GV_ADD));
  return SvREFCNT_inc(RETVAL);
}

// Generate a new blessed hashref that can be packed from
SV *_new_with( void *field, SV *base, Size_t size)
{
  if ( field == NULL )
  {
    croak("_new_with requires a defined field pointer");
  }

  // Coerce an empty hash into an object, and copy to the field ptr
  SV *href = sv_2mortal(newRV( (SV *)newHV() ));

  SV *RETVAL = _get_mg_obj(aTHX_ href, base);

  ASSUME( RETVAL != NULL );

  MAGIC *mg = _get_mg(aTHX_ RETVAL, base);
  ASSUME( mg != NULL );

  void *old_ptr = mg->mg_ptr;
  Copy(old_ptr, field, size, char);

  mg->mg_ptr = field;
  Safefree(old_ptr);

  return RETVAL;
}

SV *_new_opaque( SV *CLASS, void *n)
{
  if ( n == NULL )
  {
    return SvREFCNT_inc(newSV(0));
  }

  SV *h = newSViv( (Size_t)n);
  SV *RETVAL = sv_2mortal(newRV(h));

  sv_magicext((SV *)h, NULL, PERL_MAGIC_ext, NULL, (const char *)n, 0);
  sv_bless(RETVAL, gv_stashpv(SvPV_nolen(CLASS), GV_ADD));
  return SvREFCNT_inc(RETVAL);
}

/* ------------------------------------------------------------------
    {
      set      => 'Sets the field of the struct',
      unpack   => 'Sets the perl hash from the struct',
      pack     => 'Sets the struct from the perl hash',
      find     => '',
      store    => 'Sets the perl hash and packs the object',
    }
   ------------------------------------------------------------------ */

/* ------------------------------------------------------------------
   obj
   ------------------------------------------------------------------ */

void _set_obj(pTHX_ SV *new_value, void *field, Size_t size, SV *base)
{
  if ( !base )
  {
    croak("Could not find requirement base for %s", SvPV_nolen(new_value));
  }

  if ( !size )
  {
    croak("Could not find size for %s", SvPV_nolen(new_value));
  }

  void *v = SvOK(new_value) ? _get_struct_ptr(aTHX_ new_value, base) : NULL;
  Copy(v, field, size, char);
}

int _mg_set_obj(pTHX_ SV* sv, MAGIC* mg)
{
  SV *base = mg->mg_obj;
  _set_obj(aTHX_ sv, (void *) mg->mg_ptr, 0, base);
  return 0;
}

STATIC MGVTBL _mg_vtbl_obj = {
  .svt_set = _mg_set_obj
};

SV *_unpack_obj(pTHX_ HV *h, const char *key, I32 klen, void *field, Size_t size, SV* base)
{
  SV **f = NULL;

  if ( field == NULL )
  {
    croak("The field value for objptr must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  f = hv_fetch(h, key, klen, 1);

  if ( !( f && *f ) )
  {
    croak("Could not save new value for %s", key);
  }

  void *n = NULL;
  if ( sv_isobject(*f) )
  {
    n = _get_struct_ptr(aTHX_ *f, base);
  }

  if ( n == NULL || n != field )
  {
    SV *obj = _empty_with(base, field);
    f = nn_hv_store(aTHX_ h, key, klen, obj, base);
  }

  _unpack(*f);

  return *f;
}

SV *_pack_obj(pTHX_ HV *h, const char *key, I32 klen, void *field, Size_t size, SV *base)
{
  SV **f;
  SV *fp;

  if ( field == NULL )
  {
    croak("The field value to _pack_obj must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    SV *val = _new_with(field, base, size);
    f = nn_hv_store(aTHX_ h, key, klen, val, base);
  }

  SV *obj = _get_mg_obj(aTHX_ *f, base);
  ASSUME( obj != NULL );

  if ( *f != obj )
  {
    // Since we know it was coerced, we can go ahead and reuse the obj
    MAGIC *mg = _get_mg(aTHX_ obj, base);
    ASSUME( mg != NULL );
    void *old_ptr = mg->mg_ptr;
    Copy(old_ptr, field, size, char);
    mg->mg_ptr = field;
    Safefree(old_ptr);

    f = nn_hv_store(aTHX_ h, key, klen, obj, base);
  }
  else
  {
    // Save the new value to the field
    // This will copy the C struct from *f to field
    _set_obj(aTHX_ *f, field, size, base);
  }

  SvREFCNT_inc(*f);

  // If the struct ptrs differ, build a new object to store
  // Its a bit of action at a distance, but it reflects what the C
  // level would be doing
  if ( SvOK(*f) && _get_struct_ptr(aTHX_ *f, base) != field )
  {
    return _unpack_obj(aTHX_ h, key, klen, field, size, base);
  }

  return *f;
}

SV *_find_obj(pTHX_ HV *h, const char *key, I32 klen, void *field, Size_t size, SV *base)
{
  SV **f;

  if ( field == NULL )
  {
    croak("The field value to _find_obj must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_obj(aTHX_ h, key, klen, field, size, base);
  }

  return *f;
}

void _store_obj(pTHX_ HV *h, const char *key, I32 klen, void *field, Size_t size, SV* base, SV *value)
{
  SV **f = nn_hv_store(aTHX_ h, key, klen, value, base);

  _pack_obj(aTHX_ h, key, klen, field, size, base);

  return;
}

/* ------------------------------------------------------------------
   objptr
   ------------------------------------------------------------------ */

void _set_objptr(pTHX_ SV *new_value, void **field, SV *base)
{
  if ( !base )
  {
    croak("Could not find requirement base for %s", SvPV_nolen(new_value));
  }

  void *v = SvOK(new_value) ? _get_struct_ptr(aTHX_ new_value, base) : NULL;
  *field = v;
}

int _mg_set_objptr(pTHX_ SV* sv, MAGIC* mg)
{
  SV *base = mg->mg_obj;
  _set_objptr(aTHX_ sv, (void *) mg->mg_ptr, base);
  return 0;
}

STATIC MGVTBL _mg_vtbl_objptr = {
  .svt_set = _mg_set_objptr
};

SV *_unpack_objptr(pTHX_ HV *h, const char *key, I32 klen, void **field, SV* base)
{
  SV **f = NULL;

  if ( field == NULL )
  {
    croak("The field value for objptr must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  f = hv_fetch(h, key, klen, 1);

  if ( !( f && *f ) )
  {
    croak("Could not save new value for %s", key);
  }

  void *n = NULL;
  if ( sv_isobject(*f) )
  {
    n = _get_struct_ptr(aTHX_ *f, base);
  }

  if ( n == NULL || n != *field )
  {
    SV *obj = _empty_with(base, *field);
    f = nn_hv_store(aTHX_ h, key, klen, obj, base);
  }

  _unpack(*f);

  return *f;
}

SV *_pack_objptr(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base)
{
  SV **f;
  SV *fp;

  if ( field == NULL )
  {
    croak("The field value to _pack_objptr must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_objptr(aTHX_ h, key, klen, field, base);
  }

  // If _new returns something different, it coerced it up to an object
  SV *obj = _coerce_obj(base, *f);
  if ( obj != *f )
  {
    f = nn_hv_store(aTHX_ h, key, klen, obj, base);
  }

  // Save the new value to the field
  _set_objptr(aTHX_ *f, field, base);
  SvREFCNT_inc(*f);

  _pack(*f);

  return *f;
}

SV *_find_objptr(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base)
{
  SV **f;

  if ( field == NULL )
  {
    croak("The field value to _find_objptr must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_objptr(aTHX_ h, key, klen, field, base);
  }

  return *f;
}

void _store_objptr(pTHX_ HV *h, const char *key, I32 klen, void **field, SV* base, SV *value)
{
  SV **f = nn_hv_store(aTHX_ h, key, klen, value, base);

  _pack_objptr(aTHX_ h, key, klen, field, base);

  return;
}

/* ------------------------------------------------------------------
   objarray
   ------------------------------------------------------------------ */

SV * _array_new(SV *base, void *n, Size_t size, Size_t count)
{
  /* Make sure the count is less than an excessive limit */
  if ( count > 268435456 )
  {
    croak("Array count of %zd cannot be that large", count);
  }

  bool is_enum   = sv_derived_from(base, "WebGPU::Direct::Enum");
  bool is_opaque = sv_derived_from(base, "WebGPU::Direct::Opaque");

  if ( is_enum && size != sizeof(uint32_t) )
  {
    croak("Enum is expected to be of size %zu, not %zu", sizeof(uint32_t), size);
  }

  AV *ret = newAV();
  av_extend(ret, count);

  void *field = n;
  for ( Size_t i = 0; i < count; i++ )
  {
    SV *obj = NULL;
    if ( is_enum )
    {
      obj = _new(base, newSViv(*(uint32_t *)field));
    }
    else if ( is_opaque )
    {
      obj = _new_opaque(base, field);
    }
    else
    {
      obj = _new_with(field, base, size);
    }
    SV **f = nn_av_store(aTHX_ ret, i, obj, base);

    field = ((char *)field) + size;
  }

  SV *aref = sv_2mortal(newRV((SV*)ret));
  SV *array_base = newSVsv(base);
  sv_catpvs(array_base, "::Array");

  sv_bless(aref, gv_stashpv(SvPV_nolen(array_base), GV_ADD));

  return aref;
}

void _set_objarray(pTHX_ SV *new_value, void **field, Size_t *cntField, Size_t size, SV *base)
{
  if ( !base )
  {
    croak("Could not find requirement base for %s", SvPV_nolen(new_value));
  }

  if ( new_value == NULL || !SvOK(new_value) )
  {
    *field = NULL;
    *cntField = 0;
    return;
  }

  if ( !SvROK(new_value) )
  {
    croak("The field value to _set_objarray must be a reference, for %s", SvPV_nolen(base));
  }

  if ( SvTYPE(SvRV(new_value)) != SVt_PVAV )
  {
    croak("The field value to _set_objarray must be an array reference, for %s", SvPV_nolen(base));
  }

  void *v = _get_struct_ptr(aTHX_ new_value, base);
  *field = v;
  *cntField = av_count(SvRV(new_value));
}

SV *_unpack_objarray(pTHX_ HV *h, const char *key, I32 klen, void **field, Size_t *cntField, Size_t size, SV* base)
{
  SV **f = NULL;
  SV **c = NULL;
  SV *keyCnt = NULL;
  Size_t count = 0;

  if ( field == NULL )
  {
    croak("The field value for objarray must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  f = hv_fetch(h, key, klen, 1);

  if ( !( f && *f ) )
  {
    croak("Could not save new value for %s", key);
  }

  // -1 so it removes the s at the end of the key
  keyCnt = newSVpv(key, klen-1);
  sv_catpvs(keyCnt, "Count");
  Size_t keyCntLen = sv_len(keyCnt);
  c = hv_fetch(h, SvPV_nolen(keyCnt), keyCntLen, 1);

  if ( !( c && *c ) )
  {
    croak("Could not save new value for %s", SvPV_nolen(keyCnt));
  }

  *c = newSViv(*cntField);

  SV *array_base = newSVsv(base);
  sv_catpvs(array_base, "::Array");

  void *n = NULL;
  if ( sv_isobject(*f) )
  {
    n = _get_struct_ptr(aTHX_ *f, array_base);
  }

  if ( n == NULL || n != *field )
  {
    SV *val = _array_new(base, *field, size, *cntField);
    f = nn_hv_store(aTHX_ h, key, klen, val, base);
  }

  return *f;
}

SV *_pack_objarray(pTHX_ HV *h, const char *key, I32 klen, void **field, Size_t *cntField, Size_t size, SV *base)
{
  SV **f;
  SV **c = NULL;
  SV *keyCnt = NULL;
  I32 keyCntLen;
  Size_t count = 0;
  void *arr = NULL;
  AV *objs = NULL;

  if ( field == NULL )
  {
    croak("The field value to _pack_objarray must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_objarray(aTHX_ h, key, klen, field, cntField, size, base);
  }

  // -1 so it removes the s at the end of the key
  {
    I32 rmlen = 1;
    ASSUME( key[klen-1] == 's' );
    if ( key[klen-2] == 'e' && key[klen-3] == 'i' )
    {
      rmlen = 3;
    }
    keyCnt = newSVpv(key, klen-rmlen);
    if ( rmlen != 1 )
    {
      sv_catpvs(keyCnt, "y");
    }
    sv_catpvs(keyCnt, "Count");
    keyCntLen = sv_len(keyCnt);
  }

  SV *array_base = newSVsv(base);
  sv_catpvs(array_base, "::Array");

  if ( !SvOK(*f) )
  {
    SV *val = sv_2mortal(newRV( (SV *)newAV() ));
    f = nn_hv_store(aTHX_ h, key, klen, val, base);
  }

  if ( !SvROK(*f) )
  {
    croak("The field value to _pack_objarray must be a reference, for %s{%s}", SvPV_nolen(base), key);
  }

  if ( SvTYPE(SvRV(*f)) == SVt_PVHV )
  {
    AV *new_fields = newAV();

    SV **arrf = nn_av_store(aTHX_ new_fields, 0, *f, base);
    SV **new_array = NULL;

    *f = sv_2mortal(newRV((SV*)new_fields));
  }

  if ( SvTYPE(SvRV(*f)) != SVt_PVAV )
  {
    croak("The field value to _pack_objarray must be an array, for %s{%s}", SvPV_nolen(base), key);
  }

  objs = (AV *)SvRV(*f);
  count = av_count(objs);

  if ( !sv_isobject(*f) )
  {
    SV *a = (SV *)newAV();
    *f = sv_2mortal(newRV(a));
    sv_bless(*f, gv_stashpv(SvPV_nolen(array_base), GV_ADD));
    f = nn_hv_store(aTHX_ h, key, klen, *f, base);
  }

  arr = _get_struct_ptr(aTHX_ *f, array_base);
  AV *out_objs = (AV *)SvRV(*f);

  if ( arr != NULL )
  {
    Renew(arr, (count+1) * size, char);
  }
  else
  {
    Newxz(arr, (count+1) * size, char);
  }

  bool is_enum   = sv_derived_from(base, "WebGPU::Direct::Enum");
  bool is_opaque = sv_derived_from(base, "WebGPU::Direct::Opaque");

  void *new_ptr = arr;

  for ( Size_t i = 0; i < count; i++ )
  {
    SV **f = av_fetch(objs, i, 1);

    if ( !( f && *f ) )
    {
      croak("Could not fetch array entry %zd, for %s{%s}", i, SvPV_nolen(base), key);
    }

    SV *obj = _coerce_obj(base, *f);
    if ( obj != *f )
    {
      f = nn_av_store(aTHX_ out_objs, i, obj, base);
    }

    assert(SvOK(*f));
    if ( is_enum )
    {
      *(I32 *)new_ptr = (I32)SvIV(*f);
    }
    else if ( is_opaque )
    {
      void *old_ptr = _get_struct_ptr(aTHX_ *f, base);
      if ( !old_ptr )
      {
        croak("Could not find a %s type element at index %zu for %s", SvPV_nolen(base), i, key);
      }
      *(void **)new_ptr = old_ptr;
    }
    else
    {
      void *old_ptr = _get_struct_ptr(aTHX_ *f, base);
      if ( old_ptr )
      {
        if ( old_ptr != new_ptr )
        {
          // TODO: object should probably be duplicated (if refcnt is minimal?)
          Copy(old_ptr, new_ptr, size, char);

          MAGIC *mg = _get_mg(aTHX_ *f, base);
          if ( mg == NULL )
          {
            sv_magicext(*f, NULL, PERL_MAGIC_ext, NULL, (const char *)new_ptr, 0);
          }
          else
          {
            mg->mg_ptr = new_ptr;
          }
          Safefree(old_ptr);
        }
      }
      else
      {
        SV *h = _get_mg_hash(aTHX_ *f, base);
        sv_magicext(h, NULL, PERL_MAGIC_ext, NULL, (const char *)new_ptr, 0);
      }
    }

    new_ptr = ((char *)new_ptr) + size;
  }

  Zero(new_ptr, size, char);

  {
    SV *cnt = newSViv(count);
    SV **cnt_f = nn_hv_store(aTHX_ h, SvPV_nolen(keyCnt), keyCntLen, cnt, base);
  }

  SvREFCNT_inc(*f);

  sv_magicext((SV *)out_objs, NULL, PERL_MAGIC_ext, NULL, (const char *)arr, 0);

  _set_objarray(aTHX_ (count == 0 ? NULL : *f), field, cntField, size, array_base);

  return *f;
}

SV *_find_objarray(pTHX_ HV *h, const char *key, I32 klen, void **field, Size_t *cntField, Size_t size, SV *base)
{
  SV **f;

  if ( field == NULL )
  {
    croak("The field value to _find_objarray must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_objarray(aTHX_ h, key, klen, field, cntField, size, base);
  }

  return *f;
}

void _store_objarray(pTHX_ HV *h, const char *key, I32 klen, void **field, Size_t *cntField, Size_t size, SV* base, SV *value)
{
  SV **f = nn_hv_store(aTHX_ h, key, klen, value, base);

  _pack_objarray(aTHX_ h, key, klen, field, cntField, size, base);

  return;
}

/* ------------------------------------------------------------------
   opaque (Impl)
   ------------------------------------------------------------------ */

void _set_opaque(pTHX_ SV *new_value, void **field, SV *base)
{
  if ( !base )
  {
    croak("Could not find requirement base for %s", SvPV_nolen(new_value));
  }

  void *v = SvOK(new_value) ? _get_struct_ptr(aTHX_ new_value, base) : NULL;
  *field = v;
}

int _mg_set_opaque(pTHX_ SV* sv, MAGIC* mg)
{
  SV *base = mg->mg_obj;
  _set_opaque(aTHX_ sv, (void *) mg->mg_ptr, base);
  return 0;
}

STATIC MGVTBL _mg_vtbl_opaque = {
  .svt_set = _mg_set_opaque
};

SV *_unpack_opaque(pTHX_ HV *h, const char *key, I32 klen, void **field, SV* base)
{
  SV **f = NULL;

  if ( field == NULL )
  {
    croak("The field value for void must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  f = hv_fetch(h, key, klen, 1);

  if ( !( f && *f ) )
  {
    croak("Could not save new value for %s", key);
  }

  void *n = NULL;
  if ( sv_isobject(*f) )
  {
    n = _get_struct_ptr(aTHX_ *f, base);
  }

  if ( n == NULL || n != *field )
  {
    SV *val = _new_opaque(base, *field);
    f = nn_hv_store(aTHX_ h, key, klen, val, base);
  }

  return *f;
}

SV *_pack_opaque(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base)
{
  SV **f;
  SV *fp;

  if ( field == NULL )
  {
    croak("The field value to _pack_opaque must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_opaque(aTHX_ h, key, klen, field, base);
  }

  // Save the new value to the field
  _set_opaque(aTHX_ *f, field, base);
  SvREFCNT_inc(*f);

  return *f;
}

SV *_find_opaque(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base)
{
  SV **f;

  if ( field == NULL )
  {
    croak("The field value to _find_opaque must not be null, for %s{%s}", SvPV_nolen(base), key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_opaque(aTHX_ h, key, klen, field, base);
  }

  return *f;
}

void _store_opaque(pTHX_ HV *h, const char *key, I32 klen, void **field, SV* base, SV *value)
{
  SV **f = nn_hv_store(aTHX_ h, key, klen, value, base);

  _pack_opaque(aTHX_ h, key, klen, field, base);

  return;
}

/* ------------------------------------------------------------------
   void
   ------------------------------------------------------------------ */

void _set_void(pTHX_ SV *new_value, void *field)
{
  void *v = SvOK(new_value) ? _get_struct_ptr(aTHX_ new_value, newSVpvs("WebGPU::Direct::Opaque")) : NULL;
  field = v;
}

int _mg_set_void(pTHX_ SV* sv, MAGIC* mg)
{
  _set_void(aTHX_ sv, (void *) mg->mg_ptr);
  return 0;
}

STATIC MGVTBL _mg_vtbl_void = {
  .svt_set = _mg_set_void
};

#define _unpack_CODE _unpack_void
SV *_unpack_void(pTHX_ HV *h, const char *key, I32 klen, void *field, SV *base)
{
  SV **f = NULL;

  if ( field == NULL )
  {
    croak("The field value for void must not be null, for %s", key);
  }

  f = hv_fetch(h, key, klen, 1);

  if ( !( f && *f ) )
  {
    croak("Could not save new value for %s", key);
  }

  void *n = NULL;
  if ( sv_isobject(*f) )
  {
    n = _get_struct_ptr(aTHX_ *f, newSVpvs("WebGPU::Direct::Opaque"));
  }

  if ( n == NULL || n != field )
  {
    SV *val = _void__wrap(field);
    f = nn_hv_store(aTHX_ h, key, klen, val, &PL_sv_undef);
  }
  SvIV_set(SvRV(*f), (IV)field);

  return *f;
}

#define _pack_CODE _pack_void
SV *_pack_void(pTHX_ HV *h, const char *key, I32 klen, void *field, SV *base)
{
  SV **f;
  SV *fp;

  if ( field == NULL )
  {
    croak("The field value to _pack_void must not be null, for {%s}", key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_void(aTHX_ h, key, klen, field, base);
  }

  // Save the new value to the field
  _set_void(aTHX_ *f, field);
  SvREFCNT_inc(*f);

  return *f;
}

#define _find_CODE _find_void
SV *_find_void(pTHX_ HV *h, const char *key, I32 klen, void *field, SV *base)
{
  SV **f;

  if ( field == NULL )
  {
    croak("The field value to _find_void must not be null, for {%s}", key);
  }

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_void(aTHX_ h, key, klen, field, base);
  }

  return *f;
}

#define _store_CODE _store_void
void _store_void(pTHX_ HV *h, const char *key, I32 klen, void *field, SV *base, SV *value)
{
  SV **f = nn_hv_store(aTHX_ h, key, klen, value, &PL_sv_undef);

  _pack_void(aTHX_ h, key, klen, field, base);

  return;
}

/* Integer and Floating types */

#define _setup_x(type, ft, constr) \
SV *_unpack_##type(pTHX_ HV *h, const char *key, I32 klen, ft field, SV *base)  \
{                                                                               \
  SV **f = NULL;                                                                \
  SV *val = constr;                                                             \
  f = nn_hv_store(aTHX_ h, key, klen, val, &PL_sv_undef);                       \
                                                                                \
  return *f;                                                                    \
}                                                                               \
                                                                                \
SV *_pack_##type(pTHX_ HV *h, const char *key, I32 klen, ft field, SV *base)    \
{                                                                               \
  SV **f;                                                                       \
                                                                                \
  /* Find the field from the hash */                                            \
  f = hv_fetch(h, key, klen, 0);                                                \
                                                                                \
  /* If the field is not found, create a default one */                         \
  if ( !( f && *f ) )                                                           \
  {                                                                             \
    return _unpack_##type(aTHX_ h, key, klen, field, base);                     \
  }                                                                             \
                                                                                \
  /* Save the new value to the field */                                         \
  SV *val = _set_##type(aTHX_ *f, field, base);                                 \
  if ( val != *f )                                                              \
  {                                                                             \
    f = nn_hv_store(aTHX_ h, key, klen, val, base);                             \
  }                                                                             \
  SvREFCNT_inc(*f);                                                             \
                                                                                \
  return *f;                                                                    \
}                                                                               \
                                                                                \
SV *_find_##type(pTHX_ HV *h, const char *key, I32 klen, ft field, SV *base)    \
{                                                                               \
  SV **f;                                                                       \
                                                                                \
  /* Find the field from the hash */                                            \
  f = hv_fetch(h, key, klen, 0);                                                \
                                                                                \
  /* If the field is not found, create a default one */                         \
  if ( !( f && *f ) )                                                           \
  {                                                                             \
    return _unpack_##type(aTHX_ h, key, klen, field, base);                     \
  }                                                                             \
                                                                                \
  return *f;                                                                    \
}                                                                               \
                                                                                \
void _store_##type(pTHX_ HV *h, const char *key, I32 klen, ft field, SV * base, \
                         SV *value)                                             \
{                                                                               \
  SV **f = nn_hv_store(aTHX_ h, key, klen, value, &PL_sv_undef);                \
                                                                                \
  _pack_##type(aTHX_ h, key, klen, field, base);                                \
                                                                                \
  return;                                                                       \
}                                                                               \
                                                                                \


/* ------------------------------------------------------------------
   str
   ------------------------------------------------------------------ */

SV *_set_str(pTHX_ SV *new_value, const char **field, SV *base)
{
  char *v = SvPVbyte_nolen(new_value);
  *field = v;
  return new_value;
}

_setup_x(str, const char **, newSVpv(*field, 0));

/* ------------------------------------------------------------------
   enum
   ------------------------------------------------------------------ */

SV *_set_enum(pTHX_ SV *new_value, I32 *field, SV *base)
{
  /* Coerce this SV to an enum value
     The SV is marked as an IV, PV and NV all so we can check quick. This
     combo is going to be pretty rare, so in general packing a string or
     a simple number will get upgraded, but we also don't have to always
     coerce it */
  if ( !( SvIOK(new_value) && SvPOK(new_value) && SvNOK(new_value) ) )
  {
    new_value = _new(base, new_value);
  }
  I32 v = (I32)SvIV(new_value);
  *field = v;
  return new_value;
}

SV *_coerce_enum(pTHX_ void *field, SV *base)
{
  // In order to support strings as values, we need the enum type
  SV *result = _new(base, newSViv(*(int *)field));
  return result;
}

_setup_x(enum, void *, _coerce_enum(aTHX_ field, base));

/* ------------------------------------------------------------------
   bool
   ------------------------------------------------------------------ */

SV *_set_bool(pTHX_ SV *new_value, bool *field, SV *base)
{
  bool v = (bool)SvIV(new_value);
  *field = v;
  return new_value;
}

_setup_x(bool, bool *, newSViv(*field));

/* ------------------------------------------------------------------
   double
   ------------------------------------------------------------------ */

SV *_set_double(pTHX_ SV *new_value, double *field, SV *base)
{
  double v = (double)SvNV(new_value);
  *field = v;
  return new_value;
}

_setup_x(double, double *, newSVnv(*field));

/* ------------------------------------------------------------------
   float
   ------------------------------------------------------------------ */

SV *_set_float(pTHX_ SV *new_value, float *field, SV *base)
{
  float v = (U16)SvNV(new_value);
  *field = v;
  return new_value;
}

_setup_x(float, float *, newSVnv(*field));

/* ------------------------------------------------------------------
   uint16_t
   ------------------------------------------------------------------ */

SV *_set_uint16_t(pTHX_ SV *new_value, U16 *field, SV *base)
{
  U16 v = (U16)SvIV(new_value);
  *field = v;
  return new_value;
}

_setup_x(uint16_t, uint16_t *, newSViv(*field));

/* ------------------------------------------------------------------
   uint32_t
   ------------------------------------------------------------------ */

SV *_set_uint32_t(pTHX_ SV *new_value, U32 *field, SV *base)
{
  U32 v = (U32)SvIV(new_value);
  *field = v;
  return new_value;
}

_setup_x(uint32_t, uint32_t *, newSViv(*field));

/* ------------------------------------------------------------------
   uint64_t
   ------------------------------------------------------------------ */

SV *_set_uint64_t(pTHX_ SV *new_value, U64 *field, SV *base)
{
  U64 v = (U64)SvIV(new_value);
  *field = v;
  return new_value;
}

_setup_x(uint64_t, uint64_t *, newSViv(*field));

/* ------------------------------------------------------------------
   int32_t
   ------------------------------------------------------------------ */

SV *_set_int32_t(pTHX_ SV *new_value, I32 *field, SV *base)
{
  I32 v = (I32)SvIV(new_value);
  *field = v;
  return new_value;
}

_setup_x(int32_t, int32_t *, newSViv(*field));

/* ------------------------------------------------------------------
   size_t
   ------------------------------------------------------------------ */

SV *_set_size_t(pTHX_ SV *new_value, size_t *field, SV *base)
{
  Size_t v = (Size_t)SvIV(new_value);
  *field = v;
  return new_value;
}

_setup_x(size_t, size_t *, newSViv(*field));

/* ------------------------------------------------------------------
   WebGPU::Direct::MappedBuffer
   ------------------------------------------------------------------ */

typedef SV* WebGPU__Direct__MappedBuffer;

typedef struct mapped_buffer {
  Size_t size;
  const char *buffer;
} mapped_buffer;

void WebGPU__Direct__MappedBuffer__unpack(pTHX_ SV *THIS )
{
  if (!SvROK(THIS) || !sv_derived_from(THIS, "WebGPU::Direct::MappedBuffer"))
  {
    croak_nocontext("%s: %s is not of type %s",
      "WebGPU::Direct::MappedBuffer",
      "THIS", "WebGPU::Direct::MappedBuffer");
  }

  HV *h = (HV *)SvRV(THIS);
  mapped_buffer *n = (mapped_buffer *) _get_struct_ptr(aTHX, THIS, newSVpvs("WebGPU::Direct::MappedBuffer"));
  if ( !n )
  {
    croak("%s: Cannot find Memory Bufffer", "WebGPU::Direct::MappedBuffer");
  }

  SV **f;

  /* Find the field from the hash */
  f = hv_fetchs(h, "buffer", 1);

  /* If the field cannot be used, croak*/
  if ( !( f && *f ) )
  {
    croak("%s: Cannot save buffer to object", "WebGPU::Direct::MappedBuffer");
  }

    if ( SvREADONLY(*f) )
    {
      SV *new = newSV(0);
      f = hv_stores(h, "buffer", new);

      if ( !( f && *f ) )
      {
        croak("%s: Could not save new value for buffer", "WebGPU::Direct::MappedBuffer");
      }
      SvREFCNT_inc(*f);
    }

  sv_setpvn(*f, n->buffer, n->size);

  {
    SV *size = newSViv(n->size);
    SvREFCNT_inc(size);
    f = hv_stores(h, "size", size);

    if ( !f )
    {
      SvREFCNT_dec(size);
      croak("Could not save value to hash for size in type %s", "WebGPU::Direct::MappedBuffer");
    }
  }

  return;
}

void WebGPU__Direct__MappedBuffer__pack(pTHX_ SV *THIS )
{
  if (!SvROK(THIS) || !sv_derived_from(THIS, "WebGPU::Direct::MappedBuffer"))
  {
    croak_nocontext("%s: %s is not of type %s",
      "WebGPU::Direct::MappedBuffer",
      "THIS", "WebGPU::Direct::MappedBuffer");
  }

  HV *h = (HV *)SvRV(THIS);
  mapped_buffer *n = (mapped_buffer *) _get_struct_ptr(aTHX, THIS, newSVpvs("WebGPU::Direct::MappedBuffer"));
  if ( !n )
  {
    croak("%s: Cannot find Memory Bufffer", "WebGPU::Direct::MappedBuffer");
  }

  SV **f;

  /* Find the field from the hash */
  f = hv_fetchs(h, "buffer", 0);

  /* Save the new value to the field */
  if ( f && *f )
  {
    STRLEN len = n->size;
    STRLEN vlen;
    const char *v = SvPVbyte(*f, vlen);

    if ( vlen < len )
    {
      Zero(n->buffer+vlen, len-vlen, char);
      len = vlen;
    }
    Copy(v, n->buffer, len, char);
  }

  return WebGPU__Direct__MappedBuffer__unpack(aTHX_ THIS);
}

SV *WebGPU__Direct__MappedBuffer_buffer(pTHX_ SV *THIS, SV *value)
{
  HV *h = (HV *)SvRV(THIS);
  SV **f;

  if ( value && SvOK(value) )
  {
    SvREFCNT_inc(value);
    f = hv_stores(h, "buffer", value);

    if ( !f )
    {
      SvREFCNT_dec(value);
      croak("%s: Could not save value to hash for %s", "WebGPU::Direct::MappedBuffer", "buffer");
    }

    WebGPU__Direct__MappedBuffer__pack(aTHX_ THIS);
  }

  f = hv_fetchs(h, "buffer", 0);
  SvREFCNT_inc(*f);

  return *f;
}

SV *WebGPU__Direct__MappedBuffer__wrap(pTHX_ const char * buffer, Size_t size)
{
  HV *h = newHV();
  SV *RETVAL = sv_2mortal(newRV((SV*)h));

  mapped_buffer *n;
  Newxz(n, 1, mapped_buffer);

  n->buffer = buffer;
  n->size = size;

  sv_magicext((SV *)h, NULL, PERL_MAGIC_ext, NULL, (const char *)n, 0);
  sv_bless(RETVAL, gv_stashpv("WebGPU::Direct::MappedBuffer", GV_ADD));
  WebGPU__Direct__MappedBuffer__unpack(aTHX_ RETVAL);
  return SvREFCNT_inc(RETVAL);
}

/* ------------------------------------------------------------------
   END
   ------------------------------------------------------------------ */

#include "xs/webgpu.c"
#include "xs/x11.c"
#include "xs/wayland.c"

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::XS            PREFIX = wgpu

INCLUDE: xs/webgpu.xs

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::Enum      PREFIX = wgpu

# /* Mark an SV as an Enum to make the check faster. We cleverly do this by
#    making THIS a trivar: intentionally ensuring that IV, NV and PV are all set */

SV *
_mark_enum(THIS)
        SV *THIS
    PROTOTYPE: $
    CODE:
        SvNV(THIS);
    OUTPUT:
        THIS

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::MappedBuffer      PREFIX = wgpu

void
pack(THIS)
        SV *THIS
    PROTOTYPE: $
    CODE:
        WebGPU__Direct__MappedBuffer__pack( aTHX_ THIS );

void
unpack(THIS)
        SV *THIS
    PROTOTYPE: $
    CODE:
        WebGPU__Direct__MappedBuffer__unpack( aTHX_ THIS );

SV *
buffer(THIS, value = NULL)
        SV *THIS
        SV *value
    PROTOTYPE: $;$
    CODE:
        RETVAL = WebGPU__Direct__MappedBuffer_buffer( aTHX_ THIS, value );
    OUTPUT:
        RETVAL

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct                PREFIX = wgpu

WebGPU::Direct::SurfaceDescriptorFromXlibWindow
new_window_x11(CLASS, xw = 640, yh = 360)
        SV *  CLASS
        int   xw
        int   yh
    PROTOTYPE: $
    CODE:
#ifdef HAS_X11
#define _DEF_X11 1
        SV *THIS = _new( newSVpvs("WebGPU::Direct::SurfaceDescriptorFromXlibWindow"), NULL );
        WGPUSurfaceDescriptorFromXlibWindow *result = (WGPUSurfaceDescriptorFromXlibWindow *) _get_struct_ptr(aTHX, THIS, NULL);
        if ( ! x11_window(result, xw, yh) )
        {
          Perl_croak(aTHX_ "Could not create an X11 window");
        }

        SV *h = SvRV(THIS);
        _unpack(THIS);

        RETVAL = THIS;
#else
#define _DEF_X11 0
        Perl_croak(aTHX_ "Cannot create X11 window: X11 not found");
#endif
    OUTPUT:
        RETVAL

WebGPU::Direct::SurfaceDescriptorFromWaylandSurface
new_window_wayland(CLASS, xw = 640, yh = 360)
        SV *  CLASS
        int   xw
        int   yh
    PROTOTYPE: $
    CODE:
#ifdef HAS_WAYLAND
#define _DEF_WAYLAND 1
        SV *THIS = _new( newSVpvs("WebGPU::Direct::SurfaceDescriptorFromWaylandSurface"), NULL );
        WGPUSurfaceDescriptorFromWaylandSurface *result = (WGPUSurfaceDescriptorFromWaylandSurface *) _get_struct_ptr(aTHX, THIS, NULL);
        if ( ! wayland_window(result, xw, yh) )
        {
          Perl_croak(aTHX_ "Could not create an Wayland window");
        }

        SV *h = SvRV(THIS);
        _unpack(THIS);

        RETVAL = THIS;
#else
#define _DEF_WAYLAND 0
        Perl_croak(aTHX_ "Cannot create Wayland window: Wayland not found");
#endif
    OUTPUT:
        RETVAL

MODULE = WebGPU::Direct         PACKAGE = WebGPU::Direct::XS            PREFIX = wgpu

BOOT:
{
  HV *stash = gv_stashpv("WebGPU::Direct::XS", 0);

  newCONSTSUB(stash, "HAS_X11", newSViv(_DEF_X11));
  newCONSTSUB(stash, "HAS_WAYLAND", newSViv(_DEF_WAYLAND));
}

