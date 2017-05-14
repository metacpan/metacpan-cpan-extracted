@perl $user = $ENV{"USER"};
@foreach class_list          
@//-------------------------------------------------------------------------
@// Note: we are opening a new ".h" file within the foreach above ...
@perl print "Generating ${class_name}.h\n";
@openfile ${class_name}.h 
#ifndef _${class_name}_h_
#define _${class_name}_h_
#include <stdio.h>
// File : '${class_name}.h'
// User : "$user"
class $class_name {
@foreach attr_list
   $attr_type $attr_name;
@end
   $class_name(); // private constructor. Use Create()
public:
   // Methods
   $class_name* Create();
    ~$class_name();
   // Accessor Methods;
@foreach attr_list
   $attr_type   get_${attr_name}();
   void set_${attr_name}($attr_type);
@end .. attr_list
}
#endif
@end .. class_list
@//
@//-------------------------------------------------------------------------
@//
@perl print "db.sql\n";
@openfile db.sql 
@perl %db_typemap = ("int" => 'integer', string => 'varchar');
@foreach class_list
create table $class_name (
@foreach attr_list
@perl $typemap = $db_typemap{$attr_type};
     $attr_name $typemap,
@end
)
@end
