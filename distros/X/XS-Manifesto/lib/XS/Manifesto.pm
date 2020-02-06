package XS::Manifesto;

our $VERSION = '1.0.0';

=head1 NAME

XS::Manifesto - Shared XS modules manifesto

=cut

=head1 THE CURRENT STATE

Out of the box Perl offers tools to create XS-modules, i.e. to write code in
C/C++ language for it to be both fast and be available from Perl via tools
like L<ExtUtils::MakeMaker>.

This approach works well, however it has B<limited extensibility>. First, it's
hard to call C/XS-code from other C/XS-code; while it I<can> be done, it's 
possible only via a I<Perl layer> which has a huge performance penalty compared
to a direct C/C++ function call. Type safety is also lost, which is quite
important for early compile-time error detection with C/C++. Second, there is 
no way to share I<source code>, e.g. header files and 
native-type-to-Perl-type mappings (aka I<typemaps>). Without that information, 
C/C++ types and templates from one module cannot be reused in another C/C++
module.

There is an alternative approach on CPAN - L<Alien>, which tries to make 
non-Perl libraries available for Perl. The approach I<reuses> system libraries
or downloads and builds them. It successfully solves I<sharing native code>
issue, i.e. C/C++ headers, but not sharing XS-code. One could argue that it's
Perl own fault that it ships no mechanism to share typemaps. Maybe it's even
not possible to implement this at all with pure C-layer. 

The L<Alien>-specific issue is that it doesn't aim for 
B<sharing binary (executable) code> (see 
L<Alien CAVEATS| https://metacpan.org/pod/Alien#When-building-from-source-code,-build-static-libraries-whenever-possible> ). 
While this approach has benefits, like the requirement of an Alien-library to
be a build-only (compile-only) dependency, the ease of module upgrades (without
rebuilding dependencies), etc., it has it's own limitations:

First, the non-sharing of library code means duplication of it in a processes'
memory. Let's say, there is an C<Alien::libX> and XS-libraries C<My::libA>
and C<My::libB>, which both use C-interface of C<libX>. Statically compiled 
C<Alien::libX> will be duplicated in the both of XS-libraries. While memory is
considered to be cheap nowadays, it can still be an issue.

Second, as both XS-libraries C<My::libA> and C<My::libB> use C<Alien::libX>
independently, they can upgrade C<Alien::libX> independently. While it's a
benefit in some circumstances, in can lead to them loosing binary compatibility
between themselves, i.e. data structures created via C<My::libA::libX> might
be not allowed to be transferred to C<My::libB::libX>. In other words, it's
only possible to have final XS-modules without binary inter-dependencies.


Third, as there is no support for XS-modules from L<Alien>, it makes it
impossible to have cross-dependent binary B<hierarchy> of XS-modules, like:


              +---------------------------------+
              |                                 |
              v                                 |
    alien::libX  <-- xs::libA <-- xs::libB <-- xs::libC <-- xs::libD
                         ^                                      |
                         |                                      |
                         +--------------------------------------+

as the modules are statically compiled, there is no runtime dependency between
C<xs::libA> (C<libA.a>) and C<xs::libB> (C<libB.a>); the C<libB.a> just embeds
(copies) C<libA.a> directly into own code. The object code copying propagates
through all further dependecies, upto C<xs::libD>. The opposite approach is 
to have shared libraries, without any duplication.


=head1 THE INTUITION

It should be possible to have B<fast> applications in Perl. It should be
possible to have low-level components (like parsers, event loops, protocol
handlers, etc.) written in C/C++, while being able to access as much as
possible of their functions from Perl. The middleware components (like
application servers, session managers, etc.) can be written in Perl or in
C/C++ for performance-critical parts. The higher level application logic
is suitable mostly for Perl, with the exception of very limited 
performance-critical parts.

There is an exception from the last rule: if the application models/code
B<have to be shared> with non-Perl applications (e.g. in game-application
with L<Unity|https://unity.com/> or L<Unreal|https://www.unrealengine.com>
engines), it obviously should be written in C/C++. But they still should
be accessible from Perl servers.

I<Summa summarum> any part of an application can be written in Perl and/or
in C/C++, the transition should be transparent. And as it's much faster to
create code in Perl, it's most likely that during the early stages of the
developement Perl code dominates, while later, as an application grows and
performance becomes an issue, parts of it are replaced with XS modules written
in C/C++. This make it possible to have a gradual evolution instead of radical
solutions like "let's rewrite everything in Go!".


=head1 THE PRINCIPLES

=over 2

=item 1. B<Share binary code>

It's like L<Alien> modules build with system modules or with shared libraries
support. 

Provided by L<XS::Install>.

=item 2. B<Application Binary Interface (ABI) runtime version check>

If C<XS::libraryX> had been compiled with the C<XS::libraryY v1.0> dependency,
but when loaded it finds out that the actual version of C<XS::libraryY> is
different (e.g. C<v1.1>), it by default refuses to load and asks for 
recompilation with the actual dependency verison C<XS::libraryY v1.1>.

Provided by L<XS::Install>.

=item 3. B<No ABI backward compatibility>

Perl itself does not guarantees ABI-compatibility between major releases.
Maintaining ABI-compatibility has it's own costs, as well as possible
performance penalty, e.g. instead of a direct access of a public property
of a C-structure it now must be accessed via a function, preventing inlines
from a C/C++ compiler. 

Usually C++ libraries do not maintain ABI-compatibility, so let it be. As the
drawback/consequence, if a base C<libraryX> is upgraded, all other modules
which depend on it should be recompiled. We exchange here build time for the
runtime performance.

=item 4. B<Sharing C++ XS-code>

There has been several attempts to share typemaps, i.e. make it possible to
reuse in C<xs::libraryX> conversion rules between C and Perl layers already
defined in C<xs::libraryY>. Unfortunately all attempts are unsatisfying, mostly
because there are no tools nor language support in C<C> for that.

However with modern C<C++> the situation is a bit different, as the powerful
template mechanism is provided by C<C++>. It can be used to share
I<C++ typemaps>. It is even possible to share C<C>-typemaps this way as long
as they are compile-time compatible with C<C++>.

Provided by L<XS::Framework>.

=item 5. B<Dual interface: C/C++ and Perl>

Every XS-module should have Perl interface to make it possible to use it as
self-contained module from Perl. It should also have a C/C++ interface to make
it possible to use it from other XS-module from theirs C/C++ code, i.e. embed
as a type or use in inheritance. 

C<C++ typemap> should also be provided for easy using of the module. It is
considered as a part of C/C++ interface of a XS-module.

=back


=head1 EXAMPLE

There is a module L<Date>, which provides methods for serialization and parsing
dates in various formats. It is very fast, and when C<Date.pm> is loaded it
loads it's C++ XS backend as C<Date.so> (or C<Date.dll> on Windows). 
It depends on L<XS::Framework>, so C<Framework.so> is also loaded and it's C++
functions are used directly from C<Date.so>.

There is a module L<URI::XS> (say C<uri.so>), which parses/serializes URIs. 
It also depends on L<XS::Framework>.

Now there is a module C<Protocol::HTTP>. When its C<http.so> is loaded, it
also loads C<Framework.so>, C<uri.so> and C<Date.so>. So when date or URIs are
parsed/serialized from Perl code using C<Protocol::HTTP>, it directly invokes
code from C<uri.so> or C<Date.so>, without routing via Perl (which isn't fast). 

When URI/Date objects are returned to Perl layer from the C<Protocol::HTTP> XS
API, they're exactly the same C++ objects (i.e. no any additional memory
allocations for C++ objects) just wrapped into Perl SV (scalars) and it's
possible to simply use them in Perl APIs of the corresponding modules
(L<URI::XS> or L<Date>), which exists completely outside of C<Protocol::HTTP>
space.

L<XS::Install> (tooling support) and L<XS::Framework> (XS/C++ support) makes
it possible to do that sharing in easy way.

=head1 SEE ALSO

L<Alien>

L<ExtUtils::MakeMaker>

L<XS::Install>

L<XS::Framework>

=head1 AUTHORS

Pronin Oleg (SYBER) <syber@crazypanda.ru>, Crazy Panda LTD

Sergey Aleynikov (RANDIR) <sergey.aleynikov@gmail.com>, Crazy Panda LTD

Ivan Baidakou (DMOL) <i.baydakov@crazypanda.ru>, Crazy Panda LTD

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut


1;