/*
 * 23 October 2001
 * This defines the interface to the coordinate routines.
 * It does *not* define the internal structures.
 * rcsid = $Id: coord_i.h,v 1.1 2007/09/28 16:57:10 mmundry Exp $
 */

#ifndef COORD_I_H
#define COORD_I_H

struct coord;
int            coord_2_bin (struct coord *c, const char *fname);
char *         coord_name (struct coord *c);
size_t         coord_size (const struct coord *c);
struct coord * coord_read (const char *fname);
struct seq   * coord_get_seq (struct coord *c);
void           coord_calc_psi (struct coord *c);
void           coord_calc_phi (struct coord *c);
float
            coord_psi (struct coord *c, const size_t i, const float shift_min);
float
            coord_phi (struct coord *c, const size_t j, const float shift_min);
void           coord_nm_2_a (struct coord *c);
void           coord_a_2_nm (struct coord *c);
struct coord * coord_template (const struct coord *c, size_t i );
struct coord * coord_trim (struct coord *c, const size_t size);
void           coord_destroy (struct coord *c);
int            coord_has_sec_s (const struct coord *c);
float          coord_c_n_dist (const struct coord *c,
                               const unsigned int i, const unsigned int j,
                               const unsigned int sqrt_flag);
#endif  /* COORD_I_H */
