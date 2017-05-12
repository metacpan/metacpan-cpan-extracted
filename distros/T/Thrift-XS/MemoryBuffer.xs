MODULE = Thrift::XS   PACKAGE = Thrift::XS::MemoryBuffer

SV *
new(char *klass, ...)
CODE:
{
  int bufsize = 8192;
  TMemoryBuffer *mbuf;  
  New(0, mbuf, sizeof(TMemoryBuffer), TMemoryBuffer);
  New(0, mbuf->buffer, sizeof(Buffer), Buffer);
  
  MEM_TRACE("new()\n");
  MEM_TRACE("  New mbuf @ %p\n", mbuf);
  MEM_TRACE("  New buffer @ %p\n", mbuf->buffer);
  
  if (items > 1 && SvIOK_UV(ST(1)))
    bufsize = SvIV(ST(1));
  
  buffer_init(mbuf->buffer, bufsize);
  
  RETVAL = xs_object_magic_create(
    aTHX_
    (void *)mbuf,
    gv_stashpv(klass, 0)
  );
}
OUTPUT:
  RETVAL

int
isOpen(SV *)
CODE:
{
  RETVAL = 1;
}
OUTPUT:
  RETVAL

void
open(SV *)
CODE:
{ }

void
close(SV *)
CODE:
{ }

void
flush(SV *)
CODE:
{ }

int
available(TMemoryBuffer *mbuf)
CODE:
{
  RETVAL = buffer_len(mbuf->buffer);
}
OUTPUT:
  RETVAL

SV *
read(TMemoryBuffer *mbuf, int len)
CODE:
{
  int avail = buffer_len(mbuf->buffer);
  
  if (avail == 0) {
    RETVAL = newSVpvn("", 0);
  }
  else {
    if (avail < len)
      len = avail;
    
    DEBUG_TRACE("read(%d)\n", len);
    RETVAL = newSVpvn( buffer_ptr(mbuf->buffer), len );
    buffer_consume(mbuf->buffer, len);
  }
}
OUTPUT:
  RETVAL

SV *
readAll(TMemoryBuffer *mbuf, int len)
CODE:
{
  int avail = buffer_len(mbuf->buffer);
  
  if (avail < len) {
    THROW_SV("TTransportException", newSVpvf("Attempt to readAll(%d) found only %d available", len, avail));
  }
  
  DEBUG_TRACE("readAll(%d)\n", len);
#ifdef XS_DEBUG
  //buffer_dump(mbuf->buffer, len);
#endif
  
  RETVAL = newSVpvn( buffer_ptr(mbuf->buffer), len );
  buffer_consume(mbuf->buffer, len);
}
OUTPUT:
  RETVAL

void
write(TMemoryBuffer *mbuf, SV *buf, ...)
CODE:
{
  int len;
  
  if (items > 2)
    len = SvIV(ST(2));
  else
    len = sv_len(buf);
    
  buffer_append(mbuf->buffer, (void *)SvPVX(buf), len);
  
  DEBUG_TRACE("write(%d)\n", len);
#ifdef XS_DEBUG
  //buffer_dump(mbuf->buffer, 0);
#endif
}
  
void
DESTROY(TMemoryBuffer *mbuf)
CODE:
{
  MEM_TRACE("DESTROY()\n");
  MEM_TRACE("  free buffer @ %p\n", mbuf->buffer);
  MEM_TRACE("  free mbuf @ %p\n", mbuf);
  
  buffer_free(mbuf->buffer);
  Safefree(mbuf->buffer);
  Safefree(mbuf);
}
