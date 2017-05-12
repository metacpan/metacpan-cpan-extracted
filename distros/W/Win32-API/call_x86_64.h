
/* size_t because it's definitely pointer-size. AFAIK no other int type is on both MSVC and gcc */
typedef union {
	size_t i;
	double d;
	float f;
} stackitem;

void Call_x64_real(FARPROC, size_t *, double *, stackitem *, unsigned int);
/* GCC requires a union, fnc ptr cast not allowed, error is
   "function called through a non-compatible type" */
typedef union {
    double (*fp) (FARPROC, size_t *, double *, stackitem *, unsigned int);
    long_ptr (*numeric) (FARPROC, size_t *, double *, stackitem *, unsigned int);
} CALL_REAL_U;


enum {
	available_registers = 4
};

void Call_asm(FARPROC ApiFunction, APIPARAM *params, int nparams, APIPARAM *retval)
{
	size_t nRegisters = 0, nStack = 0;
	size_t required_registers = 0;
	unsigned int required_stack = 0;

	double float_registers[available_registers] = { 0., 0., 0., 0. };
	size_t int_registers[available_registers] = { 0, 0, 0, 0 };

	stackitem *stack = NULL;

	int i;
    const CALL_REAL_U u_var = {(double (*) (FARPROC, size_t *, double *, stackitem *, unsigned int))Call_x64_real};

	required_registers = nparams > available_registers ? available_registers : nparams;
	required_stack = nparams > available_registers ? nparams - available_registers : 0;

	if (required_stack)
	{
		stack = _alloca(required_stack * sizeof(*stack));
		memset(stack, 0, required_stack * sizeof(*stack));
	}

	for (i = 0; i < nparams; ++i)
	{
		if (i < available_registers)
		{
			/* First four arguments go in registers, either integer or floating point. */
			switch (params[i].t+1)
			{
				case T_NUMBER:
                case T_CODE:
				case T_INTEGER:
				case T_CHAR:
				case T_NUMCHAR:
					int_registers[i] = params[i].l;
					break;
				case T_POINTER:
				case T_STRUCTURE:
					int_registers[i] = (size_t) params[i].p;
					break;
				case T_FLOAT: //do not convert the float to a double,
                    //put a float in the XMM reg, not a double made from a float
                    //otherwise a func taking floats will see garbage because
                    //XMM reg contains a double that is numerically
                    //identical/similar to the original float but isn't
                    //the original float bit-wise
					float_registers[i] = *(double *)&(params[i].f);
					break;
				case T_DOUBLE:
					float_registers[i] = params[i].d;
					break;
			}
		}
		else
		{
			switch (params[i].t+1)
			{
				case T_NUMBER:
                case T_CODE:
					stack[i - available_registers].i = params[i].l;
					break;
				case T_INTEGER:
					stack[i - available_registers].i = params[i].l;
					break;
				case T_POINTER:
				case T_STRUCTURE:
					stack[i - available_registers].i = (size_t) params[i].p;
					break;
				case T_CHAR:
				case T_NUMCHAR:
					stack[i - available_registers].i = params[i].l;
					break;
				case T_FLOAT:
					stack[i - available_registers].f = params[i].f;
					break;
				case T_DOUBLE:
					stack[i - available_registers].d = params[i].d;
					break;
			}
		}
	}
    //use function type punning
	switch (retval->t) {
        //read XMM0
		case T_FLOAT:
		case T_DOUBLE:
        retval->d = u_var.fp(ApiFunction, int_registers, float_registers, stack, required_stack);
        break;
        //read RAX
        default:
        retval->l = u_var.numeric(ApiFunction, int_registers, float_registers, stack, required_stack);
        break;
    }
}


