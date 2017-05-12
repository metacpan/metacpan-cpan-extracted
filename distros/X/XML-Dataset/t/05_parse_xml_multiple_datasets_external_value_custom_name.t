#!perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'XML::Dataset' );

# Create example data
my $example_data = qq(<?xml version="1.0"?>
<catalog>
   <lowest number="123">
      <book id="bk101">
         <author>Gambardella, Matthew</author>
         <title>XML Developer's Guide</title>
         <genre>Computer</genre>
         <price>44.95</price>
         <publish_date>2000-10-01</publish_date>
         <description>An in-depth look at creating applications 
         with XML.</description>
      </book>
      <book id="bk102">
         <author>Ralls, Kim</author>
         <title>Midnight Rain</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2000-12-16</publish_date>
         <description>A former architect battles corporate zombies, 
         an evil sorceress, and her own childhood to become queen 
         of the world.</description>
      </book>
      <book id="bk103">
         <author>Corets, Eva</author>
         <title>Maeve Ascendant</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2000-11-17</publish_date>
         <description>After the collapse of a nanotechnology 
         society in England, the young survivors lay the 
         foundation for a new society.</description>
      </book>
      <book id="bk104">
         <author>Corets, Eva</author>
         <title>Oberon's Legacy</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2001-03-10</publish_date>
         <description>In post-apocalypse England, the mysterious 
         agent known only as Oberon helps to create a new life 
         for the inhabitants of London. Sequel to Maeve 
         Ascendant.</description>
      </book>
      <book id="bk105">
         <author>Corets, Eva</author>
         <title>The Sundered Grail</title>
         <genre>Fantasy</genre>
         <price>5.95</price>
         <publish_date>2001-09-10</publish_date>
         <description>The two daughters of Maeve, half-sisters, 
         battle one another for control of England. Sequel to 
         Oberon's Legacy.</description>
      </book>
      <book id="bk106">
         <author>Randall, Cynthia</author>
         <title>Lover Birds</title>
         <genre>Romance</genre>
         <price>4.95</price>
         <publish_date>2000-09-02</publish_date>
         <description>When Carla meets Paul at an ornithology 
         conference, tempers fly as feathers get ruffled.</description>
      </book>
      <book id="bk107">
         <author>Thurman, Paula</author>
         <title>Splish Splash</title>
         <genre>Romance</genre>
         <price>4.95</price>
         <publish_date>2000-11-02</publish_date>
         <description>A deep sea diver finds true love twenty 
         thousand leagues beneath the sea.</description>
      </book>
      <book id="bk108">
         <author>Knorr, Stefan</author>
         <title>Creepy Crawlies</title>
         <genre>Horror</genre>
         <price>4.95</price>
         <publish_date>2000-12-06</publish_date>
         <description>An anthology of horror stories about roaches,
         centipedes, scorpions  and other insects.</description>
      </book>
      <book id="bk109">
         <author>Kress, Peter</author>
         <title>Paradox Lost</title>
         <genre>Science Fiction</genre>
         <price>6.95</price>
         <publish_date>2000-11-02</publish_date>
         <description>After an inadvertant trip through a Heisenberg
         Uncertainty Device, James Salway discovers the problems 
         of being quantum.</description>
      </book>
      <book id="bk110">
         <author>O'Brien, Tim</author>
         <title>Microsoft .NET: The Programming Bible</title>
         <genre>Computer</genre>
         <price>36.95</price>
         <publish_date>2000-12-09</publish_date>
         <description>Microsoft's .NET initiative is explored in 
         detail in this deep programmer's reference.</description>
      </book>
      <book id="bk111">
         <author>O'Brien, Tim</author>
         <title>MSXML3: A Comprehensive Guide</title>
         <genre>Computer</genre>
         <price>36.95</price>
         <publish_date>2000-12-01</publish_date>
         <description>The Microsoft MSXML3 parser is covered in 
         detail, with attention to XML DOM interfaces, XSLT processing, 
         SAX and more.</description>
      </book>
      <book id="bk112">
         <author>Galos, Mike</author>
         <title>Visual Studio 7: A Comprehensive Guide</title>
         <genre>Computer</genre>
         <price>49.95</price>
         <publish_date>2001-04-16</publish_date>
         <description>Microsoft Visual Studio 7 is explored in depth,
         looking at how Visual Basic, Visual C++, C#, and ASP+ are 
         integrated into a comprehensive development 
         environment.</description>
      </book>
   </lowest>
</catalog>
);

# Create example profile
my $profile = qq(
   catalog
      lowest
         number = external_dataset:__external_value__1
         book
           id     = dataset:1
           author = dataset:1 dataset:2
           title  = dataset:1 dataset:2
           genre  = dataset:1
           price  = dataset:1 dataset:2
           publish_date = dataset:1
           description  = dataset:1
           __EXTERNAL_VALUE__ = __external_value__1:number:1:numberx __external_value__1:number:2:numbery
);

my $desired_output = {
   '1' => [
      {
         'numberx'     => '123',
         'author'      => 'Gambardella, Matthew',
         'description' => 'An in-depth look at creating applications 
         with XML.',
         'genre'        => 'Computer',
         'publish_date' => '2000-10-01',
         'id'           => 'bk101',
         'title'        => 'XML Developer\'s Guide',
         'price'        => '44.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Ralls, Kim',
         'description' => 'A former architect battles corporate zombies, 
         an evil sorceress, and her own childhood to become queen 
         of the world.',
         'genre'        => 'Fantasy',
         'publish_date' => '2000-12-16',
         'id'           => 'bk102',
         'title'        => 'Midnight Rain',
         'price'        => '5.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Corets, Eva',
         'description' => 'After the collapse of a nanotechnology 
         society in England, the young survivors lay the 
         foundation for a new society.',
         'genre'        => 'Fantasy',
         'publish_date' => '2000-11-17',
         'id'           => 'bk103',
         'title'        => 'Maeve Ascendant',
         'price'        => '5.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Corets, Eva',
         'description' => 'In post-apocalypse England, the mysterious 
         agent known only as Oberon helps to create a new life 
         for the inhabitants of London. Sequel to Maeve 
         Ascendant.',
         'genre'        => 'Fantasy',
         'publish_date' => '2001-03-10',
         'id'           => 'bk104',
         'title'        => 'Oberon\'s Legacy',
         'price'        => '5.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Corets, Eva',
         'description' => 'The two daughters of Maeve, half-sisters, 
         battle one another for control of England. Sequel to 
         Oberon\'s Legacy.',
         'genre'        => 'Fantasy',
         'publish_date' => '2001-09-10',
         'id'           => 'bk105',
         'title'        => 'The Sundered Grail',
         'price'        => '5.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Randall, Cynthia',
         'description' => 'When Carla meets Paul at an ornithology 
         conference, tempers fly as feathers get ruffled.',
         'genre'        => 'Romance',
         'publish_date' => '2000-09-02',
         'id'           => 'bk106',
         'title'        => 'Lover Birds',
         'price'        => '4.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Thurman, Paula',
         'description' => 'A deep sea diver finds true love twenty 
         thousand leagues beneath the sea.',
         'genre'        => 'Romance',
         'publish_date' => '2000-11-02',
         'id'           => 'bk107',
         'title'        => 'Splish Splash',
         'price'        => '4.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Knorr, Stefan',
         'description' => 'An anthology of horror stories about roaches,
         centipedes, scorpions  and other insects.',
         'genre'        => 'Horror',
         'publish_date' => '2000-12-06',
         'id'           => 'bk108',
         'title'        => 'Creepy Crawlies',
         'price'        => '4.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Kress, Peter',
         'description' => 'After an inadvertant trip through a Heisenberg
         Uncertainty Device, James Salway discovers the problems 
         of being quantum.',
         'genre'        => 'Science Fiction',
         'publish_date' => '2000-11-02',
         'id'           => 'bk109',
         'title'        => 'Paradox Lost',
         'price'        => '6.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'O\'Brien, Tim',
         'description' => 'Microsoft\'s .NET initiative is explored in 
         detail in this deep programmer\'s reference.',
         'genre'        => 'Computer',
         'publish_date' => '2000-12-09',
         'id'           => 'bk110',
         'title'        => 'Microsoft .NET: The Programming Bible',
         'price'        => '36.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'O\'Brien, Tim',
         'description' => 'The Microsoft MSXML3 parser is covered in 
         detail, with attention to XML DOM interfaces, XSLT processing, 
         SAX and more.',
         'genre'        => 'Computer',
         'publish_date' => '2000-12-01',
         'id'           => 'bk111',
         'title'        => 'MSXML3: A Comprehensive Guide',
         'price'        => '36.95'
      },
      {
         'numberx'     => '123',
         'author'      => 'Galos, Mike',
         'description' => 'Microsoft Visual Studio 7 is explored in depth,
         looking at how Visual Basic, Visual C++, C#, and ASP+ are 
         integrated into a comprehensive development 
         environment.',
         'genre'        => 'Computer',
         'publish_date' => '2001-04-16',
         'id'           => 'bk112',
         'title'        => 'Visual Studio 7: A Comprehensive Guide',
         'price'        => '49.95'
      }
   ],
   '2' => [
      {
         'numbery' => '123',
         'price'   => '44.95',
         'title'   => 'XML Developer\'s Guide',
         'author'  => 'Gambardella, Matthew'
      },
      {
         'numbery' => '123',
         'price'   => '5.95',
         'title'   => 'Midnight Rain',
         'author'  => 'Ralls, Kim'
      },
      {
         'numbery' => '123',
         'price'   => '5.95',
         'title'   => 'Maeve Ascendant',
         'author'  => 'Corets, Eva'
      },
      {
         'numbery' => '123',
         'price'   => '5.95',
         'title'   => 'Oberon\'s Legacy',
         'author'  => 'Corets, Eva'
      },
      {
         'numbery' => '123',
         'price'   => '5.95',
         'title'   => 'The Sundered Grail',
         'author'  => 'Corets, Eva'
      },
      {
         'numbery' => '123',
         'price'   => '4.95',
         'title'   => 'Lover Birds',
         'author'  => 'Randall, Cynthia'
      },
      {
         'numbery' => '123',
         'price'   => '4.95',
         'title'   => 'Splish Splash',
         'author'  => 'Thurman, Paula'
      },
      {
         'numbery' => '123',
         'price'   => '4.95',
         'title'   => 'Creepy Crawlies',
         'author'  => 'Knorr, Stefan'
      },
      {
         'numbery' => '123',
         'price'   => '6.95',
         'title'   => 'Paradox Lost',
         'author'  => 'Kress, Peter'
      },
      {
         'numbery' => '123',
         'price'   => '36.95',
         'title'   => 'Microsoft .NET: The Programming Bible',
         'author'  => 'O\'Brien, Tim'
      },
      {
         'numbery' => '123',
         'price'   => '36.95',
         'title'   => 'MSXML3: A Comprehensive Guide',
         'author'  => 'O\'Brien, Tim'
      },
      {
         'numbery' => '123',
         'price'   => '49.95',
         'title'   => 'Visual Studio 7: A Comprehensive Guide',
         'author'  => 'Galos, Mike'
      }
   ]
};

my $output = parse_using_profile( $example_data, $profile );
is_deeply( $output, $desired_output, 'output matches desired output' );
