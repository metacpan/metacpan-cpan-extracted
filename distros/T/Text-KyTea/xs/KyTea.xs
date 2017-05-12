#define PERL_NO_GET_CONTEXT
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif

#include <cstddef> // size_t
#include <string>
#include <vector>
#include <kytea/kytea.h>
#include <kytea/kytea-struct.h>
#include <kytea/string-util.h>

typedef kytea::KyteaSentence  kytea_KyteaSentence;
typedef std::string           std_string;

namespace text_kytea
{
    const std::string tkt_keys[4] = {"surface", "feature", "score", "tags"};

    class TextKyTea
    {
        private:
            kytea::Kytea          kytea;
            kytea::KyteaConfig*   config;
            unsigned int          prontag_num;
            std::string           deftag;
        public:
            kytea::StringUtil*  util;
            void                read_model(const char* const model)  { kytea.readModel(model); }

            void _init
            (
                const char* const model,       const bool nows,               const bool notags,
                const std::vector<unsigned int> notag,  const bool nounk,     const unsigned int unkbeam,
                const unsigned int tagmax,     const char* const deftag,      const char* const unktag,
                const char* const wordbound,   const char* const tagbound,    const char* const elembound,
                const char* const unkbound,    const char* const skipbound,   const char* const nobound,
                const char* const hasbound,    const unsigned int prontag_num
            )
            {
                read_model(model);
                util   = kytea.getStringUtil();
                config = kytea.getConfig();

                config->setDoWS(!nows);
                config->setDoTags(!notags);

                std::vector<unsigned int>::const_iterator iter;
                for (iter = notag.begin(); iter != notag.end(); ++iter)
                    config->setDoTag( (*iter) - 1, false );

                config->setDoUnk(!nounk);
                config->setUnkBeam(unkbeam);
                config->setTagMax(tagmax);
                config->setDefaultTag(deftag);
                config->setUnkTag(unktag);
                config->setWordBound(wordbound);
                config->setTagBound(tagbound);
                config->setElemBound(elembound);
                config->setUnkBound(unkbound);
                config->setSkipBound(skipbound);
                config->setNoBound(nobound);
                config->setHasBound(hasbound);

                TextKyTea::prontag_num = prontag_num;
                TextKyTea::deftag      = deftag;
            }
            kytea_KyteaSentence parse(const char* const text)
            {
                kytea::KyteaString surface_string = util->mapString(text);
                kytea::KyteaSentence sentence( surface_string, util->normalize(surface_string) );
                kytea.calculateWS(sentence);

                for (int i = 0; i < config->getNumTags(); ++i)
                    if ( config->getDoTag(i) ) kytea.calculateTags(sentence, i);

                return sentence;
            }
            std_string pron(const char* const text, const char* replacement = "")
            {
                kytea::KyteaString kytea_string = util->mapString(text);
                kytea::KyteaSentence sentence( kytea_string, util->normalize(kytea_string) );
                kytea.calculateWS(sentence);

                kytea.calculateTags(sentence, prontag_num);

                const kytea::KyteaSentence::Words& words = sentence.words;

                std::string pron;

                for (size_t i = 0; i < words.size(); ++i)
                {
                    std::string partial_pron = util->showString(words[i].tags[prontag_num][0].first);

                    if (partial_pron != deftag) pron += partial_pron;
                    else
                    {
                        if (replacement[0] == '\0') pron += util->showString(words[i].surface);
                        else                        pron += replacement;
                    }
                }

                return pron;
            }
    };
}

typedef text_kytea::TextKyTea  text_kytea_TextKyTea;

MODULE = Text::KyTea    PACKAGE = Text::KyTea

PROTOTYPES: DISABLE

text_kytea_TextKyTea *
_init_text_kytea(const char* const CLASS, SV* args_ref)
    CODE:
        HV* hv    = (HV*)sv_2mortal( (SV*)newHV() );
        AV* notag = (AV*)sv_2mortal( (SV*)newAV() );
        std::vector<unsigned int> notag_vec;

        hv    = (HV*)SvRV(args_ref);
        notag = (AV*)SvRV( *hv_fetchs(hv, "notag", FALSE) );

        for (int i = 0; av_len(notag) >= i; ++i)
            notag_vec.push_back( SvIV( *av_fetch(notag, i, FALSE) ) );

        text_kytea::TextKyTea* tkt = new text_kytea::TextKyTea();

        tkt->_init(
            SvPV_nolen( *hv_fetchs(hv, "model", FALSE) ),
            SvUV( *hv_fetchs(hv, "nows",    FALSE) ),
            SvUV( *hv_fetchs(hv, "notags",  FALSE) ),
            notag_vec,
            SvUV( *hv_fetchs(hv, "nounk",   FALSE) ),
            SvUV( *hv_fetchs(hv, "unkbeam", FALSE) ),
            SvUV( *hv_fetchs(hv, "tagmax",  FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "deftag",    FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "unktag",    FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "wordbound", FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "tagbound",  FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "elembound", FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "unkbound",  FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "skipbound", FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "nobound",   FALSE) ),
            SvPV_nolen( *hv_fetchs(hv, "hasbound",  FALSE) ),
            SvUV( *hv_fetchs(hv, "prontag_num",  FALSE) )
        );

        RETVAL = tkt;

    OUTPUT:
        RETVAL


void
text_kytea_TextKyTea::read_model(const char* const model)

kytea_KyteaSentence
text_kytea_TextKyTea::parse(const char* const text)

std_string
text_kytea_TextKyTea::pron(const char* const text, const char* replacement = "")
