use Config;
use ExtUtils::MakeMaker;

use Tk::MMutil;


if( $tkversion <= 800.022 ){
	# Tkversion 800.022 needs the old style LandWidgetArg
	#  instead of the new LangWidgetObj call
	$define .= ' -DUSE_LANGWIDGETARG';
}

# mTk directory to use for munging into the pTk dir.
#   If Tk804 or greater, use the normal Tktable dir.
#   If otherwise using the old Tktable800 dir
my $mTkDir = 'Tktable';
if( $tkversion < 804.000 ){
	print STDERR "### Your Tk version is less than 804.        ###\n";
	print STDERR "### Ok, Using Tk800.0XX dir 'mTk/Tktable800' ###\n";
	$mTkDir = 'Tktable800';
}

# Find path to existing pTk include files
my $ptkPath = Tk::MMutil::findINC('Tk/pTk/Lang.h');
$ptkPath =~ s/\/Lang\.h$//g;

Tk::MMutil::TkExtMakefile(
    'NAME'	=> 'Tk::pTk',
    'VERSION'	=> '1.29',
    'XS_VERSION'=> '0.9',
    'LINKTYPE'	=> 'static',
    'OBJECT'	=> '$(O_FILES)', 
    macro	=> { WINARCH     => $win_arch },
    'DEFINE'	=> $define,
    'INC'	=> "-I$ptkPath -I. -Ibitmaps",
    'SKIP'	=> [qw( distclean dist makeaperl xs_o)],
    'clean'	=> {'FILES' => 'libpTk$(LIB_EXT)'}
);

sub MY::top_targets {
 my ($self) = @_;
 local $_ = $self->MM::top_targets;
 s/^(\$\(O_FILES\)\s*:.*)$/# Explicit dependencies provided\n# $1/m;
 return $_;
}

sub MY::xs_c {
'
';
}

sub MY::post_initialize
{
 my ($self) = @_;
 my %mTk;
 my $dir;
 my @list = ($mTkDir);
 print STDERR "Generating Dependencies for $^O, win_arch=$win_arch\n";
 foreach $dir (@list)
  {
   my %exc;
   my $src = $self->catdir("mTk",$dir);
   next unless -d $src;
   if (open(EXC,$self->catfile($src,"pTk.inc")))
    {
     while (<EXC>)
      {          
       s/\s+$//s;
       s/#.*$//;
       next unless /\S/;
       $mTk{$_} = $self->catfile($src,$_) unless (exists $mTk{$_});
      }          
     close(EXC);
    }
   else
    {
     opendir(DIR,$src) || die "Cannot open $src:$!";
     if (open(EXC,$self->catfile($src,"pTk.exc")))
      {            
       while (<EXC>)
        {          
         s/\s+$//s;
         s/#.*$//;
         next unless /\S/;
         $exc{$_} = 1;
         if (-f $_)
          {        
           chmod(0777,$_);
           unlink($_); 
           warn "Loose $_\n";
          }        
        }          
       close(EXC); 
      }            
     else          
      {            
       warn "Cannot open $src/pTk.exc:$!";
      }            
     my $file;     
     while (defined($file = readdir(DIR)))
      {            
       next if $exc{$file};
       if ($file =~ /\.[ch]$/)
        {          
         $mTk{$file} = $self->catfile($src,$file) unless (exists $mTk{$file});
        }          
      }            
     closedir(DIR);
    }
  }
 my @loose = ();
 $self->Tk::MMutil::mTk_CHO(\%mTk,@loose);
 my %files = ();
 $files{'windows.h'} = 1 if $win_arch eq 'open32';
 my $name;
 $self->{'dir_targets'} = [];
 $dir = $self->catdir('$(INST_ARCHLIBDIR)','pTk');
 push(@{$self->{'dir_targets'}},$dir);
 foreach $name ($self->lsdir("."))
  {
   next if ($name =~ /^\./);
   next unless (-f $name);
   $files{$name} = 1 if ($name =~ /\.[tm]$/);
  }
 foreach $name (sort(@{$self->{H}},keys %files))
  {
   $self->{PM}->{$name} = $self->catfile($dir,$name);
  }

 if ($Tk::MMutil::IsWin32 or $win_arch eq 'open32' or $win_arch eq 'pm')
  {my $ddir = $self->catdir('$(INST_ARCHLIBDIR)','X11');
   my $sdir = $self->catdir('mTk','xlib','X11');
   push(@{$self->{'dir_targets'}},$ddir);
   foreach $name ($self->lsdir($sdir))
    {
     next if $name =~ /^\.+$/;
     my $src = $self->catfile($sdir,$name);
     next unless -f $src;
     $self->{PM}->{$src} = $self->catfile($ddir,$name);
    }
  }
 $dir = $self->catdir($dir,"compat");
 push(@{$self->{'dir_targets'}},$dir);
 foreach $name ($self->lsdir("compat"))
  {
   next if $name =~ /^\.+$/;
   my $src = $self->catfile('compat',$name);
   next unless -f $src;
   $self->{PM}->{$src} = $self->catfile($dir,$name);
  }
 '';
}

sub MY::test 
{
 q[
test :: 
	@echo 'No tests defined for $(NAME)'
 ];
}

sub MY::post_constants 
{
 '
INST_STATIC=libpTk$(LIB_EXT)
';
};

sub MY::install {
'
install :: all
';
}

sub MY::dynamic_lib { my $self = shift; "dynamic_lib :: static_lib\n\t".$self->{'NOECHO'}."\$(NOOP)\n" }

sub MY::dynamic     { my $self = shift; "dynamic :: static\n\t".$self->{'NOECHO'}."\$(NOOP)\n" }

sub MY::static 
{
  my $self = shift;
  my $str  = $self->MM::static(@_);
  if ($win_arch eq 'open32' or $win_arch eq 'pm')
   {
    $str .= '
static :: dllInit$(LIB_EXT)
dllInit$(LIB_EXT): dllMain$(OBJ_EXT)
	$(AR) $(AR_STATIC_ARGS) $@ dllMain$(OBJ_EXT) && $(RANLIB) $@
';
   }
 return $str; 
}

sub MY::realclean {
  my $self = shift;
  my $str  = $self->MM::realclean(@_);
  $str =~ s/(::\s*clean)/$1 mungeclean/;
  $str .= "\nmungeclean ::\n";
  $str .= "\t\$(RM_F) ".join(" \\\n\t",keys %{$self->{'MTK'}})."\n";
  return $str;
}


sub MY::postamble {
    my $self = shift;
    my $dep = $self->Tk::MMutil::mTk_postamble;

    $dep .= $self->dir_target(@{$self->{'dir_targets'}}); 
    
    # add some additional dir targets - reason currently unknown. Use $(DFSEP) as dir separator or makefile will not find target (target uses $(DFSEP) too).
    $dep .= "config :: " . join(" \\\n\t",map($_.'$(DFSEP).exists',@{$self->{'dir_targets'}})) .
        "\n\t".$self->{NOECHO}."\$(NOOP)\n";


    $dep . '

	'.$self->{NOECHO}.'$(NOOP)

';
}





