Testing: +, -, *, /, <, >, <=, >=, =, !=
    Age: <PORE.render attr="age">
=============================
<PORE.if cond="age < '60'">Younger than 60</PORE.if>
<PORE.if cond="age + '10' > '60'">Older than 50<PORE.else>10 years later not old than 60</PORE.if>
<PORE.if cond="age - '10' <= '40'">10 years ago younger or same as 40</PORE.if>
<PORE.if cond="age * '2' >= '100'">Twice the age is older or same as 100</PORE.if>
<PORE.if cond="age / '2' = '25'">Half the age equals to 25</PORE.if>
<PORE.if cond="age != '51'">Not equals to 51</PORE.if>

Testing: eq, eqs
    Name: <PORE.render attr="name">
===============================
<PORE.if cond="name eqs 'Joe Smith'">Name is Joe Smith.</PORE.if>
<PORE.if cond="name eqs 'joe smith'">Name is joe smith.<PORE.else>Name is not joe smith.</PORE.if>
<PORE.if cond="name eq 'joe smith'">If case insensitive, name is same as joe smith.</PORE.if>

Testing: and, or, not, (, )
    Age: <PORE.render attr="age">
    Name: <PORE.render attr="name">
===============================
<PORE.if cond="(name eqs 'Joe Smith') and (age < '60')">Name is Joe Smith and younger than 60.</PORE.if>
<PORE.if cond="(name eqs 'Joe Smith') or (age > '60')">Name is Joe Smith or older than 60.</PORE.if>
<PORE.if cond="(name eqs 'John Doe') or (age < '60')">Name is Johe Doe or younger than 60.</PORE.if>
<PORE.if cond="NOT(name eqs 'John Doe') and  NOT(age > '60')">Name is not Johe Doe and not older than 60.</PORE.if>
