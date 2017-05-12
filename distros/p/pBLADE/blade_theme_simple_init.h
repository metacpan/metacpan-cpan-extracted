#ifndef _BLADE_PM_BLADE_THEME_SIMPLE_INIT_H
#define _BLADE_PM_BLADE_THEME_SIMPLE_INIT_H

extern void register_blade_theme_simple_init_callbacks(SV *start_code, SV *end_code, SV *init_code, SV *data);
extern void blade_theme_simple_init_start_wrapper(blade_env *blade, CORBA_char *blar_title, CORBA_char *page_title, CORBA_char *head, void *data);
extern void blade_theme_simple_init_end_wrapper(blade_env *blade, CORBA_char *blar_title, CORBA_char *page_title, void *data);
extern void blade_theme_simple_init_init_wrapper(blade_env *blade, void *data);

#endif /* _BLADE_PM_BLADE_THEME_SIMPLE_INIT_H */
