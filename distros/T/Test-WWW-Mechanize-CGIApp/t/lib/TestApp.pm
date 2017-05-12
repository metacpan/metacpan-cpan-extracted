
package TestApp;

use warnings;
use strict;

use base qw( CGI::Application );

sub setup {
  my $self = shift;

  $self->start_mode('welcome');
  $self->run_modes(
		   'welcome' => \&welcome_mode,
		   'hello' => \&hello_mode,
		   'whoopee' => \&whoopee_mode,
		  );
}

################################################################
#
# run modes
#
#################################################################

sub welcome_mode {
  my $self = shift;

  my $content = <<EOC;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Welcome</title>
  </head>

  <body>

        Home is where....

  </body>

</html>
EOC

  return $content;
}

sub hello_mode {
  my $self = shift;
  my $content = <<EOC;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Hello</title>
  </head>

  <body>

     Hello world!

     <a href="/?rm=whoopee">Whoopee</a>
     <a href="/TestApp/whoopee">Whoopee_dispatch</a>

  </body>

</html>
EOC

  return $content;
}

sub whoopee_mode {
  my $content = <<EOC;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Whoopee</title>
  </head>

  <body>

     Whoopee!

  </body>

</html>
EOC

  return $content;
}
1;
