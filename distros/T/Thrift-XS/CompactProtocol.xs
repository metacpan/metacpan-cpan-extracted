MODULE = Thrift::XS   PACKAGE = Thrift::XS::CompactProtocol

 # new() in parent

 #` Not a standard method, but used for tests
void
resetState(TBinaryProtocol *p)
CODE:
{
  DEBUG_TRACE("resetState()\n");
  
  p->bool_type     = -1;
  p->bool_id       = -1;
  p->bool_value_id = -1;
  p->last_field_id = 0;
  
  // clear field queue
  struct field_entry *entry;
  while (!SIMPLEQ_EMPTY(p->last_fields)) {
    entry = SIMPLEQ_FIRST(p->last_fields);
    SIMPLEQ_REMOVE_HEAD(p->last_fields, entries);
    MEM_TRACE("free entry @ %p\n", entry);
    Safefree(entry);
  }
}

void
writeMessageBegin(TBinaryProtocol *p, SV *name, int type, uint32_t seqid)
CODE:
{
  DEBUG_TRACE("writeMessageBegin()\n");
  
  SV *namecopy = sv_mortalcopy(name); // because we can't modify the original name
  sv_utf8_encode(namecopy);
  uint32_t namelen = sv_len(namecopy);
  SV *data = sv_2mortal(newSV(16 + namelen));
  char tmp[5]; // 5 required for varint32
  
  // byte protocol ID
  tmp[0] = PROTOCOL_ID;
  
  // byte version/type
  tmp[1] = (VERSION_N & VERSION_MASK_COMPACT) | ((type << TYPE_SHIFT_AMOUNT) & TYPE_MASK);
  
  sv_setpvn(data, tmp, 2);
  
  // varint32 seqid
  int varlen;
  UINT_TO_VARINT(varlen, tmp, seqid, 0);
  sv_catpvn(data, tmp, varlen);

  // varint32 len + string
  UINT_TO_VARINT(varlen, tmp, namelen, 0);
  sv_catpvn(data, tmp, varlen);
  sv_catsv(data, namecopy);

  WRITE_SV(p, data);
}

# writeMessageEnd in parent

void
writeStructBegin(TBinaryProtocol *p, SV *)
CODE:
{
  DEBUG_TRACE("writeStructBegin()\n");
  
  // No writing here, but we push last_field_id onto the fields stack
  // and reset last_field_id to 0
  struct field_entry *entry;
  New(0, entry, sizeof(struct field_entry), struct field_entry);
  MEM_TRACE("New entry @ %p\n", entry);
  entry->field_id = p->last_field_id;
  SIMPLEQ_INSERT_HEAD(p->last_fields, entry, entries);
  
  DEBUG_TRACE("writeStructBegin(), insert_head %d\n", entry->field_id);
  
  p->last_field_id = 0;
}

void
writeStructEnd(TBinaryProtocol *p)
CODE:
{
  DEBUG_TRACE("writeStructEnd()\n");
  
  // pop last field off the stack and save it in
  // last_field_id
  struct field_entry *entry = SIMPLEQ_FIRST(p->last_fields);
  p->last_field_id = entry->field_id;
  SIMPLEQ_REMOVE_HEAD(p->last_fields, entries);
  
  DEBUG_TRACE("writeStructEnd(), remove_head %d\n", entry->field_id);
  
  MEM_TRACE("free entry @ %p\n", entry);
  Safefree(entry);
}

void
writeFieldBegin(TBinaryProtocol *p, SV * /*name*/, int type, int id)
CODE:
{
  DEBUG_TRACE("writeFieldBegin()\n");
  
  if (unlikely(type == T_BOOL)) {
    // Special case, save type/id for use later
    p->bool_type = type;
    p->bool_id = id;
  }
  else {
    write_field_begin_internal(p, type, id, -1);
  }
}

 # writeFieldEnd in parent

 # writeFieldStop in parent

void
writeMapBegin(TBinaryProtocol *p, int keytype, int valtype, uint32_t size)
CODE:
{
  DEBUG_TRACE("writeMapBegin()\n");
  
  char data[6];
  
  if (size == 0) {
    data[0] = 0;
    WRITE(p, data, 1);
  }
  else {
    int varlen;
    UINT_TO_VARINT(varlen, data, size, 0);
    data[varlen] = (get_compact_type(keytype) << 4) | get_compact_type(valtype);
    WRITE(p, data, varlen + 1);
  }
}

 # writeMapEnd in parent

void
writeListBegin(TBinaryProtocol *p, int elemtype, int size)
CODE:
{
  DEBUG_TRACE("writeListBegin()\n");
  
  write_collection_begin_internal(p, elemtype, size);
}

 # writeListEnd in parent

void
writeSetBegin(TBinaryProtocol *p, int elemtype, int size)
CODE:
{
  DEBUG_TRACE("writeSetBegin()\n");
  
  write_collection_begin_internal(p, elemtype, size);
}

 # writeSetEnd in parent

void
writeBool(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeBool()\n");
  
  if (unlikely(p->bool_type != -1)) {
    // we haven't written the field header yet
    write_field_begin_internal(p, p->bool_type, p->bool_id, SvTRUE(value) ? CTYPE_BOOLEAN_TRUE: CTYPE_BOOLEAN_FALSE);
    p->bool_type = -1;
    p->bool_id = -1;
  }
  else {
    // we're not part of a field, so just write the value.
    char data[1];
    data[0] = SvTRUE(value) ? 1 : 0;

    WRITE(p, data, 1);
  }
}

 # writeByte in parent

void
writeI16(TBinaryProtocol *p, int value)
CODE:
{
  DEBUG_TRACE("writeI16()\n");
  
  char data[3];
  int varlen;
  
  uint32_t uvalue = int_to_zigzag(value);
  UINT_TO_VARINT(varlen, data, uvalue, 0);
  WRITE(p, data, varlen);  
}

void
writeI32(TBinaryProtocol *p, int value)
CODE:
{
  DEBUG_TRACE("writeI32()\n");
  
  char data[5];
  int varlen;
  
  uint32_t uvalue = int_to_zigzag(value);
  UINT_TO_VARINT(varlen, data, uvalue, 0);
  WRITE(p, data, varlen);
}

void
writeI64(TBinaryProtocol *p, SV *value)
CODE:
{  
  char data[10];
  int varlen = 0;
  
  // Stringify the value, then convert to an int64_t
  const char *str = SvPOK(value) ? SvPVX(value) : SvPV_nolen(value);
  int64_t i64 = (int64_t)strtoll(str, NULL, 10);
  
  DEBUG_TRACE("writeI64(%lld)\n", i64);
  
  uint64_t uvalue = ll_to_zigzag(i64);
  UINT_TO_VARINT(varlen, data, uvalue, 0);  
  WRITE(p, data, varlen);
}

void
writeDouble(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeDouble()\n");
  
  char data[8];
  union {
    double d;
    int64_t i;
  } u;
  
  u.d = (double)SvNV(value);

  data[0] = u.i & 0xff;
  data[1] = (u.i >> 8) & 0xff;
  data[2] = (u.i >> 16) & 0xff;
  data[3] = (u.i >> 24) & 0xff;
  data[4] = (u.i >> 32) & 0xff;
  data[5] = (u.i >> 40) & 0xff;
  data[6] = (u.i >> 48) & 0xff;
  data[7] = (u.i >> 56) & 0xff;
  
  WRITE(p, data, 8);
}

void
writeString(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("writeString()\n");
  
  SV *valuecopy = sv_mortalcopy(value);
  if (SvUTF8(value) != 0) {
    sv_utf8_encode(valuecopy);
  }
  int len = sv_len(valuecopy);
  SV *data = sv_2mortal(newSV(5 + len));
  char tmp[5];
  
  int varlen;
  UINT_TO_VARINT(varlen, tmp, len, 0);
  sv_setpvn(data, tmp, varlen);
  sv_catsv(data, valuecopy);
  
  WRITE_SV(p, data);
}

void
readMessageBegin(TBinaryProtocol *p, SV *name, SV *type, SV *seqid)
CODE:
{
  DEBUG_TRACE("readMessageBegin()\n");
  
  SV *tmp;
  char *tmps;
  uint32_t tmpui;
  
  // read protocol id, version, type
  READ_SV(p, tmp, 2);
  tmps = SvPVX(tmp);
  
  int protocol_id = tmps[0];
  if (protocol_id != PROTOCOL_ID) {
    THROW_SV("Thrift::TException", newSVpvf("Expected protocol id %d but got %d", PROTOCOL_ID, protocol_id));
  }
  
  int version_and_type = tmps[1];
  int version = version_and_type & VERSION_MASK_COMPACT;
  if (version != VERSION_N) {
    THROW_SV("Thrift::TException", newSVpvf("Expected version id %d but got %d", VERSION_N, version));
  }

  // set type
  if (SvROK(type))
    sv_setiv(SvRV(type), (version_and_type >> TYPE_SHIFT_AMOUNT) & 0x03);

  // read/set seqid
  READ_VARINT(p, tmpui);
  if (SvROK(seqid))
    sv_setiv(SvRV(seqid), tmpui);
  
  // read/set name
  READ_VARINT(p, tmpui);
  if (tmpui) {
    READ_SV(p, tmp, tmpui);
    sv_utf8_decode(tmp);
    if (SvROK(name))
      sv_setsv(SvRV(name), tmp);
  }
  else {
    if (SvROK(name))
      sv_setpv(SvRV(name), "");
  }
}

 # readMessageEnd in parent

void
readStructBegin(TBinaryProtocol *p, SV *name)
CODE:
{
  DEBUG_TRACE("readStructBegin()\n");
  
  // No reading here, but we push last_field_id onto the fields stack
  struct field_entry *entry;
  New(0, entry, sizeof(struct field_entry), struct field_entry);
  MEM_TRACE("New entry @ %p\n", entry);
  entry->field_id = p->last_field_id;
  SIMPLEQ_INSERT_HEAD(p->last_fields, entry, entries);
  
  p->last_field_id = 0;
  
  if (SvROK(name))
    sv_setpv(SvRV(name), "");
}

void
readStructEnd(TBinaryProtocol *p)
CODE:
{
  DEBUG_TRACE("readStructEnd()\n");
  
  // pop last field off the stack
  struct field_entry *entry = SIMPLEQ_FIRST(p->last_fields);
  SIMPLEQ_REMOVE_HEAD(p->last_fields, entries);
  p->last_field_id = entry->field_id;
  
  MEM_TRACE("free entry @ %p\n", entry);
  Safefree(entry);
}

void
readFieldBegin(TBinaryProtocol *p, SV * /*name*/, SV *fieldtype, SV *fieldid)
CODE:
{
  DEBUG_TRACE("readFieldBegin()\n");
  
  SV *tmp;
  char *tmps;
  
  // fieldtype byte
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  int type = tmps[0];
  
  if (SvROK(fieldtype))
    sv_setiv(SvRV(fieldtype), get_ttype(type & 0x0f));
  
  if (type == T_STOP) {
    if (SvROK(fieldid))
      sv_setiv(SvRV(fieldid), 0);
    XSRETURN_EMPTY;
  }
  
  // fieldid i16 varint
  int fid;
  
  // mask off the 4 MSB of the type header. it could contain a field id delta.
  uint8_t modifier = ((type & 0xf0) >> 4);
  if (modifier == 0) {
    // pop field
    struct field_entry *entry = SIMPLEQ_FIRST(p->last_fields);
    SIMPLEQ_REMOVE_HEAD(p->last_fields, entries);
    MEM_TRACE("free entry @ %p\n", entry);
    Safefree(entry);
    
    // not a delta. look ahead for the zigzag varint field id.
    READ_VARINT(p, fid);
    fid = zigzag_to_int(fid);
  }
  else {
    // has a delta. add the delta to the last read field id.
    // pop field
    struct field_entry *entry = SIMPLEQ_FIRST(p->last_fields);
    SIMPLEQ_REMOVE_HEAD(p->last_fields, entries);
    int last = entry->field_id;
    MEM_TRACE("free entry @ %p\n", entry);
    Safefree(entry);
    
    fid = last + modifier;
  }
  
  // if this happens to be a boolean field, the value is encoded in the type
  if (is_bool_type(type)) {
    // save the boolean value in a special instance variable.
    p->bool_value_id = (type & 0x0f) == CTYPE_BOOLEAN_TRUE ? 1 : 0;
  }
  
  // push the new field onto the field stack so we can keep the deltas going.
  struct field_entry *entry;
  New(0, entry, sizeof(struct field_entry), struct field_entry);
  MEM_TRACE("New entry @ %p\n", entry);
  entry->field_id = fid;
  SIMPLEQ_INSERT_HEAD(p->last_fields, entry, entries);
  
  if (SvROK(fieldid))
    sv_setiv(SvRV(fieldid), fid);
}

 # readFieldEnd in parent

void
readMapBegin(TBinaryProtocol *p, SV *keytype, SV *valtype, SV *size)
CODE:
{
  DEBUG_TRACE("readMapBegin()\n");
  
  SV *tmp;
  char *tmps;
  
  // size
  uint32_t isize;
  READ_VARINT(p, isize);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
  
  // key and value type
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  
  // keytype byte
  if (SvROK(keytype))
    sv_setiv(SvRV(keytype), get_ttype((tmps[0] >> 4) & 0xf));
  
  // valtype byte
  if (SvROK(valtype))
    sv_setiv(SvRV(valtype), get_ttype(tmps[0] & 0xf));
}

 # readMapEnd in parent

void
readListBegin(TBinaryProtocol *p, SV *elemtype, SV *size)
CODE:
{
  DEBUG_TRACE("readListBegin()\n");
  
  SV *tmp;
  char *tmps;
  
  // size and type may be in the same byte
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  int isize = (tmps[0] >> 4) & 0x0f;
  if (isize == 15) {
    // size is in a varint
    READ_VARINT(p, isize);
  }
  int type = get_ttype(tmps[0] & 0x0f);

  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), type);
  
  // size
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

 # readListEnd in parent

void
readSetBegin(TBinaryProtocol *p, SV *elemtype, SV *size)
CODE:
{
  DEBUG_TRACE("readSetBegin()\n");
  
  SV *tmp;
  char *tmps;
  
  // size and type may be in the same byte
  READ_SV(p, tmp, 1);
  tmps = SvPVX(tmp);
  int isize = (tmps[0] >> 4) & 0x0f;
  if (isize == 15) {
    // size is in a varint
    READ_VARINT(p, isize);
  }
  int type = get_ttype(tmps[0] & 0x0f);

  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), type);
  
  // size
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

 # readSetEnd in parent

void
readBool(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readBool()\n");
  
  SV *tmp;
  char *tmps;
  
  // Check for bool_value encoded in the fieldBegin type
  if (p->bool_value_id != -1) {
    if (SvROK(value))
      sv_setiv(SvRV(value), p->bool_value_id);
    p->bool_value_id = -1;
  }
  else {  
    READ_SV(p, tmp, 1);
    tmps = SvPVX(tmp);
  
    if (SvROK(value))
      sv_setiv(SvRV(value), tmps[0] ? 1 : 0);
  }
}

 # readByte in parent

void
readI16(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI16()\n");
  
  uint32_t varint;
  READ_VARINT(p, varint);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), zigzag_to_int(varint));
}

void
readI32(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readI32()\n");
  
  uint32_t varint;
  READ_VARINT(p, varint);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), zigzag_to_int(varint));
}

void
readI64(TBinaryProtocol *p, SV *value)
CODE:
{
  uint64_t varint;
  READ_VARINT(p, varint);

  DEBUG_TRACE("readI64(%lld) (from varint %llu)\n", zigzag_to_ll(varint), varint);

  // Store as a string so it works on 32-bit platforms
  if (SvROK(value)) {
    char string[25];
    STRLEN length;
    length = sprintf(string, "%lld", zigzag_to_ll(varint));
    sv_setpvn(SvRV(value), string, length);
  }
}

void
readDouble(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readDouble()\n");
  
  SV *tmp;
  char *tmps;
  
  READ_SV(p, tmp, 8);
  tmps = SvPVX(tmp);
  
  uint32_t lo = (uint8_t)tmps[0] |
    ((uint8_t)tmps[1] << 8) |
    ((uint8_t)tmps[2] << 16) |
    ((uint8_t)tmps[3] << 24);
  uint64_t hi = (uint8_t)tmps[4] |
    ((uint8_t)tmps[5] << 8) |
    ((uint8_t)tmps[6] << 16) |
    ((uint8_t)tmps[7] << 24);

  union {
    double d;
    int64_t i;
  } u;
  u.i = (hi << 32) | lo;
  
  if (SvROK(value))
    sv_setnv(SvRV(value), u.d);
}

void
readString(TBinaryProtocol *p, SV *value)
CODE:
{
  DEBUG_TRACE("readString()\n");
  
  SV *tmp;
  
  uint64_t len;
  READ_VARINT(p, len);
  if (len) {
    READ_SV(p, tmp, len);
    sv_utf8_decode(tmp);
    if (SvROK(value))
      sv_setsv(SvRV(value), tmp);
  }
  else {
    if (SvROK(value))
      sv_setpv(SvRV(value), "");
  }
}
