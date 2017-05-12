/*
 * 10 Jan 2002
 * Read parameters for the score_fx function.
 * $Id: param_fx.c,v 1.1 2007/09/28 16:57:03 mmundry Exp $
 */

#include <stdio.h>
#include <stdlib.h>

#include "fio.h"
#include "fx.h"
#include "param_fx_i.h"
#include "e_malloc.h"
#include "matrix.h"
#include "mprintf.h"

/* ---------------- Constants   -------------------------------
 */
enum {MAX_LINE_LEN = 200 };
enum {                    
    MAX_NR_GROUPS = 10000,  /* These two are maximum numbers so we can */
    MAX_NR_INST   = 50      /* check for sanity after reading them from file */
};

/* ---------------- param_read_fx -----------------------------
 */

struct FXParam *
param_fx_read (const char *filename)
{
    struct FXParam *fx;
    char  line[MAX_LINE_LEN], *pos;
    long unsigned lutmp;
    size_t i, j;
    int  k;
    FILE    *f;
    const char *this_sub = "param_read_fx";
    const char *broke_continuing =
        "%s appears to be %ld\nfrom file \"%s\"\nContinuing anyway\n";
    const char *scanf_fail =
        "Wanted %d real numbers from\n\"%s\"\n. Failed\n";

    fx = E_MALLOC (sizeof (*fx));

    if (! (f = mfopen(filename, "r", this_sub)))
        return NULL;

    if (fgets(line, MAX_LINE_LEN, f) == NULL)
        return NULL;
    sscanf(line, "%lu", &lutmp);
    if (lutmp > MAX_NR_INST)
        err_printf (this_sub, broke_continuing, "nr_inst", lutmp, filename);
    fx->nr_inst = (size_t) lutmp;
    if (fgets(line, MAX_LINE_LEN, f) == NULL)
        return NULL;
    sscanf(line, "%lu", &lutmp);
    if (lutmp > MAX_NR_GROUPS)
        err_printf (this_sub, broke_continuing, "nr_groups", lutmp, filename);
    fx->nr_groups = lutmp;
    fx->cw       = E_MALLOC (fx->nr_groups * sizeof (fx->cw[0]));
    fx->Ijk      = f_matrix(fx->nr_groups, fx->nr_inst);
    fx->Ijk_nbr  = f_matrix(fx->nr_groups, fx->nr_inst);
    fx->Ijk_psi  = f_matrix(fx->nr_groups, fx->nr_inst);
    fx->Ijk_dist = E_MALLOC (fx->nr_groups * sizeof (fx->Ijk_dist[0]));
    fx->pdav     = E_MALLOC (fx->nr_groups * sizeof (fx->pdav[0]));
    fx->pdsig    = E_MALLOC (fx->nr_groups * sizeof (fx->pdsig[0]));
    fx->psi      = f_matrix(fx->nr_groups, fx->nr_inst);
    fx->dpsi     = f_matrix(fx->nr_groups, fx->nr_inst);
    fx->paa      = E_MALLOC (fx->nr_groups * sizeof (fx->paa[0]));
    fx->pna      = E_MALLOC (fx->nr_groups * sizeof (fx->pna[0]));
    for (i = 0; i < fx->nr_groups; i++) {
        fx->paa[i] = f_matrix(fx->nr_inst, 21);
        fx->pna[i] = f_matrix(fx->nr_inst, 20);
    }
    for (i = 0; i < fx->nr_groups; i++) {
        if (fgets(line, MAX_LINE_LEN, f) == NULL)
            return NULL;
        sscanf(line, "%f", &fx->cw[i]);
    }

    for (i = 0; i < fx->nr_groups; i++) {
        int rr;
        if (fgets(line, MAX_LINE_LEN, f) == NULL)
            return NULL;
        if (fgets(line, MAX_LINE_LEN, f) == NULL)
            return NULL;
                                        /* end distance parameters */
        if (fgets(line, MAX_LINE_LEN, f) == NULL)
            return NULL;
        rr =
         sscanf(line, "%f%f%f", &fx->Ijk_dist[i], &fx->pdav[i], &fx->pdsig[i]);
        if (rr != 3) {
            err_printf (this_sub, scanf_fail, 3, line);
            fclose (f);
            return (NULL);
        }
        for (j = 0; j < fx->nr_inst; j++) {
            int r;
            if (fgets(line, MAX_LINE_LEN, f) == NULL)
                return NULL;
            r = sscanf(line, "%f%f%f%f%f", &fx->Ijk[i][j],
                   &fx->Ijk_psi[i][j], &fx->Ijk_nbr[i][j],
                   &fx->psi[i][j], &fx->dpsi[i][j]);
            if (r != 5) {
                err_printf (this_sub, scanf_fail, 5, line);
                fclose (f);
                return NULL;
            }
            if (fx->psi[i][j] > 180)
                fx->psi[i][j] -= 360;
        }

        for (k = 0; k < 21; k++) {
            if (fgets(line, MAX_LINE_LEN, f) == NULL)
                return NULL;
            pos = &line[1];
            for (j = 0; j < fx->nr_inst; j++) {
                sscanf(pos, "%f", &fx->paa[i][j][k]);
                pos += 10;
            }
        }
        for (k = 0; k < 20; k++) {
            if (fgets(line, MAX_LINE_LEN, f) == NULL)
                return NULL;
            pos = &line[2];
            for (j = 0; j < fx->nr_inst; j++) {
                sscanf(pos, "%f", &fx->pna[i][j][k]);
                pos += 10;
            }
        }
    }
    if (fgets(line, MAX_LINE_LEN, f) == NULL)
        return NULL;
    sscanf(line, "%lu", &lutmp);
    fx->nr_dbins = lutmp;

    fx->dbin = E_MALLOC (fx->nr_dbins * sizeof (fx->dbin[0]));
    for (i = 0; i < fx->nr_dbins; i++) {
        if (fgets(line, MAX_LINE_LEN, f) == NULL)
            return NULL;
        sscanf(line, "%f", &fx->dbin[i]);
    }
    fclose(f);
    return fx;
}


/* ---------------- FXParam_destroy ---------------------------
 */

void
FXParam_destroy (FXParam *fx)
{
    size_t i;
    if (!fx)
        return;
    free(fx->cw);
    free(fx->Ijk[0]);
    free(fx->Ijk);
    free(fx->Ijk_nbr[0]);
    free(fx->Ijk_nbr);
    free(fx->Ijk_psi[0]);
    free(fx->Ijk_psi);
    free(fx->Ijk_dist);
    free(fx->pdav);
    free(fx->pdsig);
    free(fx->psi[0]);
    free(fx->psi);
    free(fx->dpsi[0]);
    free(fx->dpsi);
    for (i = 0; i < fx->nr_groups; i++) {
        free(fx->paa[i][0]);
        free(fx->paa[i]);
        free(fx->pna[i][0]);
        free(fx->pna[i]);
    }
    free(fx->paa);
    free(fx->pna);
    free(fx->dbin);
    free(fx);
}



#ifdef TESTME
int main(int argc, char *argv[])
{
    FXParam  fx;


    ReadFXParam(argv[1], &fx);

    FreeFXparam(&fx);

    return 0;
}
#endif
