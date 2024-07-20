bool XSParseInfix_parse(pTHX_ enum XSParseInfixSelection select, struct XSParseInfixInfo **infop);
OP *XSParseInfix_new_op(pTHX_ const struct XSParseInfixInfo *info, U32 flags, OP *lhs, OP *rhs);
bool XSParseInfix_check_opname(pTHX_ const char *opname, STRLEN oplen);
void XSParseInfix_register(pTHX_ const char *opname, const struct XSParseInfixHooks *hooks, void *hookdata);
void XSParseInfix_boot(pTHX);
