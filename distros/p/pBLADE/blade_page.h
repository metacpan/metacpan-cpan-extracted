#ifndef _BLADE_PM_BLADE_PAGE_H
#define _BLADE_PM_BLADE_PAGE_H

extern void register_blade_page_callbacks(SV *body_code, SV *init_code, SV *halt_code, SV *data);
extern void blade_page_body_wrapper(blade_env *blade, void *data);
extern void blade_page_init_wrapper(blade_env *blade, void *data);
extern void blade_page_halt_wrapper(blade_env *blade, void *data);

#endif /* _BLADE_PM_BLADE_PAGE_H */
