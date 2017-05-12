use strict;
use Module::Build;

my $filename = "t/SKIPXPATH";
eval { require XML::XPath; };
if ($@) {
    open( F, ">$filename" ) or die "Can't create $filename";
    close F;
    print <<EOT
    
XML::XPath is not installed. This means that you will not be able to 
access the full functionality of this module. However should you install
XML::XPath at a later date this functionality will become available

EOT
            
} else {
    unlink $filename;
}

$filename = "t/SKIPWITHOUT";
eval { require Test::Without::Module; };
if ($@) {
    open( F, ">$filename" ) or die "Can't create $filename";
    close F;
} else {
    unlink $filename;
}

$filename = "t/SKIPWARN";
eval { require Test::Warn; };
if ($@) {
    open( F, ">$filename" ) or die "Can't create $filename";
    close F;
} else {
    unlink $filename;
}

Module::Build
    ->new(
        module_name =>  "WebService::Validator::HTML::W3C",
        license     =>  'perl',
        requires    =>  {
                            'Class::Accessor'   =>  0,
                            'LWP' =>  '0',
                        },
        build_requires  =>  {
                                'Test::More'    =>  0,
                            },
         )
    ->create_build_script;
