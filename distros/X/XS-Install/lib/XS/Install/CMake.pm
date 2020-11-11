package
    XS::Install::CMake;
use strict;
use warnings;
use Env qw/@PATH/;

sub configure {
    my $result = run(@_);
    return import_cmake_properites($result);
}

sub run {
    my ($bdir, $props_dir, $target, $options) = @_;
    my $ok = eval { require Alien::cmake3; 1 };
    die "This module requires Alien::cmake3 to build.\n" unless $ok;

    unshift @PATH, Alien::cmake3->bin_dir;
    open(CMAKELISTS, '>', "$props_dir/CMakeLists.txt") or die $!;

    print CMAKELISTS <<'EOS';
cmake_minimum_required(VERSION 3.5)
project(GetProps)

macro(find_package)
    set(find_package_ARGS ${ARGV})
    list(REMOVE_ITEM find_package_ARGS "REQUIRED")
    list(APPEND find_package_ARGS "QUIET")
    _find_package(${find_package_ARGS})
endmacro()

function(is_good_lib_item ret name)
    set(${ret} FALSE PARENT_SCOPE)
    if(${name} MATCHES "debug|optimized|general|PRIVATE|PUBLIC|INTERFACE" OR ${name} MATCHES "^-.*" OR TARGET ${name})
        set(${ret} TRUE PARENT_SCOPE)
    endif()
    find_library(${name}_is_good ${name})
    if(${name}_is_good)
        set(${ret} TRUE PARENT_SCOPE)
    endif()
endfunction()


macro(target_link_libraries)
    set(TARGET_LINK_LIBS_ARGS ${ARGV})
    list(REMOVE_AT TARGET_LINK_LIBS_ARGS 0)

    foreach(ARG ${TARGET_LINK_LIBS_ARGS})
        is_good_lib_item(is_good ${ARG})
        message(STATUS "checking " ${ARG}  " -> " ${is_good})
        if(${is_good})
            list(APPEND TARGET_LINK_LIBS_OK ${ARG})
        endif()
    endforeach()

    if (TARGET_LINK_LIBS_OK)
        message(STATUS "linking:" ${ARGV0} ${TARGET_LINK_LIBS_OK})
        _target_link_libraries(${ARGV0} ${TARGET_LINK_LIBS_OK})
    endif()
endmacro()

macro(add_library)
    set(args ${ARGV})
    list(FIND args IMPORTED index)
    if (index GREATER_EQUAL 0)
        MATH(EXPR index "${index}+1")
        list (INSERT args ${index} GLOBAL)
    endif()
    message(STATUS "add_library: ${args}")
    _add_library(${args})
endmacro()

add_subdirectory(".." "../build")

function(get_all_libs_locations ret tgt)
    set(self_loc "")
    get_target_property(lret ${tgt} TYPE)
    if (NOT ${lret} STREQUAL INTERFACE_LIBRARY)
        get_target_property(lret ${tgt} IMPORTED_LOCATION)
        message(STATUS "got:" ${lret} "for" ${tgt})
        if (lret)
            set(self_loc ${lret})
        endif()
    endif()
    get_target_property(deps ${tgt} INTERFACE_LINK_LIBRARIES)
    message(STATUS "deps:" ${deps} "for" ${tgt})
    foreach(lib ${deps})
        if (TARGET ${lib})
            get_all_libs_locations(lret ${lib})
            list(APPEND self_loc ${lret})
        endif()
    endforeach()
    set(${ret} ${self_loc} PARENT_SCOPE)
endfunction()

foreach(PROP ${REQUESTED_PROPS})
get_target_property(GOT_RES ${REQUESTED_TARGET} ${PROP})
    if (GOT_RES)
        message(STATUS "GOT_${PROP}=" "${GOT_RES}")
    else (GOT_RES)
        message(STATUS "GOT_${PROP}=")
    endif (GOT_RES)
endforeach()

get_target_property(libs ${REQUESTED_TARGET} INTERFACE_LINK_LIBRARIES)
if(libs)
    foreach(lib ${libs})
        if (NOT TARGET ${lib})
            list(APPEND lib_result ${lib})
        endif()
    endforeach()
    message(STATUS "GOT_FILTERED_LINK_LIBRARIES=" "${lib_result}")
endif()

foreach(TARG ${CONF_TARGETS})
    separate_arguments(OPT UNIX_COMMAND ${${TARG}_COMP_OPTIONS})
    target_compile_options(${TARG} PRIVATE ${OPT})
endforeach()

get_all_libs_locations(locs ${REQUESTED_TARGET})
message(STATUS "GOT_LOCATIONS=" "${locs}")

EOS

    close(CMAKELISTS);

    my @properties = qw(INTERFACE_COMPILE_DEFINITIONS INTERFACE_COMPILE_OPTIONS INTERFACE_INCLUDE_DIRECTORIES INTERFACE_LINK_DIRECTORIES INTERFACE_LINK_LIBRARIES INTERFACE_LINK_OPTIONS OUTPUT_NAME NAME IMPORT_PREFIX IMPORT_SUFFIX LINK_LIBRARIES LINK_OPTIONS LINK_FLAGS IMPORTED_LOCATION);
    my $prop_list = join ';', @properties;


    return `cd $props_dir && cmake . -G "Unix Makefiles" $options -DREQUESTED_TARGET=$target -DREQUESTED_PROPS="$prop_list"`;
}

sub import_cmake_properites {
    my $source = shift;
    my $result = {
        INCLUDE => _get_prop($source, 'INTERFACE_INCLUDE_DIRECTORIES', 'BUILD_INTERFACE'),
    };

    my $libs = _get_prop($source, 'FILTERED_LINK_LIBRARIES');
    my $link_opts = _get_prop($source, 'INTERFACE_LINK_OPTIONS');
    my $locations = _get_prop($source, 'LOCATIONS');

    push ( @$link_opts, map({"-l$_"} @$libs), map {_split_lib($_)} @$locations );
    @$link_opts = grep /^-.*/, @$link_opts;
    $result->{"LIBS"} = $link_opts;

    $result->{"DEFINE"} = [map {"-D$_"} @{_get_prop($source, 'INTERFACE_COMPILE_DEFINITIONS')}];
    $result->{"CCFLAGS"} = _get_prop($source, 'IMPORT_COMPILE_OPTIONS');

    return $result;
}

sub _get_raw_prop {
    my ($source, $prop_name) = @_;
    my @result = ($source =~ /(?<=GOT_$prop_name=)(.+?)$/gm);
    return \@result;
}

sub _split_lib {
    my $arg = shift;
    if ($arg =~ /(.*)\/?lib(.*)\..*/) {
        return "-L$1 -l$2"
    } else {
        return $arg;
    }
}

sub _split_cmake_generator {
    my $str = shift;
    return ;
}

sub _transform_cmake_generator {
    my ($vals, $generator_key) = @_;
    my @result;
    for my $str (@$vals) {
        my @splited = ($str =~ /(?:\$<.*?>)|(?:[^\$;]+)/g);
        for my $val (@splited) {
            if ($val =~ /\$<$generator_key:(.*)>/g) {
                push @result, split(/;/, $1);
                next;
            }
            if ($val =~ /\$/g) { #other generate expression
                next;
            }
            push @result, $val; #pure value without generators
        }
    }
    return \@result;
}

sub _get_prop {
    my ($source, $prop_name, $generator_key) = @_;
    my $res = _get_raw_prop($source, $prop_name);
    if ($generator_key) {
        return _transform_cmake_generator($res,$generator_key);
    } else {
        return [map{split(";", $_)} @$res];
    }
}

1;

