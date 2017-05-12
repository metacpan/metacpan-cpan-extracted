package Win32::Env;
our $VERSION='0.03';

=head1 NAME

Win32::Env - set and retrieve global system and user environment variables under Win32.

=head1 SYNOPSIS

	use Win32::Env;

	# Retrieving value
	my $user_path=GetEnv(ENV_USER, 'PATH');
	print $user_path;

	# Setting new value
	SetEnv(ENV_USER, 'PATH', 'C:\\MyBin');

	# Deleting value
	DelEnv(ENV_USER, 'PATH');

	# Retrieving list of all variables in environment
	my @vars=ListEnv(ENV_USER);
	print(join(', ', @vars));

	# Broadcasting message about our changes
	BroadcastEnv();

=cut

use warnings;
use strict;

use Carp;
use Win32::TieRegistry(FixSzNulls=>1);

=head1 NOTES

=head2 System and user variables

Just like many Unix shells have global defaults and user profile, Windows store
several sets of environment variables. Modifying system's set (see L</ENV_SYSTEM>)
will affect every user on system, while working with user's (see L</ENV_USER>)
will only affect current user.

=head2 Fixed and variable length values

While it is impossible to distinguish them by normal means (like C<%ENV> or C<cmd.exe>'s
C<set> command, variable values could be either fixed length or variable length strings.
Fixed length strings should always resolve to same literal value that was assigned to them, while
variable length strings may have references to other variables in them that in form of C<%OTHER_VAR%>
that should be expanded to values of that variables. Note "should". This expansion is not
performed by system automatically, but must be done by program that uses variable.

=cut

=head1 EXPORT

SetEnv GetEnv DelEnv ListEnv BroadcastEnv ENV_USER ENV_SYSTEM

=cut

use Exporter qw(import);
our @EXPORT=qw(SetEnv GetEnv DelEnv ListEnv InsertPathEnv BroadcastEnv ENV_USER ENV_SYSTEM);

=head1 CONSTANTS

=head2 ENV_USER

Used as value for C<$sys_or_usr> argument to indicate that
you wish to work with current user's environment.

=head2 ENV_SYSTEM

Used as value for C<$sys_or_usr> argument to indicate that
you wish to work with system's global environment.

=cut

use constant ENV_USER	=>0;
use constant ENV_SYSTEM	=>1;

use constant ENVKEY_USER	=> 'HKEY_CURRENT_USER\\Environment';
use constant ENVKEY_SYSTEM	=> 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment';

=head1 FUNCTIONS

=cut

sub _NWA{
 my $lib=shift,
 my @proto=@_;
 require Win32::API;
 return(new Win32::API($lib, @proto) or die "Can't import API $proto[0] from $lib: $^E\n");
}

# TODO: error/sanity checks for other args
sub _num_to_key($){
 my $sysusr=shift;
 if(!defined($sysusr) or ($sysusr ne ENV_USER and $sysusr ne ENV_SYSTEM and $sysusr ne ENVKEY_USER and $sysusr ne ENVKEY_SYSTEM)){
  local $Carp::CarpLevel=2;
  carp((caller(1))[3], ": \$sys_or_usr argument must be either ENV_USER or ENV_SYSTEM");
  return;
 }
 if($sysusr eq ENV_USER) { return ENVKEY_USER; }
 elsif($sysusr eq ENV_SYSTEM) { return ENVKEY_SYSTEM; }
 return $sysusr;
}

sub _is_empty_var{
 my $var=shift;
 if(!defined($var) or $var eq ''){
  local $Carp::CarpLevel=2;
  carp((caller(1))[3], ": \$variable argument must be defined non-empty name");
  return 1;
 }
 return;
}

=head2 SetEnv($sys_or_usr, $variable, $value[, $expand])

	$success=SetEnv($sys_or_usr, $variable, $value);
	$success=SetEnv($sys_or_usr, $variable, $value, $expand);

Sets variable named $variable in environment selected with $sys_or_usr (L</ENV_USER> or L</ENV_SYSTEM>)
to specified $value. Optional $expand set to true or false value specifies if
value should be marked as variable length string with expandable references
or not. See L</Fixed and variable length values> for details. If $expand
is not defined C<SetEnv()> will use default Windows behavior - any
value that have C<%> in it will be marked as variable length. Returns true
on success and false otherwise.

=cut

sub SetEnv{
 my ($sysusr, $var, $value, $expand)=@_;
 $sysusr=(_num_to_key($sysusr) or return);
 return if _is_empty_var($var);
 if(!defined($expand) and defined($value)){ $expand=($value=~/%/); }
 $expand=(defined($expand) and $expand)?Win32::TieRegistry::REG_EXPAND_SZ:undef;
 return Win32::TieRegistry->new($sysusr)->SetValue($var, $value, $expand);
}

=head2 GetEnv($sys_or_usr, $variable)

	$value=GetEnv($sys_or_usr, $variable);
	($value, $expand)=GetEnv($sys_or_usr, $variable);

Returns pair of value of variable named $variable from environment selected
with $sys_or_usr (L</ENV_USER> or L</ENV_SYSTEM>) and true or false value
signifying if it is should be expanded or not (see L</Fixed and variable length values>).

=cut

sub GetEnv{
 my ($sysusr, $var)=@_;
 $sysusr=(_num_to_key($sysusr) or return);
 return if _is_empty_var($var);
 my($value, $type)=Win32::TieRegistry->new($sysusr)->GetValue($var);
 return wantarray?($value, defined($type)?$type==Win32::TieRegistry::REG_EXPAND_SZ:undef):$value;
}

=head2 DelEnv($sys_or_usr, $variable)

	DelEnv($sys_or_usr, $variable)

Deletes variable named $variable from environment selected with $sys_or_usr
(L</ENV_USER> or L</ENV_SYSTEM>).

=cut

sub DelEnv{
 my ($sysusr, $var)=@_;
 $sysusr=(_num_to_key($sysusr) or return);
 return if _is_empty_var($var);
 Win32::TieRegistry->new($sysusr)->RegDeleteValue($var);
}

=head2 ListEnv($sys_or_usr)

	@list_of_variables=ListEnv($sys_or_usr);

Returns list of all variables in environment selected with $sys_or_usr
(L</ENV_USER> or L</ENV_SYSTEM>).

=cut

sub ListEnv{
 my ($sysusr, $var)=@_;
 $sysusr=(_num_to_key($sysusr) or return);
 return Win32::TieRegistry->new($sysusr)->ValueNames;
}

=head2 InsertPathEnv($sys_or_usr, $variable, $path[, $path_separator])

	$success=InsertPathEnv($sys_or_usr, $variable, $path);
	$success=InsertPathEnv($sys_or_usr, $variable, $path[, $path_separator]);

One of common use of enviroment variables is to store path lists to binary, library and
other directories like this. This function allows you to insert a path in such a variable.
Typical usage in some kind of installation script could be like this:

	InsertPathEnv(ENV_SYSTEM, PATH => $bindir);
	InsertPathEnv(ENV_SYSTEM, PERL5LIB => $libdir);
	BroadcastEnv();

Path specified with $path will be added to $variable from environment selected with $sys_or_usr
(L</ENV_USER> or L</ENV_SYSTEM>), using $path_separator as separators for elements on parse
and inserting. If you do not specify a $path_separator, default system path separator
will be detected with C<Config> module. Function returns false on failure, and true
on success with true value being one of '1' for successful insert or '2' if specified $path
already present in $variable.

=cut

sub InsertPathEnv{
 my($sysusr, $var, $path, $psep)=@_;
 $sysusr=(_num_to_key($sysusr) or return);
 return if _is_empty_var($var);
 unless(defined($path) and $path ne ''){ return; }
 if(!defined($psep)){ require Config; $psep=$Config::Config{'path_sep'}; }

 $path=~s/\//\\/g;
 my $elements=(GetEnv($sysusr, $var) or '');

 my @elements=split($psep, $elements);
 my $found=0;

 foreach(@elements){
  $_=~s/[\\\/]$//;
  if(lc($_) eq lc($path)){
   return 2;
  }
 }
 unless(SetEnv($sysusr, $var, join($psep, @elements, $path))) { return; }
 return 1;
}

=head2 BroadcastEnv()

	BroadcastEnv();

Broadcasts system message that environment has changed. This will make system processes responsible for
environment aware of change, otherwise your changes will be noticed only on next reboot. Note that most
user programs or still won't see changes until next run and neither will their children, as they get environment
from their parents. Your changes also will not be available in C<%ENV> to either your process or
any processes you spawn. Assign to C<%ENV> yourself in addition to C<SetEnv()> if need it.

=cut

sub BroadcastEnv(){
 use constant HWND_BROADCAST	=> 0xffff;
 use constant WM_SETTINGCHANGE	=> 0x001A;
 # SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM) "Environment", SMTO_ABORTIFHUNG, 5000, &dwReturnValue);
 my $SendMessage=_NWA('user32', 'SendMessage', 'LLPP', 'L');
 $SendMessage->Call(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 'Environment');
}

1;

=head1 AUTHOR

Oleg "Rowaa[SR13]" V. Volkov, C<<ROWAA@cpan.org>>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-env at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Env>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::Env

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-Env>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-Env>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Env>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-Env>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Oleg "Rowaa[SR13]" V. Volkov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
