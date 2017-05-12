#ifndef _BLADE_PM_BLADE_OBJ_SIMPLE_INIT_H
#define _BLADE_PM_BLADE_OBJ_SIMPLE_INIT_H

extern void register_blade_obj_simple_init_callback(SV *code, SV *data);
extern void blade_obj_simple_init_wrapper(blade_env *blade, CORBA_char *name, CORBA_char *args, void *data);

#endif /* _BLADE_PM_BLADE_OBJ_SIMPLE_INIT_H */
