package Video::XawTV;

=head1 NAME

Video::XawTV - read, create and edit .xawtvrc's.

=head1 SYNOPSIS

   use Video::XawTV;

   $rc = new Video::XawTV;
   # - or -
   $rc = new Video::XawTV "$HOME{ENV}/.xawtv";
   $rc->load("otherrcfile");
   $rc->save;
   $rc->save("filename");

   $source = $rc->opt('source');
   $rc->opt('source') = "Television";

   @channels = $rc->channels;
   $rc->channels(@channels);

   print $channels[0]{name};	# Arte
   print $channels[0]{channel};	# E4

=head1 DESCRIPTION

Pardon? Ha! Haa! Hahahahahaha!!!

=cut

$VESRSION = 0.1;

use Carp;

sub new {
   my $self = bless {}, shift;
   $self->load(shift) if @_;
   $self;
}

my %std_global = (
   norm		=> 1,
   capture	=> 1,
   source	=> 1,
   color	=> 1,
   bright	=> 1,
   hue		=> 1,
   contrast	=> 1,
   fullscreen	=> 1,
   wm-off-by	=> 1,
   freqtab	=> 1,
   pixsize	=> 1,
  'jpeg-quality'=> 1,
   mixer	=> 1,
   lauch	=> 1,
);

my %std_channel = (
   channel	=> 1,
   fine		=> 1,
   norm		=> 1,
   key		=> 1,
   capture	=> 1,
   source	=> 1,
   color	=> 1,
   bright	=> 1,
   hue		=> 1,
   contrast	=> 1,
);

sub load {
   my $self = shift;
   my $fn = shift;
   local $_;
   open FN, "<$fn" or croak "unable to open '$fn': $!";
   $self->{fn} = $fn;
   $self->{channels} = [];
   my $channel = $self->{global} = {};
   my $std = \%std_global;
   while (<FN>) {
      if (/^#Video::XawTV=#\s*(\S+)\s*=\s*(.*)\s*$/) {
         $channel->{lc $1} = $2;
      } elsif (/^\s*#(.*)$/) {
         # comments are being reordered, but.. my!
         $channel->{"#$1"} = 1;
      } elsif (/^\s*(\S+)\s*=\s*(.*)\s*$/) {
         $channel->{lc $1} = $2;
         $std->{lc $1}++;
      } elsif (/\s*\[(.*)\]\s*$/) {
         push @{$self->{channels}}, $channel = { name => $1 };
         $std = \%std_channel;
      } elsif (/\S/) {
         chomp;
         croak "unparsable statement in '$fn': '$_'";
      }
   }
   close FN;
}

sub save_hash {
   my ($fh, $hash, $std) = @_;
   while (my ($k,$v) = each %$hash) {
      next if $k eq 'name';
      if ($k =~ /^#/) {
         print $fh $k, "\n";
      } else {
         print $fh "#Video::XawTV=#" unless $std->{lc $k};
         print $fh "$k = $v\n";
      }
   }
   print $fh "\n";
}

sub save {
   my $self = shift;
   my $fn = shift || $self->{fn};
   open FN,">$fn~" or croak "unable to open '$fn~' for writing: $!";
   save_hash(*FN, $self->{global}, \%std_global);
   for (@{$self->{channels}}) {
      print FN "[", $_->{name}, "]\n";
      save_hash(*FN, $_, \%std_channel);
   }
   close FN;
   rename "$fn~", $fn or croak "unable to replace '$fn': $!";
}

sub opt {
   my $self = shift;
   my $opt = shift;
   $self->{global}{$opt} = shift if @_;
   $self->{global}{$opt};
}

sub channels {
   my $self = shift;
   if (@_) {
      $self->{channels} = ref $_[0] eq "ARRAY" ? $_[0] : [@_];
   }
   wantarray ? @{$self->{channels}} : $self->{channels};
}

1;
