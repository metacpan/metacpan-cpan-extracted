use inc::Module::Install;

name q(W3C-Validator-Server);
all_from q(lib/W3C/Validator/Server.pm);

requires q(Plack) => 0.99;
requires q(Plack::Middleware::SSI) => 0.10;
requires q(CGI::Compile) => 0.14;
requires q(CGI::Emulate::PSGI) => 0.10;

bugtracker q(http://rt.cpan.org/NoAuth/Bugs.html?Dist=W3C-Validator-Server);
homepage q(http://search.cpan.org/dist/W3C-Validator-Server);
repository q(git://github.com/jhthorsen/w3c-validator-server.git);

install_script glob('bin/*');
auto_install;
WriteAll;
