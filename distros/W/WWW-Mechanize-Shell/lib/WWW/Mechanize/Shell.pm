package WWW::Mechanize::Shell;

use strict;
use Carp;
use WWW::Mechanize;
use WWW::Mechanize::FormFiller;
use HTTP::Cookies;
use parent qw( Term::Shell );
use Exporter 'import';
use FindBin;
use File::Temp qw(tempfile);
use URI::URL;
use Hook::LexWrap;
use HTML::Display qw();
use HTML::TokeParser::Simple;
use B::Deparse;

our $VERSION = '0.59';
our @EXPORT = qw( &shell );

=head1 NAME

WWW::Mechanize::Shell - An interactive shell for WWW::Mechanize

=head1 SYNOPSIS

From the command line as

  perl -MWWW::Mechanize::Shell -eshell

or alternatively as a custom shell program via :

=for example begin

  #!/usr/bin/perl -w
  use strict;
  use WWW::Mechanize::Shell;

  my $shell = WWW::Mechanize::Shell->new("shell");

  if (@ARGV) {
    $shell->source_file( @ARGV );
  } else {
    $shell->cmdloop;
  };

=for example end

=for example_testing
  BEGIN {
    require WWW::Mechanize::Shell;
    $ENV{PERL_RL} = 0;
    $ENV{COLUMNS} = '80';
    $ENV{LINES} = '24';
  };
  BEGIN {
    no warnings 'once';
    no warnings 'redefine';
    *WWW::Mechanize::Shell::cmdloop = sub {};
    *WWW::Mechanize::Shell::display_user_warning = sub {};
    *WWW::Mechanize::Shell::source_file = sub {};
  };
  isa_ok( $shell, "WWW::Mechanize::Shell" );

=head1 DESCRIPTION

This module implements a www-like shell above WWW::Mechanize
and also has the capability to output crude Perl code that recreates
the recorded session. Its main use is as an interactive starting point
for automating a session through WWW::Mechanize.

The cookie support is there, but no cookies are read from your existing
browser sessions. See L<HTTP::Cookies> on how to implement reading/writing
your current browsers cookies.

=head2 C<WWW::Mechanize::Shell-E<gt>new %ARGS>

This is the constructor for a new shell instance. Some of the options
can be passed to the constructor as parameters.

By default, a file C<.mechanizerc> (respectively C<mechanizerc> under Windows)
in the users home directory is executed before the interactive shell loop is
entered. This can be used to set some defaults. If you want to supply a different
filename for the rcfile, the C<rcfile> parameter can be passed to the constructor :

  rcfile => '.myapprc',

=over 4

=item B<agent>

  my $shell = WWW::Mechanize::Shell->new(
      agent => WWW::Mechanize::Chrome->new(),
  );

Pass in a premade custom user agent. This object must be compatible to
L<WWW::Mechanize>. Use this feature from the command line as

  perl -Ilib -MWWW::Mechanize::Chrome \
             -MWWW::Mechanize::Shell \
             -e"shell(agent => WWW::Mechanize::Chrome->new())"

=back

=cut

sub init {
  my ($self) = @_;
  my ($name,%args) = @{$self->{API}{args}};

  $self->{agent} = $args{ agent };
  if( ! $self->agent ) {
      my $class = $args{ agent_class } || 'WWW::Mechanize';
      my $args  = $args{ agent_args }  || [];
      $self->{agent} = $class->new( @$args );
  };

  $self->{formfiller} = WWW::Mechanize::FormFiller->new(default => [ Ask => $self ]);

  $self->{history} = [];

  $self->{options} = {
    autosync => 0,
    warnings => (exists $args{warnings} ? $args{warnings} : 1),
    autorestart => 0,
    watchfiles => (exists $args{watchfiles} ? $args{watchfiles} : 1),
    cookiefile => 'cookies.txt',
    dumprequests => 0,
    dumpresponses => 0,
		verbose => 0,
  };
  # Install the request dumper :
  $self->{request_wrapper} = wrap 'LWP::UserAgent::request',
      #pre => sub { printf STDERR "Dumping? %s\n",$self->option("dumprequests"); $self->request_dumper($_[1]) if $self->option("dumprequests"); },
      pre => sub { $self->request_dumper($_[1]) if $self->option("dumprequests"); },
      post => sub {
                    $self->response_dumper($_[-1]) if $self->option("dumpresponses");
                  };

  $self->{redirect_ok_wrapper} = wrap 'WWW::Mechanize::redirect_ok',
    post => sub {
        return unless $_[1];
        $self->status( "\nRedirecting to ".$_[1]->uri."\n" );
        $_[-1]
    };

  # Load the proxy settings from the environment
  $self->agent->env_proxy()
      if $self->agent->can('env_proxy');

  # Read our .rc file :
  # I could use File::Homedir, but the docs claim it dosen't work on Win32. Maybe
  # I should just release a patch for File::Homedir then... Not now.
  my $sourcefile;
  if (exists $args{rcfile}) {
    $sourcefile = delete $args{rcfile};
  } else {
    my $userhome = $^O =~ /win32/i ? $ENV{'USERPROFILE'} || $ENV{'HOME'} : ((getpwuid($<))[7]);
    $sourcefile = "$userhome/.mechanizerc"
      if -f "$userhome/.mechanizerc";
  };
  $self->option('cookiefile', $args{cookiefile}) if (exists $args{cookiefile});
  $self->source_file($sourcefile) if defined $sourcefile;
  $self->{browser} = undef;

  # Keep track of the files we consist of, to enable automatic reloading
  $self->{files} = undef;
  if ($self->option('watchfiles')) {
    eval {
      my @files = grep { -f && -r && $_ ne '-e' } values %INC;
      local $, = ",";
      require File::Modified;
      $self->{files} = File::Modified->new(files=>[@files]);
    };
    $self->display_user_warning( "Module File::Modified not found. Automatic reloading disabled.\n" )
      if ($@);
  };
};

=head2 C<$shell-E<gt>release_agent>

Since the shell stores a reference back to itself within the
WWW::Mechanize instance, it is necessary to break this
circular reference. This method does this.

=cut

sub release_agent {
  my ($self) = @_;
  use Data::Dumper;
  warn Dumper $self;
  undef $self->{request_wrapper};
  undef $self->{redirect_ok_wrapper};
  $self->{agent} = undef;
};

=head2 C<$shell-E<gt>source_file FILENAME>

The C<source_file> method executes the lines of FILENAME
as if they were typed in.

  $shell->source_file( $filename );

=cut

sub source_file {
  my ($self,$filename) = @_;
  local $_; # just to be on the safe side that we don't clobber outside users of $_
  local *F;
  open F, "< $filename"
    or die "Couldn't open '$filename' : $!\n";
  while (<F>) {
    $self->cmd($_);
    warn "cmd: $_"
      if $self->{options}->{verbose};
  };
  close F;
};

sub add_history {
  my ($self,@code) = @_;
  push @{$self->{history}},[$self->line,join "",@code];
};

=head2 C<$shell-E<gt>display_user_warning>

All user warnings are routed through this routine
so they can be rerouted / disabled easily.

=cut

sub display_user_warning {
  my ($self,@message) = @_;

  warn @message
    if $self->option('warnings');
};

=head2 C<$shell-E<gt>print_paged LIST>

Prints the text in LIST using C<$ENV{PAGER}>. If C<$ENV{PAGER}>
is empty, prints directly to C<STDOUT>. Most of this routine
comes from the C<perldoc> utility.

=cut

sub print_paged {
  my $self = shift;

  if ($ENV{PAGER} and -t STDOUT) {
    my ($fh,$filename) = tempfile();
    print $fh $_ for @_;
    close $fh;

    my @pagers = ($ENV{PAGER},qq{"$^X" -p});
		foreach my $pager (@pagers) {
			if ($^O eq 'VMS') {
				last if system("$pager $filename") == 0; # quoting prevents logical expansion
			} else {
				last if system(qq{$pager "$filename"}) == 0;
			}
		};
    unlink $filename
      or $self->display_user_warning("Couldn't unlink tempfile $filename : $!\n");
  } else {
    print $_ for @_;
  };
};

sub agent { $_[0]->{agent}; };

sub option {
  my ($self,$option,$value) = @_;
  if (exists $self->{options}->{$option}) {
    my $result = $self->{options}->{$option};
    if (scalar @_ == 3) {
      $self->{options}->{$option} = $value;
    };
    $result;
  } else {
    Carp::carp "Unknown option '$option'";
    undef;
  };
};

sub restart_shell {
  if ($0 ne '-e') {
    print "Restarting $0\n";
    exec $^X, $0, @ARGV;
  };
};

sub precmd {
  my $self = shift @_;
  # We want to restart when any module was changed
  if ($self->{files} and $self->{files}->changed()) {
    print "One or more of the base files were changed\n";
    $self->restart_shell if ($self->option('autorestart'));
  };

  $self->SUPER::precmd(@_);
};

sub browser {
  my ($self) = @_;
  $self->{browser} ||= HTML::Display->new();
  $self->{browser};
};

sub sync_browser {
  my ($self) = @_;

  # We only can display html if we have any :
  return unless $self->agent->res;

  # Prepare the HTML for local display :
  my $unclean = $self->agent->content;
  my $html = '';

  # ugly fix:
  # strip all target='_blank' attributes from the HTML:
  my $p = HTML::TokeParser::Simple->new(\$unclean);
  while (my $token = $p->get_token) {
    $token->delete_attr('target')
      if $token->is_start_tag;
    $html .= $token->as_is;
  };

  my $location = $self->agent->{uri};
  my $browser = $self->browser;
  $browser->display( html => $html, location => $location );
};

sub prompt_str {
    my $self = shift;
    if ($self->agent->response) {
        return ($self->agent->uri || "") . ">"
    } else {
        return "(no url)>"
    };
};

sub request_dumper { print $_[1]->as_string };
sub response_dumper {
  if (ref $_[1] eq 'ARRAY') {
    print $_[1]->[0]->as_string;
  } else {
    print $_[1]->as_string;
  }
};

sub re_or_string {
  my ($self,$arg) = @_;
  if ($arg =~ m!^/(.*)/([imsx]*)$!) {
    my ($re,$mode) = ($1,$2);
    $re =~ s!([^\\])/!$1\\/!g;
    $arg = eval "qr/$re/$mode";
  };
  $arg;
};

=head2 C<< $shell->link_text LINK >>

Returns a meaningful text from a WWW::Mechanize::Link object. This is (in order of
precedence) :

    $link->text
    $link->name
    $link->url

=cut

sub link_text {
  my ($self,$link) = @_;
  my $result;
  for (qw( text name url )) {
    $result = $link->$_ and last;
  };
  $result;
};

=head2 C<$shell-E<gt>history>

Returns the (relevant) shell history, that is, all commands
that were not solely for the information of the user. The
lines are returned as a list.

  print join "\n", $shell->history;

=cut

sub history {
  my ($self) = @_;
  map { $_->[0] } @{$self->{history}}
};

=head2 C<$shell-E<gt>script>

Returns the shell history as a Perl program. The
lines are returned as a list. The lines do not have
a one-by-one correspondence to the lines in the history.

  print join "\n", $shell->script;

=cut

sub script {
  my ($self,$prefix) = @_;
  $prefix ||= "";

  my @result = sprintf <<'HEADER', $^X;
#!%s -w
use strict;
use WWW::Mechanize;
use WWW::Mechanize::FormFiller;
use URI::URL;

my $agent = WWW::Mechanize->new( autocheck => 1 );
my $formfiller = WWW::Mechanize::FormFiller->new();
$agent->env_proxy();
HEADER

  push @result, map { my $x = $_->[1]; $x =~ s/^/$prefix/mg; $x } @{$self->{history}};
  @result;
};

=head2 C<$shell-E<gt>status>

C<status> is called for status updates.

=cut

sub status {
  my $self = shift;
  print join "", @_;
};

=head2 C<$shell-E<gt>display FILENAME LINES>

C<display> is called to output listings, currently from the
C<history> and C<script> commands. If the second parameter
is defined, it is the name of the file to be written,
otherwise the lines are displayed to the user.

=cut

sub display {
  my ($self,$filename,@lines) = @_;
  if (defined $filename) {
    eval {
      open my $f, ">", $filename
        or die "Couldn't create $filename : $!";
      binmode $f;
      print $f join( "", map { "$_\n" } (@lines) );
      close $f;
    };
    warn $@ if $@;
  } else {
    $self->print_paged( join( "", map { "$_\n" } (@lines) ));
  };
};

# sub-classed from Term::Shell to handle all run_ requests that have no corresponding sub
# This is used for comments
sub catch_run {
  my ($self) = shift;
  my ($command) = @_;
  if ($command =~ /^\s*#/) {
    # Hey, it's a comment.
  } else {
    print $self->msg_unknown_cmd($command);
  };
};

# sub-classed from Term::Shell to handle all smry requests
sub catch_smry {
  my ($self,$command) = @_;

  my $result = eval {
    require Pod::Constants;

    my @summary;
    my $module = (ref $self ).".pm";
    $module =~ s!::!/!g;
    $module = $INC{$module};

    Pod::Constants::import_from_file( $module, $command => \@summary );

    $summary[0];
  };
  if ($@) {
    return undef;
  };
  return $result;
};

# sub-classed from Term::Shell to handle all help requests
sub catch_help {
  my ($self,$command) = @_;

  my @result = eval {
    require Pod::Constants;

    my @summary;
    my $module = (ref $self ).".pm";
    $module =~ s!::!/!g;
    $module = $INC{$module};

    Pod::Constants::import_from_file( $module, $command => \@summary );

    @summary;
  };
  if ($@) {
    my $module = ref $self;
    $self->display_user_warning( "Pod::Constants not available. Use perldoc $module for help.\n" );
    return undef;
  };
  return join( "\n", @result) . "\n";
};

=head1 COMMANDS

The shell implements various commands :

=head2 exit

Leaves the shell.

=cut

sub alias_exit { qw(quit) };

=head2 restart

Restart the shell.

This is mostly useful when you are modifying the shell itself. It dosen't
work if you use the shell in oneliner mode with C<-e>.

=cut

sub run_restart {
  my ($self) = @_;
  $self->restart_shell;
};

sub activate_first_form {
    $_[0]->agent->form_number(1)
        if $_[0]->agent->forms and scalar @{$_[0]->agent->forms};
};

=head2 get

Download a specific URL.

This is used as the entry point in all sessions

Syntax:

  get URL

=cut

sub run_get {
  my ($self,$url) = @_;
  $self->status( "Retrieving $url" );
  my $code;
  eval { $self->agent->get($url) };
  if ($@) {
    print "\n$@\n" if $@;
    $self->agent->back;
  } else {
    $code = $self->agent->res->code;
    $self->status( "($code)\n" );
  };

  $self->activate_first_form;
  $self->sync_browser if $self->option('autosync');
  $self->add_history( sprintf q{$agent->get('%s');}."\n".q{ $agent->form_number(1) if $agent->forms and scalar @{$agent->forms};}, $url);
};

=head2 save

Download a link into a file.

If more than one link matches the RE, all matching links are
saved. The filename is taken from the last part of the
URL. Alternatively, the number of a link may also be given.

Syntax:

  save RE

=cut

sub run_save {
  my ($self,$user_link) = @_;

  unless (defined $user_link) {
    print "No link given to save\n";
    return
  };
  my @history;

  my @links = ();
  my @all_links = $self->agent->links;
  push @history, q{my @links;} . "\n";
  push @history, q{my @all_links = $agent->links();} . "\n";

  $user_link = $self->re_or_string($user_link);

  if (ref $user_link) {
    my $count = -1;
    my $re = $user_link;
    @links = map { $count++; ((defined $_->text && $_->text =~ /$re/)||(defined $_->url && $_->url =~ /$re/)) ? $count : () } @all_links;
    if (@links == 0) {
      print "No match for /$re/.\n";
    };
    push @history, q{my $count = -1;} . "\n";
    push @history, sprintf q{@links = map { $count++; ((defined $_->text && $_->text =~ qr(%s))||(defined $_->url && $_->url =~ qr(%s))) ? $count : () } @all_links;} . "\n", $re, $re;
  } else {
    @links = $user_link;
    push @history, sprintf q{@links = '%s';} . "\n", $user_link;
  };

  if (@links) {
    $self->add_history( @history,<<'CODE' );
  my $base = $agent->uri;
  for my $link (@links) {
    my $target = $all_links[$link]->url;
    my $url = URI::URL->new($target,$base);
    $target = $url->path;
    $target =~ s!^(.*/)?([^/]+)$!$2!;
    $url = $url->abs;

    # use this line instead of the next in case you want to use smart mirroring
    #$agent->mirror($url,$target);
    $agent->get( $url, ':content_file' => $target );
  };
CODE
    my $base = $self->agent->uri;
    for my $link (@links) {
      my $target = $all_links[$link]->url;
      my $url = URI::URL->new($target,$base);
      $target = $url->path;
      $target =~ s!^(.*/)?([^/]+)$!$2!;
      $url = $url->abs;
      eval {
        $self->status( "$url => $target" );
        $self->agent->get( $url, ':content_file' => $target );
      };

      warn $@ if $@;
    };
  }
};

=head2 content

Display the content for the current page.

Syntax: content [FILENAME]

If the FILENAME argument is provided, save the content to the file.

A trailing "\n" is added to the end of the content when using the
shell, so this might not be ideally suited to save binary files without
manual editing of the produced script.

=cut

sub run_content {
  my ($self, $filename) = @_;
  $self->display($filename, $self->agent->content);
  if ($filename) {
    $self->add_history( sprintf '{ my $filename = q{%s};
  local *F;
  open F, "> $filename" or die "$filename: $!";
  binmode F;
  print F $agent->content,"\n";
  close F
};', $filename );
  } else {
    $self->add_history('print $agent->content,"\n";');
  };
};

=head2 title

Display the current page title as found
in the C<< <TITLE> >> tag.

=cut

sub run_title {
    my ($self) = @_;
    my $title = $self->agent->title;
    if (! defined $title) {
        $title = "<missing title>"
    } elsif ($title eq '') {
        $title = "<empty title>"
    };
    print "$title\n";
};

=head2 headers

Prints all C<< <H1> >> through C<< <H5> >> strings found in the content,
indented accordingly.  With an argument, prints only those
levels; e.g., C<headers 145> prints H1,H4,H5 strings only.

=cut

sub run_headers {
    my ($self,$headers) = @_;
    $headers ||= "12345";

    my $content = $self->agent->content;

    # Convert the $headers argument to a RE matching
    # the header tags:
    my $wanted = join "|", map { "H$_" } split //, $headers;
    $wanted = qr/^$wanted$/i;
    #warn $wanted;

    my $p = HTML::TokeParser::Simple->new( \$content );
    while ( my $token = $p->get_token ) {
        # This prints all text in an HTML doc (i.e., it strips the HTML)
	if ($token->is_start_tag($wanted)) {
	    my $tag = $token->get_tag;

	    # Indent with two spaces per level
	    my $indent;
	    $indent = $1
	        if ($tag =~ /(\d)/);
	    $indent ||= 1;
	    $indent--;
	    $indent *= 2;

	    # advance and print the first text tag we encounter
	    while ($token and not $token->is_text and not $token->is_end_tag($wanted)) {
	        $token = $p->get_token
	    };
	    my $text = "<no text>";
	    if ($token and $token->is_text) {
	        $text = $token->as_is;
		if ($text !~ /\S/) {
		    $text = "<empty tag>";
		};
	    };

	    # Clean up whitespace
	    $text =~ s/^\s+//g;
	    $text =~ s/\s+$//g;
	    $text =~ s/\s+/ /g;

	    printf "%s:%${indent}s%s\n", $tag, "", $text;
	};
    }
};

=head2 ua

Get/set the current user agent

Syntax:

  # fake Internet Explorer
  ua "Mozilla/4.0 (compatible; MSIE 4.01; Windows 98)"

  # fake QuickTime v5
  ua "QuickTime (qtver=5.0.2;os=Windows NT 5.0Service Pack 2)"

  # fake Mozilla/Gecko based
  ua "Mozilla/5.001 (windows; U; NT4.0; en-us) Gecko/25250101"

  # set empty user agent :
  ua ""

=cut

sub run_ua {
  my ($self,$ua) = @_;
  my ($result) = $self->agent->agent;
  if (scalar @_ == 2) {
    $self->agent->agent($ua);
    $self->add_history( sprintf q{$agent->agent('%s');}, $ua);
  } else {
    print "Current user agent: $result\n";
  };
};

=head2 links

Display all links on a page

The links numbers displayed can used by C<open> to directly
select a link to follow.

=cut

sub run_links {
  my ($self) = @_;
  my @links = $self->agent->links;
  my $count = 0;
  for my $link (@links) {
    # print "[", $count++, "] ", $link->[1],"\n";
    print sprintf "[%s] %s\n", $count++, $self->link_text($link);
  };
};

=head2 images

Display images on a page

=cut

sub run_images {
    my ($self) = @_;

    my @images = $self->agent->images;
    my $count  = 0;

    for my $image ( @images ) {
        print sprintf("[%d] \"%s\" %s\n", $count++, $image->alt, $image->url);
    }
}

=head2 parse

Dump the output of HTML::TokeParser of the current content

=cut

sub run_parse {
  my ($self) = @_;
  my $content = $self->agent->content;
  my $p = HTML::TokeParser->new(\$content);

	#$p->report_tags(qw(form input textarea select optgroup option));

  while (my $token = $p->get_token()) {
  #while (my $token = $p->get_tag("frame")) {
  #  print "<",$token->[0],":",ref $token->[1] ? $token->[1]->{src} : "",">";
    print "<",$token->[0],":",$token->[1],">";
  }
};

=head2 forms

Display all forms on the current page.

=cut

sub run_forms {
  my ($self,$number) = @_;

  my $count = 1;
  my $agent = $self->agent;
  my @forms = $agent->forms;
  if (@forms) {
    for (@forms) {
      print "Form [",$count++,"]\n";
      $_->dump;
    };
  } else {
    print "No forms on current page.\n";
  };
};

=head2 form

Select the form named NAME

If NAME matches C</^\d+$/>, it is assumed to be the (1-based) index
of the form to select. There is no way of selecting a numerically
named form by its name.

=cut

sub run_form {
  my ($self,$name) = @_;
  my $number;

  unless ($self->agent->current_form) {
    print "There is no form on this page.\n";
    return;
  };

  if ($name) {
    my ($method,$val);
    $val = $name;
    if ($name =~ /^\d+$/) {
      $method = 'form_number';
    } else {
      $method = 'form_name';
      $val = qq{'$name'};
    };
    eval {
      $self->agent->$method($name);
      $self->add_history(sprintf q{$agent->%s(%s);}, $method, $val);
      $self->status($self->agent->current_form->dump);
    };
    $self->display_user_warning( $@ )
      if ($@);
  } else {
    my $count = 1;
    my @forms = $self->agent->forms;
    if (@forms) {
      for my $form (@forms) {
        print sprintf "Form [%s] (%s)\n", $count++, ($form->attr('name') || "<no name>");
        $form->dump;
      };
    } else {
      print "No forms found on the current page.\n";
    };
  };
};

=head2 dump

Dump the values of the current form

=cut

sub run_dump {
  my ($self) = @_;
  my $form = $self->agent->current_form;
  if ($form) {
    $form->dump
  } else {
    warn "There is no form on the current page\n"
      if $self->option('warnings');
  };
};

=head2 value

Set a form value

Syntax:

  value NAME [VALUE]

=cut

sub run_value {
  my ($self,$key,@values) = @_;

  # dwim on @values
  my $value = join " ", @values;

  # Look if we are filling a checkbox set:
  #my $field = $self->agent->current_form->find_input($key);
  #if ($field and ($field->type eq 'checkbox')) {
  #  # We want to explicitly multiple checkboxes. This means we
  #  # have to clear all checkboxes and then set them explicitly.
 #
 #   for my $value (@values) {
  #    # Blatantly stolen from WWW::Mechanize::Ticky by
  #    # Mark Fowler E<lt>mark@twoshortplanks.comE<gt>
  #    my $input;
  #    my $index = 0;
  #    INPUT: while($input = $self->agent->current_form->find_input($name,"checkbox",$index)) {
  #      # can't guarentee that the first element will be undef and the second
  #      # element will be the right name
  #      foreach my $val ($input->possible_values()) {
  #        next unless defined $val;
  #        if ($val eq $value) {
  #          $input->value($set ? $value : undef);
  #          last INPUT;
  #        }
  #      }
  #
  #      # move onto the next input
  #      $index++;
  #    }
  #  };
  #};

  eval {
    local $^W;
    $self->agent->current_form->value($key,$value);
    # Hmm - neither $key nor $value may contain backslashes nor single quotes ...
    $self->add_history( sprintf q{{ local $^W; $agent->current_form->value('%s', '%s'); };}, $key, $value);
  };
  warn $@ if $@;
};

=head2 tick

Set checkbox marks

Syntax:

  tick NAME VALUE(s)

If no value is given, all boxes are checked.

=cut

sub tick {
  my ($self,$tick,$key,@values) = @_;
  eval {
    local $^W;
    for my $value (@values) {
      $self->agent->$tick($key,$value);
    };
    # Hmm - neither $key nor $value may contain backslashes nor single quotes ...
    my $value_str = join ", ", map {qq{'$_'}} @values;
    $self->add_history( sprintf q{{ local $^W; for (%s) { $agent->%s('%s', $_); };}}, $value_str, $tick, $key);
  };
  warn $@ if $@;
};

sub tick_all {
  my ($self,$tick,$name) = @_;
  eval {
    local $^W;
    my $index = 1;
    while(my $input = $self->agent->current_form->find_input($name,'checkbox',$index)) {
      my $value = (grep { defined $_ } ($input->possible_values()))[0];
      $self->agent->$tick($name,$value);
      $index++;
    };
    $self->add_history( sprintf q{
    { local $^W; my $index = 1;
      while(my $input = $agent->current_form->find_input('%s','checkbox',$index)) {
        my $value = (grep { defined $_ } ($input->possible_values()))[0];
        $agent->%s('%s',$value);
        $index++;
      };
    }}, $name, $tick, $name);
  };
  warn $@ if $@;
};

sub run_tick {
  my ($self,$key,@values) = @_;
  if (scalar @values) {
    $self->tick( "tick", $key, @values )
  } else {
    $self->tick_all( "tick", $key )
  };
};

=head2 untick

Remove checkbox marks

Syntax:

  untick NAME VALUE(s)

If no value is given, all marks are removed.

=cut

sub run_untick {
  my ($self,$key,@values) = @_;
  if (scalar @values) {
    $self->tick( "untick", $key, @values )
  } else {
    $self->tick_all( "untick", $key )
  };
};

=head2 submit

submits the form without clicking on any button

=cut

sub run_submit {
  my ($self) = @_;
  eval {
    my $res = $self->agent->submit;
    $self->status( $res->code."\n" );
    $self->add_history('$agent->submit();');
    $self->sync_browser if $self->option('autosync');
  };
  warn $@ if $@;
};

=head2 click

Clicks on the button named NAME.

No regular expression expansion is done on NAME.

Syntax:

  click NAME

If you have a button that has no name (displayed as NONAME),
use

  click ""

to click on it.

=cut

sub run_click {
  my ($self,$button) = @_;
  $button ||= "";
  eval {
    my $res = $self->agent->click($button);
    $self->status( "(".$res->code.")\n");
    $self->activate_first_form;
    $self->sync_browser if ($self->option('autosync'));
    $self->add_history( sprintf qq{\$agent->click('%s');}, $button );
  };
  warn $@ if $@;
};

=head2 open

<open> accepts one argument, which can be a regular expression or the number
of a link on the page, starting at zero. These numbers are displayed by the
C<links> function. It goes directly to the page if a number is used
or if the RE has one match. Otherwise, a list of links matching
the regular expression is displayed.

The regular expression should start and end with "/".

Syntax:

  open  [ RE | # ]

=cut

sub run_open {
  my ($self,$user_link) = @_;
  $user_link = $self->re_or_string($user_link);
  my $link = $user_link;
  my $user_link_expr = ref $link ? qq{qr($link)} : qq{'$link'};
  unless (defined $link) {
    print "No link given\n";
    return
  };

  if ($link =~ /\D/) { # looks like a name/re
    my $re = $link if ref $link;
    my $count = -1;
    my @possible_links = $self->agent->links();
    my @links = defined $re
        ? map { $count++; my $t = $_->text; defined $t && $t =~ /$re/ ? $count : () } @possible_links
        : map { $count++; my $t = $_->text; defined $t && $t eq $link ? $count : () } @possible_links;
    if (@links > 1) {
      $self->print_pairs([ @links ],[ map {$possible_links[$_]->[1]} @links ]);
      undef $link;
    } elsif (@links == 0) {
      print "No match.\n";
      undef $link;
    } else {
      $self->status( "Found $links[0]\n" );
      $link = $links[0];
      if ($possible_links[$count]->url =~ /^javascript:(.*)/i) {
        print "Can't follow javascript link $1\n";
        undef $link;
      };
    };
  };

  if (defined $link) {
    eval {
      $self->agent->follow_link('n' => $link +1);
      my ( $hist_option, $hist_value ) =
          $user_link =~ /^\d+$/
              ? ('n', $user_link + 1 )
              : ref $user_link
          ? ( 'text_regex', $user_link_expr )
          : ( 'text'      , $user_link_expr );
      $self->add_history(
          sprintf qq{\$agent->follow_link('%s' => %s);},
          $hist_option,
          $hist_value
      );
      $self->activate_first_form;
      if ($self->option('autosync')) {
        $self->sync_browser;
      };
      $self->status( "(".$self->agent->res->code.")\n" );
    };
    warn $@ if $@;
  };
};

# Complete partially typed links :
sub comp_open {
  my ($self,$word,$line,$start) = @_;
  my @completions = eval { grep {/^$word/} map { $self->link_text( $_ )} ($self->agent->find_all_links()) };
  $self->display_user_warning($@) if $@;
  return @completions;
};

=head2 back

Go back one page in the browser page history.

=cut

sub run_back {
  my ($self) = @_;
  eval {
    $self->agent->back();
    $self->add_history('$agent->back();');
    $self->sync_browser
      if ($self->option('autosync'));
  };
  warn $@ if $@;
};

=head2 reload

Repeat the last request, thus reloading the current page.

Note that also POST requests are blindly repeated, as this command
is mostly intended to be used when testing server side code.

=cut

sub run_reload {
    my ($self) = @_;
    eval {
        $self->agent->reload();
        $self->add_history('$agent->reload;');
        $self->sync_browser
          if ($self->option('autosync'));
    };
    $self->display_user_warning($@)
        if $@;
};

=head2 browse

Open the web browser with the current page

Displays the current page in the browser.

=cut

sub run_browse {
  my ($self) = @_;
  $self->sync_browser;
};

=head2 set

Set a shell option

Syntax:

   set OPTION [value]

The command lists all valid options. Here is a short overview over
the different options available :

    autosync      - automatically synchronize the browser window
    autorestart   - restart the shell when any required module changes
                    This does not work with C<-e> oneliners.
    watchfiles    - watch all required modules for changes
    cookiefile    - the file where to store all cookies
    dumprequests  - dump all requests to STDOUT
    dumpresponses - dump the headers of the responses to STDOUT
    verbose       - print commands to STDERR as they are run,
                    when sourcing from a file

=cut

sub run_set {
  my ($self,$option,$value) = @_;
  $option ||= "";
  if ($option && exists $self->{options}->{$option}) {
    if ($option and defined $value) {
      $self->option($option,$value);
    } else {
      $self->print_pairs( [$option], [$self->option($option)] );
    };
  } else {
    print "Unknown option '$option'\n" if $option;
    print "Valid options are :\n";
    $self->print_pairs( [keys %{$self->{options}}], [ map {$self->option($_)} (keys %{$self->{options}}) ] );
  };
};

=head2 history

Display your current session history as the relevant commands.

Syntax:

  history [FILENAME]

Commands that have no influence on the browser state are not added
to the history. If a parameter is given to the C<history> command,
the history is saved to that file instead of displayed onscreen.

=cut

sub run_history {
  my ($self,$filename) = @_;
  $self->display($filename,$self->history);
};

=head2 script

Display your current session history as a Perl script using WWW::Mechanize.

Syntax:

  script [FILENAME]

If a parameter is given to the C<script> command, the script is saved to
that file instead of displayed on the console.

This command was formerly known as C<history>.

=cut

sub run_script {
  my ($self,$filename) = @_;
  $self->display($filename,$self->script("  "));
};

=head2 comment

Adds a comment to the script and the history. The comment
is prepended with a \n to increase readability.

=cut

sub run_comment {
  my $self = shift;
  if (@_)
  {
        $self->add_history("\n# @_ ");
  }
}

=head2 fillout

Fill out the current form

Interactively asks the values hat have no preset
value via the autofill command.

=cut

sub run_fillout {
  my ($self) = @_;
  my @interactive_values;
  eval {
    $self->{answers} = [];
    my $form = $self->agent->current_form;
    if ($form) {
      $self->{formfiller}->fill_form($self->agent->current_form);
      @interactive_values = @{$self->{answers}};
    } else {
      $self->display_user_warning( "No form found on the current page." )
    };
  };
  warn $@ if $@;
  $self->add_history( join( "\n",
                      map { sprintf( q[$formfiller->add_filler( '%s' => Fixed => '%s' );], $_->[0], defined $_->[1] ? $_->[1] : '' ) } @interactive_values) . '$formfiller->fill_form($agent->current_form);');
};

=head2 auth

Set basic authentication credentials.

Syntax:

  auth user password

If you know the authority and the realm in advance, you can
presupply the credentials, for example at the start of the script :

	>auth corion secret
	>get http://www.example.com
	Retrieving http://www.example.com(200)
	http://www.example.com>

=cut

sub run_auth {
    my ($self) = shift;
    my ($user, $password);
    if (scalar @_ == 2) {
      ($user,$password) = @_;
      $password = "" if not defined $password;

      my $code = sub {
          $self->agent->credentials($user => $password);
      };
      $code->();
      my $body = $self->munge_code($code);

      $self->add_history(
          sprintf( q{my ($user,$password) = ('%s','%s');}, $user, $password),
          $body,
      );
    } else {
        $self->display_user_warning("Authentication only supports the two-argument form");
    };
};

=head2 table

Display a table described by the columns COLUMNS.

Syntax:

  table COLUMNS

Example:

  table Product Price Description

If there is a table on the current page that has in its first row the three
columns C<Product>, C<Price> and C<Description> (not necessarily in that order),
the script will display these columns of the whole table.

The C<HTML::TableExtract> module is needed for this feature.

=cut

sub run_table {
  my ($self,@columns) = @_;

  eval {
    require HTML::TableExtract;
    die "I need a HTML::TableExtract version of 2 or greater. I found '$HTML::TableExtract::VERSION'"
        if $HTML::TableExtract::VERSION < 2;

    my $code = sub {
        my $table = HTML::TableExtract->new( headers => [ @columns ] );
        (my $content = $self->agent->content) =~ s/\&nbsp;?//g;
        $table->parse($content);
        my @lines;
        push @lines, join(", ", @columns),"\n";
        for my $ts ($table->table_states) {
          for my $row ($ts->rows) {
            push @lines, ">".join(", ", @$row)."<\n";
          };
        };
        $self->print_paged(@lines);
    };
    $code->();
    my $body = $self->munge_code($code);

    $self->add_history(
        "require HTML::TableExtract;\n",
        sprintf( 'my @columns = ( %s );'."\n", join( ",", map( { s/(['\\])/\\$1/g; qq('$_') } @columns ))),
        $body
    );
  };
  $self->display_user_warning( "Couldn't load HTML::TableExtract: $@" )
    if ($@);
};

=head2 tables

Display a list of tables.

Syntax:

  tables

This command will display the top row for every
table on the current page. This is convenient if you want
to find out what the exact spellings for each column are.

The command does not always work nice, for example if a
site uses tables for layout, it will be harder to guess
what tables are irrelevant and what tables are relevant.

L<HTML::TableExtract> is needed for this feature.

=cut

sub run_tables {
  my ($self,@columns) = @_;

  eval {
    require HTML::TableExtract;
    die "I need a HTML::TableExtract version of 2 or greater. I found '$HTML::TableExtract::VERSION'"
        if $HTML::TableExtract::VERSION < 2;

    my $table = HTML::TableExtract->new( subtables => 1 );
    (my $content = $self->agent->content) =~ s/\&nbsp;?//g;
    $table->parse($content);
    my @lines;
    for my $ts ($table->table_states) {
      my ($row) = $ts->rows;
      if (grep { /\S/ } (@$row)) {
        push @lines, join( "", "Table ", join( ",",$ts->coords ), " : ", join(",", @$row),"\n" );
      };
    };
    $self->print_paged(@lines);
  };
  $self->display_user_warning( $@ )
    if $@;
};

=head2 cookies

Set the cookie file name

Syntax:

  cookies FILENAME

=cut

sub run_cookies {
  my ($self,$filename) = @_;
  $self->agent->cookie_jar(HTTP::Cookies->new(
    file => $filename,
    autosave => 1,
    ignore_discard => 1,
  ));
};

sub run_ {
  # ignore empty lines
};

=head2 autofill

Define an automatic value

Sets a form value to be filled automatically. The NAME parameter is
the WWW::Mechanize::FormFiller::Value subclass you want to use. For
session fields, C<Keep> is a good candidate, for interactive stuff,
C<Ask> is a value implemented by the shell.

A field name starting and ending with a slash (C</>) is taken to be
a regular expression and will be applied to all fields with their
name matching the expression. A field with a matching name still
takes precedence over the regular expression.

Syntax:

  autofill NAME [PARAMETERS]

Examples:

  autofill login Fixed corion
  autofill password Ask
  autofill selection Random red green orange
  autofill session Keep
  autofill "/date$/" Random::Date string "%m/%d/%Y"

=cut

sub run_autofill {
  my ($self,$name,$class,@args) = @_;
  @args = ($self)
    if ($class eq 'Ask');
  if ($class) {
    my $name_vis;
    $name = $self->re_or_string($name);
    if (ref $name) {
      $name_vis = qq{qr($name)};
      #warn "autofill RE detected $name";
    } else {
      $name_vis = qq{"$name"};
    };
    eval {
      $self->{formfiller}->add_filler($name,$class,@args);
      $self->add_history( sprintf qq{\$formfiller->add_filler( %s => "%s" => %s ); }, $name_vis, $class, join( ",", map {qq{'$_'}} @args));
    };
    warn $@
      if $@;
  } else {
    warn "No class for the autofiller given\n";
  };
};

=head2 eval

Evaluate Perl code and print the result

Syntax:

  eval CODE

For the generated scripts, anything matching the regular expression
C</\$self-E<gt>agent\b/> is automatically
replaced by C<$agent> in your eval code, to do the Right Thing.

Examples:

  # Say hello
  eval "Hello World"

  # And take a look at the current content type
  eval $self->agent->ct

=cut

sub run_eval {
  my ($self,@rest) = @_;
  my $code = $self->line;
  if ($code !~ /^eval\s+(.*)$/sm) {
      #warn "Don't know what to do with '$code'";
      $self->display_user_warning("Don't know what to make of '$code'");
  } else {
    my $str = $1;
    my $code = qq{ do { $str } };
    my @res = eval $code;
    if (my $err = $@) {
        #warn "Don't know what to do with '$str' ($err)";
        $self->display_user_warning($err);
        return
    };
    print join "", @res,"\n";


    my $script_code = $self->munge_code(qq{print $code, "\\n";});
    #warn "Script: $script_code<<";
    $self->add_history( $script_code );
  };
};

=head2 source

Execute a batch of commands from a file

Syntax:

  source FILENAME

=cut

sub run_source {
  my ($self,$file) = @_;
  if ($file) {
    eval { $self->source_file($file); };
    if ($@) {
      $self->display_user_warning( "Could not source file '$file' : $@" );
    };
  } else {
    print "Syntax: source FILENAME\n";
  };
};

=head2 versions

Print the version numbers of important modules

Syntax:

  versions

=cut

sub run_versions {
  my ($self) = @_;
  no strict 'refs';
  my @modules = qw( WWW::Mechanize::Shell WWW::Mechanize::FormFiller WWW::Mechanize
  							    Term::Shell
                    HTML::Parser HTML::TableExtract HTML::Parser HTML::Display
                    Pod::Constants
                    File::Modified );
  eval "require $_" foreach @modules;
  $self->print_pairs( [@modules], [map { defined ${"${_}::VERSION"} ? ${"${_}::VERSION"} : "<undef>" } @modules]);
};

=head2 timeout

Set new timeout value for the agent. Effects all subsequent
requests. VALUE is in seconds.

Syntax:

  timeout VALUE

=cut

sub run_timeout {
  my ($self, $timeout) = @_;
  if ($timeout) {
    eval { $self->agent->timeout($timeout); };
    if ($@) {
      print "Could not set new timeout value : $@";
    };
    $self->add_history( sprintf q{$agent->timeout(%s);}, $timeout);
  } else {
    print "Syntax: timeout VALUE\n";
  };
};

=head2 ct

prints the content type of the most current response.

Syntax:

  ct

=cut

sub run_ct {
  my ($self) = @_;
  if ($self->agent->content) {
    eval { print $self->agent->ct, "\n"; };
    if ($@) {
      print "Could not get content-type : $@";
    };
    $self->add_history('print $agent->ct, "\n";');
  } else {
    print "No content available yet!\n";
  }
};

=head2 referrer

set the value of the Referer: header

Syntax:

  referer URL
  referrer URL

=cut

sub run_referrer {
  my ($self, $referrer) = @_;
  if (defined $referrer) {
    eval { $self->agent->add_header(Referer => $referrer); };
    if ($@) {
      print "Could not set referrer : $@";
    };
    # warn "Added $referrer";
    $self->add_history( sprintf q{$agent->add_header('Referer', '%s');}, $referrer);
  } else {
    # print "syntax: referer|referrer URL\n";
    eval {
			print "Referer: ", $self->agent->{req}->header('Referer'),"\n";
    };
  }
};

=head2 referer

Alias for referrer

=cut

sub run_referer {
  goto &WWW::Mechanize::Shell::run_referrer
};
# sub alias_referrer { qw(referer) };

=head2 response

display the last server response

=cut

sub run_response {
  my ($self) = @_;
  eval { $self->print_paged( $self->agent->res->as_string )};
};

=head2 C<< $shell->munge_code( CODE ) >>

Munges a coderef to become code fit for
output independent of WWW::Mechanize::Shell.

=cut

our %munge_map = (
        '^{' => '',
        '}$' => '',
        '\$self->print_paged' => 'print ',
        '\$self->agent'       => '$agent',
        '\s*package ' . __PACKAGE__ . ';' => '',
);

sub munge_code {
    my ($self, $code) = @_;
    my $body;

    if (ref $code) {
        # Munge code
        my $d = B::Deparse->new('-sC');
	if ($d->can('ambient_pragmas')) {
            $d->ambient_pragmas(strict => 'all', warnings => 'all');
	};
        $body = $d->coderef2text($code);
    } else {
        $body = $code
    }

    while (my ($key,$val) = each %munge_map) {
        $body =~ s/$key/$val/gs;
    };

    $body
};

=head2 C<< shell >>

This subroutine is exported by default as a convenience method
so that the following oneliner invocation works:

    perl -MWWW::Mechanize::Shell -eshell

You can pass constructor arguments to this
routine as well. Any scripts given in C<< @ARGV >>
will be run. If C<< @ARGV >> is empty,
an interactive loop will be started.

=cut

sub shell {
  my @args = ("shell",@_);
  my $shell = WWW::Mechanize::Shell->new(@args);

  if (@ARGV) {
    $shell->source_file( @ARGV );
  } else {
    $shell->cmdloop;
  };
};

{
  package # hide from CPAN
      WWW::Mechanize::FormFiller::Value::Ask;
  use WWW::Mechanize::FormFiller;
  use base 'WWW::Mechanize::FormFiller::Value::Callback';

  our $VERSION = '0.59';

  sub new {
    my ($class,$name,$shell) = @_;
    # Using the name here to allow for late binding and overriding via eval()
    # from the shell command line
    #warn __PACKAGE__ . "::ask_value";
    my $self = $class->SUPER::new($name, __PACKAGE__ . '::ask_value');
    $self->{shell} = $shell;
    Carp::carp "WWW::Mechanize::FormFiller::Value::Ask->new called without a value for the shell" unless $self->{shell};

    $self;
  };

  sub ask_value {
    my ($self,$input) = @_;
    my @values;
    if ($input->possible_values) {
      @values = $input->possible_values;
      print join( "|", @values ), "\n";
    };
    my $value;
    $value = $input->value;
    #warn $value if $value;
    if ($input->type !~ /^(submit|hidden)$/) {
      $value = $self->{shell}->prompt("(" . $input->type . ")" . $input->name . "> [" . ($input->value || "") . "] ",
                              ($input->value||''), @values );
      undef $value if ($value eq "" and $input->type eq "checkbox");
      push @{$self->{shell}->{answers}}, [ $input->name, $value ];
    };
    $value;
  };
};

__END__

=head1 SAMPLE SESSIONS

=head2 Entering values

  # Search for a term on Google
  get http://www.google.com
  value q "Corions Homepage"
  click btnG
  script
  # (yes, this is a bad example of automating, as Google
  #  already has a Perl API. But other sites don't)

=head2 Retrieving a table

  get http://www.perlmonks.org
  open "/Saints in/"
  table User Experience Level
  script
  # now you have a program that gives you a csv file of
  # that table.

=head2 Uploading a file

  get http://aliens:xxxxx/
  value f path/to/file
  click "upload"

=head2 Batch download

  # download prerelease versions of my modules
  get http://www.corion.net/perl-dev
  save /.tar.gz$/

=head1 REGULAR EXPRESSION SYNTAX

Some commands take regular expressions as parameters. A regular
expression B<must> be a single parameter matching C<^/.*/([isxm]+)?$>, so
you have to use quotes around it if the expression contains spaces :

  /link_foo/       # will match as (?-xims:link_foo)
  "/link foo/"     # will match as (?-xims:link foo)

Slashes do not need to be escaped, as the shell knows that a RE starts and
ends with a slash :

  /link/foo/       # will match as (?-xims:link/foo)
  "/link/ /foo/"   # will match as (?-xims:link/\s/foo)

The C</i> modifier works as expected.
If you desire more power over the regular expressions, consider dropping
to Perl or recommend me a good parser module for regular expressions.

=head1 DISPLAYING HTML

WWW::Mechanize::Shell now uses the module HTML::Display
to display the HTML of the current page in your browser.
Have a look at the documentation of HTML::Display how to
make it use your browser of choice in the case it does not
already guess it correctly.

=head1 FILLING FORMS VIA CUSTOM CODE

If you want to stay within the confines of the shell, but still
want to fill out forms using custom Perl code, here is a recipe
how to achieve this :

Code passed to the C<eval> command gets evalutated in the WWW::Mechanize::Shell
namespace. You can inject new subroutines there and these get picked
up by the Callback class of WWW::Mechanize::FormFiller :

  # Fill in the "date" field with the current date/time as string
  eval sub &::custom_today { scalar localtime };
  autofill date Callback WWW::Mechanize::Shell::custom_today
  fillout

This method can also be used to retrieve data from shell scripts :

  # Fill in the "date" field with the current date/time as string
  # works only if there is a program "date"
  eval sub &::custom_today { chomp `date` };
  autofill date Callback WWW::Mechanize::Shell::custom_today
  fillout

As the namespace is different between the shell and the generated
script, make sure you always fully qualify your subroutine names,
either in your own namespace or in the main namespace.

=head1 GENERATED SCRIPTS

The C<script> command outputs a skeleton script that reproduces
your actions as done in the current session. It pulls in
C<WWW::Mechanize::FormFiller>, which is possibly not needed. You
should add some error and connection checking afterwards.

=head1 ADDING FIELDS TO HTML

If you are automating a JavaScript dependent site, you will encounter
JavaScript like this :

    <script>
      document.write( "<input type=submit name=submit>" );
    </script>

HTML::Form will not know about this and will not have provided a
submit button for you (understandably). If you want to create such
a submit button from within your automation script, use the following
code :

  $agent->current_form->push_input( submit => { name => "submit", value =>"submit" } );

This also works for other dynamically generated input fields.

To fake an input field from within a shell session, use the C<eval> command :

  eval $self->agent->current_form->push_input(submit=>{name=>"submit",value=>"submit"});

And yes, the generated script should do the Right Thing for this eval as well.

=head1 LOCAL FILES

If you want to use the shell on a local file without setting up a C<http> server
to serve the file, you can use the C<file:> URI scheme to load it into the "browser":

  get file:local.html
  forms

=head1 PROXY SUPPORT

Currently, the proxy support is realized via a call to
the C<env_proxy> method of the WWW::Mechanize object, which
loads the proxies from the environment. There is no provision made
to prevent using proxies (yet). The generated scripts also
load their proxies from the environment.

=head1 ONLINE HELP

The online help feature is currently a bit broken in C<Term::Shell>,
but a fix is in the works. Until then, you can re-enable the
dynamic online help by patching C<Term::Shell> :

Remove the three lines

      my $smry = exists $o->{handlers}{$h}{smry}
    ? $o->summary($h)
    : "undocumented";

in C<sub run_help> and replace them by

      my $smry = $o->summary($h);

The shell works without this patch and the online help is still
available through C<perldoc WWW::Mechanize::Shell>

=head1 BUGS

Bug reports are very welcome - please use the RT interface at
https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Shell or send a
descriptive mail to bug-WWW-Mechanize-Shell@rt.cpan.org . Please
try to include as much (relevant) information as possible - a test script
that replicates the undesired behaviour is welcome every time!

=over 4

=item *

The two parameter version of the C<auth> command guesses the realm from
the last received response. Currently a RE is used to extract the realm,
but this fails with some servers resp. in some cases. Use the four
parameter version of C<auth>, or if not possible, code the extraction
in Perl, either in the final script or through C<eval> commands.

=item *

The shell currently detects when you want to follow a JavaScript link and tells you
that this is not supported. It would be nicer if there was some callback mechanism
to (automatically?) extract URLs from JavaScript-infected links.

=back

=head1 TODO

=over 4

=item *

Add XPath expressions (by moving C<WWW::Mechanize> from HTML::Parser to XML::XMLlib
or maybe easier, by tacking Class::XPath onto an HTML tree)

=item *

Add C<head> as a command ?

=item *

Optionally silence the HTML::Parser / HTML::Forms warnings about invalid HTML.

=back

=head1 EXPORT

The routine C<shell> is exported into the importing namespace. This
is mainly for convenience so you can use the following commandline
invocation of the shell like with CPAN :

  perl -MWWW::Mechanize::Shell -e"shell"

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/WWW-Mechanize-Shell>.

=head1 SUPPORT

The public support forum of this module is
L<http://perlmonks.org/>.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2002-2020 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module. More tests are also very welcome !

=head1 SEE ALSO

L<WWW::Mechanize>,L<WWW::Mechanize::FormFiller>,L<WWW::Mechanize::Firefox>

=cut
