package Tk::MDI::Images;

use vars qw($VERSION);
use strict;
use Carp;

my $MDI_Images={}; 

sub createImage
{
    my ($top, $style)=@_;
    croak "Please define a style" unless $style;
    no strict 'refs';
    eval(&$style($top));
    return $MDI_Images; #return hash reference to image hash references
}

sub default
{
    my ($top)=@_;

    $MDI_Images->{minimize}=$top->Bitmap(
            -data =>"#define default_minimize_width 9\n".
                    "#define default_minimize_height 8\n".
        <<EOF);
static unsigned char default_minimize_bits[] = {
0x00, 0x00, 0x00, 0x00, 0xff, 0x01, 0xff, 0x01, 0xfe, 0x00, 0x7c, 0x00,
0x38, 0x00, 0x10, 0x00};

EOF
  
    $MDI_Images->{maximize}= $top->Bitmap(
            -data =>"#define default_maximize_width 9\n".
                    "#define default_maximize_height 8\n".
        <<EOF);
static unsigned char default_maximize_bits[] = {
0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xfe, 0x00, 0xff, 0x01, 0xff, 0x01,
0x00, 0x00, 0x00, 0x00};

EOF

    $MDI_Images->{close}= $top->Bitmap(
            -data =>"#define default_close_width 9\n".
                    "#define default_close_height 8\n".
        <<EOF);
static unsigned char default_close_bits[] = {
0x83, 0x01, 0xc7, 0x01, 0xee, 0x00, 0x7c, 0x00, 0x7c, 0x00, 0xee, 0x00,
0xc7, 0x01, 0x83, 0x01};

EOF


    $MDI_Images->{restore}=$top->Bitmap(
            -data =>"#define default_restore_width 9\n".
                    "#define default_restore_height 8\n".
        <<EOF);
static unsigned char default_restore_bits[] = {
0xf8, 0x01, 0xf8, 0x01, 0x08, 0x01, 0x3f, 0x01, 0xff, 0x01, 0x21, 0x00,
0x21, 0x00, 0x3f, 0x00};

EOF

}

sub win32
{
    my ($top)=@_;

    $MDI_Images->{minimize}=$top->Bitmap(
            -data =>"#define win32_minimize_width 9\n".
                    "#define win32_minimize_height 8\n".
        <<EOF);
static unsigned char win32_minimize_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0xff, 0x01, 0xff, 0x01};

EOF
   
    $MDI_Images->{maximize}=$top->Bitmap(
            -data =>"#define win32_maximize_width 9\n".
                    "#define win32_maximize_height 8\n".
        <<EOF);
static unsigned char win32_maximize_bits[] = {
0xff, 0x01, 0xff, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
0x01, 0x01, 0xff, 0x01};

EOF

    $MDI_Images->{close}=$top->Bitmap(
            -data =>"#define win32_close_width 9\n".
                    "#define win32_close_height 8\n".
        <<EOF);
static unsigned char win32_close_bits[] = {
0x83, 0x01, 0xc7, 0x01, 0xee, 0x00, 0x7c, 0x00, 0x7c, 0x00, 0xee, 0x00,
0xc7, 0x01, 0x83, 0x01};

EOF

    $MDI_Images->{restore}=$top->Bitmap(
            -data =>"#define win32_restore_width 9\n".
                    "#define win32_restore_height 8\n".
        <<EOF);
static unsigned char win32_restore_bits[] = {
0xf8, 0x01, 0xf8, 0x01, 0x08, 0x01, 0x3f, 0x01, 0xff, 0x01, 0x21, 0x00,
0x21, 0x00, 0x3f, 0x00};

EOF
}
sub kde
{
    my ($top)=@_;

    $MDI_Images->{minimize}=$top->Bitmap(
            -data =>"#define kde_minimize_width 10\n".
                    "#define kde_minimize_height 10\n".
        <<EOF);
static unsigned char kde_minimize_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x78, 0x00, 0x78, 0x00, 0x78, 0x00,
   0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

EOF
   
    $MDI_Images->{maximize}=$top->Bitmap(
            -data =>"#define kde_maximize_width 10\n".
                    "#define kde_maximize_height 10\n".
        <<EOF);
static unsigned char kde_maximize_bits[] = {
   0xff, 0x03, 0xff, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03,
   0x03, 0x03, 0x03, 0x03, 0xff, 0x03, 0xff, 0x03};

EOF

    $MDI_Images->{close}=$top->Bitmap(
            -data =>"#define kde_close_width 10\n".
                    "#define kde_close_height 10\n".
        <<EOF);
static unsigned char kde_close_bits[] = {
   0x03, 0x03, 0x87, 0x03, 0xce, 0x01, 0xfc, 0x00, 0x78, 0x00, 0x78, 0x00,
   0xfc, 0x00, 0xce, 0x01, 0x87, 0x03, 0x03, 0x03};

EOF

    $MDI_Images->{restore}=$top->Bitmap(
            -data =>"#define kde_restore_width 9\n".
                    "#define kde_restore_height 8\n".
        <<EOF);
static unsigned char kde_restore_bits[] = {
   0xff, 0x00, 0xff, 0x00, 0x81, 0x00, 0xfd, 0x03, 0xfd, 0x03, 0x05, 0x02,
   0x05, 0x02, 0x07, 0x02, 0x04, 0x02, 0xfc, 0x03};

EOF
}
sub fvwm
{}


1;
