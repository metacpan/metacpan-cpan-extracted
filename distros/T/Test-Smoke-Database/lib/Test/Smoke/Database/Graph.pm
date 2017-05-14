package Test::Smoke::Database::Graph;

# module Test::Smoke::Database - Create graph about smoke database
# Copyright 2003 A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2003/11/07 17:34:01 $
# $Log: Graph.pm,v $
# Revision 1.10  2003/11/07 17:34:01  alian
# Return undef if fetch by-config failed
#
# Revision 1.9  2003/09/16 15:41:50  alian
#  - Update parsing to parse 5.6.1 report
#  - Change display for lynx
#  - Add top smokers
#
# Revision 1.8  2003/08/19 10:37:24  alian
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
# Revision 1.7  2003/08/15 15:50:40  alian
# Group smoke for graph
#
# Revision 1.6  2003/08/06 18:50:42  alian
# New interfaces with DB.pm & Display.pm
#
# Revision 1.5  2003/08/02 12:38:27  alian
# Minor typo
#
# Revision 1.4  2003/07/30 15:42:27  alian
# -Graph in 1000*300
# - Graphs always in png
# - Add warn messages
# - Add use of GD in a eval
#
# Revision 1.3  2003/07/19 18:12:16  alian
# Use a debug flag and a verbose one. Fix output
#
# Revision 1.2  2003/02/16 16:14:29  alian
# - Add CPAN chart
# - All graph are 1000*300
# -  Change new parameters: use a var for directory where create img

use strict;
use Data::Dumper;
use LWP::Simple;
use Carp qw/confess/;
use POSIX;
eval("
  use GD::Graph::mixed;
  use GD::Graph::colour;
  use GD::Graph::Data;
");

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;


@ISA = qw(Exporter);
@EXPORT = qw(prompt);
$VERSION = ('$Revision: 1.10 $ ' =~ /(\d+\.\d+)/)[0];

my $debug = 0;
my $font = '/usr/X11R6/share/enlightenment/themes/Blue_OS/ttfonts/arial.ttf';

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new   {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->{DBH} = shift;
  $self->{dbsmoke} = shift;
  $self->{LIMIT} = shift || 0;
  $self->{DIR} = shift || $self->{LIMIT};
  if (!-e $self->{DIR}) { 
    if (!mkdir $self->{DIR},0755) {
      die "Can't create $self->{DIR}:$!\n";
    }
  }
  return $self;
}

#------------------------------------------------------------------------------
# percent_configure
#------------------------------------------------------------------------------
sub percent_configure {
  my $self = shift;
  my $request = "select DATE_FORMAT(date,'%Y-%c'),
                        os,
                       (sum(nbco)/sum(nbco+nbcf+nbcc+nbcm))*100 
                 from builds ";
  $request.="where smoke > $self->{LIMIT} " if ($self->{LIMIT});
  $request.="group by 1,os order by 1";
  my (%l,%tt);
  my $st = $self->{DBH}->prepare($request);
  $st->execute || print STDERR $request,"<br>";
  while (my @l = $st->fetchrow_array) { $l{lc($l[1])}{$l[0]}=$l[2] if ($l[2]);}
  $st->finish;
  my @l1;
  foreach my $os (keys %l) {
    $os=~s!/!!g;
    my (@l,@l2,$tt);
    foreach (sort keys %{$l{$os}}) {
      push(@l,$_);
      push(@l2,$l{$os}{$_});
      $tt+=$l{$os}{$_};
    }
    next if $#l2 < 2;
    $tt{$os}=sprintf("%2d", $tt/($#l2+1));
    my @la=(\@l, \@l2);
    my $my_graph = GD::Graph::area->new(1000,300);
    $my_graph->set_legend("","% of successful make test");
    $my_graph->set( 
		   title           => '% of successful make test for '
		                      .$os. ' each month',
		   y_max_value     => 100,
		   y_tick_number   => 10,
		   x_label_skip    => ($#l2)/ 8,
 		   legend_spacing => 40,
		   axis_space => 20,
		   t_margin => 40,
		   b_margin => 10,
		   box_axis => 0,
		   dclrs       => [ qw/dpurple/ ],
		   transparent     => 0,
		  )
      or warn $my_graph->error;
    go($my_graph, \@la, "$self->{DIR}/9_os_".$os);
  }
}
#------------------------------------------------------------------------------
# percent_configure_all
#------------------------------------------------------------------------------
sub percent_configure_all {
  my $self = shift;
  my $request = "select DATE_FORMAT(date,'%Y-%c'),
                        (sum(nbco)/sum(nbco+nbcf+nbcc+nbcm))*100 from builds ";
  $request.="where smoke > $self->{LIMIT} " if ($self->{LIMIT});
  $request.="group by 1 order by 1";
  my $ref = $self->fetch_array($request);
  my $my_graph = GD::Graph::area->new(1000,300);
  $my_graph->set_legend("","% of successful make test");
  $my_graph->set( 
		 title           => '% of successful make test each month',
		 y_max_value     => 100,
		 y_tick_number   => 10,
		 x_label_skip    => 3,
		 legend_spacing => 40,
		 axis_space => 20,
		 t_margin => 40,
		 b_margin => 10,
		 box_axis => 0,
		 dclrs       => [ qw/black/ ],
		 transparent     => 0,
		)
    or warn $my_graph->error;
  go($my_graph, $ref, "$self->{DIR}/90_os");
}

#------------------------------------------------------------------------------
# configure_per_smoke
#------------------------------------------------------------------------------
sub configure_per_smoke {
  my $self = shift;
  my $req ="select DATE_FORMAT(date,'%Y-%c'),
                   sum(nbco+nbcf+nbcc+nbcm),
                   sum(nbco) from builds ";
  $req.="where smoke > $self->{LIMIT} " if ($self->{LIMIT});
  $req.="group by 1 order by 1";
  my $ref = $self->fetch_array($req);
  my $my_graph = GD::Graph::mixed->new(1000,300);
  $my_graph->set_legend("make test run","make test pass all tests");
  $my_graph->set(
		 y_label         => 'make test run',
		 title           => 'make test run/pass all tests each month',
		 y_max_value     => 40000,
		 y_tick_number   => 10,
		 x_label_skip    => 3,
		 types => [qw(lines area )],
		 shadowclr       => 'dred',
		 transparent     => 0,
		 legend_spacing => 30,
		 dclrs       => [ qw/red dblue/ ],
		 axis_space => 20,
		 t_margin => 50,
		 b_margin => 20,
		 box_axis => 0,

		)
    or warn $my_graph->error;
  go($my_graph, $ref, "$self->{DIR}/7_conftested");
}

#------------------------------------------------------------------------------
# configure_per_os
#------------------------------------------------------------------------------
sub configure_per_os {
  my $self = shift;
  my $req = "select os,sum(nbc) from builds ";
  $req.="where smoke > $self->{LIMIT} " if ($self->{LIMIT});
  $req.="group by os order by 2";
  my $ref = $self->fetch_array($req,2);
  # no info about this config. Can't create graph
  if (!ref($$ref[1]) || ref($$ref[1] ne 'ARRAY')) {
    warn __PACKAGE__." not enough data to make graph with \"$req\".";
    return;
  }
  my @a = @{$$ref[1]};
  my $my = (floor($a[$#a] / 50)+1)*50;
  my $my_graph = GD::Graph::bars->new(1000,300);
  $my_graph->set_legend("","os tested");
  $my_graph->set(
		 title           => 'Number of configure run by os',
		 y_max_value     => $my,
		 y_tick_number   => 5,
		 show_values => 1,
		 x_label_skip    => 1,
		 y_label_position => 0,
		 axis_space      => 20,
		 shadowclr       => 'dred',
		 shadow_depth    => 4,
		 transparent     => 0,
		 bar_spacing => 10,
		 legend_spacing => 40,
		 t_margin => 35,
		 box_axis => 0,
		)
    or warn $my_graph->error;
  return go($my_graph, $ref, "$self->{DIR}/4_nb_configure");
}

#------------------------------------------------------------------------------
# smoke_per_os
#------------------------------------------------------------------------------
sub smoke_per_os {
  my $self = shift;
  my $req = "select os,count(id) from builds ";
  $req.="where smoke > $self->{LIMIT} " if ($self->{LIMIT});
  $req.="group by os order by 2";
  my $ref = $self->fetch_array($req,2);
  # no info about this config. Can't create graph
  if (!ref($$ref[1]) || ref($$ref[1] ne 'ARRAY')) {
    warn __PACKAGE__." not enough data to make smoke per os graph";
    return undef;
  }
  my @a = @{$$ref[1]};
  my $my = (floor($a[$#a] / 50)+1)*50;
  my $my_graph = GD::Graph::bars->new(1000,300);
  $my_graph->set_legend("","os tested");
  $my_graph->set(
		 title           => 'Number of smoke run by os',
		 y_max_value     => $my,
		 y_tick_number   => 10,
		 show_values => 1,
		 x_label_skip    => 1,
		 y_label_position => 0,
		 axis_space => 20,
		 shadowclr       => 'dred',
		 shadow_depth    => 4,
		 transparent     => 0,
		 bar_spacing => 10,
		 legend_spacing => 40,
 		 t_margin => 35,
		 box_axis => 0
		)
    or warn $my_graph->error;
  return go($my_graph, $ref, "$self->{DIR}/3_nb_smoke");
}

#------------------------------------------------------------------------------
# os_by_smoke
#------------------------------------------------------------------------------
sub os_by_smoke {
  my $self = shift;
  my $req = "select DATE_FORMAT(date,'%Y-%c'),count(distinct os,osver,archi,cc) from builds ";
  $req.="where smoke > $self->{LIMIT} " if ($self->{LIMIT});
  $req.="group by 1 order by 1";
  my $ref = $self->fetch_array($req);
  my $my_graph = GD::Graph::area->new(1000,300);
  $my_graph->set_legend("","os tested");
  $my_graph->set(
		 title           => 'Number of distinct smoke machine each month',
		 y_max_value     => 50,
		 y_tick_number   => 10,
		 x_label_skip    => 3,
		 y_label_position => 0,
		 axis_space => 20,
		 # shadows
		 shadowclr       => 'dred',
		 shadow_depth    => 4,
		 transparent     => 0,
		 bar_spacing => 10,
		 legend_spacing => 40,
 		 t_margin => 35,
		 box_axis => 0
		)
    or warn $my_graph->error;
  go($my_graph, $ref, "$self->{DIR}/6_nb_os_by_smoke");
}

#------------------------------------------------------------------------------
# success_by_os
#------------------------------------------------------------------------------
sub success_by_os {
  my $self = shift;
  my $req = "select os,(sum(nbco)/sum(nbco+nbcc+nbcm+nbcf))*100 from builds ";
  $req.="where smoke > $self->{LIMIT} " if ($self->{LIMIT});
  $req.="group by os order by 2";
  my $ref = $self->fetch_array($req, 15);
  my $my_graph = GD::Graph::bars->new(1000,300);
  $my_graph->set_legend("","os tested");
  $my_graph->set(
		 title           => 'Average % of successful make test by os',
		 y_max_value     => 100,
		 y_tick_number   => 10,
		 show_values => 1,
		 x_label_skip    => 1,
		 y_label_position => 0,
		 axis_space => 20,
		 # shadows
		 shadowclr       => 'dred',
		 shadow_depth    => 4,
		 transparent     => 0,
		 bar_spacing => 10,
		 legend_spacing => 40,
 		 t_margin => 35,
		 box_axis => 0
		)
    or warn $my_graph->error;
  go($my_graph, $ref, "$self->{DIR}/5_configure_by_os");
}

#------------------------------------------------------------------------------
# go
#------------------------------------------------------------------------------
sub go {
  my ($my_graph, $data, $filename)=@_;
  my $ok = 0;
  print STDERR $filename,"=>\n",Data::Dumper->Dump( $data) if ($debug);
  foreach my $ref ($$data[1]) {
    foreach my $ref2 (@$ref) {
      $ok=1 if ($ref2 != 0);
    }
  }
  return if (!$ok);
  $data = GD::Graph::Data->new($data) or die GD::Graph::Data->error;
  $my_graph->set_x_axis_font($font,12 );
  $my_graph->set_y_axis_font($font,9 );
  $my_graph->set_title_font($font,14);
  $my_graph->set_values_font($font,11);
  $my_graph->set_text_clr("black");
  $my_graph->plot($data) or die $my_graph->error;
  print STDERR "Create $filename.png\n" if ($debug);
  return save_chart($my_graph, $filename);
}

#------------------------------------------------------------------------------
# save_chart
#------------------------------------------------------------------------------
sub save_chart {
  my $chart = shift or warn "Need a chart!";
  my $name = shift or warn "Need a name!";
  return if (!$name or !$chart);
  local(*OUT);
  open(OUT, ">$name.png") or 
    confess "Cannot open $name.png for write: $!";
  binmode OUT;
  print OUT $chart->gd->png();
  close OUT;
  return 1;
}

#------------------------------------------------------------------------------
# fetch_array
#------------------------------------------------------------------------------
sub fetch_array {
  my ($self,$request, $limit)=@_;
  my (@tab,@tab2);
  print STDERR "SQL request =>$request\n" if ($debug);
  my $ref = $self->{DBH}->selectall_arrayref($request);
  print STDERR "1:",Data::Dumper->Dump($ref) if ($debug);
  foreach (@$ref) {
    next if (($limit && $_->[1] < $limit) or (!$_->[1] and !$_->[0]));
    my $i = 0;
    foreach my $v (@$_) { push( @{$tab[$i++]}, $v);  }
  }

  print STDERR "2:",Data::Dumper->Dump([ \@tab ]) if ($debug);
  return \@tab;
}

#------------------------------------------------------------------------------
# create_html
#------------------------------------------------------------------------------
sub create_html {
  my ($self, $mt, $ref, $c)=@_;
  my $i=0;
  print STDERR "Create $mt.html\n" if ($self->{opts}->{debug});
  open(STATS,">$mt.html") or die "Can't create $mt.html:$!\n";
  print STATS $self->{dbsmoke}->HTML->header_html.
    $c->h2($$ref{$mt})."Current result - ";
  foreach my $mt2 (keys %$ref) {
    print STATS $c->a({-href=>"$mt2.html"},$$ref{$mt2})." - ";
  }
  print STATS "<hr>\n";
  foreach (glob("$mt/*.png")) {
    print STATS $c->img({-src => $_,-align=>'center',-width=>1000,
			 -height=>300}),"<hr>\n";
  }
  print STATS "Build with DBD::Mysql / GD::Graph / Test::Smoke::Database on ",
    scalar localtime,$c->end_html;
  close(STATS);
}

#------------------------------------------------------------------------------
# stats_cpan
#------------------------------------------------------------------------------
sub stats_cpan {
  my $self = shift;
  my $content = get("http://testers.cpan.org/search?request=by-config")
    or return undef;
  my @liste;
  my ($perl, $os, $osver, $archi);
  foreach (split(/<tr>/, $content)) {
    my @content2 = split(/<td/, $_);
    my ($val, $num);
    my $i=$#content2+1;
    next if ($i==0);
    foreach (@content2) {
      next if (--$i==$#content2);
      #    print $_,"\n";
      if (m!<A HREF=[^>]*>(.*)</A>.*<sub>(\d*)</sub>!) {
	($val, $num) = ($1, $2);
      }
      #    print $i," ",$val,"\n";
    if ($i==4 && $val){ $perl = $val; }
      elsif ($i==3 && $val) { $os = $val; }
      elsif ($i==2 && $val) { $osver = $val; }
      elsif ($i==1 && $val) { $archi = $val; }
      #    $i--;
      last if ($i==1);
    }
    next if (!$perl or !$os or !$osver or !$archi or !$num);
    #  print "$perl / $os / $osver / $archi / $num\n";
    push(@liste, [ $perl, $os, $osver, $archi, $num]);
  }

  my (%perl,%os,%os58,%os56,%os55);
  my ($tt,$tt58,$tt56,$tt55);
  foreach my $ref (@liste) {
    $perl{$$ref[0]}+=$$ref[4];
    if ($$ref[0] eq '5.008') { $os58{$$ref[1]}+=$$ref[4]; $tt58+=$$ref[4]; }
    elsif ($$ref[0] eq '5.006_01') { $os56{$$ref[1]}+=$$ref[4]; $tt56+=$$ref[4]; }
    elsif ($$ref[0] eq '5.005_03') { $os55{$$ref[1]}+=$$ref[4]; $tt55+=$$ref[4]; }
    $os{$$ref[1]}+=$$ref[4];
    $tt+=$$ref[4];
  }
  foreach my $ref (\%perl,\%os ) {
    foreach my $n (keys %$ref) { $$ref{$n}=$$ref{$n}*100/$tt; }
  }
  foreach my $n (keys %os58) { $os58{$n}=$os58{$n}*100/$tt58; }
  foreach my $n (keys %os56) { $os56{$n}=$os56{$n}*100/$tt56; }
  foreach my $n (keys %os55) { $os55{$n}=$os55{$n}*100/$tt55; }

  graph_cpan("1_perl_version","% CPAN reports by Perl version",%perl);
  graph_cpan("2_os","% CPAN reports by OS",%os);
  graph_cpan("3_os58","% CPAN reports by OS for Perl 5.008 ($tt58 reports)",%os58);
  graph_cpan("4_os56","% CPAN reports by OS for Perl 5.006_01 ($tt56 reports)",
	     %os56);
  graph_cpan("5_os55","% CPAN reports by OS for Perl 5.005_03 ($tt55 reports)",
	     %os55);
}

#------------------------------------------------------------------------------
# graph
#------------------------------------------------------------------------------
sub graph_cpan {
  my ($name, $title, %perl)=@_;
  foreach my $r (keys %perl) {
    if ($perl{$r} <2) {
      $perl{"others"}+=$perl{$r};
      delete $perl{$r};
#      print $perl{$r},"\n";
    }
  }
  my @l = sort { $perl{$a} <=> $perl{$b} } keys %perl;
  my @l2;
  foreach (@l) { push(@l2, $perl{$_}); }
  my $ref = [ \@l, \@l2];
  my $my_graph = GD::Graph::bars->new(1000,300);
  #$my_graph->set_legend("","% of successful make test");
  $my_graph->set( 
		 title           => $title,
	#	 y_max_value     => 25000,
		#y_tick_number   => 10,
#		 x_label_skip    => 0,
		 show_values => 1,
		 axis_space => 20,
		 t_margin => 40,
		 b_margin => 20,
		 box_axis => 0,
	#	 dclrs       => [ qw/black/ ],
		 transparent     => 0,
		 shadowclr       => 'dred',
		 legend_spacing => 40,
		 shadow_depth    => 4,
		 transparent     => 0,
		 bar_spacing => 20,
		 values_format       => "%2.1f %%"
		)
    or warn $my_graph->error;
  go($my_graph, $ref, "cpan/$name");
}

__END__

#------------------------------------------------------------------------------
# POD DOC
#------------------------------------------------------------------------------


=head1 NAME

Test::Smoke::Database::Graph - Method for build chart on BleadPerl

=head1 SYNOPSIS

  $ admin_smokedb --create --suck --import --update_archi
  $ lynx http://localhost/cgi-bin/smokedb.cgi

=head1 DESCRIPTION

This module build chart about smoke database

=head1 SEE ALSO

L<Test::Smoke::Database>

=head1 METHODS

=over 4

=item B<new> I<DBH>, I<LIMIT>, I<DIRECTORY>

Construct a new Test::Smoke::Database::Graph object and return it.

=back

=head1 VERSION

$Revision: 1.10 $

=head1 AUTHOR

Alain BARBET

=cut

1;
