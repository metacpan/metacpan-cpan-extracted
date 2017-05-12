package Pod::Simple::Wiki::Twiki::Upload;

use strict;
use warnings;

use Data::Dumper;
use File::Find;
use File::Spec;
use IO::File;
require Exporter;

our $VERSION = 0.3;
our @ISA = qw(Exporter);
our @EXPORT = qw(make_file_list);


sub make_file_list
{
	my %bin_files = find_bin_pods();
	my %files;
	for my $bin (keys %bin_files) {
		my $x = $bin;
		$x =~ s=.*/(.+)=$1=;
		$files{"$x"} = $bin_files{$bin};
	}
	for my $f (@{rscan_dir('lib', qr/\.(pm|pod)$/)}) {
		my $base = $f;
		$base =~ s/\.pm$//;
		my $mod = $base;
		$mod =~ s=/=::=g;
		$mod =~ s/^lib:://;
		if (contains_pod($f)) {
			$files{$mod} = $f;
		}
		elsif (-e "$base.pod") {
			$files{$mod} = "$base.pod";
		} 
	}
	return %files;
}

sub twiki_upload 
{
	my ($twikiroot, $twikiweb) = @_;
	$twikiweb ||= 'Main';

	my %files = make_file_list;
	return unless %files;

	my $user = $ENV{TWIKI_USER} || prompt("What is your twiki user id?", scalar(getpwuid($<)));
	chomp($user);
	$user =~ s/ $//;
	system("stty -echo");
	my $pass = $ENV{TWIKI_PASS} || prompt("What is your twiki password?", '');
	chomp($pass);
	system("stty echo");
	print "\n";

	require IO::Scalar or die;
	import IO::Scalar;

	require Pod::Simple::Wiki or die;
	import Pod::Simple::Wiki;

	require WWW::TWikiClient or die;
	import WWW::TWikiClient;

	{
		package Private::Module::WWW::TWikiClient;
		use strict;
		use warnings;
		our @ISA = qw(WWW::TWikiClient);
		sub _skin_regex_authentication_failed {
			return qr/Please enter your username and pas|Unrecognized user and/;
		}

		sub get_old_stuff {
			my ($self, $topic) = @_;
			$self->get("$twikiroot/edit/$twikiweb/$topic");
			die unless $self->{form};
			die unless $self->{form}{action};
			die unless $self->{form}{inputs};
			die unless $self->{form}{inputs}[0];
			die unless $self->{form}{inputs}[0]{name} eq 'text';
			die unless $self->{form}{inputs}[0]{type} eq 'textarea';
			return $self->{form}{inputs}[0]{value};
		}

		sub save_new_stuff {
			my ($self, $stuff) = @_;
			$self->submit_form(
				form_name	=> 'main',
				fields		=> {
					text		=> $stuff,
					action_save	=> 'Save',
				},
			);
		}
	}

	my $twiki = new Private::Module::WWW::TWikiClient (
		verbose			=> 1, 
		auth_user		=> $user,
		auth_passwd		=> $pass,
		bin_url			=> $twikiroot,
	);
	die "could get twiki link" unless $twiki;

	$twiki->get("$twikiroot/login/TWiki/LoginName");
	$twiki->submit_form(
		form_name	=> 'loginform',
		fields		=> {
			username	=> $user,
			password	=> $pass,
		},
	);

	my $newcontent = qr{\A\s+-- Main\.\S+ -\s+\d+ (?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) 20\d\d\s+\Z}s;

	$| = 1;
	for my $name (sort keys %files) {
		my $file = $files{$name};
		print "working on $name (from $file)... ";
		my $parser = Pod::Simple::Wiki->new('twiki');
		my $newtext;
		my $outfh = new IO::Scalar \$newtext;

		open my $input, "<", $file or die "open $file: $!";

		$parser->output_fh($outfh);
		$parser->parse_file($input);

		my $n = $name;
		#$n =~ s/:://g;
		#$n = ucfirst($n);
		$twiki->current_default_web('Perl');
		$twiki->current_topic("$n");

		my $old_content = $twiki->get_old_stuff($n);


		my $new;
		pos($newtext) = 0;
		while (pos($newtext) < length($newtext)) {
			if ($newtext =~ m{\G((?:.(?!<verbatim>))+)}gcs) {
				my $t = $1;
				$t =~ s/\b([\w+:]+)\b/[[Perl.$1][$1]]/g;
				$new .= $t;
			} elsif ($newtext =~ m{(<verbatim>.*?</verbatim>)}gcs) {
				$new .= $1;
			} else {
				die;
			}
		}
		$newtext = $new;

		my $header = "This is auto-generated content from =$file=, do not edit";
		my $new_content = $header."\n\n".$newtext;
		if ($old_content eq $new_content) {
			print "already up-to-date.\n";
		} elsif ($old_content =~ /$newcontent/ or $old_content =~ /\Q$header\E/) {
			# my $res = $twiki->save_topic($header."\n\n".$newtext);
			$twiki->save_new_stuff($new_content);
			print "uploaded\n";
		} else {
			print "skipping: content doesn't match starting cookie\n";
		}
	}
}


sub contains_pod {
	my ($file) = @_;
	return '' unless -T $file;  # Only look at text files

	my $fh = IO::File->new( $file ) or die "Can't open $file: $!";
	while (my $line = <$fh>) {
		return 1 if $line =~ /^\=(?:head|pod|item)/;
	}

	return '';
}


sub find_bin_pods {
	my %files;
	for my $spec ("blib/script") {
		my $dir = localize_dir_path($spec);
		next unless -e $dir;
		for my $file ( @{ rscan_dir( $dir ) } ) {
			next if $file =~ /\.bat$/;
			if ( contains_pod( $file ) ) {
				$files{$file} = $file;
			}
			elsif (my $pm_file = find_client_lib( $file ) ) {
				$files{$file} = $pm_file;
			}
		}
	}
	return %files;
}


sub find_client_lib {
	my ($file) = @_;
	return '' unless -T $file;      # Only look at text files

	my $fh = IO::File->new( $file ) or die "Can't open $file: $!";
	while (my $line = <$fh>) {
		next if $line !~ /^use\s+(?:aliased\s+(['"]))((?:[\w:]+)?Client::\w+)\1;$/;
		# We have a client class.
		return join( '/', 'lib', split /::/, $2 ) . '.pm'
	}
	return;
}


sub localize_dir_path {
	my ($path) = @_;
	return File::Spec->catdir( split m{/}, $path );
}


sub rscan_dir {
	my ($dir, $pattern) = @_;
	my @result;
	local $_; # find() can overwrite $_, so protect ourselves
	my $subr = !$pattern ? sub {push @result, $File::Find::name} :
		!ref($pattern) || (ref $pattern eq 'Regexp') ? sub {push @result, $File::Find::name if /$pattern/} :
		ref($pattern) eq 'CODE' ? sub {push @result, $File::Find::name if $pattern->()} : die "Unknown pattern type";
  
	File::Find::find({wanted => $subr, no_chdir => 1}, $dir);
	return \@result;
}


# NOTE this is a blocking operation if(-t STDIN)
sub _is_interactive {
	return -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;   # Pipe?
}

sub _is_unattended {
	return $ENV{PERL_MM_USE_DEFAULT} || ( ! _is_interactive() && eof STDIN );
}

sub _readline {
	return undef if _is_unattended();

	my $answer = <STDIN>;
	chomp $answer if defined $answer;
	return $answer;
}


sub prompt {
	my ($mess) = @_;
	if (not defined $mess) {
		die "prompt() called without a prompt message";
	}

	# use a list to distinguish a default of undef() from no default
	my @def;
	@def = (shift) if @_;
	# use dispdef for output
	my @dispdef = scalar(@def) ?  ('[', (defined($def[0]) ? $def[0] . ' ' : ''), ']') : (' ', '');

	local $|=1;
	print "$mess ", @dispdef;

	if ( _is_unattended() && !@def ) {
		die "ERROR: This runseems to be unattended, but there is no default value for this question.  Aborting.";
	}

	my $ans = _readline();

	     # Ctrl-D or unattendeda           User hit return
	if ( !defined($ans)                    or !length($ans) ) {
		print "$dispdef[1]\n";
		$ans = scalar(@def) ? $def[0] : '';
	}

	return $ans;
}


1;

__END__

=head1 NAME

Pod::Simple::Wiki::Twiki::Upload - Update a Twiki with POD documentation for scripts and modules.

=head1 SYNOPSIS

 use Pod::Simple::Wiki::Twiki::Upload;

 chdir($top_of_source);
 twiki_upload("http://twiki.example.com/bin", "Main");

=head1 DESCRIPTION

This attempts to find all the POD documentation in the directories
below C<.> and upload it into a twiki.

The formatting for perl C<=item> lists isn't very good, but it's 
better than nothing.

Even though this module is just released, no maintenance is planned: it is
up for adoption.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

