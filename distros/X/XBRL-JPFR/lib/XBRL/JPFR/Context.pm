package XBRL::JPFR::Context;

our $VERSION = '0.01';

#use strict;
use warnings;
use Carp;
use Hash::Merge qw(merge);
use Clone qw(clone);
use Data::Dumper;

my @org_fields = qw(id scheme identifier startDate endDate label dimension duration);
my @fields = qw(lang rolelink);
XBRL::JPFR::Context->mk_accessors(@fields);
use base qw(XBRL::Context);

my %default = (
	'lang' => 'ja',
	'rolelink' => 'http://www.xbrl.org/2003/role/link',
);

sub new() {
	my ($class, $xml, $labels, $prefix, $args) = @_;
	$args = {} if !$args;
	$args = merge($args, \%default);
	my $self = $class->SUPER::new($xml);
	bless $self, $class;
	foreach (keys %$args) {
		$self->$_($$args{$_});
	}
	$self->make_label($self->lang(), $labels, $prefix);

	return $self;
}

sub dimension_label {
	my ($self, $labels) = @_;
	my $dims = $self->dimension();
	foreach my $dim (@$dims) {
		foreach my $key ('dim', 'val') {
			my $id_short = $$dim{$key};
			$id_short =~ s/:/_/;
			my $role = "http://www.xbrl.org/2003/role/verboseLabel";
			my $label = $$labels{$id_short}{$$self{'rolelink'}}{$role} if $$labels{$id_short}{$$self{'rolelink'}}{$role};
			$role = "http://www.xbrl.org/2003/role/label";
			$label = $$labels{$id_short}{$$self{'rolelink'}}{$role} if !$label;
			if ($label) {
				$$dim{"${key}_label"} = $label
			}
			else {
				warn "No dimension label($id_short)";
			}
		}
	}
}

sub date_label_ja {
	my ($self) = @_;
	my $date = '2001/01/01';
	if ($self->startDate() && $self->endDate()) {
		my ($sy, $sm, $sd) = $self->startDate()->value();
		my ($ey, $em, $ed) = $self->endDate()->value();
		map {$_ = Encode::encode('UTF-8', $_)} ($sy, $sm, $sd, $ey, $em, $ed); # Why ?
		$date = sprintf "自%d年%02d月%02d日 至%d年%02d月%02d日", $sy, $sm, $sd, $ey, $em, $ed;
	}
	elsif ($self->endDate()) {
		my ($ey, $em, $ed) = $self->endDate()->value();
		map {$_ = Encode::encode('UTF-8', $_)} ($ey, $em, $ed);
		$date = sprintf "%d年%02d月%02d日", $ey, $em, $ed;
	}
	return $date;
}

sub make_label {
	my ($self, $lang, $labels, $prefix) = @_;
	my $label_func = "make_label_$lang";
	&$label_func($self, $$labels{$lang}, $prefix);
}

sub make_label_en {
}

BEGIN {

my %labels = (
	FilingDate						=> '提出日',
	DateOfEvent						=> '基準日',
	DocumentInfo					=> '提出書類情報',
	CG								=> 'コーポレート・ガバナンス',
	Interim		=> '中間期',
	Current		=> {
		Year		=> '当期',
		YTD			=> '当四半期累計期間',
		Quarter		=> '当四半期会計期間',
	},
	Prior		=> {
		Quarter		=> '前四半期会計期間',
		1			=> {
			Year		=> '前年度',
			Interim		=> '前中間期',
			YTD			=> '１年度前同四半期累計期間',
			Quarter		=> '１年度前同四半期会計期間',
		},
		2			=> {
			Year		=> '前々年度',
			Interim		=> '前々中間期',
			YTD			=> '２年度前同四半期累計期間',
			Quarter		=> '２年度前同四半期会計期間',
		},
		3			=> {
			Year		=> '３年度前',
			Interim		=> '３年度前中間期',
			YTD			=> '３年度前同四半期累計期間',
			Quarter		=> '３年度前同四半期会計期間',
		},
		4			=> {
			Year		=> '４年度前',
			Interim		=> '４年度前中間期',
			YTD			=> '４年度前同四半期累計期間',
			Quarter		=> '４年度前同四半期会計期間',
		},
		5			=> {
			Year		=> '５年度前',
			Interim		=> '５年度前中間期',
			YTD			=> '５年度前同四半期累計期間',
			Quarter		=> '５年度前同四半期会計期間',
		},
		6			=> {
			Year		=> '６年度前',
			Interim		=> '６年度前中間期',
			YTD			=> '６年度前同四半期累計期間',
			Quarter		=> '６年度前同四半期会計期間',
		},
		7			=> {
			Year		=> '７年度前',
			Interim		=> '７年度前中間期',
			YTD			=> '７年度前同四半期累計期間',
			Quarter		=> '７年度前同四半期会計期間',
		},
		8			=> {
			Year		=> '８年度前',
			Interim		=> '８年度前中間期',
			YTD			=> '８年度前同四半期累計期間',
			Quarter		=> '８年度前同四半期会計期間',
		},
		9			=> {
			Year		=> '９年度前',
			Interim		=> '９年度前中間期',
			YTD			=> '９年度前同四半期累計期間',
			Quarter		=> '９年度前同四半期会計期間',
		},
	},
	Last		=> {
		Quarter			=> '前四半期会計期間',
		1			=> {
			Quarter		=> '１年度前の前四半期会計期間',
		},
		2			=> {
			Quarter		=> '２年度前の前四半期会計期間',
		},
		3			=> {
			Quarter		=> '３年度前の前四半期会計期間',
		},
		4			=> {
			Quarter		=> '４年度前の前四半期会計期間',
		},
		5			=> {
			Quarter		=> '５年度前の前四半期会計期間',
		},
		6			=> {
			Quarter		=> '６年度前の前四半期会計期間',
		},
		7			=> {
			Quarter		=> '７年度前の前四半期会計期間',
		},
		8			=> {
			Quarter		=> '８年度前の前四半期会計期間',
		},
		9			=> {
			Quarter		=> '９年度前の前四半期会計期間',
		},
	}
);

# 2684/S00057FU/jpfr-q2r-E03369-000-2009-12-31-01-2010-02-12.xbrl
#   No relative duration nor instant(edinet,Pruir1QuarterConsolidatedInstant)
# 4684/S00039KN/jpfr-q1r-E05025-000-2009-06-30-01-2009-08-07.xbrl
#   No relative duration nor instant(edinet,Prior1LastQuarterConsolidatedInstant)
# 4686
#   No relative duration nor instant(edinet,Prior1LastQuarterConsolidatedInstant)
# 7921
#   No relative duration nor instant(edinet,Prior1NonYearConsolidatedInstant)
# 8697
#   No relative duration nor instant(edinet,Prir1QuarterConsolidatedInstant)
sub find_relative_ja {
	my ($id) = @_;
	$id =~ s/NonConsolidated|Consolidated|Instant|Duration//g;
	my @keys = grep {$_ ne ''} split /(Current|Prior|Last|Year|Interim|YTD|Quarter|\d)/, $id;
	#print "$id ".Dumper(\@keys);
	my $ls = \%labels;
	foreach my $key (@keys) {
		return undef if !exists $$ls{$key};
		 if (ref $$ls{$key}) {
		 	$ls = $$ls{$key};
		}
		else {
		 	return $$ls{$key};
		}
	}
	return undef;
}

sub make_label_ja {
	my ($self, $labels, $prefix) = @_;
	if ($self->scheme() =~ /edinet/) {
		make_label_ja_edinet($self, $labels, $prefix);
	}
	elsif ($self->scheme() =~ /tse/) {
		make_label_ja_tdnet($self, $labels, $prefix);
	}

	$self->dimension_label($labels);
}

# 9399/S000D6KG/jpfr-asr-E05951-000-2012-12-31-01-2013-04-02.xbrl
#   CurrentYearConsolidatedDuration{,_2}: have different unitRefs(Yen and USD)
sub make_label_ja_edinet {
	my ($self, $labels, $prefix) = @_;
	my $id = $self->id();
	my @ids = split /_/, $id, 2;

	my $rel = find_relative_ja($ids[0]);
	if (!$rel) {
		warn "No relative duration nor instant(edinet,$id)";
		$rel = "";
	}

	my $cn;
	if ($id =~ /NonConsolidated/) {
		$cn = "個別";
	}
	elsif ($id =~ /Consolidated/) {
		$cn = "連結";
	}
	else {
		# FIXME:
		# http://www.fsa.go.jp/search/20130821/2b_1.pdf: P31
		# EDINET 2013-08-31 基準では連結の判別が不能？
		# 連結・個別の区別がされない箇所(「大株主の状況」等)がある。
		# そのリストもない。
		$cn = "";
	}

	my $di;
	if ($id =~ /Instant/) {
		$di = "時点";
	}
	elsif ($id =~ /Duration/) {
		$di = "期間";
	}
	elsif ($id =~ /DocumentInfo|DateOfEvent|CG/) {
	}
	else {
		warn "No duration nor instant(edinet,$id)";
		$di = "";
	}

	my $mem_label;
	my $label;
	if (@ids == 1) {
		if ($id =~ /FilingDate|DocumentInfo|DateOfEvent|CG/) {
			$label = $rel;
		}
		else {
			$label = "$rel${di}";
			$label .= "_$cn";
		}
	}
	elsif (@ids == 2) {
		if ($id =~ /FilingDate|DocumentInfo|DateOfEvent|CG/) {
			$label = $rel;
		}
		else {
			$label = "$rel${di}";
			$label .= "_$cn";
		}
		my @mem_labels = $self->get_member_labels($ids[1], $labels, $prefix);
		$label = join '_', $label, @mem_labels;
	}

	my $date = $self->date_label_ja();
	$label .= "_$date" if $date;

	$self->label($label);
}

sub get_member_labels {
	my ($self, $mem, $labels, $prefix) = @_;
	(undef, $mem) = split /_/, $mem, 2 if $mem =~ /NonConsolidatedMember/;
	return () if !defined $mem;
	my @mems = $mem =~ /^jp/ ? ($mem) : split /_/, $mem;
	my @mem_labels;
	foreach my $mem (@mems) {
		my $mem_label;
		if ($mem =~ /^\d+$/) {
			$mem_label = $mem;
		}
		elsif ($mem =~ /^jp[a-z]{3}\d{6}/) {
			# jplvh030000-lvh_E03530-000_FilerLargeVolumeHolder1Member が
			# jplvh030000-lvh_E03530-000FilerLargeVolumeHolder1Member となっている
			$mem =~ s/(\d{3})([A-Z])/$1_$2/;
			my $id_short = $mem;
			my $role = "http://www.xbrl.org/2003/role/verboseLabel";
			$mem_label = $$labels{$id_short}{$$self{'rolelink'}}{$role} if $$labels{$id_short}{$$self{'rolelink'}}{$role};
			$role = "http://www.xbrl.org/2003/role/label";
			$mem_label = $$labels{$id_short}{$$self{'rolelink'}}{$role} if !$mem_label;
		}
		else {
			foreach my $pref ('jppfs_cor', 'jpcrp_cor', 'jplvh_cor', 'ifrs', $prefix) {
				my $id_short = "${pref}_$mem";
				my $role = "http://www.xbrl.org/2003/role/verboseLabel";
				$mem_label = $$labels{$id_short}{$$self{'rolelink'}}{$role} if $$labels{$id_short}{$$self{'rolelink'}}{$role};
				$role = "http://www.xbrl.org/2003/role/label";
				$mem_label = $$labels{$id_short}{$$self{'rolelink'}}{$role} if !$mem_label;
				last if $mem_label;
			}
		}
		if (!$mem_label) {
			warn "No member label($mem)";
			push @mem_labels, $mem;
		}
		else {
			push @mem_labels, $mem_label;
		}
	}
	return @mem_labels;
}

sub make_label_ja_tdnet {
	my ($self, $labels, $prefix) = @_;
	my $id = $self->id();

	my $di;
	if ($id =~ /Instant/) {
		$di = "時点";
	}
	elsif ($id =~ /Duration/) {
		$di = "期間";
	}
	elsif ($id =~ /DocumentInfo|DateOfEvent|CG/) {
	}
	else {
		warn "No duration nor instant(tdnet,$id)";
		$di = "";
	}

	my $cn;
	if ($id =~ /NonConsolidated/) {
		$cn = "個別";
	}
	elsif ($id =~ /Consolidated/) {
		$cn = "連結";
	}
	else {
		#warn "No nonconsolidated nor consolidated(tdnet,$id)";
		$cn = "";
	}

	my $rel;
	if ($id =~ /CurrentYear/) {
		# 年間配当スケジュール軸(AnnualDividendPaymentScheduleAxis)
		if ($id =~ /FirstQuarterMember/) {
			$rel = "当期第１四半期末_${cn}";
		}
		elsif ($id =~ /SecondQuarterMember/) {
			$rel = "当期第２四半期末_${cn}";
		}
		elsif ($id =~ /ThirdQuarterMember/) {
			$rel = "当期第３四半期末_${cn}";
		}
		elsif ($id =~ /YearEndMember/) {
			$rel = "当期期末_${cn}";
		}
		elsif ($id =~ /AnnualMember/) {
			$rel = "当期合計_${cn}";
		}
		# 
		else {
			$rel = "当期${di}_${cn}";
		}
	}
	elsif ($id =~ /CurrentAccumulatedQ1/) {
		$rel = "当期第１四半期累計${di}_${cn}";
	}
	elsif ($id =~ /CurrentAccumulatedQ2/) {
		$rel = "当期第２四半期累計${di}_${cn}";
	}
	elsif ($id =~ /CurrentAccumulatedQ3/) {
		$rel = "当期第３四半期累計${di}_${cn}";
	}
	elsif ($id =~ /NextYear/) {
		$rel = "次期${di}_${cn}";
	}
	elsif ($id =~ /Next2Year/) {
		$rel = "次々期${di}_${cn}";
	}
	elsif ($id =~ /NextAccumulatedQ1/) {
		$rel = "次期第１四半期累計${di}_${cn}";
	}
	elsif ($id =~ /NextAccumulatedQ2/) {
		$rel = "次期第２四半期累計${di}_${cn}";
	}
	elsif ($id =~ /NextAccumulatedQ3/) {
		$rel = "次期第３四半期累計${di}_${cn}";
	}
	elsif ($id =~ /PriorYear/) {
		# 年間配当スケジュール軸(AnnualDividendPaymentScheduleAxis)
		if ($id =~ /FirstQuarterMember/) {
			$rel = "前期第１四半期末_${cn}";
		}
		elsif ($id =~ /SecondQuarterMember/) {
			$rel = "前期第２四半期末_${cn}";
		}
		elsif ($id =~ /ThirdQuarterMember/) {
			$rel = "前期第３四半期末_${cn}";
		}
		elsif ($id =~ /YearEndMember/) {
			$rel = "前期期末_${cn}";
		}
		elsif ($id =~ /AnnualMember/) {
			$rel = "前期合計_${cn}";
		}
		# 
		else {
			$rel = "前期${di}_${cn}";
		}
	}
	elsif ($id =~ /PriorAccumulatedQ1/) {
		$rel = "前期第１四半期累計${di}_${cn}";
	}
	elsif ($id =~ /PriorAccumulatedQ2/) {
		$rel = "前期第２四半期累計${di}_${cn}";
	}
	elsif ($id =~ /PriorAccumulatedQ3/) {
		$rel = "前期第３四半期累計${di}_${cn}";
	}
	else {
		$rel = find_relative_ja($id);
		if (!$rel) {
			warn "No relative duration nor instant(tdnet,$id)";
			$rel = "";
		}
		elsif ($id =~ /FilingDate|DocumentInfo|DateOfEvent|CG/) {
		}
		else {
			$rel = "$rel${di}_${cn}";
		}
	}

	my $fr;
	if ($id =~ /CurrentMember_ResultMember/) {
		$fr = "今回実績";
	}
	elsif ($id =~ /PreviousMember_ResultMember/) {
		$fr = "前回実績";
	}
	elsif ($id =~ /CurrentMember_ForecastMember/) {
		$fr = "今回予想";
	}
	elsif ($id =~ /PreviousMember_ForecastMember/) {
		$fr = "前回予想";
	}
	elsif ($id =~ /CurrentMember_LowerMember/) {
		$fr = "今回下限";
	}
	elsif ($id =~ /PreviousMember_LowerMember/) {
		$fr = "前回下限";
	}
	elsif ($id =~ /CurrentMember_UpperMember/) {
		$fr = "今回上限";
	}
	elsif ($id =~ /PreviousMember_UpperMember/) {
		$fr = "前回上限";
	}
	elsif ($id =~ /ResultMember/) {
		$fr = "実績";
	}
	elsif ($id =~ /ForecastMember/) {
		$fr = "予想";
	}
	elsif ($id =~ /LowerMember/) {
		$fr = "下限";
	}
	elsif ($id =~ /UpperMember/) {
		$fr = "上限";
	}
	else {
		#warn "No result nor forecast member(tdnet,$id)";
		$fr = "";
	}

	my $label = $rel;
	$label .= "_$fr";
	my $date = $self->date_label_ja();
	$label .= "_$date" if $date;

	$self->label($label);
}

} # BEGIN

sub freeze {
	my ($self) = @_;
	$$self{'startDate'} = $$self{'startDate'} ? $$self{'startDate'}->printf("%Y/%m/%d") : '';
	$$self{'endDate'} = $$self{'endDate'} ? $$self{'endDate'}->printf("%Y/%m/%d") : '';
	return $self;
}


=head1 XBRL::JPFR::Context

XBRL::JPFR::Context - OO Module for Encapsulating XBRL::JPFR Contexts

=head1 SYNOPSIS

  use XBRL::JPFR::Context;

	my $context = XBRL::JPFR::Context->new($context_xml);

=head1 DESCRIPTION

This module is part of the XBRL::JPFR modules group and is intended for use with XBRL::JPFR.

=item new

Object constructor takes a scalar containing the XML representing the context

=back

=head1 AUTHOR

Tetsuya Yamamoto <yonjouhan@gmail.com>

=head1 SEE ALSO

Modules: XBRL XBRL::JPFR XBRL::Context

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tetsuya Yamamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
