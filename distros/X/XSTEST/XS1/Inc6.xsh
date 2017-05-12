


int
okzzz(x)
	int x
	CODE:
	RETVAL = x;
	OUTPUT:
	RETVAL

INCLUDE: Inc7.xsh

int
froybox(v,h)
CASE: ix == 0
	ALIAS:
	main::froobox = 1
	INPUT:
	int v
	int h
	INIT:
	printf("# froybox\n");
CASE:
	int v
	int h
	CODE:
	RETVAL = v - h;
	OUTPUT:
	RETVAL

int
frozbox(v,h)
CASE: SvIV(ST(0)) == 22
	PROTOTYPE: $$
	INPUT:
	int v
	int h
	INIT:
	printf("# frozbox first case\n");
	CODE:
	RETVAL = v;
	OUTPUT:
	RETVAL
CASE:
	int v
	int h
	INIT:
	printf("# frozbox second case\n");
	CODE:
	RETVAL = v;
	OUTPUT:
	RETVAL
