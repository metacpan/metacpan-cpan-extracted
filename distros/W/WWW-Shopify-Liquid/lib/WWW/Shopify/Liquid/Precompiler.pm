=head1 

WWW::Shopify:::Liquid::Precompiler - Tool to automatically compile .liquid files, which have multiple extensions.

=cut

package WWW::Shopify::Liquid::Precompiler;
use File::Find;
use File::stat;
use File::Slurp;
use File::Basename;
use Encode;

use strict;
use warnings;

use WWW::Shopify::Liquid::Analyzer;

sub new { 
	my $package = shift;
	my ($self) = bless { 
		options => {},
		analyzer => undef,
		entities => {},
		liquid => undef,
		@_ 
	}, $package; 
	$self->{liquid} = WWW::Shopify::Liquid->new if !$self->liquid;
	$self->{analyzer} = WWW::Shopify::Liquid::Analyzer->new(liquid => $self->liquid) if !$self->analyzer;
	return $self;
}
sub liquid { return $_[0]->{liquid}; } 
sub analyzer { return $_[0]->{analyzer}; } 
	
# Destination can be a folder, or a filename.
sub should_compile { 
	my ($self, $target, $destination) = @_;
	return 0 if -d $target;
	return 0 unless $target =~ m/^(.*?[^\/]+\.[^\/]+)\.liquid$/ && -e $target; 
	my $file;
	if ($destination) {
		$file = -d $destination ? $destination . "/" . basename($1) : $file;
	} else {
		$file = $1;
	}
	return $file if !-e $file;
	my $mtime = stat($target)->mtime;
	return $file if stat($file)->mtime < $mtime;
	my $entity = $self->analyzer->add_refresh_path($target, values(%{$self->{entities}}));
	$self->{entities}->{$entity->id} = $entity;
	return $file if int(grep { $_->file && $mtime < stat($_->file)->mtime } (@{$entity->{full_dependencies}})) > 0;
	return 0;
}

sub options {
	my ($self, $target) = @_;
	return $_[0]->{options};
}

sub compile {
	my ($self, $file, $target) = @_;
	my $text = $self->{liquid}->render_file($self->options($file), $file);
	write_file($target, encode("UTF-8", $text));
	return $target;
}

sub compile_directories {
	my ($self, @directories) = @_;
	find({
		wanted => sub {
			my $file = $_;
			if (my $target = $self->should_compile($file)) {
				eval { $self->compile($file, $target); };
				if (my $exp = $@) {
					die new WWW::Shopify::Liquid::Exception("Can't target.") unless $file =~ m/^(.*?[^\/]+\.[^\/]+)\.liquid$/ && -e $file;
					my $target = $1;
					if (!-e $target) {
						open(my $fh, ">>", $target) or die $!; close($fh);
					} else {
						utime(undef, undef, $target);
					}
					die $exp;
				}
			}
		}, no_chdir => 1
	}, @directories)
}

sub watch_directories {
	my ($self, @directories) = @_;
	while (1) {
		eval { 
			$self->compile_directories(@directories);
		};
		if (my $exp = $@) {
			print STDERR "Error compiling: " . $exp->error . "\n";
		}
		sleep(1);
	}
}

1;