

var tickCounter = 0;
var stepRunnerStatus = { "stepRunnerCounter": 0, "stepRunning": false};
var steps = [
	{"method": "CLICK_NODE", "xpath": "//a[contains(., 'Pre-delegated domain')]"},
	{"method": "WAIT_FOR_XPATH", "xpath": "//div[contains(@ng-show, 'inactive_domain_check')]//*/div[contains(@ng-repeat, 'in ns_list')][1]", "time_seconds": 5},
	{"method": "SET_TEXT", "xpath": "//div[contains(@ng-show, 'inactive_domain_check')]//*/input[contains(@id, 'domain_check_name')]", "text": "AfNiC.Fr"},
	{"method": "SLEEP", "time_seconds": 3 },
	{"method": "CLICK_NODE", "xpath": "//div[contains(@ng-show, 'inactive_domain_check')]//*/button[contains(@ng-click, 'fetchFromParent')]"},
	{"method": "WAIT_FOR_XPATH", "xpath": "//div[contains(@ng-show, 'inactive_domain_check')]//*/div[contains(@ng-repeat, 'in ns_list')][3]", "time_seconds": 60},
	{"method": "CLICK_NODE", "xpath": "//div[contains(@ng-show, 'inactive_domain_check')]//*/a[contains(@ng-click, 'domainCheck')]"},
	{"method": "SLEEP", "time_seconds": 3 },
	{"method": "WAIT_FOR_XPATH", "xpath": "//div[contains(@ng-show, 'inactive_domain_check')]//*/div[contains(@class, 'alert-INFO') and contains(., 'Using version')]", "time_seconds": 120},
];


function moveToNextStep () {
	stepRunnerStatus["stepRunning"] = false;
	stepRunnerStatus["stepRunnerCounter"]++;
};

function sleep (time_seconds) {
	setTimeout(function() {
		moveToNextStep();
	}, steps[stepRunnerStatus["stepRunnerCounter"]]["time"] * 1000);
};

function waitForXPath(xpath, time_secs) {
	var maxtimeOutMillis = time_secs ? time_secs*1000 : 5*60*1000, 
		start = new Date().getTime(),
		condition = false,
		interval = setInterval(function() {
//			console.log('Stripped down page text:\n' + page.plainText);
			if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
				// If not time-out yet and condition not yet fulfilled
				var testFx = function(path) {
					return page.evaluate(function(path) {
						var getElementByXpath = function () {
							return document.evaluate(path, document, null, 9, null).singleNodeValue;
						};

						return (getElementByXpath(path) ? true : false);
					}, path);
				}
				
				condition = testFx(xpath);
			} else {
				if(!condition) {
					// If condition still not fulfilled (timeout but condition is 'false')
					console.log("WAIT_FOR_XPATH:["+xpath+"] TIMEOUT");
					phantom.exit(1);
				} else {
					console.log("WAIT_FOR_XPATH:["+xpath+"] Finished");
					moveToNextStep();
					clearInterval(interval); //< Stop this interval
				}
			}
		}, 500); //< repeat check every 250ms
};

function clickNode (xpath) {
	page.evaluate(function (xpath) {
		var getElementByXpath = function (path) {
			return document.evaluate(path, document, null, 9, null).singleNodeValue;
		};
						
		var clickNode = function click(el){
			var ev = document.createEvent("MouseEvent");
			ev.initMouseEvent("click", true, true, window, null, 0, 0, 0, 0, false, false, false, false, 0, null);
			el.dispatchEvent(ev);
		};

		var element = getElementByXpath(xpath);
		if (element) {
			clickNode(element);
			console.log('Clicked on XPath -> '+xpath);
		}
		else {
			console.log('Element with XPath -> '+xpath+' NOT FOUND');
		}
		
		return;
	}, xpath );
	
	moveToNextStep();
};

function setText (xpath, text) {
	page.evaluate(function (xpath, text) {
		var getElementByXpath = function (path) {
			return document.evaluate(path, document, null, 9, null).singleNodeValue;
		};
						
		var element = getElementByXpath(xpath);

		if (element) {
			element.value = text;
			var evt = document.createEvent("HTMLEvents");
			evt.initEvent("change", false, true);
			element.dispatchEvent(evt);
			
			console.log('setText on XPath -> '+xpath+' OK');
		}
		else {
			console.log('setText NOK, element with XPath -> '+xpath+' NOT FOUND');
		}
		
		return;
	}, xpath, text );
	
	moveToNextStep();
};

var system = require('system');
if (system.args.length === 1) {
    console.log('This script requires the hostname:port of the Zonemaster server as parameter');
	phantom.exit(1);
}
else {
	var page = require('webpage').create();
	var url = 'http://'+system.args[1]+'/';

	page.onError = function (msg, trace) {
		console.log(msg);
		trace.forEach(function(item) {
			console.log('  ', item.file, ':', item.line);
		});
	};
	
	function printArgs() {
		var i, ilen;
		for (i = 0, ilen = arguments.length; i < ilen; ++i) {
			console.log(" arguments[" + i + "] = " + JSON.stringify(arguments[i]));
		}
		console.log("");
	}
	
	page.onConsoleMessage = function(msg) {
		system.stdout.writeLine('page.evaluate console: ' + msg);
	};
	
	page.onUrlChanged = function() {
		console.log("page.onUrlChanged");
		printArgs.apply(this, arguments);
	};

	page.onAlert = function() {
		console.log("page.onAlert");
		printArgs.apply(this, arguments);
	};
	
	page.open(url, function (status) {
		// Check for page load success
		if (status !== "success") {
			console.log("Unable to access network");
		} else {
			var interval = setInterval(function() {
				if (tickCounter < 100) {
					tickCounter++;
					if (!stepRunnerStatus["stepRunning"]) {
						if (stepRunnerStatus["stepRunnerCounter"] < steps.length) {
							console.log("["+tickCounter+"]No step currently executing");
							stepRunnerStatus["stepRunning"] = true;

							if (steps[stepRunnerStatus["stepRunnerCounter"]]["method"] == "SLEEP") {
								sleep(5);
							}
							else if (steps[stepRunnerStatus["stepRunnerCounter"]]["method"] == "WAIT_FOR_XPATH") {
								waitForXPath(steps[stepRunnerStatus["stepRunnerCounter"]]["xpath"], steps[stepRunnerStatus["stepRunnerCounter"]]["time_seconds"]);
							}
							else if (steps[stepRunnerStatus["stepRunnerCounter"]]["method"] == "CLICK_NODE") {
								clickNode(steps[stepRunnerStatus["stepRunnerCounter"]]["xpath"]);
							}
							else if (steps[stepRunnerStatus["stepRunnerCounter"]]["method"] == "SET_TEXT") {
								setText(steps[stepRunnerStatus["stepRunnerCounter"]]["xpath"], steps[stepRunnerStatus["stepRunnerCounter"]]["text"]);
							}
							else {
								console.log("UNKNOWN METHOD: "+steps[stepRunnerStatus["stepRunnerCounter"]]["method"]);
								phantom.exit(1);
							}
						}
						else {
							console.log("["+tickCounter+"]All steps executed: DONE");
							phantom.exit(0);
						}
					}
					else {
						console.log("["+tickCounter+"]Executing setp: "+stepRunnerStatus["stepRunnerCounter"]+" -> "+steps[stepRunnerStatus["stepRunnerCounter"]]["method"]);
					}
				}
				else {
					console.log("tickCounter:EXPIRED");
					clearInterval(interval);
					phantom.exit(1);
				}
			}
			, 1000);
		}
	});
}

