static size_t X_FN_NAME(
    pTHX_
    const char *pa, const char *pa_end,
    const char *pb, const char *pb_end
) {
    assert(pa <= pa_end);
    assert(pb <= pb_end);

    size_t cp_bound = 0;
    for (; pa < pa_end && pb < pb_end; pa++, pb++, cp_bound++) {
        if (!X_IS_CONTINUATION(*pa)) {
            cp_bound = 0;
        }

        if (*pa != *pb) {
            pa -= cp_bound;
            pb -= cp_bound;
            cp_bound = 0;
            for (;;) {
                if (pa_end[-1] != pb_end[-1]) {
                    pa_end += cp_bound;
                    pb_end += cp_bound;
                    cp_bound = 0;
                    break;
                }
                pa_end--;
                pb_end--;
                if (X_IS_CONTINUATION(*pa_end)) {
                    cp_bound++;
                } else {
                    cp_bound = 0;
                }
                if (!(pa < pa_end && pb < pb_end)) {
                    if (cp_bound) {
                        errno = EILSEQ;
                        return SIZE_MAX;
                    }
                    break;
                }
            }
            break;
        }
    }

    size_t
        len_a = X_LENGTH(pa, pa_end),
        len_b = X_LENGTH(pb, pb_end);
    if (len_a == 0) {
        return len_b;
    }
    if (len_b == 0) {
        return len_a;
    }

    if (len_a > len_b) {
        const char *p_tmp = pa;
        pa = pb;
        pb = p_tmp;
        p_tmp = pa_end;
        pa_end = pb_end;
        pb_end = p_tmp;
        size_t n_tmp = len_a;
        len_a = len_b;
        len_b = n_tmp;
    }

    const size_t rwidth = len_a + 1u;

    if (
        rwidth == 0 ||
        SIZE_MAX - 2u < len_b ||
        SIZE_MAX / sizeof (size_t) < rwidth ||
        SIZE_MAX / (rwidth * sizeof (size_t)) < len_b + 2
    ) {
        errno = ENOMEM;
        return SIZE_MAX;
    }

    size_t *const alloc = safemalloc(rwidth * (len_b + 2) * sizeof (size_t));
    if (!alloc) {
        errno = ENOMEM;
        return SIZE_MAX;
    }

    size_t *const idy_cx = alloc, *const dist = alloc + rwidth;

    dist[0] = 0u;
    for (size_t i = 1; i <= len_a; i++) {
        dist[i] = i;
        idy_cx[i - 1] = SIZE_MAX;
    }
    for (size_t i = 1; i <= len_b; i++) {
        dist[i * rwidth] = i;
    }

    const char *pa_orig = pa;
    for (size_t j = 0; j < len_b; j++) {
        const size_t cyn = X_CHARBYTES(pb, pb_end);
        size_t idx_cy = SIZE_MAX;
        for (size_t i = 0; i < len_a; i++) {
            const size_t cxn = X_CHARBYTES(pa, pa_end);
            size_t d = dist[j * rwidth + i];
            if (X_CHAR_EQ(pa, cxn, pb, cyn)) {
                idx_cy = i;
                idy_cx[i] = j;
            } else {
                const size_t idy_cx_i = idy_cx[i];
                size_t w = dist[(j + 1) * rwidth + i];
                if (w < d) d = w;
                w = dist[j * rwidth + i + 1];
                if (w < d) d = w;
                if (idx_cy != SIZE_MAX && idy_cx_i != SIZE_MAX) {
                    w = dist[idy_cx_i * rwidth + idx_cy] + i - idx_cy + j - idy_cx_i - 2u;
                    if (w < d) d = w;
                }
                d++;
                assert(d != 0u);
            }
            dist[(j + 1) * rwidth + i + 1] = d;
#if 0
            for (size_t dj = 0; dj <= len_b; dj++) {
                fprintf(stderr, "|");
                for (size_t di = 0; di <= len_a; di++) {
                    fprintf(stderr, " %3d |", di == 0 || dj < j + 1 || (dj == j + 1 && di <= i + 1) ? dist[dj * rwidth + di] : 99);
                }
                fprintf(stderr, "\n");
            }
            fprintf(stderr, "\n");
#endif
            pa += cxn;
        }
        pa = pa_orig;
        pb += cyn;
    }

    const size_t r = dist[len_b * rwidth + len_a];
    Safefree(alloc);
    return r;
}

#undef X_FN_NAME
#undef X_IS_CONTINUATION
#undef X_LENGTH
#undef X_CHARBYTES
#undef X_CHAR_EQ
