<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<!--
	Tomato GUI
	Copyright (C) 2006-2010 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv='content-type' content='text/html;charset=utf-8'>
<meta name='robots' content='noindex,nofollow'>
<title>[<% ident(); %>] 带宽监控：每日流量</title>
<link rel='stylesheet' type='text/css' href='tomato.css'>
<% css(); %>
<script type='text/javascript' src='tomato.js'></script>

<!-- / / / -->

<script type='text/javascript' src='debug.js'></script>
<script type='text/javascript' src='bwm-hist.js'></script>

<script type='text/javascript'>

//	<% nvram("wan_ifname,wan2_ifname,wan3_ifname,wan4_ifname,lan_ifname,rstats_enable"); %>
try {
//	<% bandwidth("daily"); %>
}
catch (ex) {
	daily_history = [];
}
rstats_busy = 0;
if (typeof(daily_history) == 'undefined') {
	daily_history = [];
	rstats_busy = 1;
}

function save()
{
	cookie.set('daily', scale, 31);
}

function genData()
{
	var w, i, h, t;

	w = window.open('', 'tomato_data_d');
	w.document.writeln('<pre>');
	for (i = 0; i < daily_history.length; ++i) {
		h = daily_history[i];
		t = getYMD(h[0]);
		w.document.writeln([t[0], t[1] + 1, t[2], h[1], h[2]].join(','));
	}
	w.document.writeln('</pre>');
	w.document.close();
}

function getYMD(n)
{
	// [y,m,d]
	return [(((n >> 16) & 0xFF) + 1900), ((n >>> 8) & 0xFF), (n & 0xFF)];
}

function redraw()
{
	var h;
	var grid;
	var rows;
	var ymd;
	var d;
	var lastt;
	var lastu, lastd;

	if (daily_history.length > 0) {
		ymd = getYMD(daily_history[0][0]);
		d = new Date((new Date(ymd[0], ymd[1], ymd[2], 12, 0, 0, 0)).getTime() - ((30 - 1) * 86400000));
		E('last-dates').innerHTML = '(' + ymdText(ymd[0], ymd[1], ymd[2]) + ' 到 ' + ymdText(d.getFullYear(), d.getMonth(), d.getDate()) + ')';

		lastt = ((d.getFullYear() - 1900) << 16) | (d.getMonth() << 8) | d.getDate();
	}

	lastd = 0;
	lastu = 0;
	rows = 0;
	block = '';
	gn = 0;

	grid = '<table class="bwmg" cellspacing="1">';
	grid += makeRow('header', '日期', '下载', '上传', '合计');

	for (i = 0; i < daily_history.length; ++i) {
		h = daily_history[i];
		ymd = getYMD(h[0]);
		grid += makeRow(((rows & 1) ? 'odd' : 'even'), ymdText(ymd[0], ymd[1], ymd[2]), rescale(h[1]), rescale(h[2]), rescale(h[1] + h[2]));
		++rows;

		if (h[0] >= lastt) {
			lastd += h[1];
			lastu += h[2];
		}
	}

	E('bwm-daily-grid').innerHTML = grid + '</table>';

	E('last-dn').innerHTML = rescale(lastd);
	E('last-up').innerHTML = rescale(lastu);
	E('last-total').innerHTML = rescale(lastu + lastd);
}

function init()
{
	var s;

	if (nvram.rstats_enable != '1') {
		E('refresh-button').disabled = 1;
		return;
	}

	if ((s = cookie.get('daily')) != null) {
		if (s.match(/^([0-2])$/)) {
			E('scale').value = scale = RegExp.$1 * 1;
		}
	}

	initDate('ymd');
	daily_history.sort(cmpHist);
	redraw();
}
</script>

</head>
<body onload='init()'>
<form>
<table id='container' cellspacing=0>
<tr><td colspan=2 id='header'>
	<div class='title'>Tomato</div>
	<div class='version'>Version <% version(); %></div>
</td></tr>
<tr id='body'><td id='navi'><script type='text/javascript'>navi()</script></td>
<td id='content'>
<div id='ident'><% ident(); %></div>

<!-- / / / -->

<div class='section-title'>WAN 每日流量</div>
<div id='bwm-daily-grid' style='float:left'></div>
<div style="float:right;text-align:right">


<table class='tomato-grid' style='width:150px'>
<tr class='header'><td colspan=2 style='text-align:center'>最近 30 天<br><span style='font-weight:normal' id='last-dates'></span></td></tr>
<tr class='even'><td>下载</td><td id='last-dn'>-</td></tr>
<tr class='odd'><td>上传</td><td id='last-up'>-</td></tr>
<tr class='footer'><td>合计</td><td id='last-total'>-</td></tr>
</table>

<br>
<hr size=1>
<br>

<b>日期格式</b> <select onchange='changeDate(this, "ymd")' id='dafm'><option value=0>年-月-日</option><option value=1>月-日-年</option><option value=2>月 日, 年</option><option value=3>日.月.年</option></select><br>
<b>单位切换</b> <select onchange='changeScale(this)' id='scale'><option value=0>KB</option><option value=1>MB</option><option value=2 selected>GB</option></select><br>
<br>
&raquo; <a href="javascript:genData()">数据</a>
<br>
&raquo; <a href="admin-bwm.asp">设置</a>
<br><br><br>
</div>
<br>

</script>

<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>
<input type='button' value='刷新' onclick='reloadPage()'>
</td></tr>
</table>
</form>
</body>
</html>
