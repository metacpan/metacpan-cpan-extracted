MODULE = APR::Request::Hook    PACKAGE = APR::Request::Hook

APR::Request::Hook
make(class, pool, hook, next=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    apreq_hook_function_t hook
    APR::Request::Hook next

  CODE:
    RETVAL = apreq_hook_make(pool, hook, next, NULL);

  OUTPUT:
    RETVAL

APR::Request::Hook
disable_uploads(class, pool, next=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::Request::Hook next
  CODE:
    RETVAL = apreq_hook_make(pool, apreq_hook_disable_uploads,
                             next, NULL);
  OUTPUT:
    RETVAL

APR::Request::Hook
apr_xml_parser(class, pool, next=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::Request::Hook next
  CODE:
    RETVAL = apreq_hook_make(pool, apreq_hook_apr_xml_parser,
                             next, NULL);
  OUTPUT:
    RETVAL

APR::Request::Hook
find_param(class, pool, name, next=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::Request::Hook next
    char *name
  CODE:
    RETVAL = apreq_hook_make(pool, apreq_hook_find_param,
                             next, name);
  OUTPUT:
    RETVAL

APR::Request::Hook
discard_brigade(class, pool, next=NULL)
    apreq_xs_subclass_t class
    APR::Pool pool
    APR::Request::Hook next
  CODE:
    RETVAL = apreq_hook_make(pool, apreq_hook_discard_brigade,
                             next, NULL);
  OUTPUT:
    RETVAL

