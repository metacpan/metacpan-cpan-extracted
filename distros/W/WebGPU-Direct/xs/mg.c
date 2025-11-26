// Chosen by fair dice roll
#define CB_GUARD 0x25b3eea3

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
  IV opaque = (IV)n;
  SV *h = newSViv( opaque );
  SV *RETVAL = sv_2mortal(newRV(h));

  sv_magicext((SV *)h, NULL, PERL_MAGIC_ext, NULL, (const char *)opaque, 0);
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

  // If there is no valid class, don't bother
  if ( CLASS == NULL )
  {
    return fields;
  }

  // If there the value is not defined, don't bother
  if ( !SvOK(fields) )
  {
    return fields;
  }

  // Otherwise run CLASS->new(fields)
  return _new(CLASS, fields);
}

SV *_new( SV *CLASS, SV *fields )
{
  dSP;

  ENTER;
  SAVETMPS;

  if ( CLASS == NULL || !SvOK(CLASS) )
  {
    croak("CLASS passed to _new was null, which is not expected to happen");
  }

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
  SV *RETVAL = newRV_noinc(h);
  RETVAL = sv_2mortal(RETVAL);

  sv_magicext((SV *)h, NULL, PERL_MAGIC_ext, NULL, (const char *)n, 0);
  sv_bless(RETVAL, gv_stashpv(SvPV_nolen(CLASS), GV_ADD));
  return SvREFCNT_inc(RETVAL);
}

/* ------------------------------------------------------------------
   WGPUStringView is a special case. They represent strings that can
   have nulls, which perl can handle just fine
   ------------------------------------------------------------------ */

WGPUStringView string_view_from_sv(SV *input)
{
  WGPUStringView result;
  if ( !SvOK(input) )
  {
    result.data = NULL;
    result.length = WGPU_STRLEN;
    return result;
  }
  result.data = SvPVutf8(input, result.length);
  return result;
}

SV *_string_view_to_sv(WGPUStringView input)
{
  if ( input.length == WGPU_STRLEN )
  {
    if ( input.data == NULL )
    {
      return &PL_sv_undef;
    }
    return newSVpv(input.data, 0);
  }

  if ( input.length == 0 )
  {
    return newSVpvn("", 0);
  }

  if ( input.data == NULL )
  {
    croak("Recieved an invalid WGPUStringView with a length of %zd, but a NULL pointer", input.length);
  }

  return newSVpvn(input.data, input.length);
}

SV *string_view_to_sv(WGPUStringView input)
{
  SV *result = _string_view_to_sv(input);
  return result;
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

  if ( is_enum )
  {
    SV *STRICT_ENUM = get_sv("WebGPU::Direct::Enum::STRICT_NEW", GV_ADDWARN | GV_ADDMULTI);
    save_item(STRICT_ENUM);
    sv_setsv(STRICT_ENUM, &PL_sv_undef);

    if ( size != sizeof(uint32_t) )
    {
      croak("Enum is expected to be of size %zu, not %zu", sizeof(uint32_t), size);
    }
  }

  AV *ret = newAV();
  av_extend(ret, count);

  void *field = n;
  for ( Size_t i = 0; i < count; i++ )
  {
    SV *obj = NULL;
    if ( is_enum )
    {
      if ( base == NULL || !SvOK(base) )
      {
        croak("_array_new got a null base");
      }
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
  *cntField = av_count((AV *)SvRV(new_value));
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

  void *old_arr = arr;
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
    if ( obj != *f || out_objs != objs )
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
          ptrdiff_t offset_in_old_arr = ((char *)old_ptr) - ((char *)old_arr);
          bool was_in_old_arr = (old_arr != NULL &&
                                 offset_in_old_arr >= 0 &&
                                 offset_in_old_arr <= (count * size));

          // TODO: object should probably be duplicated (if refcnt is minimal?)
          // TODO: how does this inteact when an item is moved in the array?
          // Don't copy/free if the array was reallocated with Renew above
          if ( !was_in_old_arr )
          {
            Copy(old_ptr, new_ptr, size, char);
            Safefree(old_ptr);
          }

          MAGIC *mg = _get_mg(aTHX_ *f, base);
          if ( mg == NULL )
          {
            sv_magicext(*f, NULL, PERL_MAGIC_ext, NULL, (const char *)new_ptr, 0);
          }
          else
          {
            mg->mg_ptr = new_ptr;
          }
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

void _set_void(pTHX_ SV *new_value, void **field)
{
  void *v = SvOK(new_value) ? _get_struct_ptr(aTHX_ new_value, newSVpvs("WebGPU::Direct::Opaque")) : NULL;
  *field = v;
}

int _mg_set_void(pTHX_ SV* sv, MAGIC* mg)
{
  _set_void(aTHX_ sv, (void *) mg->mg_ptr);
  return 0;
}

STATIC MGVTBL _mg_vtbl_void = {
  .svt_set = _mg_set_void
};

SV *_unpack_void(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base)
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
    SV *val = _void__wrap(*field);
    f = nn_hv_store(aTHX_ h, key, klen, val, &PL_sv_undef);
  }
  SvIV_set(SvRV(*f), (IV)*field);

  return *f;
}

SV *_pack_void(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base)
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

SV *_find_void(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base)
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

void _store_void(pTHX_ HV *h, const char *key, I32 klen, void **field, SV *base, SV *value)
{
  SV **f = nn_hv_store(aTHX_ h, key, klen, value, &PL_sv_undef);

  _pack_void(aTHX_ h, key, klen, field, base);

  return;
}

/* ------------------------------------------------------------------
   StringView
   ------------------------------------------------------------------ */

void _set_strview(pTHX_ SV *new_value, char const **data, size_t *length, SV *base)
{
  WGPUStringView v = string_view_from_sv(new_value);
  *data = v.data;
  *length = v.length;
}

SV *_unpack_strview(pTHX_ HV *h, const char *key, I32 klen, char const **data, size_t *length, SV *base)
{
  SV **f = NULL;
  WGPUStringView rebuilt = {
    .data = *data,
    .length = *length,
  };

  SV *val = string_view_to_sv(rebuilt);
  f = nn_hv_store(aTHX_ h, key, klen, val, base);
  nn_hv_store(aTHX_ h, "length", 6, newSViv(*length), base);

  return *f;
}

SV *_pack_strview(pTHX_ HV *h, const char *key, I32 klen, char const **data, size_t *length, SV *base)
{
  SV **f;

  /* Find the field from the hash */
  f = hv_fetch(h, key, klen, 0);

  /* If the field is not found, create a default one */
  if ( !( f && *f ) )
  {
    return _unpack_strview(aTHX_ h, key, klen, data, length, base);
  }

  /* Save the new value to the field */
  _set_strview(aTHX_ *f, data, length, base);
  nn_hv_store(aTHX_ h, "length", 6, newSViv(*length), base);

  return *f;
}

SV *_find_strview(pTHX_ HV *h, const char *key, I32 klen, char const **data, size_t *length, SV *base)
{
  SV **f;

  // Find the field from the hash
  f = hv_fetch(h, key, klen, 0);

  // If the field is not found, create a default one
  if ( !( f && *f ) )
  {
    return _unpack_strview(aTHX_ h, key, klen, data, length, base);
  }

  return *f;
}

void _store_strview(pTHX_ HV *h, const char *key, I32 klen, char const **data, size_t *length, SV *base, SV *value)
{
  croak("unimplemented _store_strview...%d", __LINE__);
}

void _init_strview(pTHX_ HV *h, WGPUStringView *n)
{
  SV **f  = hv_fetch(h, "data", 4, 0);
  SV **f1 = hv_fetch(h, "length", 6, 0);

  // We want to preserve the data=undef,length=... semantics
  if ( !( f && *f ) )
  {
    n->data = NULL;
    n->length = WGPU_STRLEN;

    _unpack_strview(aTHX_ h, "data", 4,  &n->data, &n->length, NULL);
    return;
  }

  // Handle data => undef, which may include a length
  if ( !SvOK(*f) )
  {
    n->data = NULL;
    n->length = WGPU_STRLEN;

    if ( f1 && *f1 )
    {
      n->length = SvIV(*f1);
    }

    _unpack_strview(aTHX_ h, "data", 4,  &n->data, &n->length, NULL);
    return;
  }

  n->data = SvPVutf8(*f, n->length);

  if ( f1 && *f1 )
  {
    n->length = SvIV(*f1);
  }

  _unpack_strview(aTHX_ h, "data", 4,  &n->data, &n->length, NULL);
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
   SV
   ------------------------------------------------------------------ */

SV *_set_SV(pTHX_ SV *new_value, void **field, SV *base)
{
  *field = (void *)new_value;
  return new_value;
}
_setup_x(SV, void **, (SV *)*field);

SV *_set_CODE(pTHX_ SV *new_value, void **field, SV *base)
{
  if ( SvOK(new_value) )
  {
    if ( !SvROK(new_value) )
    {
      croak("%s is not an coderef", SvPVbyte_nolen(new_value));
    }
    if ( SvTYPE(SvRV(new_value)) != SVt_PVCV )
    {
      croak("%s reference is not an coderef", SvPVbyte_nolen(new_value));
    }
  }

  *field = (void *)new_value;
  return new_value;
}
_setup_x(CODE, void **, (SV *)*field);

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
    if ( base == NULL || !SvOK(base) )
    {
      croak("_set_enum got a null base");
    }
    new_value = _new(base, new_value);
  }
  I32 v = (I32)SvIV(new_value);
  *field = v;
  return new_value;
}

SV *_coerce_enum(pTHX_ void *field, SV *base)
{
  // In order to support strings as values, we need the enum type
  if ( base == NULL || !SvOK(base) )
  {
    croak("_coerce_enum got a null base");
  }
  SV *result = _new(base, newSViv(*(int *)field));
  return result;
}

_setup_x(enum, void *, _coerce_enum(aTHX_ field, base));

#define _set_flag _set_enum
#define _coerce_flag _coerce_enum
#define _pack_flag _pack_enum
#define _unpack_flag _unpack_enum
#define _find_flag _find_enum
#define _store_flag _store_enum

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

SV *_set_uint32_t(pTHX_ SV *new_value, uint32_t *field, SV *base)
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

SV *_set_int32_t(pTHX_ SV *new_value, int32_t *field, SV *base)
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
