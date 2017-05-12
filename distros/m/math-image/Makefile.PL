#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-Image.
#
# Math-Image is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Image is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Image.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %gtk2_interface
  = (
     'Glib' => '1.220', # for Glib::SOURCE_REMOVE
     'Glib::Object::Subclass' => 0,
     'Glib::Ex::ConnectProperties' => 14, # v.14 for response-sensitive#

     # my Glib-Ex-ObjectBits
     'Glib::Ex::EnumBits'     => 11, # new in v.11
     # 'Glib::Ex::FreezeNotify' => 0,
     'Glib::Ex::ObjectBits'   => 12, # new in v.12
     'Glib::Ex::SourceIds'    => 2,  # new in v.2
     'Glib::Ex::SignalBits'   => 9,  # new in v.9
     'Glib::Ex::SignalIds'    => 0,

     # Perl-Gtk2
     'Gtk2' => '1.220',
     'Gtk2::Pango' => 0, # part of Perl-Gtk2, used explicitly

     # my Gtk2-Ex-WidgetBits
     'Gtk2::Ex::ActionTooltips' => 10, # new in v.10
     'Gtk2::Ex::ContainerBits'  => 21, # new in v.21
     'Gtk2::Ex::GdkBits'        => 23, # v.23 for window_clear_region()
     'Gtk2::Ex::MenuItem::Subclass' => 29, # new in v.29
     'Gtk2::Ex::MenuBits'       => 35, # v.35 for mnemonic_escape()
     'Gtk2::Ex::PixbufBits'     => 37, # v.37 fix save_adapt()
     'Gtk2::Ex::Statusbar::Message'         => 47, # new in v.47
     'Gtk2::Ex::Statusbar::MessageUntilKey' => 11, # new in v.11
     'Gtk2::Ex::ToolbarBits'    => 36, # v.36 avoid stray 5.010
     'Gtk2::Ex::ToolItem::CheckButton' => 42,  # new in v.42
     'Gtk2::Ex::ToolItem::OverflowToDialog' => 41,  # v.41 fix overflow-mnemonic
     'Gtk2::Ex::Units'          => 13, # new in v.13
     'Gtk2::Ex::SyncCall'       => 12, # v.12 workaround gtk 2.12 bug
     'Gtk2::Ex::WidgetEvents'   => 21, # new in v.21
     'Test::Weaken::Gtk2'       => 39, # v.39 for ignore_default_root_window()

     # my QuadButton / QuadScroll
     'Gtk2::Ex::AdjustmentBits' => 46, # v.46 for scroll_event()
     'Gtk2::Ex::EntryBits'      => 46, # v.46 for scroll_number_handler()
     'Gtk2::Ex::WidgetBits'     => 40, # v.40 for pixel_size_mm()
     'Gtk2::Ex::Statusbar::DynamicContext' => 20, # new in v.20

     # my Gtk2-Ex-ComboBoxBits
     # 'Gtk2::Ex::ComboBoxBits'   => 2, # version 2 fix MoreUtils dependency
     'Gtk2::Ex::ComboBox::Enum' => 5, # v.5 for set_active_nick()
     'Gtk2::Ex::ComboBox::Text' => 2,
     'Gtk2::Ex::ComboBox::PixbufType' => 31, # v.31 fix initial for_width
     'Gtk2::Ex::Menu::EnumRadio' => 6, # new in version 6
     'Gtk2::Ex::ToolItem::ComboEnum' => 28, # new in version 28

     'Gtk2::Ex::Dragger' => 2, # v.2 for external adj changes
     'Gtk2::Ex::NumAxis' => 2,
     'Gtk2::Ex::WidgetCursor' => 15, # v.15 for SignalIds fix
     'Gtk2::Ex::Splash' => 1,

     # my Image-Base-Gtk2
     'Image::Base::Gtk2::Gdk::Pixmap' => 2, # v.2 lowering 5.10
     'Image::Base::Gtk2::Gdk::Window' => 2,
     'Image::Base::Gtk2::Gdk::Pixbuf' => 11, # v.11 clip 0,0,width,height

     'Proc::SyncExec' => 0,
     'Software::License::GPL_3' => '0.001',  # about dialog
     'Text::Capitalize' => 0,
    );

my %gtk2_optionals
  = ('Gtk2::Ex::CrossHair'   => 0,
     # suggest ErrorTextDialog v.7 for popup control
     'Gtk2::Ex::ErrorTextDialog::Handler' => 7,
     'Gtk2::Ex::PodViewer'   => 0,
     'Gtk2::Ex::QuadButton'  => 0,
    );

my %x11_interface
  = ('X11::Protocol' => 0,
     # my X11-Protocol-Other
     'X11::Protocol::Other'    => 1,
     'X11::Protocol::WM'       => 19, # v.19 root_to_virtual_root()
     'X11::Protocol::XSetRoot' => 3,  # new in v.3
     'X11::AtomConstants'      => 2,  # new in v.2
     # my Image-Base-X11-Protocol
     'Image::Base::X11::Protocol::Drawable' => 13, # v.13 clipping
     'Image::Base::X11::Protocol::Pixmap' => 0,
     'Image::Base::X11::Protocol::Window' => 0,
    );

my %gtk1_interface
  = ('Gtk' => 0,
     # my Gtk-Ex-WidgetBits
     'Gtk::Ex::Statusbar::MessageUntilKey' => 0,
     # my Image-Base-Gtk
     'Image::Base::Gtk::Gdk::Pixmap' => 0,
     'Image::Base::Gtk::Gdk::Window' => 0,

     'Proc::SyncExec' => 0,
    );

my %tk_interface = (# main Perl-Tk of whatever new enough version
                    'Tk::MainWindow' => 0,
                    'Tk::Balloon' => 0,

                    # my Image-Base-Tk
                    'Image::Base::Tk::Photo' => 4, # v.4 clip fixes
                   );
my %tk_optionals = (# main Perl-Tk of whatever new enough version
                    'Tk::PNG' => 0,
                    'Tk::JPEG' => 0,
                    # separate Tk-TIFF dist
                    'Tk::TIFF' => 0,
                    'Tk::Pod' => 0,
                   );

my %wx_interface
  = (# main wxPerl of whatever new enough version
     'Wx' => 0,

     # my Image-Base-Wx
     'Image::Base::Wx::DC' => 0,

     'Software::License::GPL_3' => '0.001', # about dialog
    );
my %wx_optionals
  = ('Wx::Perl::PodBrowser'   => 2,  # v.2 for File/Print

     # my Image-Base-Wx
     'Image::Base::Wx::Image' => 0, # --png etc file output
    );

my %curses_interface = ('Curses::UI' => 0,
                        'Curses::UI::Common' => 0,
                       );

my %maximum_planepath
  = (
     # cf App::MathImage::Generator path_choices() preferences
     'Math::PlanePath::SquareSpiral'   => 5,  # v.5 wider parameter
     'Math::PlanePath::SacksSpiral'    => 1,
     'Math::PlanePath::VogelFloret'    => 12, # v.12 other rotations + fix
     'Math::PlanePath::TheodorusSpiral'      => 70, # v.70 save pos fix
     'Math::PlanePath::ArchimedeanChords'    => 23, # new in v.23
     'Math::PlanePath::MultipleRings'        => 101, # v.101 polygon fixes
     'Math::PlanePath::PixelRings'           => 28, # v.28 fix xy_to_n diagonal
     'Math::PlanePath::FilledRings'          => 96, # v.96 n_start
     'Math::PlanePath::Hypot'                => 78, # v.78 points odd,even
     'Math::PlanePath::HypotOctant'          => 78, # v.78 points odd,even
     'Math::PlanePath::TriangularHypot'      => 81, # v.81 points hex_rotated
     'Math::PlanePath::PythagoreanTree'      => 95, # v.95 coordinates AC,BC
     'Math::PlanePath::DiagonalRationals'    => 101, # v.101 direction=up
     'Math::PlanePath::FactorRationals'      => 61, # new in v.61
     'Math::PlanePath::GcdRationals'         => 78, # v.78 pairs_order
     'Math::PlanePath::RationalsTree'        => 89, # v.89 L-tree
     'Math::PlanePath::FractionsTree'        => 62, # new in v.62
     'Math::PlanePath::ChanTree'             => 90, # new in v.90
     'Math::PlanePath::CfracDigits'          => 90, # new in v.90
     'Math::PlanePath::CoprimeColumns'       => 32, # new in v.32
     'Math::PlanePath::DivisibleColumns'     => 49, # new in v.49

     'Math::PlanePath::DiamondSpiral'        => 1,
     'Math::PlanePath::PentSpiral'           => 107, # v.107 n_start
     'Math::PlanePath::PentSpiralSkewed'     => 107, # v.107 n_start
     'Math::PlanePath::HexSpiral'            => 9,  # v.9 wider parameter
     'Math::PlanePath::HexSpiralSkewed'      => 9,  # v.9 wider parameter
     'Math::PlanePath::HeptSpiralSkewed'     => 107, # v.107 n_start
     'Math::PlanePath::TriangleSpiral'       => 3,  # new in v.3
     'Math::PlanePath::TriangleSpiralSkewed' => 100, # v.100 skew
     'Math::PlanePath::AnvilSpiral'          => 96, # v.96 n_start
     'Math::PlanePath::OctagramSpiral'       => 107, # v.107 n_start
     'Math::PlanePath::KnightSpiral'         => 1,
     'Math::PlanePath::CretanLabyrinth'      => 68, # new in v.68

     'Math::PlanePath::SquareArms'           => 37, # new in v.37
     'Math::PlanePath::DiamondArms'          => 37, # new in v.37
     'Math::PlanePath::HexArms'              => 36, # new in v.36
     'Math::PlanePath::AztecDiamondRings'    => 49, # new in v.49
     'Math::PlanePath::GreekKeySpiral'       => 80, # v.80 turns
     'Math::PlanePath::MPeaks'               => 55, # new in v.55

     'Math::PlanePath::PyramidRows'          => 84, # v.84 align parameter
     'Math::PlanePath::PyramidSides'         => 1,
     'Math::PlanePath::PyramidSpiral'        => 106, # v.106 n_start
     'Math::PlanePath::CellularRule'         => 63, # new in v.63
     'Math::PlanePath::CellularRule54'       => 40, # new in v.40
     'Math::PlanePath::CellularRule57'       => 67, # new in v.67
     'Math::PlanePath::CellularRule190'      => 54, # v.54 exact rect
     'Math::PlanePath::UlamWarburton'        => 103, # v.103 parts=2,1
     'Math::PlanePath::UlamWarburtonQuarter' => 49, # new in v.49
     'Math::PlanePath::Corner'               => 1,
     'Math::PlanePath::Diagonals'            => 2,  # v.2 sqrt fix
     'Math::PlanePath::DiagonalsAlternating' => 56, # new in v.56
     'Math::PlanePath::DiagonalsOctant'      => 77, # new in v.77
     'Math::PlanePath::Staircase'            => 107, # v.107 n_start
     'Math::PlanePath::StaircaseAlternating' => 107, # v.107 end_type info
     'Math::PlanePath::Rows'                 => 26, # v.26 against width==0
     'Math::PlanePath::Columns'              => 26, # v.26 against height==0

     'Math::PlanePath::PeanoCurve'           => 36, # v.36 radix parameter
     'Math::PlanePath::HilbertCurve'         => 13, # new in v.13
     'Math::PlanePath::HilbertSpiral'        => 57, # new in v.57
     'Math::PlanePath::ZOrderCurve'          => 34, # v.34 radix parameter
     'Math::PlanePath::GrayCode'             => 73, # new in v.73
     'Math::PlanePath::WunderlichMeander'    => 54, # new in v.54
     'Math::PlanePath::WunderlichSerpentine' => 73, # new in v.73
     'Math::PlanePath::BetaOmega'            => 54, # v.54 exact rect
     'Math::PlanePath::AR2W2Curve'           => 59, # new in v.59
     'Math::PlanePath::KochelCurve'          => 55, # new in v.55
     'Math::PlanePath::DekkingCurve'         => 88, # new in v.88
     'Math::PlanePath::DekkingCentres'       => 88, # new in v.88
     'Math::PlanePath::CincoCurve'           => 56, # new in v.56
     'Math::PlanePath::ImaginaryBase'        => 41, # new in v.41
     'Math::PlanePath::ImaginaryHalf'        => 94, # v.94 digit_order
     'Math::PlanePath::CubicBase'            => 75, # new in v.75
     'Math::PlanePath::SquareReplicate'      => 47, # new in v.47
     'Math::PlanePath::CornerReplicate'      => 52, # new in v.52
     'Math::PlanePath::LTiling'              => 57, # v.57 L_fill options
     'Math::PlanePath::DigitGroups'          => 52, # new in v.52
     'Math::PlanePath::FibonacciWordFractal' => 53, # new in v.53

     'Math::PlanePath::Flowsnake'            => 80, # v.80 arms frac fix
     'Math::PlanePath::FlowsnakeCentres'     => 80, # v.80 arms frac fix
     'Math::PlanePath::GosperReplicate'      => 46, # new in v.46
     'Math::PlanePath::GosperIslands'        => 33, # new in v.33
     'Math::PlanePath::GosperSide'           => 35, # new in v.35

     'Math::PlanePath::QuintetCurve'         => 55, # v.55 faster xy_to_n()
     'Math::PlanePath::QuintetCentres'       => 45, # new in v.45
     'Math::PlanePath::QuintetReplicate'     => 45, # new in v.45

     'Math::PlanePath::KochCurve'            => 30, # new in v.30
     'Math::PlanePath::KochPeaks'            => 30, # new in v.30
     'Math::PlanePath::KochSnowflakes'       => 30, # new in v.30
     'Math::PlanePath::KochSquareflakes'     => 30, # new in v.30
     'Math::PlanePath::QuadricCurve'         => 41, # new in v.41
     'Math::PlanePath::QuadricIslands'       => 66, # v.66 n_frac_discontinuity

     'Math::PlanePath::SierpinskiCurve'      => 49, # new in v.49
     'Math::PlanePath::SierpinskiCurveStair' => 73, # new in v.73
     'Math::PlanePath::HIndexing'            => 52, # new in v.52

     'Math::PlanePath::SierpinskiTriangle'   => 83, # v.83 align option
     'Math::PlanePath::SierpinskiArrowhead'        => 87, # v.87 align
     'Math::PlanePath::SierpinskiArrowheadCentres' => 87, # v.87 align
     'Math::PlanePath::DragonCurve'          => 66, # v.66 faster xy_to_n()
     'Math::PlanePath::DragonRounded'        => 67, # v.67 xy_to_n() arms fix
     'Math::PlanePath::DragonMidpoint'       => 67, # v.67 xy_to_n() arms fix
     'Math::PlanePath::AlternatePaper'       => 64, # new in v.64
     'Math::PlanePath::AlternatePaperMidpoint' => 80, # new in v.80
     'Math::PlanePath::CCurve'               => 75, # new in v.75
     'Math::PlanePath::TerdragonCurve'       => 64, # new in v.64
     'Math::PlanePath::TerdragonRounded'     => 80, # v.80 arms frac fix
     'Math::PlanePath::TerdragonMidpoint'    => 80, # v.80 arms frac fix
     'Math::PlanePath::R5DragonCurve'        => 75, # new in v.75
     'Math::PlanePath::R5DragonMidpoint'     => 80, # v.80 arms frac fix
     'Math::PlanePath::ComplexPlus'          => 80, # v.80 arms frac fix
     'Math::PlanePath::ComplexMinus'         => 44, # new in v.44
     'Math::PlanePath::ComplexRevolving'     => 63, # new in v.63

     'Math::PlanePath::WythoffArray'         => 78, # new in v.78
     'Math::PlanePath::PowerArray'           => 78, # new in v.78
     'Math::PlanePath::File'                 => 37, # new in v.37

     'Math::PlanePath::ToothpickTree'        => 6,  # v.6 parts=octant
     'Math::PlanePath::ToothpickReplicate'   => 1,
     'Math::PlanePath::ToothpickUpist'       => 2,  # v.2 num_children_max
     'Math::PlanePath::ToothpickSpiral'      => 10, # new in v.10
     'Math::PlanePath::LCornerTree'          => 9,  # v.9 parts=octant+1
     'Math::PlanePath::LCornerReplicate'     => 1,
     'Math::PlanePath::OneOfEight'           => 5,  # v.5 parts=octant_up
    );

my %maximum_numseq
  = (
     'Math::NumSeq' => 23, # v.23 for characteristic(integer)
     # cf App::MathImage::Generator values_choices() preferences
     'Math::NumSeq::Squares'     => 25, # v.25 for BigInt pred()
     'Math::NumSeq::Pronic'      => 1,
     'Math::NumSeq::Triangular'  => 25, # v.25 for BigInt pred()
     'Math::NumSeq::Polygonal'   => 25, # v.25 for BigInt pred()
     'Math::NumSeq::Cubes'       => 1,
     'Math::NumSeq::Tetrahedral' => 38, # v.38 for value_to_i_estimate()
     'Math::NumSeq::StarNumbers' => 1,
     'Math::NumSeq::Powerful'    => 26, # new in v.26
     'Math::NumSeq::PowerPart'   => 28, # new in v.28
     'Math::NumSeq::PowerFlip'   => 45, # new in v.45

     'Math::NumSeq::Even'          => 1,
     'Math::NumSeq::Odd'           => 1,
     'Math::NumSeq::AllDigits'     => 25, # v.25 for BigInt ith()
     # 'Math::NumSeq::PrimesDigits'  => 43, # new in v.43
     'Math::NumSeq::ConcatNumbers' => 38, # v.38 for value_to_i_estimate()
     'Math::NumSeq::Runs'          => 34, # new in v.34

     'Math::NumSeq::Primes'              => 29, # v.29 value_to_i_estimate()
     'Math::NumSeq::TwinPrimes'          => 35, # v.35 value_to_i_estimate()
     'Math::NumSeq::SophieGermainPrimes' => 4,  # new in v.4
     'Math::NumSeq::AlmostPrimes'        => 14, # new in v.14
     'Math::NumSeq::DeletablePrimes'     => 37, # new in v.37
     'Math::NumSeq::Emirps'              => 4,  # new in v.4
     'Math::NumSeq::MobiusFunction'      => 6,  # new in v.6
     'Math::NumSeq::LiouvilleFunction'   => 52, # v.53 values_type
     'Math::NumSeq::GoldbachCount'       => 43, # v.43 faster on bigint
     'Math::NumSeq::LemoineCount'        => 43, # v.43 faster on bigint
     'Math::NumSeq::DivisorCount'        => 12, # new in v.12
     'Math::NumSeq::ErdosSelfridgeClass' => 38, # new in v.38
     'Math::NumSeq::PrimeIndexOrder'     => 39, # new in v.39
     'Math::NumSeq::PrimeIndexPrimes'    => 39, # new in v.39
     'Math::NumSeq::PythagoreanHypots'   => 29, # new in v.29
     'Math::NumSeq::Totient'             => 36, # v.36 bigger range
     'Math::NumSeq::TotientCumulative'   => 36, # v.36 bigger range
     'Math::NumSeq::TotientSteps'        => 36, # v.36 bigger range
     'Math::NumSeq::TotientPerfect'      => 36, # v.36 bigger range
     'Math::NumSeq::DedekindPsiCumulative' => 36, # new in v.36
     'Math::NumSeq::DedekindPsiSteps'      => 36, # new in v.36
     'Math::NumSeq::Abundant'              => 65, # v.64 pred() bug fix
     'Math::NumSeq::PolignacObstinate'     => 25, # new in v.25
     'Math::NumSeq::DuffinianNumbers'      => 47, # new in v.47

     'Math::NumSeq::PrimeFactorCount'    => 32, # v.32 prime_type choices
     'Math::NumSeq::AllPrimeFactors'     => 42, # new in v.42

     'Math::NumSeq::Factorials'        => 29, # v.29 i_estimate
     'Math::NumSeq::Catalan'           => 53, # new in v.53
     'Math::NumSeq::BalancedBinary'    => 53, # new in v.53
     'Math::NumSeq::Primorials'        => 29, # v.29 i_estimate
     'Math::NumSeq::Fibonacci'         => 38, # v.38 ith() by powering
     'Math::NumSeq::LucasNumbers'      => 29, # v.29 BigInt fix + i_estimate
     'Math::PlanePath::PisanoPeriod'      => 54, # new in v.54
     'Math::PlanePath::PisanoPeriodSteps' => 54, # new in v.54
     'Math::NumSeq::Fibbinary'         => 15, # v.15 faster next()
     'Math::NumSeq::FibbinaryBitCount' => 18, # new in v.18
     'Math::NumSeq::FibonacciWord'  => 36, # v.36 "dense" option
     'Math::NumSeq::Pell'           => 38, # v.38 BigInt and i_estimate()
     'Math::NumSeq::Tribonacci'     => 29, # v.29 value_to_i_estimate()
     'Math::NumSeq::Perrin'         => 29, # v.29 value_to_i_estimate()
     'Math::NumSeq::SpiroFibonacci' => 40, # new in v.40


     'Math::NumSeq::FractionDigits'      => 38, # v.38 ith()
     'Math::NumSeq::SqrtDigits'          => 1,
     'Math::NumSeq::SqrtContinued'       => 27, # new in v.27
     'Math::NumSeq::SqrtContinuedPeriod' => 24, # new in v.24
     'Math::NumSeq::AlgebraicContinued'  => 54, # new in v.54
     'Math::NumSeq::SqrtEngel'           => 1,

     'Math::NumSeq::DigitCount'            => 13, # v.13 fix values_max()
     'Math::NumSeq::DigitCountHigh'        => 16, # new in v.16
     'Math::NumSeq::DigitCountLow'         => 46, # v.46 digit parameter fix
     'Math::NumSeq::DigitLength'           => 1,
     'Math::NumSeq::DigitLengthCumulative' => 38, # v.38 value_to_i_estimate()
     'Math::NumSeq::SelfLengthCumulative'  => 38, # new in v.38
     'Math::NumSeq::RadixWithoutDigit'     => 1,
     'Math::NumSeq::RadixConversion'       => 50, # new in v.50
     'Math::NumSeq::MaxDigitCount'         => 42, # new in v.42

     'Math::NumSeq::DigitSum'              => 56, # v.56 bug fixes
     'Math::NumSeq::DigitSumModulo'        => 5,  # new in v.5
     'Math::NumSeq::DigitProduct'          => 2,  # new in v.2
     'Math::NumSeq::DigitProductSteps'     => 42, # new in v.42

     'Math::NumSeq::Beastly'           => 1,
     'Math::NumSeq::Repdigits'         => 41, # v.41 radix=2 fix, i_estimate
     'Math::NumSeq::RepdigitAny'       => 16, # new in v.16
     'Math::NumSeq::RepdigitRadix'     => 37, # v.37 charact(value_is_radix)
     'Math::NumSeq::Palindromes'       => 1,
     'Math::NumSeq::HarshadNumbers'    => 1,
     'Math::NumSeq::MoranNumbers'      => 38, # new in v.38
     'Math::NumSeq::HappyNumbers'      => 7,  # new in v.7
     'Math::NumSeq::HappySteps'        => 17,  # new in v.17
     'Math::NumSeq::UndulatingNumbers' => 34,  # new in v.34

     'Math::NumSeq::CollatzSteps'  => 1,
     'Math::NumSeq::JugglerSteps'  => 13, # new in v.13
     'Math::NumSeq::ReverseAdd'    => 30, # v.30 fix past bigint
     'Math::NumSeq::ReverseAddSteps' => 1, # new in what version ?

     'Math::NumSeq::CullenNumbers'  => 29, # v.29 BigInt and i_estimate
     'Math::NumSeq::ProthNumbers'   => 38, # v.38 next() BigInt
     'Math::NumSeq::WoodallNumbers' => 29, # v.29 BigInt and i_estimate
     'Math::NumSeq::BaumSweet'      => 10, # new in v.10
     'Math::NumSeq::GolayRudinShapiro' => 51, # v.51 values_type
     'Math::NumSeq::GolayRudinShapiroCumulative' => 38, # new in v.38
     'Math::NumSeq::HafermanCarpet' => 64, # new in v.64
     'Math::NumSeq::KlarnerRado'    => 11, # new in v.11
     'Math::NumSeq::UlamSequence'   => 29, # new in v.29
     'Math::NumSeq::AsciiSelf'      => 67, # v.67 fix characteristic smaller
     'Math::NumSeq::Kolakoski'      => 13, # new in v.13
     'Math::NumSeq::GolombSequence' => 43, # v.43 squares,primes in paraminfo
     'Math::NumSeq::ReRound'        => 38, # v.38 fix value_to_i_estimate()
     'Math::NumSeq::LuckyNumbers'   => 38, # new in v.38
     'Math::NumSeq::ReReplace'      => 33, # new in v.33
     'Math::NumSeq::MephistoWaltz'  => 14, # new in v.14

     'Math::NumSeq::SternDiatomic'    => 4,  # new in v.4
     'Math::NumSeq::NumAronson'       => 8,  # new in v.8
     'Math::NumSeq::HofstadterFigure' => 34, # new in v.34

     'Math::NumSeq::File'       => 1,
     'Math::NumSeq::OEIS'       => 35, # v.35 progressive reading
     'Math::NumSeq::Expression' => 20, # v.20 workaround Safe.pm

     # in Math-Aronson
     'Math::Aronson'         => 4, # version 4 for lying option
     'Math::NumSeq::Aronson' => 6, # new in v.6

     # in Math-PlanePath
     'Math::NumSeq::PlanePathCoord' => 106, # v.106 RootN
     'Math::NumSeq::PlanePathDelta' => 100, # v.100 dAbsDiff
     'Math::NumSeq::PlanePathTurn'  => 72, # v.72 turn_type "Right"
     'Math::NumSeq::PlanePathN'     => 94, # v.94 "Depth_start" in options

     # in Math-NumSeq-Alpha
     'Math::NumSeq::AlphabeticalLength'      => 1, # new in v.1
     'Math::NumSeq::AlphabeticalLengthSteps' => 1, # new in v.1
     'Math::NumSeq::SevenSegments'           => 2, # new in v.2
    );

my %prereq_pm
  = (
     %gtk2_interface,

     'Clone::PP' => 0,
     'constant'        => 1.02,  # 1.02 for various leading underscores
     'constant::defer' => 0,

     # File::Copy 2.11 of perl 5.10.0 gives warnings on File::Temp file
     # handles by outsmarting itself in some compares plus File::Temp having
     # a bogus numize.  File::Copy 2.14 looks slightly better, though
     # enquiring into the overloadedness of handles is a very bad idea.
     'File::Copy'      => '2.14',

     'File::HomeDir' => 0,
     'Geometry::AffineTransform' => '1.3', # version 1.3 for invert()

     'Image::Base' => '1.16', # version 1.16 for diamond()

     # my Image-Base-Other
     'Image::Base::Multiplex' => 7, # v.7 for diamond()
     'Image::Base::Text'      => 8, # v.8 for 0,0,width,height clipping

     # 'List::MoreUtils' => '0.24', # 0.24 for stack growing, maybe
     'List::Pairwise' => 0,
     'Locale::TextDomain' => '1.19',
     'Locale::Messages' => 0,
     'Module::Load' => 0,
     'Module::Util' => 0,
     'Number::Format' => 0,
     'Regexp::Common' => 0,
     'Scalar::Util' => '1.18', # v1.18 for pure-perl refaddr() fix
     'Scope::Guard' => 0,
     'Term::Size' => 0,

     'Math::Prime::XS' => '0.23', # version 0.23 for fix of 1928099

     'Math::BaseCnv' => 0,
     'Math::Libm' => 0,

     # my Math-PlanePath, and should work with any set of paths
     'Math::PlanePath'               => 83, # v.83 for n_to_dxdy()
     'Math::PlanePath::SquareSpiral' => 1, # for default display
     'Math::PlanePath::SacksSpiral'  => 0, # for --sacks option
     'Math::PlanePath::VogelFloret'  => 0, # for --vogel option
     'Math::PlanePath::Base::Generic' => 0,
     'Math::PlanePath::Base::Digits'  => 82,

     # my Math-NumSeq
     'Math::NumSeq'                  => 38, # v.38 for tell_i()
     'Math::NumSeq::All'             => 1, # for Lines base, for --all option
     'Math::NumSeq::Even'            => 1, # for --even option
     'Math::NumSeq::Odd'             => 1, # for --odd option
     'Math::NumSeq::Cubes'           => 1, # for --cubes option
     'Math::NumSeq::Pronic'          => 1, # for --pronic option
     'Math::NumSeq::Squares'         => 1, # for --squares option
     'Math::NumSeq::Primes'          => 1, # for default
     'Math::NumSeq::TwinPrimes'      => 1, # for --twin
     'Math::NumSeq::AlmostPrimes'    => 1, # for --semi-primes option
     'Math::NumSeq::Polygonal'       => 1, # for --polygonal option
     'Math::NumSeq::Triangular'      => 1, # for --triangular
     'Math::NumSeq::Perrin'          => 1, # for --perrin
     'Math::NumSeq::FractionDigits'  => 1, # for --fraction
     'Math::NumSeq::Tetrahedral'     => 1, # for --tetrahedral
     'Math::NumSeq::Expression'      => 1, # for --expression
     'Math::NumSeq::OEIS::Catalogue' => 1, # for OeisEntry widget
     'Math::NumSeq::Fibbinary'       => 1, # for Zeck status message
    );

#------------------------------------------------------------------------------

WriteMakefile
  (NAME         => 'math-image',
   ABSTRACT     => 'Draw some mathematical images.',
   VERSION_FROM => 'math-image',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   EXE_FILES    => [ 'math-image' ],
   MIN_PERL_VERSION => '5.008',
   PREREQ_PM    => \%prereq_pm,

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/math-image/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     recommends =>
     {
      %maximum_planepath,
      %maximum_numseq,
      %gtk2_optionals,
      %x11_interface,
      'Math::Symbolic' => '0.605', # 0.605 fixing a simplify
      'Math::Expression::Evaluator' => 0, # maybe any ok
      'Language::Expr' => '0.14',
      'Image::Xpm'     => 0,
      'Browser::Open' => 0,
     },
     optional_features =>
     {
      x11_interface =>
      { description => 'Things for native X through X11::Protocol.',
        requires => \%x11_interface,
      },
      gtk2_optionals =>
      { description => 'Gtk2 things used if available.',
        requires => \%gtk2_optionals,
      },

      gtk1_interface =>
      { description => 'Gtk 1.x GUI modules.',
        requires => \%gtk1_interface,
      },

      tk_interface =>
      { description => 'Tk GUI modules.',
        requires => \%tk_interface,
        recommends => \%tk_optionals,
      },

      wx_interface =>
      { description => 'Wx GUI modules.',
        requires => \%wx_interface,
        recommends => \%wx_optionals,
      },

      curses_interface =>
      { description => 'Experimental Curses interface.',
        requires => \%curses_interface,
      },

      maximum_planepath =>
      { description => 'Maximum PlanePath modules',
        requires => \%maximum_planepath,
      },
      maximum_numseq =>
      { description => 'Maximum NumSeq number sequence modules',
        requires => \%maximum_numseq,
      },
      maximum_interoperation =>
      { description => 'All the optional things Math-Image can use.',
        requires => {
                     %maximum_planepath,
                     %maximum_numseq,
                     %x11_interface,
                     %gtk2_optionals,
                     %tk_interface,
                     %tk_optionals,
                     %wx_interface,
                     %wx_optionals,
                     %gtk1_interface,

                     'Image::Xpm'             => 0,
                     'Image::Base::GD'        => 15, # v.15 clip fixes
                     'Image::Base::Imager'    => 0,
                     'Image::Base::Magick'    => 0,
                     # v.5 ellipse() $fill
                     # v.7 recommended for diamond()
                     'Image::Base::PNGwriter' => 7,
                     'Image::Base::SVG'       => 3, # v.3 diamond()
                     'Image::Base::SVGout'    => 7, # v.7 diamond()

                     'Math::Symbolic' => 0.605, # 0.605 fix a simplify()
                     'Math::Expression::Evaluator' => 0,
                     'Language::Expr' => '0.14',
                     'Browser::Open' => 0,

                     'Prima' => 0,
                     'Image::Base::Prima' => 1,
                    },
      },
      maximum_tests =>
      { description => 'Have "make test" do as much as possible.',
        prereqs =>
        { test => { 'Test::Weaken'            => 3.018, # 3.018 ignore_preds
                    'Test::Weaken::ExtraBits' => 1,
                    'Image::Xpm'              => 0,
                    'Image::Base::GD'         => 4, # bug fixes
                    'Image::Base::PNGwriter'  => 2, # bug fixes
                  },
        }
      },
     },

     # devel additions to the packages
     no_index => { package => [ 'Math::PlanePath',
                                'Math::PlanePath::CellularRule',
                              ],
                   directory=>['devel'],
                 }
   },
  );
