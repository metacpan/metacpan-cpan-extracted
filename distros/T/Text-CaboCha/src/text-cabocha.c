#include "text-cabocha.h"
#ifndef  __TEXT_CABOCHA_C__
#define  __TEXT_CABOCHA_C__

void
TextCaboCha_bootstrap()
{
    HV *stash;
    stash = gv_stashpv("Text::CaboCha", TRUE);
    newCONSTSUB(stash, "CABOCHA_VERSION", newSVpvf("%s", CaboCha::Parser::version()));
    newCONSTSUB(stash, "CABOCHA_TARGET_VERSION", newSVpvf("%d.%02d", CABOCHA_MAJOR_VERSION, CABOCHA_MINOR_VERSION) );
    newCONSTSUB(stash, "CABOCHA_TARGET_MAJOR_VERSION", newSVpvf("%d", CABOCHA_MAJOR_VERSION));
    newCONSTSUB(stash, "CABOCHA_TARGET_MINOR_VERSION", newSVpvf("%d", CABOCHA_MINOR_VERSION));
    newCONSTSUB(stash, "ENCODING", newSVpvf("%s", TEXT_CABOCHA_ENCODING) );
    newCONSTSUB(stash, "CABOCHA_CONFIG", newSVpvf("%s", TEXT_CABOCHA_CONFIG));
}

TextCaboCha *
TextCaboCha_create(char **argv, unsigned int argc)
{
    TextCaboCha *cabocha;
    CaboCha::Parser *parser;
#if TEXT_CABOCHA_DEBUG
    {
        unsigned int i;

        PerlIO_printf(PerlIO_stderr(), "TextCaboCha_new called\n");
        for (i = 0; i < argc; i++) {
            PerlIO_printf(PerlIO_stderr(), "  arg %d: %s\n", i, argv[i]);
        }
    }
#endif

    parser = CaboCha::createParser(argc, argv);
    if (parser == NULL) {
        return NULL;
    }

    Newxz(cabocha, 1, TextCaboCha);
    cabocha->cabocha = parser;
    cabocha->argc  = argc;
    if (argc > 0) {
        unsigned int i;
        Newxz(cabocha->argv, argc, char *);
        for (i = 0; i < argc; i++) {
            int len = strlen(argv[i]) + 1;
            Newxz(cabocha->argv[i], len, char);
            Copy(argv[i], cabocha->argv[i], len, char);
        }
    }
    return cabocha;
}

TextCaboCha *
TextCaboCha_create_from_av(AV *av)
{
    char **argv = NULL;
    unsigned int argc;
    TextCaboCha *cabocha;

    argc = av_len(av) + 1;

    if (argc > 0) {
        unsigned int i;
        SV **svr;

        Newz(1234, argv, argc, char *);
        for (i = 0; i < argc; i++) {
            svr = av_fetch(av, i, 0);
            if (svr == NULL || !SvOK(*svr)) {
                Safefree(argv);
                croak("bad argument at index %d", i);
            }
            argv[i] = SvPV_nolen(*svr);
        }
    }
    cabocha = TextCaboCha_create(argv, argc);
    if (cabocha == NULL) {
        if (argc > 0) {
            Safefree(argv);
        }
        croak("Failed to create cabocha instance: %s", CaboCha::getParserError());
    }

    if (argc > 0) {
        Safefree(argv);
    }

    return cabocha;
}

TextCaboCha_Tree *
TextCaboCha_parse(TextCaboCha *cabocha, char *string)
{
    TextCaboCha_Tree *tree;

    tree = (TextCaboCha_Tree *)XS_2CABOCHA(cabocha)->parse(string);
    if (tree == NULL) {
        croak("CaboCha::Parser->parse(str) failed: %s", XS_2CABOCHA(cabocha)->what());
    }
    return tree;
}

TextCaboCha_Tree *
TextCaboCha_parse_from_node(TextCaboCha *cabocha, const TextMeCab_Node *node)
{
    if (node == NULL) {
        croak("Text::MeCab::Node is null");
    }

    CaboCha::Tree *t = new CaboCha::Tree;
    if (!t->read(node)) {
        croak("CaboCha::Parser->parse_from_node(Text::MeCab::Node) failed: %s", XS_2CABOCHA(cabocha)->what());
    }

    return (TextCaboCha_Tree *)XS_2CABOCHA(cabocha)->parse(t);
}

#endif /* __TEXT_CABOCHA_C__ */