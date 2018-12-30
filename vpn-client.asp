<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<!--
	Tomato GUI
	Copyright (C) 2006-2008 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	Portions Copyright (C) 2008-2010 Keith Moyer, tomatovpn@keithmoyer.com
	Portions Copyright (C) 2010-2011 Jean-Yves Avenard, jean-yves@avenard.org

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] VPN设置: OpenVPN客户端</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<script type="text/javascript" src="tomato.js"></script>
<script type="text/javascript" src="vpn.js"></script>
<script type="text/javascript">

//	<% nvram("vpn_client_eas,vpn_client1_poll,vpn_client1_if,vpn_client1_bridge,vpn_client1_nat,vpn_client1_proto,vpn_client1_addr,vpn_client1_port,vpn_client1_retry,vpn_client1_firewall,vpn_client1_crypt,vpn_client1_comp,vpn_client1_cipher,vpn_client1_ncp_enable,vpn_client1_ncp_ciphers,vpn_client1_local,vpn_client1_remote,vpn_client1_nm,vpn_client1_reneg,vpn_client1_hmac,vpn_client1_adns,vpn_client1_rgw,vpn_client1_gw,vpn_client1_custom,vpn_client1_static,vpn_client1_ca,vpn_client1_crt,vpn_client1_key,vpn_client1_userauth,vpn_client1_username,vpn_client1_password,vpn_client1_useronly,vpn_client1_tlsremote,vpn_client1_cn,vpn_client1_br,vpn_client1_digest,vpn_client1_nopull,vpn_client1_noexec,vpn_client1_route,vpn_client1_routing_val,vpn_client2_poll,vpn_client2_if,vpn_client2_bridge,vpn_client2_nat,vpn_client2_proto,vpn_client2_addr,vpn_client2_port,vpn_client2_retry,vpn_client2_firewall,vpn_client2_crypt,vpn_client2_comp,vpn_client2_cipher,vpn_client2_ncp_enable,vpn_client2_ncp_ciphers,vpn_client2_local,vpn_client2_remote,vpn_client2_nm,vpn_client2_reneg,vpn_client2_hmac,vpn_client2_adns,vpn_client2_rgw,vpn_client2_gw,vpn_client2_custom,vpn_client2_static,vpn_client2_ca,vpn_client2_crt,vpn_client2_key,vpn_client2_userauth,vpn_client2_username,vpn_client2_password,vpn_client2_useronly,vpn_client2_tlsremote,vpn_client2_cn,vpn_client2_br,vpn_client2_digest,vpn_client2_nopull,vpn_client2_noexec,vpn_client2_route,vpn_client2_routing_val,lan_ifname,lan1_ifname,lan2_ifname,lan3_ifname"); %>

function RouteGrid() {return this;}
RouteGrid.prototype = new TomatoGrid;

tabs = [['client1', 'VPN客户端 1'],['client2', 'VPN客户端 2']];
sections = [['basic', '基本设置'],['advanced', '高级设置'],['keys','密钥设置'],['policy','路由策略'],['status','运行状态']];
routingTables = [];
statusUpdaters = [];
for (i = 0; i < tabs.length; ++i)
{
	statusUpdaters.push(new StatusUpdater());
	routingTables.push(new RouteGrid());
}
ciphers = [['default','使用默认'],['none','无']];
for (i = 0; i < vpnciphers.length; ++i) ciphers.push([vpnciphers[i],vpnciphers[i]]);
digests = [['default','Use Default'],['none','None']];
for (i = 0; i < vpndigests.length; ++i) digests.push([vpndigests[i],vpndigests[i]]);

changed = 0;
vpn1up = parseInt('<% psup("vpnclient1"); %>');
vpn2up = parseInt('<% psup("vpnclient2"); %>');

function updateStatus(num) {
	var xob = new XmlHttp();
	xob.onCompleted = function(text, xml) {
		statusUpdaters[num].update(text);
		xob = null;
	}
	xob.onError = function(ex) {
		statusUpdaters[num].errors.innerHTML += 'ERROR! '+ex+'<br />';
		xob = null;
	}

	xob.post('/vpnstatus.cgi', 'client=' + (num+1));
}

function tabSelect(name) {
	tgHideIcons();

	tabHigh(name);

	for (var i = 0; i < tabs.length; ++i)
	{
		var on = (name == tabs[i][0]);
		elem.display(tabs[i][0] + '-tab', on);
	}

	cookie.set('vpn_client_tab', name);
}

function sectSelect(tab, section) {
	tgHideIcons();

	for (var i = 0; i < sections.length; ++i)
	{
		if (section == sections[i][0])
		{
			elem.addClass(tabs[tab][0]+'-'+sections[i][0]+'-tab', 'active');
			elem.display(tabs[tab][0]+'-'+sections[i][0], true);
		}
		else
		{
			elem.removeClass(tabs[tab][0]+'-'+sections[i][0]+'-tab', 'active');
			elem.display(tabs[tab][0]+'-'+sections[i][0], false);
		}
	}

	cookie.set('vpn_client'+tab+'_section', section);
}

function toggle(service, isup) {
	if (changed && !confirm("未保存的更改将丢失。继续?")) return;

	E('_' + service + '_button').disabled = true;
	form.submitHidden('service.cgi', {
		_redirect: 'vpn-client.asp',
		_sleep: '3',
		_service: service + (isup ? '-stop' : '-start')
	});
}

function verifyFields(focused, quiet) {
	tgHideIcons();

	var ret = 1;

	// When settings change, make sure we restart the right client
	if (focused)
	{
		changed = 1;

		var clientindex = focused.name.indexOf("client");
		if (clientindex >= 0)
		{
			var clientnumber = focused.name.substring(clientindex+6,clientindex+7);
			var stripped = focused.name.substring(0,clientindex+6)+focused.name.substring(clientindex+7);

			if (stripped == 'vpn_client_local')
				E('_f_vpn_client'+clientnumber+'_local').value = focused.value;
			else if (stripped == 'f_vpn_client_local')
				E('_vpn_client'+clientnumber+'_local').value = focused.value;

			var fom = E('t_fom');
			if (eval('vpn'+clientnumber+'up') && fom._service.value.indexOf('client'+clientnumber) < 0)
			{
				if ( fom._service.value != "" ) fom._service.value += ",";
				fom._service.value += 'vpnclient'+clientnumber+'-restart';
			}
		}
	}

	// Element varification
	for (i = 0; i < tabs.length; ++i)
	{
		t = tabs[i][0];

		if (!v_range('_vpn_'+t+'_poll', quiet, 0, 1440)) ret = 0;
		if (!v_ip('_vpn_'+t+'_addr', true) && !v_domain('_vpn_'+t+'_addr', true)) { ferror.set(E('_vpn_'+t+'_addr'), "Invalid server address.", quiet); ret = 0; }
		if (!v_port('_vpn_'+t+'_port', quiet)) ret = 0;
		if (!v_ip('_vpn_'+t+'_local', quiet, 1)) ret = 0;
		if (!v_ip('_f_vpn_'+t+'_local', true, 1)) ret = 0;
		if (!v_ip('_vpn_'+t+'_remote', quiet, 1)) ret = 0;
		if (!v_netmask('_vpn_'+t+'_nm', quiet)) ret = 0;
		if (!v_range('_vpn_'+t+'_retry', quiet, -1, 32767)) ret = 0;
		if (!v_range('_vpn_'+t+'_reneg', quiet, -1, 2147483647)) ret = 0;
		if (E('_vpn_'+t+'_gw').value.length > 0 && !v_ip('_vpn_'+t+'_gw', quiet, 1)) ret = 0;
	}

	// Visibility changes
	for (i = 0; i < tabs.length; ++i)
	{
		t = tabs[i][0];

		fw = E('_vpn_'+t+'_firewall').value;
		auth = E('_vpn_'+t+'_crypt').value;
		iface = E('_vpn_'+t+'_if').value;
		bridge = E('_f_vpn_'+t+'_bridge').checked;
		nat = E('_f_vpn_'+t+'_nat').checked;
		hmac = E('_vpn_'+t+'_hmac').value;
		rgw = E('_f_vpn_'+t+'_rgw').checked;
		nopull = E('_f_vpn_'+t+'_nopull').checked;
		noexec = E('_f_vpn_'+t+'_noexec').checked;
		route = E('_f_vpn_'+t+'_route');
		ncp = E('_vpn_'+t+'_ncp_enable').value;

		userauth =  E('_f_vpn_'+t+'_userauth').checked && auth == "tls";
		useronly = userauth && E('_f_vpn_'+t+'_useronly').checked;

		// Page Basic
		elem.display(PR('_f_vpn_'+t+'_userauth'), auth == "tls");
		elem.display(PR('_vpn_'+t+'_username'), PR('_vpn_'+t+'_password'), userauth );
		elem.display(PR('_f_vpn_'+t+'_useronly'), userauth);
		elem.display(E(t+'_ca_warn_text'), useronly);
		elem.display(PR('_vpn_'+t+'_hmac'), auth == "tls");
		elem.display(E(t+'_custom_crypto_text'), auth == "custom");
		elem.display(PR('_f_vpn_'+t+'_bridge'), iface == "tap");
		elem.display(PR('_vpn_'+t+'_br'), iface == "tap" && bridge > 0);
		elem.display(E(t+'_bridge_warn_text'), !bridge);
		elem.display(PR('_f_vpn_'+t+'_nat'), fw != "custom" && (iface == "tun" || !bridge));
		elem.display(E(t+'_nat_warn_text'), fw != "custom" && (!nat || (auth == "secret" && iface == "tun")));
		elem.display(PR('_vpn_'+t+'_local'), iface == "tun" && auth == "secret");
		elem.display(PR('_f_vpn_'+t+'_local'), iface == "tap" && !bridge && auth != "custom");

		// Page Advanced
		elem.display(PR('_vpn_'+t+'_adns'), PR('_vpn_'+t+'_reneg'), auth == "tls");
		elem.display(E(t+'_gateway'), iface == "tap" && rgw > 0);
		elem.display(PR('_f_vpn_'+t+'_nopull'), rgw == 0);
		elem.display(PR('_f_vpn_'+t+'_noexec'), rgw == 0);
		elem.display(PR('_f_vpn_'+t+'_rgw'),nopull == 0 && noexec == 0);
		elem.display(PR('_vpn_'+t+'_cipher'), (ncp != 2));
		elem.display(PR('_vpn_'+t+'_ncp_enable'), (auth == "tls"));
		elem.display(PR('_vpn_'+t+'_ncp_ciphers'), ((ncp > 0) && (auth == "tls")));

		// Page Routing Policy
		elem.display(PR('_f_vpn_'+t+'_route'), iface == "tun");
		elem.display(PR('table_'+t+'_routing'), route.checked);

		// Page Key
		elem.display(PR('_vpn_'+t+'_static'), auth == "secret" || (auth == "tls" && hmac >= 0));
		elem.display(PR('_vpn_'+t+'_ca'), auth == "tls");
		elem.display(PR('_vpn_'+t+'_crt'), PR('_vpn_'+t+'_key'), auth == "tls" && !useronly);
		elem.display(PR('_f_vpn_'+t+'_tlsremote'), auth == "tls");
		elem.display(E(t+'_cn'), auth == "tls" && E('_f_vpn_'+t+'_tlsremote').checked);

		keyHelp = E(t+'-keyhelp');
		switch (auth)
		{
		case "tls":
			keyHelp.href = helpURL['TLSKeys'];
			break;
		case "secret":
			keyHelp.href = helpURL['staticKeys'];
			break;
		default:
			keyHelp.href = helpURL['howto'];
			break;
		}
		E('_vpn_'+t+'_ncp_ciphers').disabled = true;
	}

	var bridge1 = E('_vpn_client1_br');
	if(nvram.lan_ifname.length < 1)
		bridge1.options[0].disabled=true;
	if(nvram.lan1_ifname.length < 1)
		bridge1.options[1].disabled=true;
	if(nvram.lan2_ifname.length < 1)
		bridge1.options[2].disabled=true;
	if(nvram.lan3_ifname.length < 1)
		bridge1.options[3].disabled=true;

	var bridge2 = E('_vpn_client2_br');
	if(nvram.lan_ifname.length < 1)
		bridge2.options[0].disabled=true;
	if(nvram.lan1_ifname.length < 1)
		bridge2.options[1].disabled=true;
	if(nvram.lan2_ifname.length < 1)
		bridge2.options[2].disabled=true;
	if(nvram.lan3_ifname.length < 1)
		bridge2.options[3].disabled=true;

	return ret;
}

RouteGrid.prototype.verifyFields = function(row, quiet) {
	var ret = 1;
	var fom = E('t_fom');
	var clientnum = 1;
	for (i = 0; i < tabs.length; ++i)
	{
		if (routingTables[i] == this)
		{
			clientnum = i+1;
			if (eval('vpn'+(i+1)+'up') && fom._service.value.indexOf('client'+(i+1)) < 0)
			{
				if ( fom._service.value != "" )
					fom._service.value += ",";
				fom._service.value += 'vpnclient'+(i+1)+'-restart';
			}
		}
	}
	var f = fields.getAll(row);

	// Verify fields in this row of the table
	if (f[2].value == "" ) { ferror.set(f[2], "Value is mandatory.", quiet); ret = 0; }
	if (f[2].value.indexOf('>') >= 0 || f[2].value.indexOf('<') >= 0) { ferror.set(f[2], "不能包含 '<' 或 '>' 字符.", quiet); ret = 0; }
	if (f[2].value.indexOf(' ') >= 0 || f[2].value.indexOf(',') >= 0) { ferror.set(f[2], "不能包含 '空格' 或 ',' 字符. 一次只能输入一个IP或域名.", quiet); ret = 0; }
	if (f[2].value.indexOf(' ') >= 0) { ferror.set(f[2], "不能包含 '-' 字符. IP范围不支持.", quiet); ret = 0; }
	return ret;
}
RouteGrid.prototype.fieldValuesToData = function(row) {
	var f = fields.getAll(row);
	return [f[0].checked?1:0, f[1].value, f[2].value];
}
RouteGrid.prototype.dataToView = function(data) {
	var temp = ['<input type=\'checkbox\' style="opacity:1" disabled'+(data[0]!=0?' checked':'')+'>',
	            ['From Source IP', 'To Destination IP', 'To Domain'][data[1] - 1],
	            data[2]
                ];
	var v = [];
	for (var i = 0; i < temp.length; ++i){
		v.push(i==0?temp[i]:escapeHTML('' + temp[i]));
	}
	return v;
}
RouteGrid.prototype.dataToFieldValues = function(data) {
	return [data[0] == 1, data[1], data[2]];
}

function save() {
	if (!verifyFields(null, false)) return;

	var fom = E('t_fom');

	E('vpn_client_eas').value = '';

	for (i = 0; i < tabs.length; ++i)
	{
		if (routingTables[i].isEditing()) return;

		t = tabs[i][0];

		if ( E('_f_vpn_'+t+'_eas').checked )
			E('vpn_client_eas').value += ''+(i+1)+',';

		var routedata = routingTables[i].getAllData();
		var routing = '';
		for (j = 0; j < routedata.length; ++j)
			routing += routedata[j].join('<') + '>';

		E('vpn_'+t+'_bridge').value = E('_f_vpn_'+t+'_bridge').checked ? 1 : 0;
		E('vpn_'+t+'_nat').value = E('_f_vpn_'+t+'_nat').checked ? 1 : 0;
		E('vpn_'+t+'_rgw').value = E('_f_vpn_'+t+'_rgw').checked ? 1 : 0;
		E('vpn_'+t+'_userauth').value = E('_f_vpn_'+t+'_userauth').checked ? 1 : 0;
		E('vpn_'+t+'_useronly').value = E('_f_vpn_'+t+'_useronly').checked ? 1 : 0;
		E('vpn_'+t+'_tlsremote').value = E('_f_vpn_'+t+'_tlsremote').checked ? 1 : 0;
		E('vpn_'+t+'_nopull').value = E('_f_vpn_'+t+'_nopull').checked ? 1 : 0;
		E('vpn_'+t+'_noexec').value = E('_f_vpn_'+t+'_noexec').checked ? 1 : 0;
		E('vpn_'+t+'_route').value = E('_f_vpn_'+t+'_route').checked ? 1 : 0;
		E('vpn_'+t+'_routing_val').value = routing;
	}

	form.submit(fom, 1);

	changed = 0;
}

function init() {
	tabSelect(cookie.get('vpn_client_tab') || tabs[0][0]);

 	for (i = 0; i < tabs.length; ++i)
	{
		sectSelect(i, cookie.get('vpn_client'+i+'_section') || sections[i][0]);

		t = tabs[i][0];

		routingTables[i].init('table_' + t + '_routing','sort', 0,[
			{ type: 'checkbox' },
			{ type: 'select', options: [[1, '从源IP'],[2, '到目标IP'],[3,'到域名']] },
			{ type: 'text', maxlen: 30 }]);
		routingTables[i].headerSet(['Enable', 'Type', 'Value']);
		var routingVal = eval('nvram.vpn_' + t + '_routing_val');
		if(routingVal.length) {
			var s = routingVal.split('>');
			for (var j = 0; j < s.length; ++j)
			{
				if (!s[j].length) continue;
				var row = s[j].split('<');
				if (row.length == 3)
					routingTables[i].insertData(-1, row);
			}
		}
		routingTables[i].showNewEditor();
		routingTables[i].resetNewEditor();

		statusUpdaters[i].init(null,null,t+'-status-stats-table',t+'-status-time',t+'-status-content',t+'-no-status',t+'-status-errors');
		updateStatus(i);
	}

	verifyFields(null, true);
}
</script>

<style type="text/css">
textarea {
	width: 98%;
	height: 10em;
}
p.keyhelp
{
	font-size: smaller;
	font-style: italic;
}
div.status-header p
{
	font-weight: bold;
	padding-bottom: 4px;
}
table.status-table
{
	width: auto;
	margin-left: auto;
	margin-right: auto;
	text-align: center;
}
</style>

</head>
<body>
<form id="t_fom" method="post" action="tomato.cgi">
<table id="container" cellspacing="0">
<tr><td colspan="2" id="header">
	<div class="title">Tomato</div>
	<div class="version">Version <% version(); %></div>
</td></tr>
<tr id="body"><td id="navi"><script type="text/javascript">navi()</script></td>
<td id="content">
<div id="ident"><% ident(); %></div>

<input type="hidden" name="_nextpage" value="vpn-client.asp">
<input type="hidden" name="_nextwait" value="5">
<input type="hidden" name="_service" value="">
<input type="hidden" name="vpn_client_eas" id="vpn_client_eas" value="">

<div class="section-title">OpenVPN 客户端设置</div>
<div class="section">
<script type="text/javascript">
tabCreate.apply(this, tabs);

for (i = 0; i < tabs.length; ++i)
{
	t = tabs[i][0];
	W('<div id=\''+t+'-tab\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_bridge\' name=\'vpn_'+t+'_bridge\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_nat\' name=\'vpn_'+t+'_nat\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_rgw\' name=\'vpn_'+t+'_rgw\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_userauth\' name=\'vpn_'+t+'_userauth\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_useronly\' name=\'vpn_'+t+'_useronly\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_tlsremote\' name=\'vpn_'+t+'_tlsremote\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_nopull\' name=\'vpn_'+t+'_nopull\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_noexec\' name=\'vpn_'+t+'_noexec\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_route\' name=\'vpn_'+t+'_route\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_routing_val\' name=\'vpn_'+t+'_routing_val\'>');

	W('<ul class="tabs">');
	for (j = 0; j < sections.length; j++)
	{
		W('<li><a href="javascript:sectSelect('+i+',\''+sections[j][0]+'\')" id="'+t+'-'+sections[j][0]+'-tab">'+sections[j][1]+'<\/a><\/li>');
	}
	W('<\/ul><div class=\'tabs-bottom\'><\/div>');

	W('<div id=\''+t+'-basic\'>');
	createFieldTable('', [
		{ title: '同WAN一起启动', name: 'f_vpn_'+t+'_eas', type: 'checkbox', value: nvram.vpn_client_eas.indexOf(''+(i+1)) >= 0 },
		{ title: '接口类型', name: 'vpn_'+t+'_if', type: 'select', options: [ ['tap','TAP'], ['tun','TUN'] ], value: eval( 'nvram.vpn_'+t+'_if' ) },
		{ title: '桥接TAP与', indent: 2, name: 'vpn_'+t+'_br', type: 'select', options: [
			['br0','LAN (br0)*'],
			['br1','LAN1 (br1)'],
			['br2','LAN2 (br2)'],
			['br3','LAN3 (br3)']
			], value: eval ( 'nvram.vpn_'+t+'_br' ), suffix: ' <small>* default<\/small> ' },
		{ title: '协议', name: 'vpn_'+t+'_proto', type: 'select', options: [ ['udp','UDP'], ['tcp-client','TCP'] ], value: eval( 'nvram.vpn_'+t+'_proto' ) },
		{ title: '服务器地址/端口', multi: [
			{ name: 'vpn_'+t+'_addr', type: 'text', maxlen: 40, size: 17, value: eval( 'nvram.vpn_'+t+'_addr' ) },
			{ name: 'vpn_'+t+'_port', type: 'text', maxlen: 5, size: 7, value: eval( 'nvram.vpn_'+t+'_port' ) } ] },
		{ title: '防火墙', name: 'vpn_'+t+'_firewall', type: 'select', options: [ ['auto', '自动'], ['custom', '自定义'] ], value: eval( 'nvram.vpn_'+t+'_firewall' ) },
		{ title: '授权模式', name: 'vpn_'+t+'_crypt', type: 'select', options: [ ['tls', 'TLS'], ['secret', '静态密钥'], ['custom', '自定义'] ], value: eval( 'nvram.vpn_'+t+'_crypt' ),
			suffix: '<span id=\''+t+'_custom_crypto_text\'>&nbsp;<small>(必须手动配置...)<\/small><\/span>' },
		{ title: '用户名/密码认证', name: 'f_vpn_'+t+'_userauth', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_userauth' ) != 0 },
		{ title: '用户名: ', indent: 2, name: 'vpn_'+t+'_username', type: 'text', maxlen: 50, size: 54, value: eval( 'nvram.vpn_'+t+'_username' ) },
		{ title: '密码: ', indent: 2, name: 'vpn_'+t+'_password', type: 'password', maxlen: 50, size: 54, value: eval( 'nvram.vpn_'+t+'_password' ) },
		{ title: '仅通过用户名认证', indent: 2, name: 'f_vpn_'+t+'_useronly', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_useronly' ) != 0,
			suffix: '<span style="color: red" id=\''+t+'_ca_warn_text\'>&nbsp<small>警告：必须指定证书颁发机构.<\/small><\/span>' },
		{ title: 'HMAC授权(TLS认证)', name: 'vpn_'+t+'_hmac', type: 'select', options: [ [-1, '关闭'], [2, '双向'], [0, '流入 (0)'], [1, '输出 (1)'] ], value: eval( 'nvram.vpn_'+t+'_hmac' ) },
		{ title: 'Auth digest', name: 'vpn_'+t+'_digest', type: 'select', options: digests, value: eval( 'nvram.vpn_'+t+'_digest' ) },
		{ title: '服务器在同一子网', name: 'f_vpn_'+t+'_bridge', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_bridge' ) != 0,
			suffix: '<span style="color: red" id=\''+t+'_bridge_warn_text\'>&nbsp<small>警告：无法桥接特定的子网。正在设置为默认路由模式.<\/small><\/span>' },
		{ title: '创建隧道NAT', name: 'f_vpn_'+t+'_nat', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_nat' ) != 0,
			suffix: '<span style="font-style: italic" id=\''+t+'_nat_warn_text\'>&nbsp<small>必须手动配置路由.<\/small><\/span>' },
		{ title: '本地/远程端点地址', multi: [
			{ name: 'vpn_'+t+'_local', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_local' ) },
			{ name: 'vpn_'+t+'_remote', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_remote' ) } ] },
		{ title: '隧道地址/子网', multi: [
			{ name: 'f_vpn_'+t+'_local', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_local' ) },
			{ name: 'vpn_'+t+'_nm', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_nm' ) } ] }
	]);
	W('<\/div>');
	W('<div id=\''+t+'-advanced\'>');
	createFieldTable('', [
		{ title: 'Poll Interval', name: 'vpn_'+t+'_poll', type: 'text', maxlen: 4, size: 5, value: eval( 'nvram.vpn_'+t+'_poll' ), suffix: '&nbsp;<small>(单位分, 0为禁用)<\/small>' }, 
		{ title: '重定向 Internet 流量', multi: [
			{ name: 'f_vpn_'+t+'_rgw', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_rgw' ) != 0 },
			{ name: 'vpn_'+t+'_gw', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_gw' ), prefix: '<span id=\''+t+'_gateway\'> Gateway:&nbsp', suffix: '<\/span>'} ] },
		{ title: '忽略重定向网关 (route-nopull)', name: 'f_vpn_'+t+'_nopull', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_nopull' ) != 0 },
		{ title: '忽略重定向网关 (route-noexec)', name: 'f_vpn_'+t+'_noexec', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_noexec' ) != 0 },
		{ title: '加密算法', name: 'vpn_'+t+'_cipher', type: 'select', options: ciphers, value: eval( 'nvram.vpn_'+t+'_cipher' ) },
		{ title: 'Cipher Negotiation', name: 'vpn_'+t+'_ncp_enable', type: 'select', options: [[0, 'Disabled'],[1, 'Enabled (with fallback)'],[2, 'Enabled']], value: eval( 'nvram.vpn_'+t+'_ncp_enable' ) },
		{ title: 'Negotiable ciphers', name: 'vpn_'+t+'_ncp_ciphers', type: 'text', size: 50, maxlen: 50, value: eval ( 'nvram.vpn_'+t+'_ncp_ciphers' ) },
		{ title: 'Legacy/fallback cipher', name: 'vpn_'+t+'_cipher', type: 'select', options: ciphers, value: eval( 'nvram.vpn_'+t+'_cipher' ) },
		{ title: '压缩', name: 'vpn_'+t+'_comp', type: 'select', options: [ ['-1', '关闭'], ['no', 'None'], ['yes', 'LZO'], ['adaptive', 'LZO Adaptive'], ['lz4', 'LZ4'], ['lz4-v2', 'LZ4-V2']], value: eval( 'nvram.vpn_'+t+'_comp' ) },
		{ title: 'TLS 重新协商时间', name: 'vpn_'+t+'_reneg', type: 'text', maxlen: 10, size: 7, value: eval( 'nvram.vpn_'+t+'_reneg' ),
			suffix: '&nbsp;<small>(单位秒, -1代表默认值)<\/small>' },
		{ title: '连接重试', name: 'vpn_'+t+'_retry', type: 'text', maxlen: 5, size: 7, value: eval( 'nvram.vpn_'+t+'_retry' ),
			suffix: '&nbsp;<small>(单位秒; -1代表无限)<\/small>' },
		{ title: '验证服务器证书 (remote-cert-tls)', multi: [
			{ name: 'f_vpn_'+t+'_tlsremote', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_tlsremote' ) != 0 },
			{ name: 'vpn_'+t+'_cn', type: 'text', maxlen: 64, size: 54,
				value: eval( 'nvram.vpn_'+t+'_cn' ), prefix: '<span id=\''+t+'_cn\'> Common Name:&nbsp', suffix: '<\/span>'} ] },
		{ title: '自定义配置', name: 'vpn_'+t+'_custom', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_custom' ) }
	]);
	W('<\/div>');
	W('<div id=\''+t+'-policy\'>');
	createFieldTable('', [
		{ title: '通过VPN重定向', name: 'f_vpn_'+t+'_route', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_route' ) != 0 },
		{ title: '', suffix: '<div class="tomato-grid" id="table_'+t+'_routing"><\/div>' }
	]);
	    W('<div>');
		W('<ul>');
		W('<li><b>类型 -> 从源IP<\/b> - 例: "1.2.3.4" or "1.2.3.0/24".');
		W('<li><b>类型 -> 到目的IP<\/b> - 例: "1.2.3.4" or "1.2.3.0/24".');
		W('<li><b>类型 -> 到域名<\/b> - 例: "domain.com". 一行输入一个域名');
		W('<\/ul>');
	    W('<\/div>');
		W('<\/div>');
		W('<div id=\''+t+'-keys\'>');
		W('<p class=\'keyhelp\'>关于密钥生成的帮助, 请查看 OpenVPN 的 <a id=\''+t+'-keyhelp\'>教程</a>.<\/p>');
	createFieldTable('', [
		{ title: '静态密钥', name: 'vpn_'+t+'_static', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_static' ) },
		{ title: '证书颁发机构', name: 'vpn_'+t+'_ca', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_ca' ) },
		{ title: '客户端证书', name: 'vpn_'+t+'_crt', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_crt' ) },
		{ title: '客户端密钥', name: 'vpn_'+t+'_key', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_key' ) },
	]);
		W('<\/div>');
		W('<div id=\''+t+'-status\'>');
		W('<div id=\''+t+'-no-status\'><p>客户端未运行或状态无法读取.<\/p><\/div>');
		W('<div id=\''+t+'-status-content\' style=\'display:none\' class=\'status-content\'>');
		W('<div id=\''+t+'-status-header\' class=\'status-header\'><p>当前数据 <span id=\''+t+'-status-time\'><\/span>.<\/p><\/div>');
		W('<div id=\''+t+'-status-stats\'><div class=\'section-title\'>综合统计<\/div><div class="tomato-grid status-table" id="'+t+'-status-stats-table"><\/div><br /><\/div>');
		W('<div id=\''+t+'-status-errors\' class=\'error\'><\/div>');
		W('<\/div>');
		W('<div style=\'text-align:right\'><a href=\'javascript:updateStatus('+i+')\'>刷新状态<\/a><\/div>');
		W('<\/div>');
		W('<input type="button" value="' + (eval('vpn'+(i+1)+'up') ? '停止' : '启动') + ' Now" onclick="toggle(\'vpn'+t+'\', vpn'+(i+1)+'up)" id="_vpn'+t+'_button">');
		W('<\/div>');
}

</script>
</div>

</td></tr>
	<tr><td id="footer" colspan="2">
	<span id="footer-msg"></span>
	<input type="button" value="保存设置" id="save-button" onclick="save()">
	<input type="button" value="取消设置" id="cancel-button" onclick="reloadPage();">
</td></tr>
</table>
</form>
<script type="text/javascript">init();</script>
</body>
</html>