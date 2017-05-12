#include "xh_config.h"
#include "xh_core.h"

static void
xh_common_reader_init(xh_reader_t *reader, SV *XH_UNUSED(input), xh_char_t *encoding, size_t buf_size)
{
    reader->buf_size = buf_size;

    if (encoding[0] != '\0')
        reader->switch_encoding(reader, encoding, NULL, NULL);
}

static void
xh_common_reader_destroy(xh_reader_t *reader)
{
#ifdef XH_HAVE_ENCODER
    xh_buffer_destroy(&reader->enc_buf);
    if (reader->encoder != NULL)
        xh_encoder_destroy(reader->encoder);
#endif
}

static void
xh_common_reader_switch_encoding(xh_reader_t *reader, xh_char_t *encoding, xh_char_t **buf, size_t *len)
{
    xh_log_debug1("switch encoding to '%s'", encoding);

    if (xh_strcasecmp(encoding, XH_INTERNAL_ENCODING) == 0) {
#ifdef XH_HAVE_ENCODER
        if (reader->encoder != NULL) {
            croak("Can't to switch encoding from %s to %s", reader->encoder->fromcode, encoding);
        }
#endif
    }
    else {
#ifdef XH_HAVE_ENCODER
        if (reader->encoder == NULL) {
            /* create encoder */
            xh_log_debug1("create a new encoder: %s", encoding);

            reader->encoder = xh_encoder_create(XH_CHAR_CAST XH_INTERNAL_ENCODING, encoding);
            if (reader->encoder == NULL) {
                croak("Can't create encoder for '%s'", encoding);
            }

            xh_buffer_init(&reader->enc_buf, reader->buf_size);

            if (len != NULL && *len > 0) {
                reader->fake_read_pos = *buf;
                reader->fake_read_len = *len;
                *len = 0;
            }
        }
        else if (xh_strcasecmp(encoding, reader->encoder->fromcode) != 0) {
            croak("Can't to switch encoding from %s to %s", reader->encoder->fromcode, encoding);
        }
#else
        croak("Can't create encoder for '%s'", encoding);
#endif
    }
}

static void
xh_string_reader_init(xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size)
{
    STRLEN     len;
    xh_char_t *str;

    str = XH_CHAR_CAST SvPV(input, len);
    reader->str = str;
    reader->len = (size_t) len;

    reader->main_buf.start = reader->main_buf.cur = str;
    reader->main_buf.end   = str + len;

    xh_common_reader_init(reader, input, encoding, buf_size);
}

static size_t
xh_string_reader_read(xh_reader_t *reader, xh_char_t **buf, xh_char_t *XH_UNUSED(preserve), size_t *off)
{
    size_t       len;
    xh_buffer_t *main_buf;

    *off     = 0;
    main_buf = &reader->main_buf;

    *buf = xh_buffer_pos(main_buf);
    len  = xh_buffer_avail(main_buf);

    xh_buffer_seek_eof(main_buf);

    return len;
}

#ifdef XH_HAVE_ENCODER
static size_t
xh_string_reader_read_with_encoding(xh_reader_t *reader, xh_char_t **buf, xh_char_t *preserve, size_t *off)
{
    xh_char_t   *old_buf_addr;
    size_t       src_left, dst_left;
    xh_buffer_t *main_buf, *enc_buf;

    *off     = 0;
    main_buf = &reader->main_buf;
    enc_buf  = &reader->enc_buf;

    xh_log_debug4("enc_buf: %p[%.*s] len: %lu", enc_buf->start, enc_buf->cur - enc_buf->start, enc_buf->cur, enc_buf->cur - enc_buf->start);

    xh_log_debug1("preserve data: %p", preserve);
    if (preserve == NULL) {
        xh_buffer_seek_top(enc_buf);
    }
    else {
        *off = preserve - enc_buf->start;
        xh_log_debug1("off: %lu", *off);
        if (*off) {
            xh_log_debug3("memmove dest: %p src %p size: %lu", enc_buf->start, preserve, enc_buf->end - preserve);
            xh_memmove(enc_buf->start, preserve, enc_buf->end - preserve);
        }
        enc_buf->cur -= *off;
    }

    old_buf_addr = xh_buffer_start(enc_buf);
    xh_buffer_grow50(enc_buf);

    if (preserve != NULL && xh_buffer_start(enc_buf) != old_buf_addr) {
        *off += old_buf_addr - xh_buffer_start(enc_buf);
    }

    *buf = xh_buffer_pos(enc_buf);

    while (enc_buf->cur < enc_buf->end) {
        if (reader->fake_read_pos != NULL) {
            main_buf->cur         = reader->fake_read_pos;
            reader->fake_read_pos = NULL;
            reader->fake_read_len = 0;
        }

        xh_log_debug2("main buf cur: %p end: %p", main_buf->cur, main_buf->end);
        src_left = xh_buffer_avail(main_buf);
        if (src_left == 0 && reader->encoder->state == XH_ENC_OK) {
            if (main_buf->cur == main_buf->end)
                break;
            croak("Truncate char found");
        }

        dst_left = xh_buffer_avail(enc_buf);

        xh_log_debug4("main_buf: %.*s src_left: %lu dst_left: %lu", src_left, main_buf->cur, src_left, dst_left);

        xh_encoder_encode_string(reader->encoder, &main_buf->cur, &src_left, &enc_buf->cur, &dst_left);

        xh_log_debug3("enc_buf: %.*s len: %lu", enc_buf->cur - enc_buf->start, enc_buf->start, enc_buf->cur - enc_buf->start);

        switch (reader->encoder->state) {
            case XH_ENC_TRUNCATED_CHAR_FOUND:
                if (src_left == 0)
                    croak("Truncated char found but buffer is empty");
                break;
            case XH_ENC_BUFFER_OVERFLOW:
            default:
                goto DONE;
        }
    }

DONE:
    dst_left = enc_buf->cur - *buf;
    xh_log_debug4("enc_buf: %p[%.*s] len: %lu", enc_buf->start, dst_left, enc_buf->cur, dst_left);

    return dst_left;
}
#endif /* XH_HAVE_ENCODER */

static void
xh_string_reader_switch_encoding(xh_reader_t *reader, xh_char_t *encoding, xh_char_t **buf, size_t *len)
{

    xh_common_reader_switch_encoding(reader, encoding, buf, len);

#ifdef XH_HAVE_ENCODER
    reader->read = reader->encoder == NULL
        ? xh_string_reader_read
        : xh_string_reader_read_with_encoding;
#endif
}

static void
xh_string_reader_destroy(xh_reader_t *reader)
{
    xh_common_reader_destroy(reader);
}

#ifdef XH_HAVE_MMAP
static void
xh_mmaped_file_reader_init(xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size)
{
    struct stat sb;

    reader->file = XH_CHAR_CAST SvPV_nolen(input);

    xh_log_debug1("open file: %s", reader->file);

    reader->fd = open((const char *) reader->file, O_RDONLY);
    if (reader->fd == -1) {
        croak("Can't open file '%s': %s", reader->file, strerror(errno));
    }

    if (fstat(reader->fd, &sb) == -1) {
        croak("Can't get stat of file '%s': %s", reader->file, strerror(errno));
    }

    xh_log_debug1("file size: %lu", sb.st_size);

    if (sb.st_size == 0) {
        croak("File '%s' is empty", reader->file);
    }
    reader->len = sb.st_size;

#ifdef WIN32
    reader->fh = (HANDLE) _get_osfhandle(reader->fd);
    if (reader->fh == INVALID_HANDLE_VALUE) {
        croak("Can't get file handle of file '%s'", reader->file);
    }

    xh_log_debug1("create mapping for file %s", reader->file);
    reader->fm = CreateFileMapping(reader->fh, NULL, PAGE_READONLY, 0, 0, NULL);
    if (reader->fm == NULL) {
        croak("Can't create file mapping of file '%s'", reader->file);
    }

    xh_log_debug1("create map view for file %s", reader->file);
    reader->str = XH_CHAR_CAST MapViewOfFile(reader->fm, FILE_MAP_READ, 0, 0, reader->len);
    if (reader->str == NULL) {
        croak("Can't create map view of file '%s'", reader->file);
    }
#else
    xh_log_debug1("mmap file %s", reader->file);
    reader->str = XH_CHAR_CAST mmap((caddr_t) 0, reader->len, PROT_READ, MAP_PRIVATE, reader->fd, 0);
    if ((caddr_t) reader->str == (caddr_t) (-1)) {
        croak("Can't create map of file '%s': %s", reader->file, strerror(errno));
    }
#endif

    reader->main_buf.start = reader->main_buf.cur = reader->str;
    reader->main_buf.end   = reader->str + reader->len;

    xh_common_reader_init(reader, input, encoding, buf_size);
}

static void
xh_mmaped_file_reader_destroy(xh_reader_t *reader)
{
    xh_common_reader_destroy(reader);

    if (reader->fd == -1) return;

#ifdef WIN32
    xh_log_debug1("unmap view of file %s", reader->file);
    UnmapViewOfFile(reader->str);
    xh_log_debug1("close handle of file %s", reader->file);
    CloseHandle(reader->fm);
#else
    xh_log_debug1("munmap file %s", reader->file);
    if (munmap(reader->str, reader->len) == -1) {
        croak("Can't munmap file '%s': %s", reader->file, strerror(errno));
    }
#endif

    xh_log_debug1("close file %s", reader->file);
    if (close(reader->fd) == -1) {
        croak("Can't close file '%s': %s", reader->file, strerror(errno));
    }
}
#else
static void
xh_file_reader_init(xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size)
{
    reader->file = XH_CHAR_CAST SvPV_nolen(input);

    xh_log_debug1("open file: %s", reader->file);

    reader->fd = open((char *) reader->file, O_RDONLY);
    if (reader->fd == -1) {
        croak("Can't open file '%s': %s", reader->file, strerror(errno));
    }

    xh_buffer_init(&reader->main_buf, buf_size);

    xh_common_reader_init(reader, input, encoding, buf_size);
}

static void
xh_file_reader_destroy(xh_reader_t *reader)
{
    xh_common_reader_destroy(reader);

    if (reader->main_buf.start != NULL)
        free(reader->main_buf.start);

    if (close(reader->fd) == -1) {
        croak("Can't close file '%s': %s", reader->file, strerror(errno));
    }
}
#endif /* XH_HAVE_MMAP */

static size_t
xh_file_reader_read(xh_reader_t *reader, xh_char_t **buf, xh_char_t *preserve, size_t *off)
{
    xh_char_t  *old_buf_addr;
    size_t      len;
    xh_buffer_t *main_buf;

    main_buf = &reader->main_buf;
    *off     = 0;

    xh_log_debug1("read preserve: %p", preserve);
    if (preserve == NULL) {
        main_buf->cur = main_buf->start;
    }
    else {
        *off = preserve - main_buf->start;
        xh_log_debug1("off: %lu", *off);
        if (*off) {
            xh_log_debug3("memmove dest: %p src %p size: %lu", main_buf->start, preserve, main_buf->end - preserve);
            xh_memmove(main_buf->start, preserve, main_buf->end - preserve);
        }
        main_buf->cur -= *off;
        xh_log_debug1("read cur: %p", main_buf->cur);
    }

    old_buf_addr = main_buf->start;

    xh_buffer_grow50(main_buf);

    if (preserve != NULL && main_buf->start != old_buf_addr) {
        *off += old_buf_addr - main_buf->start;
    }

    len = read(reader->fd, main_buf->cur, xh_buffer_avail(main_buf));
    *buf = main_buf->cur;
    if (len == (size_t) (-1)) {
        croak("Failed to read file");
    }
    main_buf->cur += len;

    return len;
}

#ifdef XH_HAVE_ENCODER
static size_t
xh_file_reader_read_with_encoding(xh_reader_t *reader, xh_char_t **buf, xh_char_t *preserve, size_t *off)
{
    xh_char_t   *old_buf_addr;
    size_t       src_left, dst_left;
    xh_buffer_t *main_buf, *enc_buf;

    *off     = 0;
    main_buf = &reader->main_buf;
    enc_buf  = &reader->enc_buf;

    xh_log_debug4("enc_buf: %p[%.*s] len: %lu", enc_buf->start, enc_buf->cur - enc_buf->start, enc_buf->cur, enc_buf->cur - enc_buf->start);

    xh_log_debug1("preserve data: %p", preserve);
    if (preserve == NULL) {
        xh_buffer_seek_top(enc_buf);
    }
    else {
        *off = preserve - enc_buf->start;
        xh_log_debug1("off: %lu", *off);
        if (*off) {
            xh_log_debug3("memmove dest: %p src %p size: %lu", enc_buf->start, preserve, enc_buf->end - preserve);
            xh_memmove(enc_buf->start, preserve, enc_buf->end - preserve);
        }
        enc_buf->cur -= *off;
    }

    old_buf_addr = enc_buf->start;
    xh_buffer_grow50(enc_buf);

    if (preserve != NULL && enc_buf->start != old_buf_addr) {
        *off += old_buf_addr - enc_buf->start;
    }

    *buf = xh_buffer_pos(enc_buf);

    while (enc_buf->cur < enc_buf->end) {
        xh_buffer_grow50(main_buf);

        if (reader->fake_read_pos == NULL) {
            src_left = read(reader->fd, xh_buffer_pos(main_buf), xh_buffer_avail(main_buf));
        }
        else {
            main_buf->cur         = reader->fake_read_pos;
            src_left              = reader->fake_read_len;
            reader->fake_read_pos = NULL;
            reader->fake_read_len = 0;
        }
        if (src_left == 0) {
            if (main_buf->cur == main_buf->end)
                break;
            croak("Truncate char found");
        }
        if (src_left == (size_t) (-1))
            croak("Failed to read file");

        dst_left = xh_buffer_avail(enc_buf);

        xh_log_debug4("main_buf: %.*s src_left: %lu dst_left: %lu", src_left, main_buf->cur, src_left, dst_left);

        xh_encoder_encode_string(reader->encoder, &main_buf->cur, &src_left, &enc_buf->cur, &dst_left);

        xh_log_debug3("enc_buf: %.*s len: %lu", enc_buf->cur - enc_buf->start, enc_buf->start, enc_buf->cur - enc_buf->start);

        switch (reader->encoder->state) {
            case XH_ENC_TRUNCATED_CHAR_FOUND:
                if (src_left == 0)
                    croak("Truncated char found but buffer is empty");
                xh_memmove(main_buf->start, main_buf->cur, src_left);
                main_buf->cur = main_buf->start + src_left;
                break;
            case XH_ENC_BUFFER_OVERFLOW:
            default:
                xh_buffer_seek_top(main_buf);
                goto DONE;
        }
    }

DONE:
    dst_left = enc_buf->cur - *buf;
    xh_log_debug4("enc_buf: %p[%.*s] len: %lu", enc_buf->start, dst_left, enc_buf->cur, dst_left);

    return dst_left;
}
#endif /* XH_HAVE_ENCODER */

static void
xh_file_reader_switch_encoding(xh_reader_t *reader, xh_char_t *encoding, xh_char_t **buf, size_t *len)
{
    xh_common_reader_switch_encoding(reader, encoding, buf, len);

#ifdef XH_HAVE_ENCODER
    reader->read = reader->encoder == NULL
        ? xh_file_reader_read
        : xh_file_reader_read_with_encoding;
#endif
}

static void
xh_perl_io_reader_init(xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size)
{
    reader->fd = PerlIO_fileno(reader->perl_io);

    xh_buffer_init(&reader->main_buf, buf_size);

    xh_common_reader_init(reader, input, encoding, buf_size);
}

static void
xh_perl_io_reader_destroy(xh_reader_t *reader)
{
    xh_common_reader_destroy(reader);

    if (reader->main_buf.start != NULL)
        free(reader->main_buf.start);
}

static size_t
xh_perl_obj_read(SV *obj, SV *buf, size_t count, size_t offset)
{
    int    nparam;
    size_t len = 0;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(obj);
    XPUSHs(buf);
    XPUSHs(sv_2mortal(newSViv(count)));
    XPUSHs(sv_2mortal(newSViv(offset)));
    PUTBACK;

    nparam = call_method("READ", G_SCALAR);

    SPAGAIN;

    if (nparam) {
        len = POPi;
    }
    else {
        len = 0;
    }

    FREETMPS;
    LEAVE;

    return len;
}

static void
xh_perl_obj_reader_init(xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size)
{
    xh_perl_buffer_init(&reader->perl_buf, buf_size);

    xh_common_reader_init(reader, input, encoding, buf_size);
}

static void
xh_perl_obj_reader_destroy(xh_reader_t *reader)
{
    xh_common_reader_destroy(reader);

    if (reader->perl_buf.scalar != NULL)
        SvREFCNT_dec(reader->perl_buf.scalar);
}

static size_t
xh_perl_obj_reader_read(xh_reader_t *reader, xh_char_t **buf, xh_char_t *preserve, size_t *off)
{
    xh_char_t        *old_buf_addr;
    size_t            len;
    xh_perl_buffer_t *main_buf;

    main_buf = &reader->perl_buf;
    *off     = 0;

    xh_log_debug1("read preserve: %p", preserve);
    if (preserve == NULL) {
        main_buf->cur = main_buf->start;
    }
    else {
        *off = preserve - main_buf->start;
        xh_log_debug1("off: %lu", *off);
        if (*off) {
            xh_log_debug3("memmove dest: %p src %p size: %lu", main_buf->start, preserve, main_buf->end - preserve);
            xh_memmove(main_buf->start, preserve, main_buf->end - preserve);
        }
        main_buf->cur -= *off;
        xh_log_debug1("read cur: %p", main_buf->cur);
    }

    {
        old_buf_addr = main_buf->start;

        xh_perl_buffer_grow50(main_buf);

        len = xh_perl_obj_read(reader->perl_obj, main_buf->scalar, xh_perl_buffer_avail(main_buf), main_buf->cur - main_buf->start);

        xh_perl_buffer_sync(main_buf);

        if (preserve != NULL && main_buf->start != old_buf_addr) {
            *off += old_buf_addr - main_buf->start;
        }
    }

    *buf = main_buf->cur;
    if (len == (size_t) (-1)) {
        croak("Failed to read file");
    }
    main_buf->cur += len;

    return len;
}

#ifdef XH_HAVE_ENCODER
static size_t
xh_perl_obj_reader_read_with_encoding(xh_reader_t *reader, xh_char_t **buf, xh_char_t *preserve, size_t *off)
{
    xh_char_t        *old_buf_addr;
    size_t            src_left, dst_left;
    xh_perl_buffer_t *main_buf;
    xh_buffer_t      *enc_buf;

    *off     = 0;
    main_buf = &reader->perl_buf;
    enc_buf  = &reader->enc_buf;

    xh_log_debug4("enc_buf: %p[%.*s] len: %lu", enc_buf->start, enc_buf->cur - enc_buf->start, enc_buf->cur, enc_buf->cur - enc_buf->start);

    xh_log_debug1("preserve data: %p", preserve);
    if (preserve == NULL) {
        xh_buffer_seek_top(enc_buf);
    }
    else {
        *off = preserve - enc_buf->start;
        xh_log_debug1("off: %lu", *off);
        if (*off) {
            xh_log_debug3("memmove dest: %p src %p size: %lu", enc_buf->start, preserve, enc_buf->end - preserve);
            xh_memmove(enc_buf->start, preserve, enc_buf->end - preserve);
        }
        enc_buf->cur -= *off;
    }

    old_buf_addr = enc_buf->start;
    xh_buffer_grow50(enc_buf);

    if (preserve != NULL && enc_buf->start != old_buf_addr) {
        *off += old_buf_addr - enc_buf->start;
    }

    *buf = xh_buffer_pos(enc_buf);

    while (enc_buf->cur < enc_buf->end) {
        xh_perl_buffer_grow50(main_buf);

        if (reader->fake_read_pos == NULL) {
            src_left = xh_perl_obj_read(reader->perl_obj, main_buf->scalar, xh_perl_buffer_avail(main_buf), main_buf->cur - main_buf->start);
        }
        else {
            main_buf->cur         = reader->fake_read_pos;
            src_left              = reader->fake_read_len;
            reader->fake_read_pos = NULL;
            reader->fake_read_len = 0;
        }
        if (src_left == 0) {
            if (main_buf->cur == main_buf->end)
                break;
            croak("Truncate char found");
        }
        if (src_left == (size_t) (-1))
            croak("Failed to read file");

        dst_left = xh_buffer_avail(enc_buf);

        xh_log_debug4("main_buf: %.*s src_left: %lu dst_left: %lu", src_left, main_buf->cur, src_left, dst_left);

        xh_encoder_encode_string(reader->encoder, &main_buf->cur, &src_left, &enc_buf->cur, &dst_left);

        xh_log_debug3("enc_buf: %.*s len: %lu", enc_buf->cur - enc_buf->start, enc_buf->start, enc_buf->cur - enc_buf->start);

        switch (reader->encoder->state) {
            case XH_ENC_TRUNCATED_CHAR_FOUND:
                if (src_left == 0)
                    croak("Truncated char found but buffer is empty");
                xh_memmove(main_buf->start, main_buf->cur, src_left);
                main_buf->cur = main_buf->start + src_left;
                break;
            case XH_ENC_BUFFER_OVERFLOW:
            default:
                xh_buffer_seek_top(main_buf);
                goto DONE;
        }
    }

DONE:
    dst_left = enc_buf->cur - *buf;
    xh_log_debug4("enc_buf: %p[%.*s] len: %lu", enc_buf->start, dst_left, enc_buf->cur, dst_left);

    return dst_left;
}
#endif /* XH_HAVE_ENCODER */

static void
xh_perl_obj_reader_switch_encoding(xh_reader_t *reader, xh_char_t *encoding, xh_char_t **buf, size_t *len)
{
    xh_common_reader_switch_encoding(reader, encoding, buf, len);

#ifdef XH_HAVE_ENCODER
    reader->read = reader->encoder == NULL
        ? xh_perl_obj_reader_read
        : xh_perl_obj_reader_read_with_encoding;
#endif
}

void
xh_reader_init(xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size)
{
    STRLEN     len;
    xh_char_t *str;
    MAGIC     *mg;
    GV        *gv;
    IO        *io;

    if (SvTYPE(input) != SVt_PVGV) {
        str = XH_CHAR_CAST SvPV(input, len);
        if (len == 0)
            croak("String is empty");

        /* Parsing string */
        if (xh_str_is_xml(str)) {
            reader->type            = XH_READER_STRING_TYPE;
            reader->init            = xh_string_reader_init;
            reader->read            = xh_string_reader_read;
            reader->switch_encoding = xh_string_reader_switch_encoding;
            reader->destroy         = xh_string_reader_destroy;
        }
        /* Parsing file */
        else {
#ifdef XH_HAVE_MMAP
            reader->type            = XH_READER_MMAPED_FILE_TYPE;
            reader->init            = xh_mmaped_file_reader_init;
            reader->read            = xh_string_reader_read;
            reader->switch_encoding = xh_string_reader_switch_encoding;
            reader->destroy         = xh_mmaped_file_reader_destroy;
#else
            reader->type            = XH_READER_FILE_TYPE;
            reader->init            = xh_file_reader_init;
            reader->read            = xh_file_reader_read;
            reader->switch_encoding = xh_file_reader_switch_encoding;
            reader->destroy         = xh_file_reader_destroy;
#endif
        }
    }
    else {
        gv = (GV *) input;
        io = GvIO(gv);

        if (!io)
            croak("Can't use file handle as a PerlIO handle");

        if ((mg = SvTIED_mg(MUTABLE_SV(io), PERL_MAGIC_tiedscalar))) {
            /* Tied handle */
            xh_log_debug0("Tied handle detected");
            reader->perl_obj        = SvTIED_obj(MUTABLE_SV(io), mg);
            reader->type            = XH_READER_FILE_TYPE;
            reader->init            = xh_perl_obj_reader_init;
            reader->read            = xh_perl_obj_reader_read;
            reader->switch_encoding = xh_perl_obj_reader_switch_encoding;
            reader->destroy         = xh_perl_obj_reader_destroy;
        }
        else {
            /* PerlIO handle */
            xh_log_debug0("PerlIO handle detected");
            reader->perl_io         = IoIFP(io);
            reader->type            = XH_READER_FILE_TYPE;
            reader->init            = xh_perl_io_reader_init;
            reader->read            = xh_file_reader_read;
            reader->switch_encoding = xh_file_reader_switch_encoding;
            reader->destroy         = xh_perl_io_reader_destroy;
        }
    }

    reader->init(reader, input, encoding, buf_size);
}

void
xh_reader_destroy(xh_reader_t *reader)
{
    if (reader->destroy != NULL)
        reader->destroy(reader);
}
