#    WebService::Pixabay - A Perl 5 interface to Pixabay API.
#    Copyright (C) 2017  faraco
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

use Test::More;
use lib 'lib';

use_ok('Moo');
use_ok('Function::Parameters');
use_ok('WebService::Pixabay');
use_ok('LWP::Online', 'online');
use_ok('WebService::Client');
use_ok('Data::Dumper', 'Dumper');

my $true  = 1;
my $false = 0;

# change $AUTHOR TESTING value from $false to $true if you want to do advanced test.
my $AUTHOR_TESTING = $false;

SKIP:
{
    skip "installation testing", 1 unless $AUTHOR_TESTING == $true;

    ok(
        my $pix =
            WebService::Pixabay->new(
                                     api_key => $ENV{PIXABAY_KEY}
                                    )
      );

SKIP:
    {
        skip "No internet connection", 1 unless online();

        ok(my $img1 = $pix->image_search, " image_search method working fine");
        ok(my $vid1 = $pix->video_search, "video_search method working fine");

        cmp_ok($pix->video_search(q => 'fire')->{total},
               '>=', 0,
               "custom video_search method total key is bigger than 0");

        cmp_ok($pix->image_search(q => 'water')->{total},
               '>=', 0,
               "custom image_search method total key is bigger than 0");
    }
}

done_testing;
