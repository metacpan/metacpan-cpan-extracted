#!/usr/bin/perl
use Module::Build 0.35;
use File::Copy;
use File::Find;

my $class = Module::Build->subclass(
      class => "Module::Build::Custom",
      code => <<'SUBCLASS' );

  sub ACTION_distdir {
      my $self = shift;
      $self->SUPER::ACTION_distdir;

      $self->depends_on("buildagent");
      my @agents = ();
      find(
         { 
             wanted => sub { 
                push @agents,$_ if /osgish-(core|bundle).*\.jar/;
             }, 
             no_chdir => 1
      },"agent");
      die "No agent jars found" unless @agents;
      for my $agent (@agents) {
         my $file = $1 . ".jar" if $agent =~ m{/(osgish-(core|bundle))};
         File::Copy::copy($agent,$self->dist_dir . "/$file") || die "Cannot copy $agent to ",$self->dist_dir,"/$file : $!";
      }
  }

  sub ACTION_clean {
      my $self = shift;
      print "No mvn installed, skipping ...\n" unless $self->do_system(qw(mvn -f agent/pom.xml clean));
      $self->SUPER::ACTION_clean;
  }

  sub ACTION_get_agent {
      &_download("osgish-core","jar");
      &_download("osgish-bundle","jar");
  }

  sub _download { 
     my ($name,$type) = @_;

      eval {
        require LWP;
      };
      if ($@) {
        print "No LWP installed\n";
        exit 1;
      }
      my $BASE_URL = "http://labs.consol.de/maven/repository/org/jolokia/osgish";
      my $version = &_extract_version();
      my $file  = "$name-${version}.$type";
      my $url = $BASE_URL . "/$name/$version/$file";
      my $ua = LWP::UserAgent->new;
      my $res = $ua->request(new HTTP::Request(GET => $url));
      my $content =  $res->content;
      if ($res->is_success) {
         open(F,">$file") || die "Cannot open $file: $!\n";
         print F $content;
         close F;
         print "Downloaded $file into local directory\n";
      } else {
         print "Error fetching $url\n";
         print $res->status_line,"\n";
         exit 1;
      }
      eval {
         require Digest::SHA1;
      };
      if ($@) {
         print "No Digest::SHA1 installed. Skipping checksum test\n";
         return;
      }
      $res = $ua->request(new HTTP::Request(GET => $url . ".sha1"));
      if ($res->is_success) {
         my $r_sha1 = $res->content;
         chomp $r_sha1;
         my $sha1 = new Digest::SHA1;
         $sha1->add($content);
         if ($r_sha1 ne $sha1->hexdigest) {
            print "CHECKSUM Error:\nRemote SHA1: $r_sha1\nLocal  SHA1: ",$sha1->hexdigest,"\n";
            exit 1;
         } else {
            print "SHA1 Checksum $r_sha1 verified\n";
            return;
         }
      } else {
         print $res->status_line,"\n";
         exit 1;
      }
  }

  sub ACTION_buildagent {
      my $self = shift;
      use FindBin;
      use File::Find;

      my $pom          = "$FindBin::Bin/agent/pom.xml";
      my $version = &_extract_version();

      die "Cannot extract version from Perl Modul OSGi::Osgish" unless $version;

      find( sub { 
        if ($_ eq "pom.xml") {
          &_replace_version($File::Find::name,$version,
            sub {  
                  my $v = shift;
                  my $t = shift;
                  $t =~ s|(</artifactId>\s+<version>)\s*(.+)\s*(</version>)|$1$v$3|;
                  $t =~ s|(<artifactId>osgish-core</artifactiId>\s+<version>)\s*(.+)\s*(</version>)|$1$v$3|;
                  $t =~ s|(<parent>.*<version>)\s*(.+)\s*(</version>.*</parent>)|$1$v$3|s;
                  return $t;
                 });
         }
       },"$FindBin::Bin/agent");

      print "Cannot re-create agent" 
              unless $self->do_system(qw(mvn -f agent/pom.xml clean install));
  }

  sub _extract_version {
      my $version_perl = "$FindBin::Bin/lib/OSGi/Osgish.pm";
      open(F,"$version_perl") || die "Cannot open $version_perl : $!";
      my $v = join "",<F>;
      close F;
      my $version = $1 if $v =~ /^\s+\$VERSION\s+=\s+"([^"]+)"/m; 
      return $version;
  }

  sub _replace_version {
      my $file = shift;
      my $version = shift;
      my $replace_sub = shift;

      my ($ma,$mi,$pa,$dev) = ($1,$2,$3,$4) if $version =~ /^(\d+)\.(\d+)(?:\.(\d+))?(?:_(\d+))?$/;
      $pa = "0" unless $pa;
      $version = "$ma.$mi.$pa";
      if ($dev) {
         $version .= ".M" . $dev;
      }
      print "Setting version to $version in $file\n";

      open(F,"$file") || die "Cannot open $file : $!";
      my $c = join "",<F>;
      close F;
      $c = &{$replace_sub}($version,$c);
      my $changed_perm = undef;
      if (! -w $file) {
         $changed_perm = 1;
         my $perm = (stat $file)[2] & 07777;
         chmod($perm | 0200,$file) || die "Cannot change write permission for $file : $!";
      }
      open(F,">$file") || die "Cannot open $file for writing: $!";
      print F $c;
      close F;
      if ($changed_perm) {
         my $perm = (stat $file)[2] & 0777;
         chmod($perm & 0577,$file) || die "Cannot remove write permission from $file : $!";
      }
  }
SUBCLASS

my $build = $class->new
  (
   dist_name => "osgish",
   dist_version_from => "lib/OSGi/Osgish.pm",
   dist_author => 'Roland Huss (roland@cpan.org)',
   dist_abstract => 'A readline shell for OSGi',
   installdirs => 'site',
   script_files => 'scripts',
   license => 'gpl',

   requires => {
                "JMX::Jmx4Perl" => "0.60",
                "Data::Dumper" => 0,
                "Pod::Usage" => 0,
                "Getopt::Long" => 0,
                "Carp" => 0,
                "Config::General" => 0,
                "Term::ReadLine" => 0,
                "Term::ReadLine::Perl" => 0,
                "Term::ShellUI" => "0.86",
                "Term::Clui" => 0,
               },
   recommends => {
                   "Term::ReadLine::Gnu" => "0.27",
                   "Term::ANSIColor" => "2.02"
                  },
   configure_requires => { 'Module::Build' => 0.35 },
   build_requires => {
                      "Module::Build" => "0.35",
                      "File::Copy" => 0,
                      "Test::More" => 0,
                      "Test::Deep" => 0,
                      "Test" => "0"
                     },                       
   keywords => [  "OSGi", "JMX", "Management", "Shell" ],
  );

$build->create_build_script;
