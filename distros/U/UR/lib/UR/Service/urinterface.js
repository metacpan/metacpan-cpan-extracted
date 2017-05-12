// Here's the basic API:
// var UR = new URInterface('http://server/api_root');
// var gsc_pse = UR.get_class('GSC::PSE');
// var pse_obj = gsc_pse.get(10001);

function construct_xmlhttp() {
    var xmlhttp = null;
    if (window.XMLHttpRequest) {
        xmlhttp = new XMLHttpRequest();
        if ( typeof xmlhttp.overrideMimeType != 'undefined') {
            xmlhttp.overrideMimeType('text/xml');
        }
     } else if (window.ActiveXObject) {
        xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
     } else {
        alert('Perhaps your browser does not support xmlhttprequests?');
     }

     return xmlhttp;
}

// a URInterface holds the info to connect to the server
function URInterface(base_url) {
    this.base_url = base_url;

    this.get_class = function(class_name) {
        return new URClassInterface(this.base_url, class_name);
    }

    this.commit = function() {
        var url = this.base_url + '/class/UR/Context';
        do_rpc(url, 'commit', []);
    }
}


function do_rpc(url, method,arglist) {

    // There must be some strange scoping rules going on here.
    // To get the struct encoded properly, I need to copy the passed-in
    // array to a local one.
    var params = new Array;
    for (var i = 0; i < arglist.length; i++) {
        params.push(arglist[i]);
    }
    var json_rpc = { "method":method,"params":params };
    //var json_rpc = { "method":method, "params":arglist };

    xmlhttp = construct_xmlhttp();
    xmlhttp.open('POST', url, false);
    post_data = json_rpc.toJSONString();
    xmlhttp.send(post_data);

    var resultstring = xmlhttp.responseText;
    var resultobj = resultstring.parseJSON();

    if (resultobj.error) {
        alert(resultobj.error);
        return null;
    }

    return resultobj.result;
}

// a URClassInterface holds the info necessary for getting instances of a class from the server
function URClassInterface(base_url,class_name) {
    this.class_name = class_name;

    var path_parts = new Array;
    path_parts = class_name.split('::');

    this.url = base_url + '/class/' + path_parts.join('/');

    var result = do_rpc(this.url, '_get_class_info', []);
    this.id_properties = result[0]["id_properties"];
    this.properties = result[0]["properties"];
    this.methods = result[0]["methods"];

    this.get = function() {

        var returned_list = do_rpc(this.url, 'get', arguments);
        var retval = new Array;
        for(var i = 0; i < returned_list.length; i++) {
            delete returned_list[i].db_committed;
            delete returned_list[i].toJSONString;

            var obj_url = base_url + '/obj/' + path_parts.join('/') + '/' + returned_list[i].id;
            var theobj = new URObject(returned_list[i], obj_url);
            theobj.add_methods(this.properties);
            theobj.add_methods(this.methods);
            retval.push(theobj);
        }
        return retval;
    };
    
}


// Yer basic object instance from the server.  For now it holds all the attributes
// of an object.  But we'll move it to only holding ID properties soonly
function URObject(thing,url) {

    for (var i in thing) {
        this[i] = thing[i];
    }
    this.url = url;

    this.tableize = function(display_location) {
        var table = '<TABLE border=1><caption>' + this.object_type + '</caption><TR><TH>Key</TH><TH>Value</TH></TR>';
        for (var i in this) {
            if (typeof(this[i]) == 'function') {
                continue;
            }
            table += '<TR><TD>' + i + '</TD><TD>' + this[i] + '</TD></TR>';
        }
        table += '</TABLE>';
        var orig_data = document.getElementById(display_location).innerHTML;
        document.getElementById(display_location).innerHTML = orig_data + table;
    };

    this.add_methods = function(method_names) {
        for (var i = 0; i < method_names.length; i++) {
            var method_name = method_names[i];
            this[method_name] = function() {
                do_rpc(this.url, method_name, arguments);
            }
        }
    };

    this.call = function(method,arglist) {
        //var arglist = new Array;
        //for (var i = 1; i < arguments.length; i++) {
        //    arglist.push(arguments[i]);
        //}
        var returned_list = do_rpc(this.url, method, arglist);
        return returned_list;
    };
}


