<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<!--
	Tomato GUI
	Copyright (C) 2007-2011 Shibby
	http://openlinksys.info
	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] Advanced: Adblock</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<script type="text/javascript" src="tomato.js"></script>

<!-- / / / -->
<style type="text/css">
#adblockg-grid {
	width: 100%;
}
#adblockg-grid .co1 {
	width: 5%;
	text-align: center;
}
#adblockg-grid .co2 {
	width: 70%;
}
#adblockg-grid .co3 {
	width: 25%;
}
textarea {
 width: 98%;
 height: 15em;
}
</style>

<script type="text/javascript" src="debug.js"></script>
<script type="text/javascript">

//	<% nvram("adblock_enable,adblock_blacklist,adblock_blacklist_custom,adblock_whitelist,dnsmasq_debug"); %>

var adblockg = new TomatoGrid();

adblockg.exist = function(f, v) {
	var data = this.getAllData();
	for (var i = 0; i < data.length; ++i) {
		if (data[i][f] == v) return true;
	}
	return false;
}

adblockg.dataToView = function(data) {
	return [(data[0] != '0') ? 'On' : '', data[1], data[2]];
}

adblockg.fieldValuesToData = function(row) {
	var f = fields.getAll(row);
	return [f[0].checked ? 1 : 0, f[1].value, f[2].value];
}

adblockg.verifyFields = function(row, quiet) {
	var ok = 1;
	return ok;
}
function verifyFields(focused, quiet) {
	var ok = 1;
	return ok;
}

adblockg.resetNewEditor = function() {
	var f;

	f = fields.getAll(this.newEditor);
	ferror.clearAll(f);
	f[0].checked = 1;
	f[1].value = '';
	f[2].value = '';
}

adblockg.setup = function() {
	this.init('adblockg-grid', '', 50, [
		{ type: 'checkbox' },
		{ type: 'text', maxlen: 130 },
		{ type: 'text', maxlen: 40 }
	]);
	this.headerSet(['On', 'Blacklist URL', 'Description']);
	var s = nvram.adblock_blacklist.split('>');
	for (var i = 0; i < s.length; ++i) {
		var t = s[i].split('<');
		if (t.length == 3) this.insertData(-1, t);
	}
	this.showNewEditor();
	this.resetNewEditor();
}

function save() {
	var data = adblockg.getAllData();
	var blacklist = '';
	for (var i = 0; i < data.length; ++i) {
		blacklist += data[i].join('<') + '>';
	}

	var fom = E('t_fom');
	fom.adblock_enable.value = E('_f_adblock_enable').checked ? 1 : 0;
	fom.dnsmasq_debug.value = E('_f_dnsmasq_debug').checked ? 1 : 0;
	fom.adblock_blacklist.value = blacklist;
	form.submit(fom, 1);
}

function init() {
	adblockg.recolor();
}
</script>
</head>
<body onload="init()">
<form id="t_fom" method="post" action="tomato.cgi">
<table id="container" cellspacing="0">
<tr><td colspan="2" id="header">
	<div class="title">Tomato</div>
	<div class="version">Version <% version(); %></div>
</td></tr>
<tr id="body"><td id="navi"><script type="text/javascript">navi()</script></td>
<td id="content">
<div id="ident"><% ident(); %></div>

<!-- / / / -->

<input type="hidden" name="_nextpage" value="advanced-adblock.asp">
<input type="hidden" name="_service" value="adblock-restart">
<input type="hidden" name="adblock_enable">
<input type="hidden" name="dnsmasq_debug">
<input type="hidden" name="adblock_blacklist">

<div class="section-title">Adblock Settings</div>
<div class="section">
	<script type="text/javascript">
	createFieldTable('', [
		{ title: 'Enable', name: 'f_adblock_enable', type: 'checkbox', value: nvram.adblock_enable != '0' },
		{ title: 'Debug Mode', indent: 2, name: 'f_dnsmasq_debug', type: 'checkbox', value: nvram.dnsmasq_debug == '1' }
	]);
	</script>
</div>

<div class="section-title">Blacklist URL</div>
<div class="section">
	<div class="tomato-grid" id="adblockg-grid"></div>
	<script type="text/javascript">adblockg.setup();</script>
</div>

<div class="section-title">Blacklist Custom</div>
<div class="section">
	<script type="text/javascript">
	createFieldTable('', [
		{ title: 'Blacklisted domains', name: 'adblock_blacklist_custom', type: 'textarea', value: nvram.adblock_blacklist_custom }
	]);
	</script>
</div>

<div class="section-title">Whitelist</div>
<div class="section">
	<script type="text/javascript">
	createFieldTable('', [
		{ title: 'Whitelisted domains', name: 'adblock_whitelist', type: 'textarea', value: nvram.adblock_whitelist }
	]);
	</script>
</div>

<div class="section-title">Notes</div>
<div class="section">
	<ul>
		<li><b>Adblock</b> - Autoupdate will be randomly launch between 2:00-2.59 AM every day</li>
		<li><b>Debug Mode</b> - All queries to dnsmasq will be logged to syslog</li>
		<li><b>Blacklist URL</b> - Correct file format: 0.0.0.0 domain.com or 127.0.0.1 domain.com, one domain per line</li>
		<li><b>Blacklist Custom</b> - Optional, space separated: domain1.com domain2.com domain3.com</li>
		<li><b>Whitelist</b> - Optional, space separated: domain1.com domain2.com domain3.com</li>
		<li><b style="text-decoration:underline">Caution!</b> - Adblock having too many large blocklists configured may crash the router, as it exhausted all available system memory.</li>
	</ul>
</div>

<!-- / / / -->

</td></tr>
<tr><td id="footer" colspan="2">
	<span id="footer-msg"></span>
	<input type="button" value="Save" id="save-button" onclick="save()">
	<input type="button" value="Cancel" id="cancel-button" onclick="reloadPage();">
</td></tr>
</table>
</form>
<script type="text/javascript">verifyFields(null, 1);</script>
</body>
</html>