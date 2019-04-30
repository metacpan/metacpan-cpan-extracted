/*
 * This software is Copyright (c) 2016 by Ashley Willis.
 * This is free software, licensed under:
 *   The Apache License, Version 2.0, January 2004
 */

// gets JSON from a URL, parses it, and sends to callback
function getOrPostJSON(method, url, callback, data) {
  if (!window.XMLHttpRequest) {
    alert("Get a real browser");
    return false;
  }
  var request = new XMLHttpRequest();
  var json;
  request.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      if (!this.responseText) { console.error("Could not load JSON from url '" + url + "'"); return false; }
      json = JSON.parse(this.responseText);
      if (!json) { console.error("Invalid JSON data obtained from url '" + url + "'"); return false; }
      callback && callback(json);
    }
  };
  request.open(method, url, true);
  if (method == 'POST') request.setRequestHeader("Content-type", "application/json");
  request.send(JSON.stringify(data));
}

function getJSON(url, callback) {
  getOrPostJSON('GET', url, callback);
}

function postJSON(url, data, callback) {
  getOrPostJSON('POST', url, callback, data);
}

function mungeData(data) {
  var munged = [];
  data.forEach(function(item) { munged.push({ id: item.id, values: item }); });
  return munged;
}

function load(grid, metadata, data) {
  grid.load({metadata: metadata, data: mungeData(data)});
};

function render(grid, containerid, className, tableid) {
  grid.renderGrid(containerid, className, tableid);
};

function reload(grid, data) {
  grid.update({data: mungeData(data)});
};

/*
 * loadJSON(url, callback, dataOnly):
   - loads a URL
   - calls processJSON(jsonData)
   - calls _callback('json', callback)
   - ignore dataOnly
 * _callback(type, callback):
   - type is ignored unless maybe callback is defined
   - if (callback) callback.call(this)
   - otherwise calls tableLoaded()
 * processJSON(jsonData)
   - turns a json string into an object, if value is not already an object
   - clears this.data
   - if (jsonData.metadata) sets up the metadata
   - if (jsonData.data) sets up the data
 * load(object) is just a wrapper on processJSON(jsonData)
 * loadJSONFromString(json) is just a wrapper on processJSON(jsonData)
 * update(object):
   - if (object.data) updates the data and reloads
 */
window.onload = function() {
  EditableGrid.prototype.modelChanged = function(rowIndex, columnIndex, oldValue, newValue, row) {
    //alert('changed ' + rowIndex + ',' + columnIndex + '\n' + 'from: "' + oldValue + '" to "' + newValue + '"\n' + 'id: ' + row.rowId + '\n' + 'field: ' + this.getColumnName(columnIndex));
    var data = {};
    data[this.getColumnName(columnIndex)] = newValue;
    if (this.currentTableid == 'nodes') {
      postJSON('/nodes/' + this.getRowAttribute(rowIndex, 'columns')[this.getColumnIndex('node')], data, loadNodes);
    } else {
      postJSON('/queues/' + row.rowId, data, loadQueues);
    }
  };

  // new
  var queueLayout = [
    { name: "id", label: "ID", datatype: "string", editable: false},
    { name: "plugin", label: "Type", datatype: "string", editable: true},
    { name: "name", label: "Name", datatype: "string", editable: true},
    { name: "threads", label: "Threads", datatype: "integer", editable: true},
    { name: "queued", label: "Queued", datatype: "integer", editable: false},
    { name: "running", label: "Running", datatype: "integer", editable: false},
    { name: "completed", label: "Completed", datatype: "integer", editable: false},
  ];
  // a small example of how you can manipulate the object in javascript
  queueLayout[1].values = {
    Europe: {"be":"Belgium","fr":"France","uk":"Great-Britain","nl":"Nederland"},
    America: {"br":"Brazil","ca":"Canada","us":"USA"},
    Africa: {"ng":"Nigeria","za":"South-Africa","zw":"Zimbabwe"},
  };
  var nodeLayout = [
    { name: "id", label: "ID", datatype: "string", editable: false},
    { name: "node", label: "Node", datatype: "string", editable: false},
    { name: "maxthreads", label: "Max Threads", datatype: "integer", editable: true},
    { name: "timestamp", label: "Timestamp", datatype: "string", editable: false},
  ];
  getJSON('/plugins', function(plugins) {
    queueLayout[1].values = {};
    var selectList = document.getElementById('inputType');
    for (var i = 0; i < plugins.length; i++) {
      queueLayout[1].values[plugins[i]] = plugins[i];
      var option = document.createElement("option");
      option.value = plugins[i];
      option.text = plugins[i];
      selectList.appendChild(option);
    }
  });

  var jsdataGrid = new EditableGrid("DemoGridJsData");
  var containerid = "tablecontent-jsdata";
  var className = "testgrid table table-striped table-bordered table-hover table-condensed";
  var tableid = "queues";
  var loadQueues = function() {
    getJSON("/queues", function(data) { load(jsdataGrid, queueLayout, data); render(jsdataGrid, containerid, className, tableid); });
  }
  var nodesGrid = new EditableGrid("DemoGridJsData2");
  var nodesContainerid = 'nodes-table';
  var nodesTableid = 'nodes';
  var loadNodes = function() {
    //if (new Date(1534782740217+900000) < new Date()) { print("old") }
    getJSON("/nodes", function(data) {
      var data2 = [];
      data.forEach(function (n) {
        //n.timestamp = new Date(n.timestamp)
        if (new Date(n.timestamp+900000) >= new Date()) {
            // within the last 15 minutes
            data2.push(n);
        }
      })
      console.log(JSON.stringify(data)); load(nodesGrid, nodeLayout, data2); render(nodesGrid, nodesContainerid, className, nodesTableid); });
  }
  loadQueuesAndNodes = function() { loadQueues(); loadNodes(); }	// no var because needed for Refresh button
  newQueue = function() {		// no var because needed for New Queue button
    var elements = document.getElementById('queue-form').elements;
    var name = elements.inputName.value;
    var plugin = elements.inputType.value;
    document.getElementById('queue-form').reset();
    postJSON('/queues', {name: name, plugin: plugin}, loadQueues);
  }
  loadQueuesAndNodes();
  var intervalID = window.setInterval(loadQueuesAndNodes, 60000);

  // json
  //jsonGrid = new EditableGrid("DemoGridJSON"); 
  //jsonGrid.tableLoaded = function() { this.renderGrid("tablecontent-json", "testgrid table table-striped table-bordered table-hover table-condensed"); };
  //jsonGrid.loadJSON("eg/grid.json");

} 
