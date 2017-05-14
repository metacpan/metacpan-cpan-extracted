package MyUtils;
use strict;
use Carp;
use Encode;
use v5.10;
use Spreadsheet::ParseExcel; 
use Spreadsheet::ParseExcel::FmtUnicode; 
use Spreadsheet::WriteExcel;
use Student;
use Moose;

sub u8_to_gbk{
    my $class = shift;
    my $content = shift ||croak "need a string to convert";
    $content =encode("gbk", decode("utf8",$content));
    return $content;
}

sub gbk_to_u8{
    my $class = shift;
    my $content = shift ||croak "need a string to convert";
    $content =encode("utf8", decode("gbk",$content));
    return $content;
}
sub  to_gb2312{
    my $class = shift;
    my $text = shift;

    return decode( 'gb2312', $text );
}

sub read_xls{
    my $class = shift;
    my $file =shift;

    my $oFmtJ = Spreadsheet::ParseExcel::FmtUnicode->new(Unicode_Map => 'GB2312'); 
    my $workbook = Spreadsheet::ParseExcel::Workbook->Parse($file, $oFmtJ); 

    my $worksheet = $workbook->worksheet(0);
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    my @ret;
    for my $row ( 1 .. $row_max ) {
        my $class = $worksheet->get_cell( $row, 0 )->unformatted();
        my $no = $worksheet->get_cell( $row, 1 )->unformatted();
        my $name = $worksheet->get_cell( $row, 2 )->value();
        my $yuwen =$worksheet->get_cell( $row, 3 )->value();
        my $shuxue =$worksheet->get_cell( $row, 4 )->value();
        my $yingyu =$worksheet->get_cell( $row, 5 )->value();
        my $wuli =$worksheet->get_cell( $row, 6 )->value();
        my $huaxue =$worksheet->get_cell( $row, 7 )->value();
        my $shengwu =$worksheet->get_cell( $row, 8 )->value();
        my $xinji =$worksheet->get_cell( $row, 9 )->value();
        my $tongji =$worksheet->get_cell( $row, 10 )->value();
        my $xintong =$worksheet->get_cell( $row, 11 )->value();
        my $sanmen =$worksheet->get_cell( $row, 12 )->value();
        my $lizong =$worksheet->get_cell( $row, 13 )->value();

        my $s1 = Student->new;
        $s1->class($class) ;
        $s1->no($no) ;
        $s1->name($name) ;
        $s1->yuwen($yuwen) ;
        $s1->shuxue($shuxue) ;
        $s1->yingyu($yingyu) ;
        $s1->wuli($wuli) ;
        $s1->huaxue($huaxue) ;
        $s1->shengwu($shengwu) ;
        $s1->xinji($xinji) ;
        $s1->tongji($tongji) ;
        $s1->xintong($xintong) ;
        $s1->sanmen($sanmen) ;
        $s1->lizong($lizong) ;

        push @ret,$s1;
#    $worksheet2->write($row,2, MyUtils->to_gb2312($name));


    }

    $workbook = undef;
    return @ret;

}

sub sort_by_km{
    my $class = shift;
    my $km_mark = shift;
    my $rank = 'rank_'.$km_mark;

    my @arr = @_;
    my @ret=sort { $b->$km_mark <=>$a->$km_mark }@arr;
    #≈≈–Úªÿ–¥
    for(my $i=0;$i<@ret;$i++){
        $ret[$i]->$rank($i+1);
        #say "≈≈√˚:\t".$ret[$i]->name."\t".$ret[$i]->$km_mark."\t".$ret[$i]->$rank."\t";
    }
    return @ret;

}

sub sort_allkm{
    my $class = shift;
    my @arr = @_;
    for my $km ('yuwen','shuxue','yingyu','wuli','huaxue','shengwu','xinji','tongji','xintong','sanmen','lizong'){
        @arr=MyUtils->sort_by_km($km,@arr);
    }
    @arr=sort {$a->class cmp $b->class or $a->no <=> $b->no } @arr;
    return @arr;
}


1;
