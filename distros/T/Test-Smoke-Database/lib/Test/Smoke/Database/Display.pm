package Test::Smoke::Database::Display;

# Test::Smoke::Database::Display - 
# Copyright 2003 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2003/08/19 10:37:24 $
# $Log: Display.pm,v $
# Revision 1.6  2003/08/19 10:37:24  alian
# Release 1.14:
#  - FORMAT OF DATABASE UPDATED ! (two cols added, one moved).
#  - Add a 'version' field to filter/parser (Eg: All perl-5.8.1 report)
#  - Use the field 'date' into filter/parser (Eg: All report after 07/2003)
#  - Add an author field to parser, and a smoker HTML page about recent
#    smokers and their available config.
#  - Change how nbte (number of failed tests) is calculate
#  - Graph are done by month, no longuer with patchlevel
#  - Only rewrite cc if gcc. Else we lost solaris info
#  - Remove ccache info for have less distinct compiler
#  - Add another report to tests
#  - Update FAQ.pod for last Test::Smoke version
#  - Save only wanted headers for each nntp articles (and save From: field).
#  - Move away last varchar field from builds to data
#
# Revision 1.5  2003/08/15 16:08:16  alian
# Display link for X status
#
# Revision 1.4  2003/08/15 15:10:03  alian
# Update html for be able to browse database with lynx
#
# Revision 1.3  2003/08/08 13:58:09  alian
# Update display limit
#
# Revision 1.2  2003/08/06 19:20:51  alian
# Add proto to methods
#
# Revision 1.1  2003/08/06 18:50:42  alian
# New interfaces with DB.pm & Display.pm
#

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use CGI qw/:standard -no_xhtml/;
use Data::Dumper;
use Carp qw(cluck);
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.6 $ ' =~ /(\d+\.\d+)/)[0];

use vars qw/$debug $verbose/;

my $limite = 18600;
#$limite = 0;


#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new   {
  my $class = shift;
  my $self = {};
  my $indexer = shift;
  bless $self, $class;
  $debug = ($indexer->{opts}->{debug} ? 1 : 0);
  $verbose = ($indexer->{opts}->{verbose} ? 1 : 0);
  $self->{CGI} = $indexer->{opts}->{cgi};
  $self->{DB} = $indexer->{DB};
  $limite = $indexer->{opts}->{limit};
  return $self;
}

#------------------------------------------------------------------------------
# db
#------------------------------------------------------------------------------
sub db(\%) { return $_[0]->{DB}; }

#------------------------------------------------------------------------------
# header
#------------------------------------------------------------------------------
sub header_html(\%) {
  my $self = shift;
  my $u = $self->{opts}->{url_base} || $ENV{BASE} || '/perl/smoke';
  if (!$ENV{SCRIPT_NAME}) {
    $ENV{SCRIPT_NAME} = $ENV{CGI_BASE} || '/cgi-bin';
    $ENV{SCRIPT_NAME}.='/smoke_db.cgi';
  }
  my $buf = start_html
    (-style=>{'src'=>"$u/smokedb.css"}, -title=>"perl-current smoke results");
  $buf.= <<EOF;
 <div class=menubar><table width="100%"><tr><td class=links>&nbsp;
   <a class=m href="$ENV{SCRIPT_NAME}">Home</a> &nbsp;|&nbsp;
   <a class=m href="$ENV{SCRIPT_NAME}?filter=1">Filter</a> &nbsp;|&nbsp;
   <a class=m href="$ENV{SCRIPT_NAME}?last=1">Last report</a> &nbsp;|&nbsp;
   <a class=m href="$ENV{SCRIPT_NAME}?last=1;want_smoke=1">Last smoke</a> &nbsp;|&nbsp;
   <a class=m href="$ENV{SCRIPT_NAME}?failure=1">
  Last failures</a> &nbsp;|&nbsp;
   <a class=m href="$ENV{SCRIPT_NAME}?smokers=1">
  Smokers</a> &nbsp;|&nbsp;
   <a class=m href="$u/FAQ.html">FAQ</a> &nbsp;|&nbsp;
   <a class=m href="$u/0.html">Stats</a> &nbsp;|&nbsp;
   <a class=m href="http://qa.perl.org">About</a> &nbsp;|&nbsp;
   <a class=m href="mailto:alian\@cpan.org">Author</a> &nbsp;|&nbsp;
</td><td align=right></td></tr></table>
</div>
<h1>Perl-current smoke results</h1>
EOF
  return $buf;

}

#------------------------------------------------------------------------------
# filter
#------------------------------------------------------------------------------
sub filter(\%) {
  my $d = shift;
  my $cgi = $d->{CGI};
  my %t =
    (
     'os'         => '1 - Os',
     'osver'      => '2 - Version OS',
     'archi'      => '3 - Architecture',
     'cc'         => '4 - Compiler',
     'ccver'      => '5 - Compiler version',
     'smoke'      => '6 - Only this smoke',
     'last_smoke' => '7 - Nothing before patchlevel',
     'version'    => '8 - Perl version',
    );
  my $bi = h2("Filter").start_form({-method=>'GET'})."<table border=1><tr>";
  $bi.= hidden({-name=>'last',-value=>1}) if ($cgi->param('last'));
  $bi.= hidden({-name=>'failure',-value=>1}) if ($cgi->param('failure'));
  foreach my $o (sort { $t{$a} cmp $t{$b} } keys %t) {
    $bi.='<tr><td>'.$t{$o}.'</td><td>'.
      "<select name=\"".$o."_fil\"><option value=\"All\">All</option>";
    my $r = $o;
#    print STDERR $r,"\n";
    $r = 'smoke' if ($o eq 'last_smoke');
    my @l = @{$d->db->distinct($r)};
    push(@l,"Last") if ($o eq 'smoke' or $o eq 'last_smoke');
    @l = reverse @l if ($o eq 'smoke');
    my $v = param($o) || param($o.'_fil') || cookie($o) || undef;
    $v = $limite if (!$v and $o eq 'last_smoke');
    foreach my $name (@l) {
      my $sname = (($o eq 'ccver') ? substr($name,0,15) : $name);
      if (($v and $v eq $name) or (!$v and $name eq 'Last') or
	 ($o eq 'last_smoke' and $name eq $limite)) {
	$bi.="<option selected value=\"$name\">$sname</option>\n";
      } else {
	$bi.="<option value=\"$name\">$sname</option>\n";
      }
    }
    $bi.="</select></td></tr>";
  }
  $bi.="<tr>
<td>9 - Results after date:</td>
<td> <select name='date_fil'><option value='All'>All</option>";
  foreach my $i (2001..2003) {
    foreach my $j (1..12) {
      my $d = $i.'-'.sprintf("%02d",$j) ;
      $bi.='<option value="'.$d.'-01 00:00:00">'.$d."</option>";
    }
  }
  $bi.= "</select></td></tr>";
  $bi.= Tr(td(),td(submit))."</table>".end_form;
  return $bi;
}

#------------------------------------------------------------------------------
# display
#------------------------------------------------------------------------------
sub display(\%$$$$$$) {
  my ($self,$os,$osver,$ar,$cc,$ccver,$smoke)=@_;
  my ($i,$summary,$details,$failure,$class,$resume)=(0);
  my ($lastsmoke, $lastsuccessful)=(0,0,0);
  # Walk on each smoke
  $summary = "
<table class=box width=\"90%\"><tr><td>
<table border=\"1\" width=\"100%\" class=\"box2\">".
  Tr(th("Os".('&nbsp;' x 5)), th("Os version".('&nbsp;' x 5)), 
     th("Archi" .('&nbsp;' x 3)), th("Compiler"), 
     th("Version compiler"), th("Patchlevel"), th(a({-href=>'#legend'},"(1)")),
     th({-width=>"15"},a({-href=>'#legend'},"(2)")),
     th({-width=>"15"},a({-href=>'#legend'},"(3)")),
     th({-width=>"15"},a({-href=>'#legend'},"(4)")),
     th({-width=>"15"},a({-href=>'#legend'},"(5)")),
     th({-width=>"15"},a({-href=>'#legend'},"(6)")),
     th("(7)"))."\n";
  my $ref = $self->db->read_all;
  my ($lasta,$lastosv,$lastcc,$lastccv,$lastar,$oss,$osvv,$ccc,$ccvv,$arr)=
    (" "," "," "," "," ");
  my @ls;
  # By os
  foreach my $os (sort keys %$ref) {
    # By os version
    $lastosv = " ";
    foreach my $osver (sort keys %{$$ref{$os}}) {
      # By arch
      $lastar= " ";
      foreach my $ar (sort keys %{$$ref{$os}{$osver}}) {
	# By cc
	$lastcc=" ";
	foreach my $cc (sort keys %{$$ref{$os}{$osver}{$ar}}) {
	  # By ccver
	  $lastccv=" ";
	  foreach my $ccver (sort keys %{$$ref{$os}{$osver}{$ar}{$cc}}) {
	    # By smoke
	    undef @ls;
	    if ($smoke && $smoke eq 'All') {
	      @ls = reverse sort keys %{$$ref{$os}{$osver}{$ar}{$cc}{$ccver}}; 
	    }
	    elsif (!$smoke or $smoke eq 'Last') { 
	      # On prend le dernier smoke
	      @ls = reverse sort keys %{$$ref{$os}{$osver}{$ar}{$cc}{$ccver}};
	      @ls = shift @ls;
	    }
	    else { @ls =($smoke);  }

	  foreach my $smoke (sort @ls) {
	    next if (!$$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke});
	    $lastsmoke = $smoke if ($smoke >$lastsmoke);
	    my ($nbt,$nbc,$nbto,$nbcf,$nbcm,$nbcc,$nbtt,$matrix)=
	      ($$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{nbte},
	       $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{nbc},
	       $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{nbco},
	       $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{nbcf},
	       $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{nbcm},
	       $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{nbcc},
	       $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{nbtt},
	       $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{matrix}
	      );
	    my $id = $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{id};
	    # debut des tableaux erreurs et details
	    my $de = "\n<a name=\"$id\"></a> <table width=\"80%\" class=\"box\">".
	      Tr(th({-colspan=>5},"$os $osver $ar $cc $ccver smoke patch $smoke"));
	    # Matrice
	    my $matrixe;
	    my $y=0;
	    my @ltmp = split(/\|/, $matrix);
	    foreach (@ltmp) {
	      $matrixe.="<tr><td align=right>$_</td>".("<td>_</td>"x$y++).
		("<td>|</td>"x($#ltmp-$y+2))."</tr>";
	    }
	    # Liste des tests echoues
	    if (param('failure') && $nbt && $$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{failure}) {
	      $failure.=$de.Tr(td(pre($$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{failure})))."</table><br>";
	    }
	    # Liste des configs testees
	    if (ref($$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{build})) {
	      my $r2 = 1;
	      my ($dets);
	      foreach my $config (sort keys %{$$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{build}}) {
		$dets.= "<tr>".td($config);
		my $co="<table border=0><tr>";
		my $r = 1; my $classe=" ";
		foreach my $v (split(/ /,$$ref{$os}{$osver}{$ar}{$cc}{$ccver}{$smoke}{build}{$config})) {
		  my $u = $ENV{SCRIPT_NAME}."?failure=1&smoke=$smoke";
		  $u.=$self->compl_url if ($self->compl_url);
		  $u.="#$id" if ($id);
		  if ( ($v eq 'F') or ($v eq 'X')) {
		    $v= a({-href=>$u},$v); $r=0; $r2=0;
		  } elsif ($v eq 'm' or $v eq 'c') {
		    $classe="red";
		  }
		  $dets.=td({-class=>$classe,-width=>3},$v);
		}
		$dets.="</tr>";
		$nbto+=$r;
		$nbc++;
	      }
	      $details.=$de.$dets.$matrixe."</table><br>"
		if (!param('want_smoke') or !$r2);
	    }
	    # Sommaire
	    if ($lasta ne $os) {
	      $oss = cw($os,7); $lasta = $os; $class=($i++)%2;
	    } else { $oss=cw(undef,7); }
	    if ($lastcc ne $cc) {
	      $ccc = cw($cc,8); $lastcc = $cc; }
	    else { $ccc=cw(undef,8); }
	    if ($lastccv ne $ccver) {
	      $ccvv = cw($ccver,18); $lastccv = $ccvv; 
	    } else { $ccvv=cw(undef,18); }
	    if ($lastosv ne $osver) {
	      $osvv = cw($osver,15); $lastosv = $osver; 
	    } else { $osvv=cw(undef, 15); }
	    if ($lastar ne $ar) { $arr = cw($ar,7); $lastar = $ar; }
	    else { $arr=cw(undef,7); }
	    if ($nbt) {
	      my $u = $ENV{SCRIPT_NAME}."?failure=1&smoke=$smoke";
	      $u.=$self->compl_url if ($self->compl_url);
	      $u.="#$id" if ($id);
	      $nbt=a({-href=>$u,-class=>'red'},cn($nbt));
	      $nbt = td({-align=>"center", -class=>'red'},$nbt);
	    }
	    else { $nbt=td({-align=>"center"},cn(0)); }
	    my $u = $ENV{SCRIPT_NAME}."?last=1&smoke=$smoke";
	    $u.= $self->compl_url if ($self->compl_url);
	    $u.="#$id" if ($id);
	    my $ss="makeOk";
	    if ($nbcc) { $ss='confFail';}
	    elsif ($nbcm) { $ss='makeFail';}
	    elsif ($nbcf) { $ss='makeTestFail';}
	    $summary.=Tr({-class=>"mod".$class},
			 td({-class=>"os"},$oss),
			 td({-class=>"osver"},$osvv),
			 td({-class=>"archi"},$arr."&nbsp;"),
			 td({-class=>"cc"},$ccc),
			 td({-class=>"ccver"},$ccvv),
			 td({-class=>"smoke"},a({-href=>$u}, $smoke)),
			 td({-class=>"configure"},cn($nbc)),
			 td({-class=>$ss,-width=>"15"},cn($nbtt)),
			 td({-class=>$ss,-width=>"15"},cn($nbto)),
			 td({-class=>$ss,-width=>"15"},cn($nbcc)),
			 td({-class=>$ss,-width=>"15"},cn($nbcm)),
			 td({-class=>$ss,-width=>"15"},cn($nbcf)),
			 $nbt)."\n";
	    $lastsuccessful = $smoke if ($nbto == $nbtt && ($smoke>$lastsuccessful));
	  }
	  }
	}
      }
    }
  }
  $summary.=<<EOF;
</table></td></tr></table>
<div class=box>
<a name="legend"></a>
<h2>Legend</h2>
<ol>
  <li>Number of configure run</li>
  <li>Number of make test run</li>
  <li>Number of make test ok</li>
  <li class="confFail">Number of failed configure</li>
  <li class="makeFail">Number of failed make</li>
  <li class="makeTestFail">Number of failed make test</li>
  <li>Number of failed test</li>
</ol>
</div>
EOF
   $lastsuccessful = "Never" if ! $lastsuccessful;
  $resume = table({ border=>1, class=>"box2" },
		  Tr(th("Smoke available"),
		     th("Since smoke"),
		     th("Last, "),
		     th("Last successfull")),
		  Tr(td($self->db->nb), td($limite),
		     td($lastsmoke),td($lastsuccessful)));
  $summary = $resume.$summary;
  return (\$summary,\$details,\$failure);
}


#------------------------------------------------------------------------------
# smokers
#------------------------------------------------------------------------------
sub smokers {
  my $self = shift;
  my $ref = $self->db->read_smokers;
      print STDERR Data::Dumper->Dump([$ref]);
  my $buf=Tr(th(cw("Author", 23)), th(cw("Os",15)), th(cw("Os version",15)),
	     th(cw("Architecture",15)), th(cw("Cc",15)), th(cw("Cc version",15)));
  my $i=0;
  # Tab author
  foreach my $author (keys %$ref) {
    my $bu;
    my $aa = $author;
    $aa=~s/\@/ at /g;
    # Tab config
    foreach my $conf (@{$ref->{$author}}) {
      $bu = $bu ? td(cw(undef, 23)) : td(cw($aa, 23));
      # tab specs
      foreach (@$conf) {
	$bu.=td(cw($_, 15));
      }
      $buf.=Tr({-class=>'mod'.$i%2},$bu)."\n";
    }
    $i++;
  }
  return h2("Smokers in last 6 month").table({-class => 'box'}, $buf);
}

#------------------------------------------------------------------------------
# cw
#------------------------------------------------------------------------------
sub cw($$) {
  my ($word, $size)= @_;
  $size = 10 if !$size;
  return $word.("&nbsp;" x ($size - length($word)));
}

#------------------------------------------------------------------------------
# cn
#------------------------------------------------------------------------------
sub cn($) {
  return ( ($_[0] <10) ? '&nbsp;'.$_[0] : $_[0]);
}

#------------------------------------------------------------------------------
# compl_url
#------------------------------------------------------------------------------
sub compl_url(\%) {
  my $self = shift;
  my $buf;
  foreach ('os','osver','archi','cc','ccver','smoke') {
    $buf.="&$_=".param($_) if (param($_));
  }
  return $buf;
}

__END__

#------------------------------------------------------------------------------
# POD DOC
#------------------------------------------------------------------------------


=head1 NAME

Test::Smoke::Database::Display - HTML display method

=head1 SYNOPSIS

  my $a = new Test::Smoke::Database;
  print $a->HTML->header_html;


=head1 DESCRIPTION

This module give HTML display for Test::Smoke::Database & smoke_db.cgi

=head1 SEE ALSO

L<admin_smokedb>, L<Test::Smoke::Database::FAQ>, L<Test::Smoke::Database>,
L<http://www.alianwebserver.com/perl/smoke/smoke_db.cgi>

=head1 METHODS

=over

=item B<header_html>

Return the HTML menubar that will be displayed in the CGI

=item B<filter>

Return the HTML filter screen.

=item B<display>

Return the main HTML screen with summary

=back

=head2 Private methods

=over 4

=item B<compl_url>

=back

=head1 VERSION

$Revision: 1.6 $

=head1 AUTHOR

Alain BARBET

=cut

1;
