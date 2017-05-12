# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use Test::More tests => 9;
use SDL;
use UAV::Pilot::SDL::Window::Mock;
use UAV::Pilot::SDL::WindowEventHandler;


package MockWindowEventHandler;
use Moose;

with 'UAV::Pilot::SDL::WindowEventHandler';


sub draw {}


package main;

my $window = UAV::Pilot::SDL::Window::Mock->new;
isa_ok( $window => 'UAV::Pilot::SDL::Window' );
cmp_ok( $window->width,  '==', 0, "No width set on base window" );
cmp_ok( $window->height, '==', 0, "No height set on base window" );


my $child1 = MockWindowEventHandler->new({
    width  => 1,
    height => 1,
});
$child1->add_to_window( $window );
cmp_ok( $window->width,  '==', 1, "Width set for first child" );
cmp_ok( $window->height, '==', 1, "Height set for first child" );

my $child2 = MockWindowEventHandler->new({
    width  => 2,
    height => 2,
});
$child2->add_to_window( $window, $window->TOP );
cmp_ok( $window->width,  '==', 2, "Width set for second child on top" );
cmp_ok( $window->height, '==', 3, "Height set for second child child on top" );

my $child3 = MockWindowEventHandler->new({
    width  => 3,
    height => 3,
});
$child3->add_to_window( $window, $window->BOTTOM );
cmp_ok( $window->width,  '==', 3, "Width set for third child on top" );
cmp_ok( $window->height, '==', 6, "Height set for third child on top" );
