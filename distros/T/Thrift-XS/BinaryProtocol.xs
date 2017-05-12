MODULE = Thrift::XS   PACKAGE = Thrift::XS::BinaryProtocol

SV *
new(char *klass, SV *transport)
CODE:
{
  TBinaryProtocol *p;
  New(0, p, sizeof(TBinaryProtocol), TBinaryProtocol);
  New(0, p->last_fields, sizeof(struct fieldq), struct fieldq);

  MEM_TRACE("new()\n");
  MEM_TRACE("  New p @ %p\n", p);
  MEM_TRACE("  New last_fields @ %p\n", p->last_fields);

  if (sv_isa(transport, "Thrift::XS::MemoryBuffer"))
    p->mbuf = (TMemoryBuffer *)xs_object_magic_get_struct_rv_pretty(aTHX_ transport, "mbuf");
  else
    p->mbuf = NULL;
    
  p->transport = transport;
  
  p->bool_type     = -1;
  p->bool_id       = -1;
  p->bool_value_id = -1;
  p->last_field_id = 0;
  
  SIMPLEQ_INIT(p->last_fields);

  RETVAL = xs_object_magic_create(
    aTHX_
    (void *)p,
    gv_stashpv(klass, 0)
  );
}
OUTPUT:
  RETVAL

void
DESTROY(TBinaryProtocol *p)
CODE:
{
  MEM_TRACE("DESTROY()\n");
  
  // clear field queue
  struct field_entry *entry;
  while (!SIMPLEQ_EMPTY(p->last_fields)) {
    entry = SIMPLEQ_FIRST(p->last_fields);
    SIMPLEQ_REMOVE_HEAD(p->last_fields, entries);
    MEM_TRACE("  free entry @ %p\n", entry);
    Safefree(entry);
  }
  
  MEM_TRACE("  free last_fields @ %p\n", p->last_fields);
  Safefree(p->last_fields);
  MEM_TRACE("  free p @ %p\n", p);
  Safefree(p);
}

SV *
getTransport(TBinaryProtocol *p)
CODE:
{
  SvREFCNT_inc(p->transport);
  RETVAL = p->transport;
}
OUTPUT:
  RETVAL

int
writeMessageBegin(TBinaryProtocol *p, SV *name, int type, int seqid)
CODE:
{
  DEBUG_TRACE("writeMessageBegin()\n");
  RETVAL = 0;
  
  SV *namecopy = sv_mortalcopy(name); // because we can't modify the original name
  sv_utf8_encode(namecopy);
  int namelen = sv_len(namecopy);
  SV *data = sv_2mortal(newSV(8 + 4+namelen));
  char i32[4];
  
  // i32 type
  type = VERSION_1 | type;
  INT_TO_I32(i32, type, 0);
  sv_setpvn(data, i32, 4);
  RETVAL += 4;
  
  // i32 len + string
  INT_TO_I32(i32, namelen, 0);
  sv_catpvn(data, i32, 4);
  sv_catsv(data, namecopy);
  RETVAL += 4 + namelen;
  
  // i32 seqid
  INT_TO_I32(i32, seqid, 0);
  sv_catpvn(data, i32, 4);
  RETVAL += 4;
  
  WRITE_SV(p, data);
}
OUTPUT:
  RETVAL

int
writeMessageEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
writeStructBegin(SV *, SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
writeStructEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
writeFieldBegin(TBinaryProtocol *p, SV * /*name*/, int type, int id)
CODE:
{
  DEBUG_TRACE("writeFieldBegin(type %d, id %d)\n", type, id);
  char data[3];
  RETVAL = 0;
  
  data[0] = type & 0xff;      // byte
  data[1] = (id >> 8) & 0xff; // i16
  data[2] = id & 0xff;
  
  WRITE(p, data, 3);
  RETVAL += 3;
}
OUTPUT:
  RETVAL

int
writeFieldEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
writeFieldStop(TBinaryProtocol *p)
CODE:
{
  DEBUG_TRACE("writeFieldStop()\n");
  RETVAL = 0;
  
  char data[1];
  data[0] = T_STOP;
  
  WRITE(p, data, 1);
  RETVAL += 1;
}
OUTPUT:
  RETVAL

int
writeMapBegin(TBinaryProtocol *p, int keytype, int valtype, int size)
CODE:
{
  DEBUG_TRACE("writeMapBegin(keytype %d, valtype %d, size %d)\n", keytype, valtype, size);
  char data[6];
  RETVAL = 0;
  
  data[0] = keytype & 0xff;
  data[1] = valtype & 0xff;
  INT_TO_I32(data, size, 2);

  WRITE(p, data, 6);
  RETVAL += 6;
}
OUTPUT:
  RETVAL

int
writeMapEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
writeListBegin(TBinaryProtocol *p, int elemtype, int size)
CODE:
{
  DEBUG_TRACE("writeListBegin(elemtype %d, size %d)\n", elemtype, size);
  char data[5];
  RETVAL = 0;
  
  data[0] = elemtype & 0xff;
  INT_TO_I32(data, size, 1);
  
  WRITE(p, data, 5);
  RETVAL += 5;
}
OUTPUT:
  RETVAL

int
writeListEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
writeSetBegin(TBinaryProtocol *p, int elemtype, int size)
CODE:
{
  DEBUG_TRACE("writeSetBegin(elemtype %d, size %d)\n", elemtype, size);
  char data[5];
  RETVAL = 0;
  
  data[0] = elemtype & 0xff;
  INT_TO_I32(data, size, 1);
  
  WRITE(p, data, 5);
  RETVAL += 5;
}
OUTPUT:
  RETVAL

int
writeSetEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
writeBool(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeBool(%d)\n", SvTRUE(value) ? 1 : 0);
  char data[1];
  RETVAL = 0;
  
  data[0] = SvTRUE(value) ? 1 : 0;
  
  WRITE(p, data, 1);
  RETVAL += 1;
}
OUTPUT:
  RETVAL

int
writeByte(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeByte(%ld)\n", SvIV(value) & 0xff);
  char data[1];
  RETVAL = 0;
  
  data[0] = SvIV(value) & 0xff;
  
  WRITE(p, data, 1);
  RETVAL += 1;
}
OUTPUT:
  RETVAL

int
writeI16(TBinaryProtocol *p, int value)
CODE:
{
  DEBUG_TRACE("writeI16(%d)\n", value);
  char data[2];
  RETVAL = 0;
  
  INT_TO_I16(data, value, 0);
  
  WRITE(p, data, 2);
  RETVAL += 2;
}
OUTPUT:
  RETVAL

int
writeI32(TBinaryProtocol *p, int value)
CODE:
{
  DEBUG_TRACE("writeI32(%d)\n", value);
  char data[4];
  RETVAL = 0;
  
  INT_TO_I32(data, value, 0);
  
  WRITE(p, data, 4);
  RETVAL += 4;
}
OUTPUT:
  RETVAL

int
writeI64(TBinaryProtocol *p, SV *value)
CODE:
{
  char data[8];
  RETVAL = 0;
  
  // Stringify the value, then convert to an int64_t
  const char *str = SvPOK(value) ? SvPVX(value) : SvPV_nolen(value);
  int64_t i64 = (int64_t)strtoll(str, NULL, 10);
  
  DEBUG_TRACE("writeI64(%lld) (from string %s)\n", i64, str);
  
  data[7] = i64 & 0xff;
  data[6] = (i64 >> 8) & 0xff;
  data[5] = (i64 >> 16) & 0xff;
  data[4] = (i64 >> 24) & 0xff;
  data[3] = (i64 >> 32) & 0xff;
  data[2] = (i64 >> 40) & 0xff;
  data[1] = (i64 >> 48) & 0xff;
  data[0] = (i64 >> 56) & 0xff;
  
  WRITE(p, data, 8);
  RETVAL += 8;
}
OUTPUT:
  RETVAL

int
writeDouble(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeDouble(%f)\n", (double)SvNV(value));
  char data[8];
  union {
    double from;
    uint64_t to;
  } u;
  RETVAL = 0;
  
  u.from = (double)SvNV(value);
  uint64_t bits = u.to;
  bits = htonll(bits);
  
  memcpy(&data, (uint8_t *)&bits, 8);

  WRITE(p, data, 8);
  RETVAL += 8;
}
OUTPUT:
  RETVAL

int
writeString(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeString(%s)\n", SvPVX(value));
  RETVAL = 0;
  
  SV *valuecopy = sv_mortalcopy(value);
  if (SvUTF8(value) != 0) {
    sv_utf8_encode(valuecopy);
  }
  int len = sv_len(valuecopy);
  SV *data = sv_2mortal(newSV(4 + len));
  char i32[4];
  
  INT_TO_I32(i32, len, 0);
  sv_setpvn(data, i32, 4);
  RETVAL += 4;
  sv_catsv(data, valuecopy);
  RETVAL += len;
  
  WRITE_SV(p, data);
}
OUTPUT:
  RETVAL

int
readMessageBegin(TBinaryProtocol *p, SV *name, SV *type, SV *seqid)
CODE:
{
  DEBUG_TRACE("readMessageBegin()\n");
  RETVAL = 0;
  
  SV *tmp;
  int version;
  char *tmps;
  
  // read version + type
  READ_SV(p, tmp, 4);
  tmps = SvPVX(tmp);
  I32_TO_INT(version, tmps, 0);
  RETVAL += 4;
  
  if (version < 0) {
    if ((version & VERSION_MASK) != VERSION_1) {
      THROW("Thrift::TException", "Missing version identifier");
    }
    // set type
    if (SvROK(type))
      sv_setiv(SvRV(type), version & 0x000000ff);
    
    // read string
    {
      uint32_t len;
      READ_SV(p, tmp, 4);
      tmps = SvPVX(tmp);
      I32_TO_INT(len, tmps, 0);
      RETVAL += 4;
      if (len) {
        READ_SV(p, tmp, len);
        sv_utf8_decode(tmp);
        RETVAL += len;
        if (SvROK(name))
          sv_setsv(SvRV(name), tmp);
      }
      else {
        if (SvROK(name))
          sv_setpv(SvRV(name), "");
      }
    }
    
    // read seqid
    {
      int s;
      READ_SV(p, tmp, 4);
      tmps = SvPVX(tmp);
      I32_TO_INT(s, tmps, 0);
      RETVAL += 4;
      if (SvROK(seqid))
        sv_setiv(SvRV(seqid), s);
    }
  }
  else {
    THROW("Thrift::TException", "Missing version identifier");
  }
}
OUTPUT:
  RETVAL

int
readMessageEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
readStructBegin(SV *, SV *name)
CODE:
{
  DEBUG_TRACE("readStructBegin()\n");
  RETVAL = 0;
  
  if (SvROK(name))
    sv_setpv(SvRV(name), "");
}
OUTPUT:
  RETVAL

int
readStructEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
readFieldBegin(TBinaryProtocol *p, SV * /*name*/, SV *fieldtype, SV *fieldid)
CODE:
{
  DEBUG_TRACE("readFieldBegin()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  RETVAL += 1;
  
  // fieldtype byte
  if (SvROK(fieldtype))
    sv_setiv(SvRV(fieldtype), tmps[0]);
  
  if (tmps[0] == T_STOP) {
    if (SvROK(fieldid))
      sv_setiv(SvRV(fieldid), 0);
  }
  else {
    // fieldid i16
    READ_SV(p, tmp, 2);
    tmps = SvPVX(tmp);
    int fid;
    I16_TO_INT(fid, tmps, 0);
    RETVAL += 2;
    if (SvROK(fieldid))
      sv_setiv(SvRV(fieldid), fid);
  }
}
OUTPUT:
  RETVAL

int
readFieldEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
readMapBegin(TBinaryProtocol *p, SV *keytype, SV *valtype, SV *size)
CODE:
{
  DEBUG_TRACE("readMapBegin()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 6);
  tmps = SvPVX(tmp);
  RETVAL += 6;
  
  // keytype byte
  if (SvROK(keytype))
    sv_setiv(SvRV(keytype), tmps[0]);
  
  // valtype byte
  if (SvROK(valtype))
    sv_setiv(SvRV(valtype), tmps[1]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 2);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}
OUTPUT:
  RETVAL

int
readMapEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
readListBegin(TBinaryProtocol *p, SV *elemtype, SV *size)
CODE:
{
  DEBUG_TRACE("readListBegin()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 5);
  tmps = SvPVX(tmp);
  RETVAL += 5;
  
  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), tmps[0]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 1);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}
OUTPUT:
  RETVAL

int
readListEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
readSetBegin(TBinaryProtocol *p, SV *elemtype, SV *size)
CODE:
{
  DEBUG_TRACE("readSetBegin()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 5);
  tmps = SvPVX(tmp);
  RETVAL += 5;
  
  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), tmps[0]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 1);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}
OUTPUT:
  RETVAL

int
readSetEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL

int
readBool(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readBool()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  RETVAL += 1;
  
  if (SvROK(value))
    sv_setiv(SvRV(value), tmps[0] ? 1 : 0);
}
OUTPUT:
  RETVAL

int
readByte(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readByte()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  RETVAL += 1;
  
  if (SvROK(value))
    sv_setiv(SvRV(value), tmps[0]);
}
OUTPUT:
  RETVAL

int
readI16(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI16()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 2);
  tmps = SvPVX(tmp);
  RETVAL += 2;
  
  int v;
  I16_TO_INT(v, tmps, 0);
  if (SvROK(value))
    sv_setiv(SvRV(value), v);
}
OUTPUT:
  RETVAL

int
readI32(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI32()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 4);
  tmps = SvPVX(tmp);
  RETVAL += 4;
  
  int v;
  I32_TO_INT(v, tmps, 0);
  if (SvROK(value))
    sv_setiv(SvRV(value), v);
}
OUTPUT:
  RETVAL

int
readI64(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI64()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  READ_SV(p, tmp, 8);
  tmps = SvPVX(tmp);
  RETVAL += 8;
  
  int64_t hi;
  uint32_t lo;
  I32_TO_INT(hi, tmps, 0);
  I32_TO_INT(lo, tmps, 4);
  
  if (SvROK(value)) {
    char string[25];
    STRLEN length;
    length = sprintf(string, "%lld", (int64_t)(hi << 32) | lo);
    sv_setpvn(SvRV(value), string, length);
  }
}
OUTPUT:
  RETVAL

int
readDouble(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readDouble()\n");
  SV *tmp;
  char *tmps;
  uint64_t bits;
  RETVAL = 0;
  
  READ_SV(p, tmp, 8);
  tmps = SvPVX(tmp);
  RETVAL += 8;
  
  bits = *(uint64_t *)tmps;
  bits = ntohll(bits);

  union {
    uint64_t from;
    double to;
  } u;
  u.from = bits;
  
  if (SvROK(value))
    sv_setnv(SvRV(value), u.to);
}
OUTPUT:
  RETVAL

int
readString(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readString()\n");
  SV *tmp;
  char *tmps;
  RETVAL = 0;
  
  uint32_t len;
  READ_SV(p, tmp, 4);
  tmps = SvPVX(tmp);
  I32_TO_INT(len, tmps, 0);
  RETVAL += 4;
  if (len) {
    READ_SV(p, tmp, len);
    sv_utf8_decode(tmp);
    RETVAL += len;
    if (SvROK(value))
      sv_setsv(SvRV(value), tmp);
  }
  else {
    if (SvROK(value))
      sv_setpv(SvRV(value), "");
  }
}
OUTPUT:
  RETVAL

int
readStringBody(TBinaryProtocol *p, SV *value, uint32_t len)
CODE:
{
  // This method is never used but is here for compat
  SV *tmp;
  RETVAL = 0;
  
  if (len) {
    READ_SV(p, tmp, len);
    sv_utf8_decode(tmp);
    RETVAL += len;
    if (SvROK(value))
      sv_setsv(SvRV(value), tmp);
  }
  else {
    if (SvROK(value))
      sv_setpv(SvRV(value), "");
  }
}
OUTPUT:
  RETVAL
