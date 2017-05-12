/*
 * 5 April 2002
 * Definitions of pieces of array for ContactEFunction.
 * rcsid = $Id: cp_cc_allat+0.h,v 1.1 2007/09/28 16:57:11 mmundry Exp $
 */

#ifndef CP_ALLAT_H
#define CP_ALLAT_H

enum { NR_PARAM = 996 };

enum {
    START1__N__N = 0,
    START1__N_CA = 1,
    START1__N_CB = 2,
    START1__N__C = 23,
    START1__N__O = 24,
    START1_CA__N = START1__N_CA,
    START1_CA_CA = 25,
    START1_CA_CB = 26,
    START1_CA__C = 47,
    START1_CA__O = 48,
    START1_CB__N = START1__N_CB,
    START1_CB_CA = START1_CA_CB,
    START1_CB_CB = 49,
    START1_CB__C = 280,
    START1_CB__O = 301,
    START1__C__N = START1__N__C,
    START1__C_CA = START1_CA__C,
    START1__C_CB = START1_CB__C,
    START1__C__C = 322,
    START1__C__O = 323,
    START1__O__N = START1__N__O,
    START1__O_CA = START1_CA__O,
    START1__O_CB = START1_CB__O,
    START1__O__C = START1__C__O,
    START1__O__O = 324,

    START2__N__N = 325,
    START2__N_CA = 326,
    START2__N_CB = 327,
    START2__N__C = 348,
    START2__N__O = 349,
    START2_CA__N = START2__N_CA,
    START2_CA_CA = 350,
    START2_CA_CB = 351,
    START2_CA__C = 372,
    START2_CA__O = 373,
    START2_CB__N = START2__N_CB,
    START2_CB_CA = START2_CA_CB,
    START2_CB_CB = 374,
    START2_CB__C = 605,
    START2_CB__O = 626,
    START2__C__N = START2__N__C,
    START2__C_CA = START2_CA__C,
    START2__C_CB = START2_CB__C,
    START2__C__C = 647,
    START2__C__O = 648,
    START2__O__N = START2__N__O,
    START2__O_CA = START2_CA__O,
    START2__O_CB = START2_CB__O,
    START2__O__C = START2__C__O,
    START2__O__O = 649,

    START3__N__N = 650,
    START3__N_CA = 651,
    START3__N_CB = 652,
    START3__N__C = 673,
    START3__N__O = 674,
    START3_CA__N = START3__N_CA,
    START3_CA_CA = 675,
    START3_CA_CB = 676,
    START3_CA__C = 697,
    START3_CA__O = 698,
    START3_CB__N = START3__N_CB,
    START3_CB_CA = START3_CA_CB,
    START3_CB_CB = 699,
    START3_CB__C = 930,
    START3_CB__O = 951,
    START3__C__N = START3__N__C,
    START3__C_CA = START3_CA__C,
    START3__C_CB = START3_CB__C,
    START3__C__C = 972,
    START3__C__O = 973,
    START3__O__N = START3__N__O,
    START3__O_CA = START3_CA__O,
    START3__O_CB = START3_CB__O,
    START3__O__C = START3__C__O,
    START3__O__O = 974,


    START4_NEIGHBOUR = 975
};

static const float
    WIDTH_FACTOR     = 30.0,
    NR_NEIGHBOUR     =  3.0,
    CUTOFF_SQR       =  0.64,
    CA_CA_CUTOFF_SQR =  1.0;

#define R01__N_CB    0.6
#define R01_CA_CB    0.5
#define R01_CB_CB    0.65
#define R01__C_CB    0.56
#define R01__O_CB    0.5
#define R01__N_CA    0.6
#define R01_CA_CA    0.58
#define R01_CB_CA    R01_CA_CB
#define R01__C_CA    0.62
#define R01__O_CA    0.5
#define R01__N__N    0.54
#define R01_CA__N    R01__N_CA
#define R01_CB__N    R01__N_CB
#define R01__C__N    0.45
#define R01__O__N    0.35
#define R01__N__C    R01__C__N
#define R01_CA__C    R01__C_CA
#define R01_CB__C    R01__C_CB
#define R01__C__C    0.55
#define R01__O__C    0.5
#define R01__N__O    R01__O__N
#define R01_CA__O    R01__O_CA
#define R01_CB__O    R01__O_CB
#define R01__C__O    R01__O__C
#define R01__O__O    0.55

#define R02__N_CB    0.6
#define R02_CA_CB    0.5
#define R02_CB_CB    0.65
#define R02__C_CB    0.56
#define R02__O_CB    0.5
#define R02__N_CA    0.6
#define R02_CA_CA    0.58
#define R02_CB_CA    R02_CA_CB
#define R02__C_CA    0.62
#define R02__O_CA    0.5
#define R02__N__N    0.54
#define R02_CA__N    R02__N_CA
#define R02_CB__N    R02__N_CB
#define R02__C__N    0.45
#define R02__O__N    0.35
#define R02__N__C    R02__C__N
#define R02_CA__C    R02__C_CA
#define R02_CB__C    R02__C_CB
#define R02__C__C    0.55
#define R02__O__C    0.5
#define R02__N__O    R02__O__N
#define R02_CA__O    R02__O_CA
#define R02_CB__O    R02__O_CB
#define R02__C__O    R02__O__C
#define R02__O__O    0.55

#define R03__N_CB    0.6
#define R03_CA_CB    0.5
#define R03_CB_CB    0.65
#define R03__C_CB    0.56
#define R03__O_CB    0.5
#define R03__N_CA    0.6
#define R03_CA_CA    0.58
#define R03_CB_CA    R03_CA_CB
#define R03__C_CA    0.62
#define R03__O_CA    0.5
#define R03__N__N    0.54
#define R03_CA__N    R03__N_CA
#define R03_CB__N    R03__N_CB
#define R03__C__N    0.45
#define R03__O__N    0.35
#define R03__N__C    R03__C__N
#define R03_CA__C    R03__C_CA
#define R03_CB__C    R03__C_CB
#define R03__C__C    0.55
#define R03__O__C    0.5
#define R03__N__O    R03__O__N
#define R03_CA__O    R03__O_CA
#define R03_CB__O    R03__O_CB
#define R03__C__O    R03__O__C
#define R03__O__O    0.55

#endif /* CP_ALLAT_H */
