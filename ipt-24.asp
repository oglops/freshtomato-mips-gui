<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<!--
	Tomato GUI
	Copyright (C) 2006-2010 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	IP Traffic enhancements
	Copyright (C) 2011 Augusto Bott
	http://code.google.com/p/tomato-sdhc-vlan/

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] IP Traffic: Last 24 Hours</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<script type="text/javascript" src="tomato.js"></script>

<!-- / / / -->

<style type="text/css">
#txt {
	width: 550px;
	white-space: nowrap;
}
#bwm-controls {
	text-align: right;
	margin-right: 5px;
	margin-top: 5px;
	float: right;
	visibility: hidden;
}
ul.tabs a,
#tabs a {
	width: 165px;
	height: 15px;
	font-size: 10px;
}
</style>

<script type="text/javascript" src="debug.js"></script>

<script type="text/javascript" src="wireless.jsx?_http_id=<% nv(http_id); %>"></script>
<script type="text/javascript" src="bwm-common.js"></script>
<script type="text/javascript" src="bwm-hist.js"></script>
<script type="text/javascript" src="interfaces.js"></script>

<script type="text/javascript">

//	<% nvram("wan_ifname,wan_proto,wan_iface,wan2_ifname,wan2_proto,wan2_iface,wan3_ifname,wan3_proto,wan3_iface,wan4_ifname,wan4_proto,wan4_iface,lan_ifname,wl_ifname,web_svg,cstats_enable,cstats_colors,dhcpd_static,lan_ipaddr,lan_netmask,lan1_ipaddr,lan1_netmask,lan2_ipaddr,lan2_netmask,lan3_ipaddr,lan3_netmask,cstats_labels"); %>

//	<% devlist(); %>

var cprefix = 'ipt_';
var updateInt = 120;
var updateDiv = updateInt;
var updateMaxL = 720;
var updateReTotal = 1;
var hours = 24;
var lastHours = 0;
var debugTime = 0;
var cstats_busy = 0;

var ipt_addr_shown = [];
var ipt_addr_hidden = [];

hostnamecache = [];

function showHours() {
	if (hours == lastHours) return;
		showSelectedOption('hr', lastHours, hours);
	lastHours = hours;
}

function switchHours(h) {
	if ((!svgReady) || (updating)) return;

	hours = h;
	updateMaxL = (720 / 24) * hours;
	showHours();
	loadData();
	cookie.set(cprefix + 'hrs', hours);
}

var ref = new TomatoRefresh('update.cgi', 'exec=ipt_bandwidth&arg0=speed');

ref.refresh = function(text) {
	++updating;
	try {
		this.refreshTime = 1500;
		speed_history = {};
		try {
			eval(text);

			var i;
			for (i in speed_history) {
				if ((ipt_addr_hidden.find(i) == -1) && (ipt_addr_shown.find(i) == -1) && (i != '_next')) {
					ipt_addr_shown.push(i);
					var option=document.createElement("option");
					option.value=i;
					if (hostnamecache[i] != null) {
						option.text = hostnamecache[i] + ' (' + i + ')';
					} else {
						option.text=i;
					}
					E('_f_ipt_addr_shown').add(option,null);
					speed_history[i].hide = 0;
				}

				if (ipt_addr_hidden.find(i) != -1) {
					speed_history[i].hide = 1;
				} else {
					speed_history[i].hide = 0;
				}
			}

			if (cstats_busy) {
				E('rbusy').style.display = 'none';
				cstats_busy = 0;
			}
			this.refreshTime = (fixInt(speed_history._next, 1, 120, 60) + 2) * 1000;
		} catch (ex) {
			speed_history = {};
			cstats_busy = 1;
			E('rbusy').style.display = '';
		}
		if (debugTime) E('dtime').innerHTML = (ymdText(new Date())) + ' ' + (this.refreshTime / 1000);

		loadData();
	}
	catch (ex) {
/* REMOVE-BEGIN
//		alert('ex=' + ex);
REMOVE-END */
	}
	--updating;
}

ref.showState = function() {
	E('refresh-button').value = this.running ? 'Stop' : 'Start';
}

ref.toggleX = function() {
	this.toggle();
	this.showState();
	cookie.set(cprefix + 'refresh', this.running ? 1 : 0);
}

ref.initX = function() {
	var a;

	a = fixInt(cookie.get(cprefix + 'refresh'), 0, 1, 1);
	if (a) {
		ref.refreshTime = 100;
		ref.toggleX();
	}
}

function init() {
	if (nvram.cstats_enable != '1') {
		E('refresh-button').setAttribute("disabled", "disabled");
		return;
	}

	populateCache();

	var c,i;
	if ((c = cookie.get('ipt_addr_hidden')) != null) {
		c = c.split(',');
		for (var i = 0; i < c.length; ++i) {
			if (c[i].trim() != '') {
				ipt_addr_hidden.push(c[i]);
				var option=document.createElement("option");
				option.value=c[i];
				if (hostnamecache[c[i]] != null) {
					option.text = hostnamecache[c[i]] + ' (' + c[i] + ')';
				} else {
					option.text = c[i];
				}
				E('_f_ipt_addr_hidden').add(option,null);
			}
		}
	}

	try {
	//	<% ipt_bandwidth("speed"); %>

		for (i in speed_history) {
			if ((ipt_addr_hidden.find(i) == -1) && (ipt_addr_shown.find(i) == -1) && ( i != '_next') && (i.trim() != '')) {
				ipt_addr_shown.push(i);
				var option=document.createElement("option");
				var ii = i;
				if (hostnamecache[i] != null) {
					ii = hostnamecache[i] + ' (' + i + ')';
				}
				option.text=ii;
				option.value=i;
				E('_f_ipt_addr_shown').add(option,null);
				speed_history[i].hide = 0;
			}
			if (ipt_addr_hidden.find(i) != -1) {
				speed_history[i].hide = 1;
			} else {
				speed_history[i].hide = 0;
			}
		}
	}
	catch (ex) {
/* REMOVE-BEGIN
//		speed_history = {};
REMOVE-END */
	}
	cstats_busy = 0;
	if (typeof(speed_history) == 'undefined') {
		speed_history = {};
		cstats_busy = 1;
		E('rbusy').style.display = '';
	}

	hours = fixInt(cookie.get(cprefix + 'hrs'), 1, 24, 24);
	updateMaxL = (720 / 24) * hours;
	showHours();

	initCommon(1, 0, 0, 1);

	verifyFields(null,1);

	var theRules = document.styleSheets[document.styleSheets.length-1].cssRules;
	switch (nvram['cstats_labels']) {
		case '1':		/* show hostnames only */
			theRules[theRules.length-1].style.cssText = 'width: 140px; font-weight:bold;';
/* REMOVE-BEGIN */
//			document.styleSheets[2].deleteRule(theRules.length - 1);
/* REMOVE-END */
			break;
		case '2':		/* show IPs only */
			theRules[theRules.length-1].style.cssText = 'width: 140px; font-weight:bold;';
			break;
		case '0':		/* show hostnames + IPs */
		default:
/* REMOVE-BEGIN */
//			theRules[theRules.length-1].style.cssText = 'width: 140px; height: 12px; font-size: 9px;';
/* REMOVE-END */
			break;
	}

	ref.initX();
}

function verifyFields(focused, quiet) {
	var changed_addr_hidden = 0;
	if (focused != null) {
		if (focused.id == '_f_ipt_addr_shown') {
			ipt_addr_shown.remove(focused.options[focused.selectedIndex].value);
			ipt_addr_hidden.push(focused.options[focused.selectedIndex].value);
			var option=document.createElement("option");
			option.text=focused.options[focused.selectedIndex].text;
			option.value=focused.options[focused.selectedIndex].value;
			E('_f_ipt_addr_shown').remove(focused.selectedIndex);
			E('_f_ipt_addr_shown').selectedIndex=0;
			E('_f_ipt_addr_hidden').add(option,null);
			changed_addr_hidden = 1;
		}

		if (focused.id == '_f_ipt_addr_hidden') {
			ipt_addr_hidden.remove(focused.options[focused.selectedIndex].value);
			ipt_addr_shown.push(focused.options[focused.selectedIndex].value);
			var option=document.createElement("option");
			option.text=focused.options[focused.selectedIndex].text;
			option.value=focused.options[focused.selectedIndex].value;
			E('_f_ipt_addr_hidden').remove(focused.selectedIndex);
			E('_f_ipt_addr_hidden').selectedIndex=0;
			E('_f_ipt_addr_shown').add(option,null);
			changed_addr_hidden = 1;
		}
		if (changed_addr_hidden == 1) {
			cookie.set('ipt_addr_hidden', ipt_addr_hidden.join(','), 1);
			if (!ref.running) {
				ref.once = 1;
				ref.start();
			} else {
				ref.stop();
				ref.start();
			}
		}
	}

	if (E('_f_ipt_addr_hidden').length < 2) {
		E('_f_ipt_addr_hidden').setAttribute("disabled", "disabled");
	} else {
		E('_f_ipt_addr_hidden').removeAttribute("disabled");
	}

	if (E('_f_ipt_addr_shown').length < 2) {
		E('_f_ipt_addr_shown').setAttribute("disabled", "disabled");
	} else {
		E('_f_ipt_addr_shown').removeAttribute("disabled");
	}

	return 1;
}
</script>

</head>
<body onload="init()">
<form action="">
<table id="container" cellspacing="0">
<tr><td colspan="2" id="header">
	<div class="title">Tomato</div>
	<div class="version">Version <% version(); %></div>
</td></tr>
<tr id="body"><td id="navi"><script type="text/javascript">navi()</script></td>
<td id="content">
<div id="ident"><% ident(); %></div>

<!-- / / / -->

<div class="section-title">IP Traffic - Last 24 Hours</div>
<div id="cstats">
	<div id="tab-area"></div>

	<script type="text/javascript">
	if ((nvram.web_svg != '0') && (nvram.cstats_enable == '1')) {
		W('<div style="border-top:1px solid #f0f0f0;border-bottom:1px solid #f0f0f0;visibility:hidden;padding:0;margin:0" id="graph"><embed src="bwm-graph.svg?<% version(); %>" style="width:760px;height:300px;margin:0;padding:0" type="image/svg+xml"><\/embed><\/div>\n');
	}
	</script>

	<div id="bwm-controls">
		<small>(2 minute interval)</small><br/>
		<br/>
		Hours:&nbsp;
			<a href="javascript:switchHours(1);" id="hr1">1</a>,
			<a href="javascript:switchHours(2);" id="hr2">2</a>,
			<a href="javascript:switchHours(4);" id="hr4">4</a>,
			<a href="javascript:switchHours(6);" id="hr6">6</a>,
			<a href="javascript:switchHours(12);" id="hr12">12</a>,
			<a href="javascript:switchHours(18);" id="hr18">18</a>,
			<a href="javascript:switchHours(24);" id="hr24">24</a><br/>
		Avg:&nbsp;
			<a href="javascript:switchAvg(1)" id="avg1">Off</a>,
			<a href="javascript:switchAvg(2)" id="avg2">2x</a>,
			<a href="javascript:switchAvg(4)" id="avg4">4x</a>,
			<a href="javascript:switchAvg(6)" id="avg6">6x</a>,
			<a href="javascript:switchAvg(8)" id="avg8">8x</a><br/>
		Max:&nbsp;
			<a href="javascript:switchScale(0)" id="scale0">Uniform</a>,
			<a href="javascript:switchScale(1)" id="scale1">Per Address</a><br/>
		Unit:&nbsp;
			<a href="javascript:switchUnit(0)" id="unit0">kbit/KB</a>,
			<a href="javascript:switchUnit(1)" id="unit1">Mbit/MB</a><br/>
		Display:&nbsp;
			<a href="javascript:switchDraw(0)" id="draw0">Solid</a>,
			<a href="javascript:switchDraw(1)" id="draw1">Line</a><br/>
		Color:&nbsp; <a href="javascript:switchColor()" id="drawcolor">-</a><br/>
			<small><a href="javascript:switchColor(1)" id="drawrev">[reverse]</a></small><br/>
			<br/><br/>
			&nbsp; &raquo; <a href="admin-iptraffic.asp">Configure</a>
	</div>

	<br/><br/>
	<table id="txt" style="border:0;border-spacing:2px">
		<tr>
			<td style="width:8%;text-align:right;vertical-align:top"><b style="border-bottom:blue 1px solid" id="rx-name">RX</b></td>
			<td style="width:15%;text-align:right;vertical-align:top"><span id="rx-current"></span></td>
			<td style="width:8%;text-align:right;vertical-align:top"><b>Avg</b></td>
			<td style="width:15%;text-align:right;vertical-align:top" id="rx-avg"></td>
			<td style="width:8%;text-align:right;vertical-align:top"><b>Peak</b></td>
			<td style="width:15%;text-align:right;vertical-align:top" id="rx-max"></td>
			<td style="width:8%;text-align:right;vertical-align:top"><b>Total</b></td>
			<td style="width:14%;text-align:right;vertical-align:top" id="rx-total"></td>
			<td>&nbsp;</td>
		</tr>
		<tr>
			<td style="width:8%;text-align:right;vertical-align:top"><b style="border-bottom:blue 1px solid" id="tx-name">TX</b></td>
			<td style="width:15%;text-align:right;vertical-align:top"><span id="tx-current"></span></td>
			<td style="width:8%;text-align:right;vertical-align:top"><b>Avg</b></td>
			<td style="width:15%;text-align:right;vertical-align:top" id="tx-avg"></td>
			<td style="width:8%;text-align:right;vertical-align:top"><b>Peak</b></td>
			<td style="width:15%;text-align:right;vertical-align:top" id="tx-max"></td>
			<td style="width:8%;text-align:right;vertical-align:top"><b>Total</b></td>
			<td style="width:14%;text-align:right;vertical-align:top" id="tx-total"></td>
			<td>&nbsp;</td>
		</tr>
	</table>

<!-- / / / -->

	<div>
		<script type="text/javascript">
			createFieldTable('', [
				{ title: 'IPs currently on graphic', name: 'f_ipt_addr_shown', type: 'select', options: [[0,'Select']], suffix: ' <small>(Click/select a device from this list to hide it)<\/small>' },
				{ title: 'Hidden addresses', name: 'f_ipt_addr_hidden', type: 'select', options: [[0,'Select']], suffix: ' <small>(Click/select to show it again)<\/small>' }
			]);
		</script>
	</div>

	<br/>

</div>

<!-- / / / -->

<script type="text/javascript">checkCstats();</script>

<!-- / / / -->

</td></tr>
<tr><td id="footer" colspan="2">
	<span id="dtime"></span>
	<img src="spin.gif" id="refresh-spinner" alt="" onclick="debugTime=1">
	<input type="button" value="Refresh" id="refresh-button" onclick="ref.toggleX()">
</td></tr>
</table>
</form>
</body>
</html>