If you want to install the lanman module or if you want to build it from the scratch,
you should read these notes.


Installation:

Unzip the lanman.1.0.10.0.zip file to a folder. Make this folder your current directory.
In contrast to the installation procedure for the module version 1.08, you don't need to
distinguish between perl 5.6 (or later) and perl 5.005. The Win32-lanman.ppd file does 
this job for you (thanks for the hint to Jenda Krynicky). Type in 

	ppm install --location=. win32-lanman

if you use perl 5.6 or perl 5.005 (type in perl -v to verify your perl version). To verify 
the installation, type in ppm query. The lanman module should appear in the list. Perl 5.8
comes with the new ppm version 3. It does not support the --location parameter. But you can
use ppm2 instead. Type in 

	ppm2 install --location=. win32-lanman

Perl 5.003 is not longer supported. If you need to run the module with Perl 5.003, you can
use the older version 1.0.9.2. 

The html help file will be installed only if you use the ppm. You can find the lanman.html
file in the <perldir>\html\lib\site\lanman directory.



Build the module:

You need an installed MSVC++ compiler. I work with MSVC++ version 6 but version 5 should work 
too. Please use the MSVC's Sp3 (Dlls's compiled with Sp4 or Sp5 seems not to work with perl 
5.005; Sp4 or Sp5 don't have a problem with Perl 5.6 or later). Next, you need the platform 
sdk. It contains some header files and libraries necessary to build the module. Furthermore, 
you need the perl source files (in particular, only header files are necessary). These include 
header files should be accessible in the <perldir>\lib\core directory. 

Set up the compiler environment with vcvars32.bat. Unzip the lanman.1.0.10.0.zip file to an empty 
folder. Make this folder to your current directory and load the Makefile in your editor.

Change the following settings to your directory names:

	perldir8xx="c:\perl.8xx"	- directory where perl 5.8 resides
	perldir6xx="c:\perl.6xx"	- directory where perl 5.6 resides
	perldir5xx="c:\perl.5xx"	- directory where perl 5.005_3 resides

If you only want to build for perl 5.8, you can leave perldir6xx and perldir5xx as they are.

	platformsdk=c:\program files\microsoft sdk

must reflect you platform sdk directory. Now you can start the build process. Type in

	nmake clean 
	nmake

or

	nmake clean cfg=perl.8xx
	nmake cfg=perl.8xx


to build the module for perl 5.8. If you use perl 5.6 type in

	nmake clean cfg=perl.6xx
	nmake cfg=perl.6xx

or 

	nmake clean cfg=perl.5xx
	nmake cfg=perl.5xx

for perl 5.005_03. If the build was successfully, you'll find the files in the .\inst_dir\perl.xxx
directory. To install the module, use

	nmake install

or
	nmake install cfg=perl.8xx

respectively

	nmake install cfg=perl.6xx

or

	nmake install cfg=perl.5xx


Still one hint: don't build on a w2k machine. Use nt4 instead. If you build on w2k, the module 
runs only on w2k machines and not on nt.

Have a lot of fun. Jens.
