/* vi: set ft=c : */

/* Some experimental extension flags. Not (currently) part of core perl API
*/
enum {
  PARSE_SUBSIGNATURE_NAMED_PARAMS = (1<<0),
  /* Permits ( :$foo, :$bar, :$splot = "default" )  named params
   * They are accumulated into a slurpy hash then extracted afterwards
   * As with positional params, any param without a defaulting expression is
   * required; an error is thrown if the caller did not provide it
   */

  PARSE_SUBSIGNATURE_PARAM_ATTRIBUTES = (1<<1),
  /* Permits ( $param :Attribute(Value) )  attributes on params
   * These must be registered by calling register_subsignature_attribute()
   */
};

#define boot_parse_subsignature_ex()  XPS_boot_parse_subsignature_ex(aTHX)
void XPS_boot_parse_subsignature_ex(pTHX);

#define parse_subsignature_ex(flags)  XPS_parse_subsignature_ex(aTHX_ flags)
OP *XPS_parse_subsignature_ex(pTHX_ int flags);

#define register_subsignature_attribute(name, funcs, funcdata)  XPS_register_subsignature_attribute(aTHX_ name, funcs, funcdata)
void XPS_register_subsignature_attribute(pTHX_ const char *name, const struct XPSSignatureAttributeFuncs *funcs, void *funcdata);
