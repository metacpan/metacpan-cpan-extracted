Name: <PORE.render attr=name>
Children:
<PORE.list attr=children>
	<PORE.render attr=name>, <PORE.render attr=age>, <PORE.if cond=
"gender EQ 'M'">Male<PORE.else>Female</PORE.if>
</PORE.list>