cpanm --installdeps .
pp -I ../lib -I ~/perl5/lib/perl5/ -M WebDyne -M Devel::Confess -M Plack::Middleware::Lint -M Plack::Middleware::StackTrace -M Plack::Middleware::AccessLog \
-M Plack::Loader -M Plack::Handler::Standalone -a ../lib/WebDyne/Err/error.psp -o webdyne.psgi.pp ../bin/webdyne.psgi
pp -p -I ../lib -I ~/perl5/lib/perl5/ -M WebDyne -M Devel::Confess -M Plack::Middleware::Lint -M Plack::Middleware::StackTrace -M Plack::Middleware::AccessLog \
-M Plack::Loader -M Plack::Handler::Standalone -a ../lib/WebDyne/Err/error.psp -o webdyne.par ../bin/webdyne.psgi
