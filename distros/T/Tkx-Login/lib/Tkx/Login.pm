package Tkx::Login;

use Tkx;

use warnings;
use strict;

$Tkx::Login::VERSION='1.11';

sub askpass {
  my $interation = 0;

  my $mw = shift @_;
  my $text = shift @_;
  my $user = shift @_;
  my $pass = shift @_;

  my $original_user = $user;
  my $original_pass = $pass;

  my $win = $mw->new_toplevel();
  $win->g_wm_title("Login");

  $win->new_ttk__label(-text => $text )->g_grid( -columnspan => 2 ) if $text;

  $win->new_ttk__label(-text => "Username:" )->g_grid( -stick=> 'e', -column => 0, -row => 1 );

  my $name_entry = $win->new_ttk__entry(-textvariable => \$user);
  $name_entry->g_grid( -column => 1, -row => 1 );

  $win->new_ttk__label(-text => "Password:" )->g_grid( -sticky => 'e', -column => 0, -row => 2 );
 
  my $pass_entry = $win->new_ttk__entry(-textvariable => \$pass, -show => '*');
  $pass_entry->g_grid( -column => 1, -row => 2 );

  my $okcancel;

  my $ok = $win->new_button(
    -text => 'Ok',
    -command => sub {
       $okcancel = 'ok';
       $interation++;
       $win->g_destroy;
    },
  )->g_grid( -column => 0, -row => 3 );

  my $cancel = $win->new_button(
    -text => 'Cancel',
    -command => sub {
       $okcancel = 'cancel';
       $interation++;
       $win->g_destroy;
    },
  )->g_grid( -column => 1, -row => 3 );

  while ( $interation < 1 ) {
    Tkx::update();
  }

  return $okcancel eq 'ok' ? ( $user, $pass ) : ( $original_user, $original_pass );
}

1;

=head1 NAME

Tkx::Login - A Simple Login Window for Tkx 

=head1 SYNOPSIS:

Tkx::Login provides a simple login interface for Tkx applications. Given
a window value to extend, it opens a new window, queries for username and
password and returns the values.

=head1 USAGE:

  use Tkx::Login;
    
  my ($username,$password) = Tkx::Login::askpass($mainwindow,$message,$pre_user,$pre_password);

  Parameters:
  
  $mainwindow - Current MainWindow in your Tkx app. (required)
  $message - A text message to display in the login window. (optional)
  $pre_user - A value to pre-populate the username blank with. (optional)
  $pre_pass - A value to pre-populate the password blank with. This will be obscured with asterisks. (optional)

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=Tkx-Login

	Source hosting: http://www.github.com/bennie/perl-Tkx-Login

=head1 VERSION

	Tkx::Login v1.11 (2014/04/29)

=head1 COPYRIGHT

	(c) 2012-2014, Phillip Pollard <bennie@cpan.org>

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of
which is included in the LICENSE file of this distribution. It may also be
reviewed here: http://opensource.org/licenses/artistic-license-2.0
