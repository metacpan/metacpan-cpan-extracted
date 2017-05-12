<?php
/**
 Plugin Name: colliertech.org's Wall Flower
 Plugin URI: http://wp.colliertech.org/downloads/wallflower.zip
 Description: colliertech.org's Wall Flower mostly holds the wall up at dances.
 Author: C.J. Adams-Collier <cjac@colliertech.org>
 Author URI: http://wp.colliertech.org/cj/
 Version: 0.0.3
 cpe URN: cpe:/a:colliertech.org:wallflower:0.0.3
 License: Perl
 */

include_once('license.php');

$include_paths = array(
        get_include_path(),
        dirname(__FILE__),
        dirname(__FILE__) . '/blib'
);
set_include_path(implode(PATH_SEPARATOR, $include_paths));

function wallflower_autoloader($class) {
        $filename = 'WordPress/Plugin/' . str_replace('_', '/', $class) . '.php';
        @include $filename;
}

spl_autoload_register('wallflower_autoloader');

?>
