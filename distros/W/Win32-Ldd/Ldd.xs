#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "libntldd.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

#include "mymemory.h"

char *
my_strdup(char *s) {
    char *ptr = savepv(s);
    SAVEFREEPV(ptr);
    return ptr;
}

void *
my_malloc(size_t size) {
    void *ptr;
    Newx(ptr, size, char *);
    SAVEFREEPV(ptr);
    return ptr;
}

void
my_free(void *ptr) {;}

void *
my_realloc(void *old, size_t old_size, size_t new_size) {
    if (old_size >= new_size) return old;

    void *ptr;
    Newx(ptr, new_size, char *);
    if (old_size > 0 && old)
        memcpy(ptr, old, old_size);
    SAVEFREEPV(ptr);
    return ptr;
}

static SearchPaths *
sv2SearchPaths(SV *sv) {
    if (SvROK(sv)) {
        AV *av = (AV*)SvRV(sv);
        if (SvTYPE((SV*)av) == SVt_PVAV) {
            SearchPaths *search_paths = malloc(sizeof(*search_paths));
            unsigned int i, j, count = av_len(av) + 1;
            search_paths->path = malloc(count * sizeof(char *));
            for (i = j = 0; i < count; i++) {
                SV **svp = av_fetch(av, i, 0);
                if (svp && SvOK(*svp)) search_paths->path[j++] = strdup(SvPV_nolen(*svp));
            }
            search_paths->count = j;
            return search_paths;
        }
    }
    Perl_croak(aTHX_ "argument is not an AV*, unable to convert to SearchPath type");
}

static struct DepTreeElement *
build_dep_tree(char *pe_file,
               SearchPaths *search_paths,
               int datarelocs, int recursive, int functionrelocs) {
    /* warn("build_dep_tree(%s, %p, %d, %d)", pe_file, search_paths, datarelocs, functionrelocs); */
    struct DepTreeElement root;
    memset(&root, 0, sizeof(root));
    struct DepTreeElement *child = malloc(sizeof(*child));
    memset(child, 0, sizeof(*child));
    child->module = strdup(pe_file);
    /* warn("calling AddDep"); */
    AddDep(&root, child);

    char **stack = NULL;
    uint64_t stack_len = 0;
    uint64_t stack_size = 0;
    BuildTreeConfig cfg;

    memset(&cfg, 0, sizeof(cfg));
    cfg.machineType = -1;
    cfg.on_self = 0;
    cfg.datarelocs = datarelocs;
    cfg.recursive = recursive,
    cfg.functionrelocs = functionrelocs;
    cfg.stack = &stack;
    cfg.stack_len = &stack_len;
    cfg.stack_size = &stack_size;
    cfg.searchPaths = search_paths;

    /* warn("calling BuildDepTree"); */
    int error =  BuildDepTree(&cfg, pe_file, &root, child);

    if (error) return NULL;
    return child;
}

static void
cache_store(HV *cache, void *ptr, SV *sv) {
    SV *key = sv_2mortal(newSVpvf("%x", ptr));
    hv_store(cache, SvPV_nolen(key), SvLEN(key), SvREFCNT_inc(sv), 0);
}

static SV *
cache_retrieve(HV *cache, void *ptr) {
    SV *key = sv_2mortal(newSVpvf("%x", ptr));
    SV **svp = hv_fetch(cache, SvPV_nolen(key), SvLEN(key), 0);
    if (svp)
        return SvREFCNT_inc(*svp);
    return NULL;
}

static SV *DepTreeElement2sv(struct DepTreeElement *dte, HV *cache);

static SV*
childs2sv(struct DepTreeElement **childs, uint64_t childs_len, HV *cache) {
    if (childs) {
        SV *sv = cache_retrieve(cache, childs);
        if (!sv) {
            AV *av = newAV();
            sv = newRV_noinc((SV*)av);
            int i;
            for (i = 0; i < childs_len; i++)
                av_push(av, DepTreeElement2sv(childs[i], cache));
            cache_store(cache, childs, sv);
        }
        return sv;
    }
    return &PL_sv_undef;
}

static SV *
export2sv(struct ExportTableItem *export, HV *cache) {
    if (export) {
        SV *sv = cache_retrieve(cache, export);
        if (!sv) {
            HV *hv = newHV();
            sv = newRV_noinc((SV*)hv);
            hv_stores(hv, "address", newSViv(PTR2IV(export->address)));
            hv_stores(hv, "name", newSVpv(export->name, 0));
            hv_stores(hv, "ordinal", newSViv(export->ordinal));
            hv_stores(hv, "forward_str", newSVpv(export->forward_str, 0));
            hv_stores(hv, "forward", export2sv(export->forward, cache));
            hv_stores(hv, "section_index", newSViv(export->section_index));
            hv_stores(hv, "address_offset", newSViv(export->address_offset));
            cache_store(cache, export, sv);
        }
        return sv;
    }
    return &PL_sv_undef;
}

static SV *
exports2sv(struct ExportTableItem *exports, uint64_t exports_len, HV *cache) {
    if (exports) {
        SV *sv = cache_retrieve(cache, exports);
        if (!sv) {
            AV *av = newAV();
            sv = newRV_noinc((SV*)av);

            int i;
            for (i = 0; i < exports_len; i++)
                av_push(av, export2sv(exports + i, cache));

            cache_store(cache, exports, sv);
        }
        return sv;
    }
    return &PL_sv_undef;
}

static SV *
import2sv(struct ImportTableItem *import, HV *cache) {
    if (import) {
        SV *sv = cache_retrieve(cache, import);
        if (!sv) {
            HV *hv = newHV();
            sv = newRV_noinc((SV*)hv);

            hv_stores(hv, "orig_address", newSVi64(import->orig_address));
            hv_stores(hv, "address", newSVi64(import->address));
            hv_stores(hv, "name", newSVpv(import->name, 0));
            hv_stores(hv, "ordinal", newSViv(import->ordinal));
            hv_stores(hv, "dll", DepTreeElement2sv(import->dll, cache));
            hv_stores(hv, "mapped", export2sv(import->mapped, cache));
        }
        return sv;
    }
    return &PL_sv_undef;
}

static SV *
imports2sv(struct ImportTableItem *imports, uint64_t imports_len, HV *cache) {
    if (imports) {
        SV *sv = cache_retrieve(cache, imports);
        if (!sv) {
            AV *av = newAV();
            sv = newRV_noinc((SV*)av);

            int i;
            for (i = 0; i < 0; i++)
                av_push(av, import2sv(imports + i, cache));

            cache_store(cache, imports, sv);
        }
        return sv;
    }
    return &PL_sv_undef;
}

static SV *
DepTreeElement2sv(struct DepTreeElement *dte, HV *cache) {
    SV *sv = cache_retrieve(cache, dte);
    if (!sv) {
        HV *hv = newHV();
        sv = newRV_noinc((SV*)hv);

        hv_stores(hv, "flags", newSVuv(dte->flags));
        hv_stores(hv, "resolved", newSVsv(dte->flags & DEPTREE_UNRESOLVED ? &PL_sv_no : &PL_sv_yes));
        hv_stores(hv, "module", newSVpv(dte->module, 0));
        hv_stores(hv, "export_module", newSVpv(dte->export_module, 0));
        hv_stores(hv, "resolved_module", newSVpv(dte->resolved_module, 0));
        hv_stores(hv, "children", childs2sv(dte->childs, dte->childs_len, cache));
        hv_stores(hv, "imports", imports2sv(dte->imports, dte->imports_len, cache));
        hv_stores(hv, "exports", exports2sv(dte->exports, dte->exports_len, cache));

        cache_store(cache, dte, sv);
    }
    return sv;
}

MODULE = Win32::Ldd		PACKAGE = Win32::Ldd

BOOT:
             PERL_MATH_INT64_LOAD_OR_CROAK;


SV *
build_dep_tree(char *pe_file, SearchPaths *search_paths, int datarelocs, int recursive, int functionrelocs)
PREINIT:
    struct DepTreeElement *deps;
CODE:
    dTARG;
    /* warn("calling build_dep_tree"); */
deps = build_dep_tree(pe_file, search_paths, datarelocs, recursive, functionrelocs);
    /* warn("build_dep_tree is back: %p", deps); */
    if (deps == NULL) {
        Perl_croak(aTHX_ "BuildDepTree failed");
    }
    RETVAL = DepTreeElement2sv(deps, (HV*)sv_2mortal((SV*)newHV()));
OUTPUT:
    RETVAL

