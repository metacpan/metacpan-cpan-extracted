use TestML1;
TestML1->new(
    testml => <<'...'
%TestML 0.1.0
Plan = 1
Print("Goodbye, World!\n")
1.OK
...
)->run;
