package URL::Checkout;

use warnings;
use strict;
use String::ShellQuote;
use Text::Sprintf::Named;
use Cwd;
use File::Path;
use File::Temp;
use Carp;

=head1 NAME

URL::Checkout - Get one or multiple files from a remote location

=head1 VERSION

Version 1.05

=cut

our $VERSION = '1.05';


=head1 SYNOPSIS

Retrieve contents from a URL, no matter if the URL specifies a simple file via 
ftp or http, or a Repository of one of the well known VCS systems, cvs, svn, git, hg, 
Unlike LWP, this module makes no attempts to be perlish. We liberally call shell 
commands to do the real work. The author especially likes to call C<wget>.

    use URL::Checkout;

    my $f = URL::Checkout->new(dest => '/tmp/outdir', verbose => 1);
    $f->auth($user, $pass);
    $f->dest($outdir);
    $f->method('*');

    #       obs://api.opensuse.org/source/home:jnweiger/fate?rev=19
    #       https://svn.suse.de/svn/inttools/trunk/features/fate
    $url = "ssh://user:pass@scm.somewhere.org/git/repo.git"; 
    $f->get($url);

    $m = $f->find_method($url);
    $cmd = $f->fmt_cmd($m, $url);
    chdir($f->dest());
    system $cmd;


=head1 SUBROUTINES/METHODS

=head2 new

Create a checkout object. 
It can be configured through several parameters to new, or through similarly named methods.
If no destination directory is specified via dest, File::Temp is consulted to create a 
temporary directory. 

=head2 auth($user, $pass)

An alternative to specifying user, pass with C<new>. 
Provide authentication credentials for the remote access. 

=head2 dest($directory)

=head2 dest()

Set and/or get the destination directory. The directory need not be created ahead of time.

=head2 list_methods()

Return a hash with method names as keys, detection patterns and retrieval commands.
The values in this hash are aliases to the internal values. You can change them to e.g. 
add a -q flag if you find a command to be too noisy.

=head2 describe()

Returns a verbal description of the matching rules.

=head2 add_method(name, qr{url-match-pattern}, cmd_fmt_string, "Some descriptive text") 

Multiple commands can be specified for each name. Commands should be written in bourne shell 
syntax, with the following named sprintf templates: %(user)s, %(pass)s, %(url)s, %(dest)s.
Commands that contain %(user)s and/or %(pass)s are ignored, if username and/or password 
credentials are not given. Example:

  add_method('git', qr{^(git://.*|\.git/?)$}, "git clone --depth 1 %(url)s");

The destination directory is the current working directory while the command runs.
The templates are expanded using String::ShellQuote and Text::Sprintf::Named.

If an array-ref of patterns is specified instead of a pattern, the patterns
should be ordered by decreasing reliability. Methods are tested breadth-first.

If a subroutine reference is specified as third parameter, it is called with the URL and the 
return value of find_method(), and is expected to return a command or an array of commands.

=head2 method('*')

Limit the method by name. The default '*' means no limitation. An array of
method names can be specified, which denotes a first match choice.
This is helpful for URLs that do not match anything specific. 
This is harmless, as it still allows other methods if the URL matches there.

=cut

sub new
{
  my $self = shift;
  my $class = ref($self) || $self;
  my %obj = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

  $obj{_methods} = 
  [
    { name => 'obs', pat => [qr{^(obs://|https://api\.(opensuse\.org|suse\.de)/(public/)?source/)}],
      osc => ['osc'], co => ['co', '--current-dir', '--expand-link'], 
      desc => "OpenSUSE Build Service(obs): URLs starting with obs://, https://api.opensuse.org/, https://api.suse.de are handled by 'osc checkout'. Path components /public and /source are stripped, the remaining path components are Project, Package, and optionally File. Project can be written as either a:/b:/c: or a:b:c",

      cmd => sub { my ($url, $m) = @_;
        my $api = $1 if $url =~ s{^\w+://([^/]+)/+}{};	
	$url =~ s{^(public/+)?sources?/+}{};
	my $rev = $1 if $url =~ s{[\?&]rev=(\w+)}{};
	$url =~ s{\?.*}{};
	$url =~ s{:/}{:}g;
	my @pp = split m{/+}, $url;

	my @cmd = (@{$m->{osc}}, '-A', "https://$api", @{$m->{co}});
	push @cmd, '-r', $rev if defined $rev;
	## -S aka --server-side-source-service-files, what an ugly name!
	return [ shell_quote(@cmd, '-S', @pp), shell_quote(@cmd, @pp)];
      },
      fake_home => { '.oscrc' => q{
[general]
apiurl = https://$api

[https://$api]
user = %(user)s
pass = %(pass)s
keyring=0
} } },

    { name => 'git', pat => [qr{(^git://|\.git/?$)}], 
      desc => "git: URLs starting with git:// or ending in .git are handled by 'git clone'",
      cmd => ["git clone --depth 1 %(url)s"] },

    { name => 'svn', pat => [qr{^svn://}, qr{[/@]svn(root)?[\./].*/(trunk|branches)/}, qr{[/@]svn(root)?[\./]}], 
      desc => "Subversion(svn): URLs starting with git:// or containing /svn. followed by /trunk/ or /branches/ or containing /svn/ followed by /trunk/ or /branches/ are handled by 'svn checkout'. Second Prio: URLs containing only /svn. or /svn/",
      cmd => ["svn --no-auth-cache --non-interactive --trust-server-cert co -q --force %(url)s",
              "svn --no-auth-cache --non-interactive --trust-server-cert --username %(user)s --password %(pass)s co -q --force %(url)s" ] },

    { name => 'http', pat => [undef, undef, qr{^https?://}], 
      desc => "WWW(http): URLs starting with http:// or https:// are handled as third priority with 'wget -m', this third priority is a fallback, if no first or second priority commands match",
      cmd => ["wget -m -np -nd -nH --no-check-certificate -e robots=off %(url)s"] },
  ];

  $obj{_sel} = ['*'];

  return bless \%obj, $class;
}

sub dest
{
  my ($self, $dir) = @_;
  $self->{dest} = $dir if defined $dir;
  $self->{dest} = File::Temp::tempdir( "co_XXXXXX", TMPDIR => 1) 
    unless $self->{dest};
  return $self->{dest};
}

sub auth
{
  my ($self, $user, $pass) = @_;
  $self->{user} = $user if defined $user;
  $self->{pass} = $pass if defined $pass;
  return ($self->{user}, $self->{pass});
}

sub list_methods
{
  return $_[0]->{_methods};
}

sub describe
{
  my @d = map { $_->{desc} } @{$_[0]->{_methods}};
  return (wantarray ? @d : join("\n\n", @d)."\n");
}

sub method
{
  my ($self, @sel) = @_;
  $sel[0] = '*' unless @sel;
  $self->{_sel} = (ref $sel[0]) ? $sel[0] : [@sel];
}

=head2 find_method($url)

Tests $url against the regexp patterns stored with each method. The first match is returned.
If multiple patterns are specified per method, all other methods are tested,
before the next set of patterns is tested.

Unless a method name was specified with C<method()>, we return undef, if no pattern matches.
With one or multiple method names specified, the first available method by that
name is returned, when there is no pattern match.

=cut 

sub find_method
{
  my ($self, $url) = @_;

  my $max_pat_idx = 0;
  for my $m (@{$self->{_methods}})
    {
      $max_pat_idx = $#{$m->{pat}} if $#{$m->{pat}} > $max_pat_idx;
    }

  # match method patterns, breadth first
  for my $sel (@{$self->{_sel}})
    {
      for my $pat_idx (0 .. $max_pat_idx)
        {
	  for my $m (@{$self->{_methods}})
	    {
	      next if $sel ne '*' and $sel ne $m->{name};
	      next unless defined (my $pat = $m->{pat}[$pat_idx]);
	      return $m if $url =~ m{$pat};
	    }
	}
    }

  # if a name was give in sel, try hard to use it, even if no pattern matched.
  for my $sel (@{$self->{_sel}})
    {
      next if $sel eq '*';
      for my $m (@{$self->{_methods}})
        {
	  return $m if $sel eq $m->{name};
	}
    }

  return undef;	# sorry, really nothing matched.
}

=head2 fmt_cmd($meth_hash, $url)

Use a method hash as returned by C<find_method> and prepare all possible commands from it with the given url. One or multiple commands are returned suitable for use with system or backticks.

=cut

sub fmt_cmd 
{
  my ($self, $m, $url) = @_;

  my $list;
  if (ref $m->{cmd} eq 'CODE')
    {
      $list = $m->{cmd}->($url, $m);
    }
  else
    {
      $list = $m->{cmd};
    }
  # use Data::Dumper; die Dumper $m, $list, $url;

  my @cmd;
  for my $cmd (@$list)
    {
      my $need_user = 0;
      my $need_pass = 0;
      my $need_dest = 0;
      $need_user++ if $cmd =~ m{%\(user\)};
      $need_pass++ if $cmd =~ m{%\(pass\)};
      $need_dest++ if $cmd =~ m{%\(dest\)};

      $self->dest() if $need_dest;	# creates tempdir
      next if $need_pass and !defined($self->{pass});
      next if $need_user and !defined($self->{user});

      my $fmt = Text::Sprintf::Named->new({fmt => $cmd});
      push @cmd, $fmt->format({ args => 
        {
          url  => shell_quote($url),
          user => shell_quote($self->{user}||''),
          pass => shell_quote($self->{pass}||''),
	  dest => shell_quote($self->{dest})
	}});
    }

  return wantarray ? @cmd : $cmd[0];
}

=head2 get($url)

Similar to this code:

    $m = $f->find_method($url);
    system "".$f->fmt_cmd($m, $url);

Except that it tries further commands from C<fmt_cmd()> if if the first fails.
It also assures that the current working directory is C<< $f->dest() >> while executing a command.
Command names are printed to stdout, if verbose is set.

=cut

sub add_method
{
  my ($self, $name, $pat, $cmd, $desc) = @_;
  $pat = [$pat] unless ref $pat eq 'ARRAY';
  $cmd = [$cmd] unless ref $cmd eq 'ARRAY';
  $desc ||= $cmd->[0];
  unshift @{$self->{_methods}}, { name => $name, desc => $desc, pat => $pat, cmd => $cmd };
}


=head2 pre_cmd($method)

Helper function run by C<get()>. This prepares temporary files if the method has a 'fake_home' and 
at least a username credential was given to C<auth()>.
This also creates the destination directory and changes into it.

=cut

sub pre_cmd
{
  my ($self, $m) = @_;

  my $cwd = getcwd();
  $cwd = $1 if $cwd =~ m{^(.*)$};

  my $dest = $self->dest();
  File::Path::mkpath($dest);
  chdir($dest) or croak "cannot chdir('$dest')\n";
  if ($m->{fake_home} and defined($self->{user}))
    {
      my $fake_home = File::Temp::tempdir("co_fake_home_XXXXXX", TMPDIR => 1, UNLINK => 1);
      chmod 0700, $fake_home;
      for my $f (keys %{$m->{fake_home}})
        {
          my $fmt = Text::Sprintf::Named->new({ fmt => $m->{fake_home}{$f} });
	  open O, ">", "$fake_home/$f" or croak "pre_cmd: failed to populate fake_home: $f: $!";
	  print O $fmt->format({ args => { user => $self->{user}||'', pass => $self->{pass}||'' } });
	  close O;
	}
      $self->{saved_fake_home} = $fake_home;
    }
  $self->{saved_cwd} = $cwd;
}

=head2 post_cmd()

Cleanup handler run by C<get()>. This removes any temporary 
files and restores the current working directory.

=cut

sub post_cmd
{
  my ($self) = @_;
  my $cwd = $self->{saved_cwd};
  croak "no {saved_cwd}. Called post_cmd() without pre_cmd() ??\n";

  if ($self->{saved_fake_home})
    {
      # cleanup that home recursively
      File::Path::remove_tree($self->{saved_fake_home});
      delete $self->{saved_fake_home};
    }
  chdir($cwd) or croak "cannot chdir back to '$cwd'\n";
}

sub get
{
  my ($self, $url) = @_;

  my $m = $self->find_method($url);
  croak "get: no method known for '$url', try add_method()\n" unless $m;

  my @cmd = $self->fmt_cmd($m, $url);
  croak "no method usable for this url. Need auth?\n" unless @cmd;

  my $cwd = $self->pre_cmd();

  my $success = 0;
  for my $c (@cmd)
    {
      print STDOUT "[$c]\n" if $self->{verbose};
      if (system $c)
        {
	  carp $self->{verbose} ? "--: r=$?, $!\n" : "[$c]: r=$?, $!\n";
	}
      else
        {
	  $success++;
	  last;
	}
    }
  $self->post_cmd();

  return $success;
}

=head1 AUTHOR

Juergen Weigert, C<< <jnw at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-checkout at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URL-Checkout>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URL::Checkout


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URL-Checkout>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URL-Checkout>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URL-Checkout>

=item * Search CPAN

L<http://search.cpan.org/dist/URL-Checkout/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Juergen Weigert.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of URL::Checkout
