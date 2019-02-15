# axk L0.pm: A dummy language that fails loading.  Language "0" is reserved
# since "0" is falsy in Perl.  Reserving this language permits using Boolean
# tests instead of definedness tests.

0;  # fail loading
