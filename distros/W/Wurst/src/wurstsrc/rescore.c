/*
 * 5 April 2002
 * Thomas' rescoring function using tanh() functional form.
 * Essentially the same function as from early sausage code, but
 * with a revised interface for wurst.
 *
 * What names should the functions have ? Unfortunately, I do not know.
 * The functions should have long informative names which make
 * their historical basis clear. They should also have nice
 * clean short names which look nice in perl scripts.
 *
 * $Id: rescore.c,v 1.1 2007/09/28 16:57:08 mmundry Exp $
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "e_malloc.h"
#include "rmacros.h"
#include "seq.h"
#include "coord.h"
#include "coord_i.h"
#include "read_seq_i.h"
#include "fio.h"
#include "mprintf.h"
#include "misc.h"
#include "rescore.h"






/* ---------------- Constants    ------------------------------
 */
#ifndef BUFSIZ
    enum {BUFSIZ = 1024};
#endif
#ifndef ZERO_AA
    enum {ZERO_AA = 20};
#endif
#include "cp_cc_allat+0.h"


/* ---------------- STANDART_BLOCK   --------------------------
 * Once I turned this into a function. It ran at the same speed
 * on a sun. I guess it made smaller code.
 */
#define STANDART_BLOCK(ri, rj, r0, n) \
            dr.x = ri->x - rj->x; \
            dr.y = ri->y - rj->y; \
            dr.z = ri->z - rj->z; \
            d = VECTOR_SQR_LENGTH(dr); \
            if (d < CUTOFF_SQR) { \
                d = sqrt(d); \
                d = (d - r0) * WIDTH_FACTOR; \
                d = 1.0 - tanh(d); \
                Xf[n] += d; \
            }


/* ---------------- ContactEFunction --------------------------

 * Give her a protein model stored in a coord structure and
 * MR_PARAM parameters in *P for re-scoring and that routine's
 * returnin' the score
 *
 * cnt = help vector of size c->size to count neighbours
 * Xf  = help vector of size NR_PARAM avoid multiplication
 *       in inner loop
 * Sorry, this was called ContactEFunction. It has been called
 * score_rs, for consistency with other score functions here.
*/
static float
ContactEFunction( const struct coord *c, const float *P)
{
    char            *aa;
    int             i, j, aai, aaj, aai2, n, nr_aa;
    float           *cnt, *Xf;           /* scratch arrays, see note above */
    float           d, cnti, E;
    struct RPoint   dr;
    struct RPoint   *ri__N, *ri_CA, *ri_CB, *ri__C, *ri__O;
    struct RPoint   *rj__N, *rj_CA, *rj_CB, *rj__C, *rj__O;
    struct RPoint   *r__N, *r_CA, *r_CB, *r__C, *r__O;
    size_t          tmpcnt, tmpXf;
    struct seq      *s;
    const char      *this_sub = "ContactEFunction";

    nr_aa = c->size;
    s = c->seq;
    seq_std2thomas (s);  /* Force Thomas style names for amino acids */
    aa = s->seq;
    r__N = c->rp_n;
    r_CA = c->rp_ca;
    r_CB = c->rp_cb;
    r__C = c->rp_c;
    r__O = c->rp_o;

    cnt = (float *) E_MALLOC ( tmpcnt = (nr_aa * sizeof (float)));
    memset (cnt, 0, tmpcnt);
    Xf =  (float *) E_MALLOC ( tmpXf = (NR_PARAM * sizeof (float)));
    memset (Xf, 0, tmpXf);


    for (i = 0; i < nr_aa-2; i++) {
        j = i + 2;
        aai = aa[i];
        aaj = aa[j];
        if ((aai != ZERO_AA) && (aaj != ZERO_AA)) {
            ri__N = &r__N[i];
            ri_CA = &r_CA[i];
            ri_CB = &r_CB[i];
            ri__C = &r__C[i];
            ri__O = &r__O[i];
            rj__N = &r__N[j];
            rj_CA = &r_CA[j];
            rj_CB = &r_CB[j];
            rj__C = &r__C[j];
            rj__O = &r__O[j];

            STANDART_BLOCK(ri__N, rj__N, R01__N__N,     START1__N__N)
            STANDART_BLOCK(ri__N, rj_CA, R01__N_CA,     START1__N_CA)
            STANDART_BLOCK(ri__N, rj_CB, R01__N_CB, aaj+START1__N_CB)
            STANDART_BLOCK(ri__N, rj__C, R01__N__C,     START1__N__C)
            STANDART_BLOCK(ri__N, rj__O, R01__N__O,     START1__N__O)

            STANDART_BLOCK(ri_CA, rj__N, R01_CA__N,     START1_CA__N)
            STANDART_BLOCK(ri_CA, rj_CA, R01_CA_CA,     START1_CA_CA)
            STANDART_BLOCK(ri_CA, rj_CB, R01_CA_CB, aaj+START1_CA_CB)
            STANDART_BLOCK(ri_CA, rj__C, R01_CA__C,     START1_CA__C)
            STANDART_BLOCK(ri_CA, rj__O, R01_CA__O,     START1_CA__O)

            STANDART_BLOCK(ri_CB, rj__N, R01_CB__N, aai+START1_CB__N)
            STANDART_BLOCK(ri_CB, rj_CA, R01_CB_CA, aai+START1_CB_CA)
            if (aai < aaj)
                n = aai + aaj*(aaj+1)/2;
            else
            n = aaj + aai*(aai+1)/2;
            STANDART_BLOCK(ri_CB, rj_CB, R01_CB_CB,   n+START1_CB_CB)
            STANDART_BLOCK(ri_CB, rj__C, R01_CB__C, aai+START1_CB__C)
            STANDART_BLOCK(ri_CB, rj__O, R01_CB__O, aai+START1_CB__O)

            STANDART_BLOCK(ri__C, rj__N, R01__C__N,     START1__C__N)
            STANDART_BLOCK(ri__C, rj_CA, R01__C_CA,     START1__C_CA)
            STANDART_BLOCK(ri__C, rj_CB, R01__C_CB, aaj+START1__C_CB)
            STANDART_BLOCK(ri__C, rj__C, R01__C__C,     START1__C__C)
            STANDART_BLOCK(ri__C, rj__O, R01__C__O,     START1__C__O)

            STANDART_BLOCK(ri__O, rj__N, R01__O__N,     START1__O__N)
            STANDART_BLOCK(ri__O, rj_CA, R01__O_CA,     START1__O_CA)
            STANDART_BLOCK(ri__O, rj_CB, R01__O_CB, aaj+START1__O_CB)
            STANDART_BLOCK(ri__O, rj__C, R01__O__C,     START1__O__C)
            STANDART_BLOCK(ri__O, rj__O, R01__O__O,     START1__O__O)
        }
    }

    for (i = 0; i < nr_aa-3; i++) {
        j = i + 3;
        aai = aa[i];
        aaj = aa[j];
        if ((aai != ZERO_AA) && (aaj != ZERO_AA)) {
            ri__N = &r__N[i];
            ri_CA = &r_CA[i];
            ri_CB = &r_CB[i];
            ri__C = &r__C[i];
            ri__O = &r__O[i];
            rj__N = &r__N[j];
            rj_CA = &r_CA[j];
            rj_CB = &r_CB[j];
            rj__C = &r__C[j];
            rj__O = &r__O[j];

            STANDART_BLOCK(ri__N, rj__N, R02__N__N,     START2__N__N)
            STANDART_BLOCK(ri__N, rj_CA, R02__N_CA,     START2__N_CA)
            STANDART_BLOCK(ri__N, rj_CB, R02__N_CB, aaj+START2__N_CB)
            STANDART_BLOCK(ri__N, rj__C, R02__N__C,     START2__N__C)
            STANDART_BLOCK(ri__N, rj__O, R02__N__O,     START2__N__O)

            STANDART_BLOCK(ri_CA, rj__N, R02_CA__N,     START2_CA__N)
            STANDART_BLOCK(ri_CA, rj_CA, R02_CA_CA,     START2_CA_CA)
            STANDART_BLOCK(ri_CA, rj_CB, R02_CA_CB, aaj+START2_CA_CB)
            STANDART_BLOCK(ri_CA, rj__C, R02_CA__C,     START2_CA__C)
            STANDART_BLOCK(ri_CA, rj__O, R02_CA__O,     START2_CA__O)

            STANDART_BLOCK(ri_CB, rj__N, R02_CB__N, aai+START2_CB__N)
            STANDART_BLOCK(ri_CB, rj_CA, R02_CB_CA, aai+START2_CB_CA)
            if (aai < aaj)
                n = aai + aaj*(aaj+1)/2;
            else
            n = aaj + aai*(aai+1)/2;
            STANDART_BLOCK(ri_CB, rj_CB, R02_CB_CB,   n+START2_CB_CB)
            STANDART_BLOCK(ri_CB, rj__C, R02_CB__C, aai+START2_CB__C)
            STANDART_BLOCK(ri_CB, rj__O, R02_CB__O, aai+START2_CB__O)

            STANDART_BLOCK(ri__C, rj__N, R02__C__N,     START2__C__N)
            STANDART_BLOCK(ri__C, rj_CA, R02__C_CA,     START2__C_CA)
            STANDART_BLOCK(ri__C, rj_CB, R02__C_CB, aaj+START2__C_CB)
            STANDART_BLOCK(ri__C, rj__C, R02__C__C,     START2__C__C)
            STANDART_BLOCK(ri__C, rj__O, R02__C__O,     START2__C__O)

            STANDART_BLOCK(ri__O, rj__N, R02__O__N,     START2__O__N)
            STANDART_BLOCK(ri__O, rj_CA, R02__O_CA,     START2__O_CA)
            STANDART_BLOCK(ri__O, rj_CB, R02__O_CB, aaj+START2__O_CB)
            STANDART_BLOCK(ri__O, rj__C, R02__O__C,     START2__O__C)
            STANDART_BLOCK(ri__O, rj__O, R02__O__O,     START2__O__O)
        }
    }

    for (i = 0; i < nr_aa-4; i++) {
        aai = aa[i];
        if (aai != ZERO_AA) {
            aai2 = aai * (aai + 1) / 2;
            ri__N = &r__N[i];
            ri_CA = &r_CA[i];
            ri_CB = &r_CB[i];
            ri__C = &r__C[i];
            ri__O = &r__O[i];
            cnti = 0.0;
            for (j = i+4; j < nr_aa; j++) {
                aaj = aa[j];
                if (aaj != ZERO_AA) {
                    rj_CA = &r_CA[j];
                    dr.x = ri_CA->x - rj_CA->x;      /* CA - CA interaction */
                    dr.y = ri_CA->y - rj_CA->y;
                    dr.z = ri_CA->z - rj_CA->z;
                    d = VECTOR_SQR_LENGTH(dr);
                    if (d < CA_CA_CUTOFF_SQR) {
                        if (d < CUTOFF_SQR) {
                            d = sqrt(d);
                            d = (d - R03_CA_CA) * WIDTH_FACTOR;
                            d = 1.0 - tanh(d);
                            cnti += d;
                            cnt[j] += d;
                            Xf[START3_CA_CA] += d;
                        }

                        rj__N = &r__N[j];
                        rj_CB = &r_CB[j];
                        rj__C = &r__C[j];
                        rj__O = &r__O[j];
                        STANDART_BLOCK(ri__N, rj__N, R03__N__N,     START3__N__N)
                        STANDART_BLOCK(ri__N, rj_CA, R03__N_CA,     START3__N_CA)
                        STANDART_BLOCK(ri__N, rj_CB, R03__N_CB, aaj+START3__N_CB)
                        STANDART_BLOCK(ri__N, rj__C, R03__N__C,     START3__N__C)
                        STANDART_BLOCK(ri__N, rj__O, R03__N__O,     START3__N__O)

                       STANDART_BLOCK(ri_CA, rj__N, R03_CA__N,     START3_CA__N)
/*                        CA--CA see above  */
                       STANDART_BLOCK(ri_CA, rj_CB, R03_CA_CB, aaj+START3_CA_CB)
                       STANDART_BLOCK(ri_CA, rj__C, R03_CA__C,     START3_CA__C)
                       STANDART_BLOCK(ri_CA, rj__O, R03_CA__O,     START3_CA__O)

                       STANDART_BLOCK(ri_CB, rj__N, R03_CB__N, aai+START3_CB__N)
                       STANDART_BLOCK(ri_CB, rj_CA, R03_CB_CA, aai+START3_CB_CA)
                       if (aai < aaj)
                           n = aai + aaj*(aaj+1)/2;
                       else
                           n = aaj + aai2;
                       STANDART_BLOCK(ri_CB, rj_CB, R03_CB_CB,   n+START3_CB_CB)
                       STANDART_BLOCK(ri_CB, rj__C, R03_CB__C, aai+START3_CB__C)
                       STANDART_BLOCK(ri_CB, rj__O, R03_CB__O, aai+START3_CB__O)

                       STANDART_BLOCK(ri__C, rj__N, R03__C__N,     START3__C__N)
                       STANDART_BLOCK(ri__C, rj_CA, R03__C_CA,     START3__C_CA)
                       STANDART_BLOCK(ri__C, rj_CB, R03__C_CB, aaj+START3__C_CB)
                       STANDART_BLOCK(ri__C, rj__C, R03__C__C,     START3__C__C)
                       STANDART_BLOCK(ri__C, rj__O, R03__C__O,     START3__C__O)

                       STANDART_BLOCK(ri__O, rj__N, R03__O__N,     START3__O__N)
                       STANDART_BLOCK(ri__O, rj_CA, R03__O_CA,     START3__O_CA)
                       STANDART_BLOCK(ri__O, rj_CB, R03__O_CB, aaj+START3__O_CB)
                       STANDART_BLOCK(ri__O, rj__C, R03__O__C,     START3__O__C)
                       STANDART_BLOCK(ri__O, rj__O, R03__O__O,     START3__O__O)

                    } /* if (CA_CA_distance < CA_CA_CUTOFF_SQR) */
                }     /* if (aaj != ZERO_AA) */
            }     /* for all j aa */
            cnt[i] += cnti;
        }      /* if (aai != ZERO_AA) */
    }         /* for all i aa */

    for (i = 0; i < nr_aa; i++) {
        d = (cnt[i] - NR_NEIGHBOUR);
        d = 1.0 - tanh(d);
        n = START4_NEIGHBOUR + aa[i];
        if (n >= NR_PARAM) {
            err_printf (this_sub, "n: %d >= NR_PARAM: %d. Disaster.\n", n, NR_PARAM);
            err_printf (this_sub, "Stopping at %s: %d\n", __FILE__, __LINE__);
            exit (EXIT_FAILURE);
        }
        Xf[n] += d;
    }

    E = 0.0;
    for (i = 0; i < NR_PARAM; i++)
        E += Xf[i] * P[i];

    free (Xf);
    free (cnt);

    return -E;
}

/* ---------------- score_rs   --------------------------------
 * This just calls Thomas' function, but it lets us leave his
 * name in the source code. Since Thomas' function is statically
 * declared, above, there is really no overhead.
 */
float
score_rs ( struct coord *c, const float *P)
{
    float r;
    coord_a_2_nm (c);  /* Convert to nanometers for Thomas */
    
    r = ContactEFunction (c, P);
    coord_nm_2_a (c);  /* Back to angstrom */
    return (r);
}

/* ---------------- param_rs_read  ----------------------------
 */
float *
param_rs_read(const char *fname)
{
    FILE       *fp;
    char       *p;
    char       buf[BUFSIZ];
    const char *this_sub = "ReadRescoreParam";
    int        i, n;
    float      *P;

    int nline = 0;
    if ((fp = mfopen (fname, "r", this_sub)) == NULL)
        return NULL;
    p = get_nline (fp, buf, &nline, BUFSIZ); /* Title not interesting */
    if (!p) {
        err_printf (this_sub, "No number of parameters\n");
        P = NULL;
        goto end;
    }

    sscanf(p, "%i", &n);
    if (n != NR_PARAM) {
        err_printf (this_sub, "Wrong number of parameters\n");
        P = NULL;
        goto end;
    }

    P =  (float *) E_MALLOC (NR_PARAM * sizeof (P[0]));

    for (i = 0; i < n; i++) {
        p = get_nline (fp, buf, &nline, BUFSIZ); /* Title not interesting */
        sscanf(p, "%f", &P[i]);
    }
    p = get_nline (fp, buf, &nline, BUFSIZ); /* Title not interesting */
    if (p[0] != '@') {
        err_printf (this_sub, "No End character found in Rescore Param: You better check this!\n");
        P = NULL;
        goto end;
    }

 end:
    fclose (fp);
    return P;
}

/* ---------------- RescoreParam_destroy ----------------------
 */
void
param_rs_destroy (float *p)
{
    free_if_not_null(p);
}
