
// *******************************************************************
// CLASS: Widget
// *******************************************************************
function Widget () {
    this.stdAttribs = stdAttribs;
    function stdAttribs () {
        var html = '';
        if (this.serviceName && !this.noId) html += ' id="' + this.serviceName + '"';
        if (this.serviceClass) html += ' class="' + this.serviceClass + '"';
        return(html);
    }
    this.validate = validate;
    function validate () {
        var validationType = this.validationType;
    }
    this.hiddenValue = hiddenValue;
    function hiddenValue () {
        var n = this.serviceName;
        return('<input type="hidden" name="' + n + '" value="' + escape(context.getValue(n)) + '">');
    }
}
Widget.prototype = new SessionObject();

// *******************************************************************
// CLASS: TextFieldWidget
// *******************************************************************
function TextFieldWidget () {
    this.html = html;
    function html () {
        var html = '<input type="text" name="' + this.serviceName + '"';
        html += this.stdAttribs();
        if (this.size) html += ' size="' + this.size + '"';
        if (this.maxlength) html += ' maxlength="' + this.maxlength + '"';
        html += '" onChange="context.sendEvent(\'' + this.serviceName + '\',\'change\');"';
        var value = this.getCurrentValue();
        if (value != null) {
            html += ' value="' + escape(value) + '"';
        }
        html += ' />';
        return(html);
    }
}
TextFieldWidget.prototype = new Widget();

// *******************************************************************
// CLASS: ButtonWidget
// A button widget is anything which can produce a "click" event.
// The following types of buttons are understood
//    type  1  text with an <a> anchor around it
//    type  2  an <input type="submit"> button
//    type  3  text with an <a> anchor inside a table
//    type 10  an <img> with an <a> anchor around it
//    type 12  an <input type="image">
// *******************************************************************
function LinkButtonWidget () {
    this.html = html;
    function html () {
        var html;
        var label = this.label;
        if (label == null) { label = this.value; }
        if (label == null) { label = this.serviceName; }
        html = '<a href="javascript:click()"' +
            this.stdAttribs() +
            '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'click\'));">' +
            escape(label) + '</a>';
        return(html);
    }
}
LinkButtonWidget.prototype = new Widget();

function SubmitButtonWidget () {
    this.html = html;
    function html () {
        var html;
        var label = this.label;
        if (label == null) { label = this.value; }
        if (label == null) { label = this.serviceName; }
        html = '<input type="submit" name="' + this.serviceName + '" value="' + escape(label) +
            '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'click\'));">';
        return(html);
    }
}
SubmitButtonWidget.prototype = new Widget();

function TableButtonWidget () {
    this.html = html;
    function html () {
        var html;
        var label = this.label;
        if (label == null) { label = this.value; }
        if (label == null) { label = this.serviceName; }
        html = '<table border="0" cellpadding="0" cellspacing="0"' + this.stdAttribs() + '><tr><td>' +
            '<a href="javascript:click()"' +
            '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'click\'));">' +
            escape(label) + '</a></td></tr></table>';
        return(html);
    }
}
TableButtonWidget.prototype = new Widget();

function TableImageButtonWidget () {
    this.html = html;
    function html () {
        var html;
        var label = this.label;
        if (label == null) { label = this.value; }
        if (label == null) { label = this.serviceName; }
        var dims = '';
        if (this.width != null) { dims += ' width="' + this.width + '"'; }
        if (this.height != null) { dims += ' height="' + this.height + '"'; }
        var linkBegin = '<a href="javascript:click()"' +
            ' onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'click\'));">';

        html = '<table border="0" cellpadding="0" cellspacing="0"><tr><td background="' + this.src + '"';
        html += ' valign="bottom" align="center"' + dims + '>';
        html += linkBegin + escape(label) + '</a></td></tr></table>';
        return(html);
    }
}
TableImageButtonWidget.prototype = new Widget();

function LinkImageButtonWidget () {
    this.html = html;
    function html () {
        var html;
        var dims = '';
        if (this.width  != null) { dims += ' width="'  + this.width  + '"'; }
        if (this.height != null) { dims += ' height="' + this.height + '"'; }
        var linkBegin = '<a href="javascript:click()"' +
            ' onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'click\'));">';
        var img = '<img src="' + this.src + '"' + dims + ' border="0">';
        html = linkBegin + img + '</a>';
        return(html);
    }
}
LinkImageButtonWidget.prototype = new Widget();

function ImageButtonWidget () {
    this.html = html;
    function html () {
        var html;
        var dims = ' border="0"';
        if (this.width != null)  { dims += ' width="'  + this.width  + '"'; }
        if (this.height != null) { dims += ' height="' + this.height + '"'; }
        html = '<input type="image" name="' + this.serviceName + '" src="' +  this.src + '"' + dims +
            ' onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'click\'));">';
        return(html);
    }
}
ImageButtonWidget.prototype = new Widget();

// *******************************************************************
// CLASS: TemplateWidget
// *******************************************************************
function TemplateWidget () {
    this.getParsedText = getParsedText;
    function getParsedText () {
        if (this.parsedText == null && this.text != null) {
            var txt = this.text;
            txt = txt.replace(/\{/g, "#:#:{");
            txt = txt.replace(/\}/g, "}#:#:");
            this.parsedText = txt.split(/#:#:/);
        }
        return(this.parsedText);
    }
    this.html = html;
    function html () {
        var parsedText = this.getParsedText();
        var i, len, wname, frag, w;
        var html = "";
        len = parsedText.length;
        for (i = 0; i < len; i++) {
            frag = parsedText[i];
            if (frag.length > 0) {
                if (frag[0] == "{") {
                    if (frag[1] == "+") {
                        wname = frag.substring(2,frag.length-1);
                        w = context.service("SessionObject",wname);
                        html += w.html();
                    }
                    else {
                        wname = frag.substring(1,frag.length-1);
                        html += '[' + wname + '.value]';
                    }
                }
                else {
                    html += frag;
                }
            }
        }
        return(html);
    }
}
TemplateWidget.prototype = new Widget();

// ***************************************************************************
// CLASS: TableWidget
// * data : [ [1,2,3],["a","b","c"] ]                - array of data for table
// * defaultAlign : "right",                  - horizontal [right,left,center]
// * defaultVAlign : "top",                     - vertical [top,middle,bottom]
// * font : {
// *   face : "MS Trebuchet,Verdana,Arial,sans-serif",
// *   size : -1,
// * }
// * font : {
// *   face : "MS Trebuchet,Verdana,Arial,sans-serif",
// *   size : -1,
// * }
// * column : [ [1,2,3],["a","b","c"] ] the array of data for table
// ***************************************************************************
function TableWidget () {
    this.tableHeaderHtml = tableHeaderHtml;
    function tableHeaderHtml (cell) {
        var html = '<div' + this.stdAttribs() + '>\n';
        html += '<table>\n';
        return(html);
    }
    this.tableFooterHtml = tableFooterHtml;
    function tableFooterHtml (cell) {
        var html = '</table>\n';
        html += '</div>\n';
        return(html);
    }
    this.cellHtml = cellHtml;
    function cellHtml (cell) {
        var html = '    <td>' + escape(cell) + '</td>\n';
        return(html);
    }
    this.rowHtml = rowHtml;
    function rowHtml (row) {
        var c;
        var html = '  <tr>\n';
        for (c = 0; c < row.length; c++) {
            html += this.cellHtml(row[c]);
        }
        html += '    </tr>\n';
        return(html);
    }
    this.html = html;
    function html () {
        var html = this.tableHeaderHtml();
        var data = this.data;
        var r;
        for (r = 0; r < data.length; r++) {
            html += this.rowHtml(data[r]);
        }
        html += this.tableFooterHtml();
        return(html);
    }
}
TableWidget.prototype = new Widget();

// *******************************************************************
// CLASS: LabelWidget
// *******************************************************************
function LabelWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(LabelWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
LabelWidget.prototype = new Widget();

// *******************************************************************
// CLASS: DateFieldWidget
// *******************************************************************
function DateFieldWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(DateFieldWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
DateFieldWidget.prototype = new Widget();

// *******************************************************************
// CLASS: ValidatedTextFieldWidget
// *******************************************************************
function ValidatedTextFieldWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(ValidatedTextFieldWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
ValidatedTextFieldWidget.prototype = new Widget();

// *******************************************************************
// CLASS: CheckboxWidget
// *******************************************************************
function CheckboxWidget () {
    this.html = html;
    function html () {
        var html = '<input type="checkbox" name="' + this.serviceName + '"';
        html += this.stdAttribs();
        var checked = this.checked;
        if (checked == null) {
            var elem = context.findElementById(this.serviceName);
            if (elem) {
                checked = elem.checked;
            }
            else {
                checked = this["default"];
            }
        }
        if (checked) html += ' checked';
        html += ' />';
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(CheckboxWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
CheckboxWidget.prototype = new Widget();

// *******************************************************************
// CLASS: CheckboxGroupWidget
// *******************************************************************
function CheckboxGroupWidget () {
    this.html = html;
    function html () {
        var values     = this.getValues();
        var labels     = this.getLabels();
        var currValues = this.getCurrentValues();

        var html = '<span' + this.stdAttribs() + '>\n';

        var i;
        var currValueSelected = new Object();
        for (i = 0; i < currValues.length; i++) {
            currValueSelected[currValues[i]] = 1;
        }

        var v, value;
        for (v = 0; v < values.length; v++) {
            value = values[v];
            html += '<input type="checkbox" name="' + this.serviceName + '-' + value +
                ' value="' + escape(value) + '"';
            if (currValueSelected[value] != null) {
                html += ' checked';
            }
            html += '>\n';
            if (labels[value] != null) {
                html += labels[value];
            }
            else {
                html += value;
            }
        }
        html += '</span>';
        return(html);
    }
}
CheckboxGroupWidget.prototype = new Widget();

// *******************************************************************
// CLASS: RadioButtonWidget
// *******************************************************************
function RadioButtonWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(RadioButtonWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
RadioButtonWidget.prototype = new Widget();

// *******************************************************************
// CLASS: RadioButtonSetWidget
// *******************************************************************
function RadioButtonSetWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(RadioButtonSetWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
RadioButtonSetWidget.prototype = new Widget();

// *******************************************************************
// CLASS: SelectWidget
// *******************************************************************
function SelectWidget () {
    this.html = html;
    function html () {

        var html = '<select name="' + this.serviceName + '"' + this.stdAttribs();

        var multiple = this.multiple || 0;
        if (multiple > 0) html += ' multiple';
        var size     = this.size || (multiple > 0 ? 5 : 0);
        if (size > 0) html += ' size="' + size + '"';
        var tabindex = this.tabindex;
        if (tabindex != null) html += ' tabindex="' + tabindex + '"';
        html += '" onChange="context.sendEvent(\'' + this.serviceName + '\',\'change\');"';
        html += '>\n';

        var values     = this.getValues();
        var labels     = this.getLabels();
        var currValues = this.getCurrentValues();

        // var nullable = this.nullable || 0;
        // if (nullable) {
        //     $values = [ "", @$values ];
        // }

        var i;
        var currValueSelected = new Object();
        for (i = 0; i < currValues.length; i++) {
            currValueSelected[currValues[i]] = 1;
        }

        var v, value;
        for (v = 0; v < values.length; v++) {
            value = values[v];
            html += '  <option value="' + escape(value) + '"';
            if (currValueSelected[value] != null) {
                html += ' selected';
            }
            html += '>';
            if (labels[value] != null) {
                html += labels[value] + '</option>\n';
            }
            else {
                html += value + '</option>\n';
            }
        }
        html += '</select>\n';
        return(html);
    }
}
SelectWidget.prototype = new Widget();

// *******************************************************************
// CLASS: ToolbarWidget
// *******************************************************************
function ToolbarWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(ToolbarWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
ToolbarWidget.prototype = new Widget();

// *******************************************************************
// CLASS: TabSetWidget
// *******************************************************************
function TabSetWidget () {
    this.html = html;
    function html () {
        var selectorName   = this.serviceName + "-selector";
        var selector       = context.widget(selectorName, {
            "serviceClass" : "TabbedSelectorWidget"
        });

        var selectorHTML      = selector.html();
        var selectedPaneWName = selector.getSelected("wname");

        var selectedPane, selectedPaneHTML, selectedPaneBgcolor;

        if (selectedPaneWName != null) {
            selectedPane        = context.widget(selectedPaneWName);
        }
        if (selectedPane != null) {
            selectedPaneHTML    = selectedPane.html();
            selectedPaneBgcolor = selectedPane.bgcolor;
        }
        else {
            selectedPaneHTML    = "&nbsp;";
        }
        if (selectedPaneBgcolor == null) {
            selectedPaneBgcolor = "#cccccc";
        }

        var html = "";
        html += '<table width="100%" border="0" cellspacing="0" cellpadding="0">\n';
        html += '  <tr>\n';
        html += '    <td valign="top">\n';
        html += '      ' + selectorHTML + '\n';
        html += '    </td>\n';
        html += '  </tr>\n';
        html += '  <tr>\n';
        html += '    <td id="' + this.serviceName + '-pane" valign="top" bgcolor="' + selectedPaneBgcolor + '">\n';
        html += '      ' + selectedPaneHTML + '\n';
        html += '    </td>\n';
        html += '  </tr>\n';
        html += '</table>\n';

        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        var handled = 0;
        if (eventName == "select") {
            var selectorName   = this.serviceName + "-selector";
            var selector       = context.widget(selectorName, {
                "serviceClass" : "TabbedSelectorWidget"
            });
            var selectedPaneWName = selector.getSelected("wname");
            var pane           = context.widget(selectedPaneWName);
            var paneHtml       = pane.html();
            var paneId         = this.serviceName + "-pane";
            var paneElem       = context.findElementById(paneId);
            paneElem.innerHTML = paneHtml;
            handled = 1;
        }
        else {
            handled = TabSetWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs);
        }
        return(handled);
    }
}
TabSetWidget.prototype = new Widget();

// *******************************************************************
// CLASS: SaveAsSelectWidget
// *******************************************************************
function SaveAsSelectWidget () {
    this.html = html;
    function html () {
        var html = '<span' + this.stdAttribs() + '>';

        html += '<select name="' + this.serviceName + '"';

        var multiple = this.multiple || 0;
        if (multiple > 0) html += ' multiple';
        var size     = this.size || (multiple > 0 ? 5 : 0);
        if (size > 0) html += ' size="' + size + '"';
        var tabindex = this.tabindex;
        if (tabindex != null) html += ' tabindex="' + tabindex + '"';
        html += '>\n';

        var values     = this.getValues();
        var labels     = this.getLabels();
        var currValues = this.getCurrentValues();

        // var nullable = this.nullable || 0;
        // if (nullable) {
        //     $values = [ "", @$values ];
        // }

        var i;
        var currValueSelected = new Object();
        for (i = 0; i < currValues.length; i++) {
            currValueSelected[currValues[i]] = 1;
        }

        var v, value;
        for (v = 0; v < values.length; v++) {
            value = values[v];
            html += '  <option value="' + escape(value) + '"';
            if (currValueSelected[value] != null) {
                html += ' selected';
            }
            html += '>';
            if (labels[value] != null) {
                html += labels[value] + '</option>\n';
            }
            else {
                html += value + '</option>\n';
            }
        }
        html += '</select>\n';
        html +=
            '\n&nbsp;<input name="' + this.serviceName + '-open" value="Open" type="submit"' +
                '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'open\'));" />' +
            '\n&nbsp;<input name="' + this.serviceName + '-save" value="Save" type="submit"' +
                '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'save\'));" />' +
            '\n&nbsp;<input name="' + this.serviceName + '-delete" value="Delete" type="submit"' +
                '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'delete\'));" />' +
            '\n&nbsp;:&nbsp;<input name="' + this.serviceName + '-saveas" value="Save As" type="submit"' +
                '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'saveas\'));" />' +
            '\n&nbsp;<input name="' + this.serviceName + '-new" value="" type="text" size="20" maxlength="255"></span>';
        return(html);
    }
}
SaveAsSelectWidget.prototype = new SelectWidget();

// *******************************************************************
// CLASS: HierSelectorWidget
// This widget is a base class providing the event handler for all
// types of hierarchical view widgets.
// *******************************************************************
function HierSelectorWidget () {

    this.getSelected = getSelected;
    function getSelected (attrib) {
        var val;
        if (this.selected == null) {
            context.log("HierSelectorWidget(" + this.serviceName + ").getSelected(): this.selected == null");
        }
        else if (this.node == null) {
            context.log("HierSelectorWidget(" + this.serviceName + ").getSelected(): this.node == null");
        }
        else {
            var nodeval = this.selected;
            var node = this.node[nodeval];
            if (node != null) {
                val = node[attrib];
            }
        }
        return(val);
    }
    this.html = html;
    function html () {
        var html = "[" + this.serviceName + " : HierVierWidget]";
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        // alert("hsw.handleEvent(" + thisServiceName + "," + eventServiceName + "," + eventName + ")");
        var nodeLabel;
        var s = context.service("SessionObject",thisServiceName);
        var node = s.node;
        var handled = true;
        if (eventName == "open") {
            nodeLabel = eventArgs[0];
            s.node[nodeLabel].open = 1;
        }
        else if (eventName == "open_exclusively") {
            nodeLabel = eventArgs[0];
            s.openExclusively(nodeLabel);
        }
        else if (eventName == "close") {
            nodeLabel = eventArgs[0];
            s.node[nodeLabel].open = 0;
        }
        else if (eventName == "select") {
            nodeLabel = eventArgs[0];
            s.selected = nodeLabel;
            var containerServiceName = s.container(thisServiceName);
            // alert("hsw.handleEvent(): nodeLabel=" + nodeLabel + " container=" + containerServiceName);
            if (containerServiceName != null) {
                var s = context.service("SessionObject",containerServiceName);
                handled = s.handleEvent(containerServiceName, s.serviceName, eventName, eventArgs);
            }
            else {
                handled = 0;
            }
        }
        else {
            handled = HierSelectorWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs);
        }
        return(handled);
    }
}
HierSelectorWidget.prototype = new Widget();

// *******************************************************************
// CLASS: TabbedSelectorWidget
// *******************************************************************
function TabbedSelectorWidget () {

    this.html = html;
    function html () {
        var html = "";;
        html += '<table border="0" cellpadding="0" cellspacing="0" width="100%">\n';
        html += '  <tr>\n';
        html += '    <td rowspan="3" width="1%" height="19" nowrap>';

        var nodeprefix = "";
        var nodes = this.node;
        if (nodes == null || nodes["1"] == null) {
            html += "TabbedSelectorWidget(" + this.serviceName + "): No nodes defined";
        }
        else {
            if (nodes["2"] == null) {
                nodeprefix = "1-";
            }
            var nodenum = 1;
            var nodeLabel, node, nodename, img, label, tabname;
            var selected = this.selected;
            while (true) {
                nodeLabel = nodeprefix + nodenum;
                node = nodes[nodeLabel];
                if (node != null) {
                    tabname = this.serviceName + "-" + nodeLabel;
                    label = node.label;
                    if (nodeLabel == selected) {
                        img = node.selectedImage;
                    }
                    else {
                        img = node.unselectedImage;
                    }
                    html += '<!--\n      --><input id="' + tabname + '" type="image" name="' + tabname + '" src="' + img +
                        '" border="0" height="19" width="127" alt="' + label +
                        '" onClick="return(context.sendEvent(\'' + this.serviceName + '\',\'select\',[\'' + nodeLabel + '\']));" />';
                }
                else {
                    break;
                }
                nodenum++;
            }
        }

        html += '<!--\n      --></td>\n';
        html += '    <td height=16 width="99%"><img src="' +
            appOptions.urlDocRoot + '/js-app/images/dot_clear.gif" height="16" width="1"></td>\n';
        html += '    <td height="16" width="99%"></td>\n';
        html += '  </tr>\n';
        html += '  <tr>\n';
        html += '    <td height="1" width="99%" bgcolor="#000000"><img src="' +
            appOptions.urlDocRoot + '/js-app/images/dot_clear.gif" height="1" width="1"></td>\n';
        html += '  </tr>\n';
        html += '\n';
        html += '  <tr>\n';
        html += '    <td height="2" width="99%" bgcolor="#ffffff"><img src="' +
            appOptions.urlDocRoot + '/js-app/images/dot_clear.gif" height="2" width="1"></td>\n';
        html += '  </tr>\n';
        html += '</table>\n';
        return(html);
    }

    this.openExclusively = openExclusively;
    function openExclusively (openNodeLabel) {
        /*
        sub open_exclusively {
            my ($self, $opennodenumber) = @_;
            my ($nodebase, $nodeidx, $nodenumber);
            my $node = $self->get("node");
            $self->set("node", $node);
        
            $nodebase = $opennodenumber;
            if ($nodebase =~ /(.*)\.[^\.]+$/) {
                $nodebase = $1 . ".";
            }
            else {
                $nodebase = "";
            }
            $nodeidx = 1;

            while (1) {
                $nodenumber = "$nodebase$nodeidx";
                last if (!defined $node->{$nodenumber});
                $node->{$nodenumber}{open} = 0;
                $nodeidx++;
            }

            if (defined $node->{$opennodenumber}) {
                $node->{$opennodenumber}{open} = 1;
            }

            if (!defined $node->{"$opennodenumber.1"}) {
                $self->set("selected", $opennodenumber);
            }
        }
        */
        alert("openExclusively: Not Yet Implemented");
    }

    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        // alert("tsw.handleEvent(" + thisServiceName + "," + eventServiceName + "," + eventName + ")");
        var handled = 0;
        var selected, node, elemId, elem;

        if (eventName == "select") {
            selected = this.selected;
            // alert("tsw.handleEvent(): selected=" + selected);

            if (selected != eventArgs[0]) {
                // alert("tsw.handleEvent(): eventArgs[0]=" + eventArgs[0]);
                node = this.node[selected];
                elemId = this.serviceName + "-" + selected;
                // alert("tsw.handleEvent(): elemId=" + elemId);
                elem = context.findElementById(elemId);
                // alert("tsw.handleEvent(): elem=" + elem);
                elem.src = node.unselectedImage;
                // alert("tsw.handleEvent(): [1] elemId=" + elemId + " image=" + node.unselectedImage);
            }
        }

        handled = TabbedSelectorWidget.prototype.handleEvent(thisServiceName,
            eventServiceName, eventName, eventArgs);

        if (eventName == "select") {
            selected = this.selected;
            node = this.node[selected];
            elemId = this.serviceName + "-" + selected;
            elem = context.findElementById(elemId)
            elem.src = node.selectedImage;
            // elem.blur();  // COMPATIBILITY
            // alert("tsw.handleEvent(): [2] elemId=" + elemId + " image=" + node.selectedImage);
        }

        return(handled);
    }
}
TabbedSelectorWidget.prototype = new HierSelectorWidget();

// *******************************************************************
// CLASS: IconPaneSelectorWidget
// *******************************************************************
function IconPaneSelectorWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
}
IconPaneSelectorWidget.prototype = new HierSelectorWidget();

// *******************************************************************
// CLASS: TreeSelectorWidget
// *******************************************************************
function TreeSelectorWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
}
TreeSelectorWidget.prototype = new HierSelectorWidget();

// *******************************************************************
// CLASS: FileTreeSelectorWidget
// *******************************************************************
function FileTreeSelectorWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(FileTreeSelectorWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
FileTreeSelectorWidget.prototype = new Widget();

// *******************************************************************
// CLASS: AppFrameWidget
// *******************************************************************
function AppFrameWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(AppFrameWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
AppFrameWidget.prototype = new Widget();

// *******************************************************************
// CLASS: TabbedAppFrameWidget
// *******************************************************************
function TabbedAppFrameWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(TabbedAppFrameWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
TabbedAppFrameWidget.prototype = new Widget();

// *******************************************************************
// CLASS: DataTableWidget
// *******************************************************************
function DataTableWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(DataTableWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
DataTableWidget.prototype = new Widget();

// *******************************************************************
// CLASS: MenuWidget
// *******************************************************************
function MenuWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(MenuWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
MenuWidget.prototype = new Widget();

// *******************************************************************
// CLASS: HTTPDictionary
// *******************************************************************
function HTTPDictionary () {

    this.load = load;
    function load (url) {
        var xmlhttp = getHTTPObject();
        xmlhttp.open("GET", url, true);
        xmlhttp.onreadystatechange = function() {
            if (xmlhttp.readyState==4) {
                this.store[url] = xmlhttp.responseText;
            }
        }
        xmlhttp.send(null)
    }

    this.get = get;
    function get (key) {
        if (!this.store[key]) {
            this.load(key);
        }
        var i;
        for (i = 0; i < 3; i++) {
            alert(this.store[key]);
        }
        return(this.store[key]);
    }
}
HTTPDictionary.prototype = new Dictionary();

// *******************************************************************
// CLASS: XxxWidget
// *******************************************************************
function XxxWidget () {
    this.html = html;
    function html () {
        var html = '[TBD:' + this.serviceClass + ':' + this.serviceName + ']';
        // ...
        return(html);
    }
    this.handleEvent = handleEvent;
    function handleEvent (thisServiceName, eventServiceName, eventName, eventArgs) {
        return(XxxWidget.prototype.handleEvent(thisServiceName, eventServiceName, eventName, eventArgs));
    }
}
XxxWidget.prototype = new Widget();

