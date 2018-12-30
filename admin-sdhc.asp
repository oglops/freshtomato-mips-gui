<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<!--
	Tomato GUI
	Copyright (C) 2006-2007 Jonathan Zarate
	http://www.polarcloud.com/tomato/
	For use with Tomato Firmware only.
	No part of this file may be used without permission.
	MMC admin module by Augusto Bott
	Modified by Tomasz S這dkowicz for SDHC/MMC driver v2.0.1
-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] 系统管理: SDHC/MMC</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<script type="text/javascript" src="tomato.js"></script>

<!-- / / / -->

<script type="text/javascript" src="debug.js"></script>

<script type="text/javascript">

//	<% nvram("mmc_on,mmc_fs_partition,mmc_fs_type,mmc_exec_mount,mmc_exec_umount,mmc_cs,mmc_clk,mmc_din,mmc_dout"); %>

var mmc_once_enabled = nvram.mmc_on;

function verifyFields(focused, quiet) {
	var a = (E('_f_show_info').checked ? '' : 'none');
	var b = !E('_f_mmc_on').checked;
	var c, cs, cl, di, du, e;
	switch (E('_f_mmc_model').value) {
		case '2' :
			E('_f_mmc_cs').value = '7';
			E('_f_mmc_clk').value = '3';
			E('_f_mmc_din').value = '5';
			E('_f_mmc_dout').value = '4';
			c=1;
			break;
		case '3' :
		case '4' :
			E('_f_mmc_cs').value = '7';
			E('_f_mmc_clk').value = '3';
			E('_f_mmc_din').value = '2';
			E('_f_mmc_dout').value = '4';
			c=1;
			break;
		default :
			cs = E('_f_mmc_cs').value;
			cl = E('_f_mmc_clk').value;
			di = E('_f_mmc_din').value;
			du = E('_f_mmc_dout').value;
			e=0;
	}
	E('_f_mmc_model').disabled = b;
	E('_f_mmc_cs').disabled = b || c;
	E('_f_mmc_clk').disabled = b || c;
	E('_f_mmc_din').disabled = b || c;
	E('_f_mmc_dout').disabled = b || c;
	E('_f_mmc_fs_partition').disabled = b;
	E('_f_mmc_fs_type').disabled = b;
	E('_f_mmc_exec_mount').disabled = b;
	E('_f_mmc_exec_umount').disabled = b;
	E('i1').style.display = a;
	E('i2').style.display = a;
	E('i3').style.display = a;
	E('i4').style.display = a;
	E('i5').style.display = a;
	E('i6').style.display = a;
	E('i7').style.display = a;
	E('i8').style.display = a;
	E('i9').style.display = a;
	E('i10').style.display = a;
	ferror.clear('_f_mmc_cs');
	ferror.clear('_f_mmc_clk');
	ferror.clear('_f_mmc_din');
	ferror.clear('_f_mmc_dout');
	if (!c) {
	if (!cmpInt(cs,cl)) {
		ferror.set('_f_mmc_cs', 'GPIO 必须是唯一的', quiet);
		ferror.set('_f_mmc_clk', 'GPIO 必须是唯一的', quiet);
		e = 1;
	}
	if (!cmpInt(cs,di)) {
		ferror.set('_f_mmc_cs', 'GPIO 必须是唯一的', quiet);
		ferror.set('_f_mmc_din', 'GPIO 必须是唯一的', quiet);
		e = 1;
	}
	if (!cmpInt(cs,du)) {
		ferror.set('_f_mmc_cs', 'GPIO 必须是唯一的', quiet);
		ferror.set('_f_mmc_dout', 'GPIO 必须是唯一的', quiet);
		e = 1;
	}
	if (!cmpInt(cl,di)) {
		ferror.set('_f_mmc_clk', 'GPIO 必须是唯一的', quiet);
		ferror.set('_f_mmc_din', 'GPIO 必须是唯一的', quiet);
		e = 1;
	}
	if (!cmpInt(cl,du)) {
		ferror.set('_f_mmc_clk', 'GPIO 必须是唯一的', quiet);
		ferror.set('_f_mmc_dout', 'GPIO 必须是唯一的', quiet);
		e = 1;
	}
	if (!cmpInt(di,du)) {
		ferror.set('_f_mmc_din', 'GPIO 必须是唯一的', quiet);
		ferror.set('_f_mmc_dout', 'GPIO 必须是唯一的', quiet);
		e = 1;
	}
	if (e) return 0;
	}
	return 1;
}

function save() {
	if (!verifyFields(null, 0)) return;
	var fom = E('_fom');
	var on = E('_f_mmc_on').checked ? 1 : 0;
	fom.mmc_on.value = on;
	fom.mmc_cs.value = fom.f_mmc_cs.value;
	fom.mmc_clk.value = fom.f_mmc_clk.value;
	fom.mmc_din.value = fom.f_mmc_din.value;
	fom.mmc_dout.value = fom.f_mmc_dout.value;
	fom.mmc_fs_partition.value = fom.f_mmc_fs_partition.value;
	fom.mmc_fs_type.value = fom.f_mmc_fs_type.value;
	fom.mmc_exec_mount.value = fom.f_mmc_exec_mount.value;
	fom.mmc_exec_umount.value = fom.f_mmc_exec_umount.value;
	form.submit(fom, 1);
}

function submit_complete() {
	reloadPage();
}
</script>

</head>
<body>
<form id="_fom" method="post" action="tomato.cgi">
<table id="container" cellspacing="0">
<tr><td colspan="2" id="header">
	<div class="title">Tomato</div>
	<div class="version">Version <% version(); %></div>
</td></tr>
<tr id="body"><td id="navi"><script type="text/javascript">navi()</script></td>
<td id="content">
<div id="ident"><% ident(); %></div>

<!-- / / / -->

<input type="hidden" name="_nextpage" value="admin-sdhc.asp">
<input type="hidden" name="_nextwait" value="10">
<input type="hidden" name="_service" value="mmc-restart">
<input type="hidden" name="_commit" value="1">

<input type="hidden" name="mmc_on">
<input type="hidden" name="mmc_cs">
<input type="hidden" name="mmc_clk">
<input type="hidden" name="mmc_din">
<input type="hidden" name="mmc_dout">
<input type="hidden" name="mmc_fs_partition">
<input type="hidden" name="mmc_fs_type">
<input type="hidden" name="mmc_exec_mount">
<input type="hidden" name="mmc_exec_umount">

<div class="section-title">SDHC/MMC 设置</div>
<div class="section">
<script type="text/javascript">
//	<% statfs("/mmc", "mmc"); %>
//	<% mmcid(); %>
mmcon = (nvram.mmc_on == 1);
createFieldTable('', [
	{ title: '启用', name: 'f_mmc_on', type: 'checkbox', value: mmcon },
	{ text: 'GPIO 引脚配置' },
	{ title: '路由器型号', name: 'f_mmc_model', type: 'select', options: [[1,'自定义'],[2,'WRT54G up to v3.1'],[3,'WRT54G v4.0 and later'],[4,'WRT54GL']], value: 1 },
		{ title: '芯片选择 (CS)', indent: 2, name: 'f_mmc_cs', type: 'select', options: [[1,1],[2,2],[3,3],[4,4],[5,5],[6,6],[7,7]], value: nvram.mmc_cs },
		{ title: '时钟 (CLK)', indent: 2, name: 'f_mmc_clk', type: 'select', options: [[1,1],[2,2],[3,3],[4,4],[5,5],[6,6],[7,7]], value: nvram.mmc_clk },
		{ title: '数据输入 (DI)', indent: 2, name: 'f_mmc_din', type: 'select', options: [[1,1],[2,2],[3,3],[4,4],[5,5],[6,6],[7,7]], value: nvram.mmc_din },
		{ title: '数据输出 (DO)', indent: 2, name: 'f_mmc_dout', type: 'select', options: [[1,1],[2,2],[3,3],[4,4],[5,5],[6,6],[7,7]], value: nvram.mmc_dout },
		null,
	{ text: '分区挂载' },
		{ title: '分区号', indent: 2, name: 'f_mmc_fs_partition', type: 'select', options: [[1,1],[2,2],[3,3],[4,4]], value: nvram.mmc_fs_partition },
		{ title: '文件系统', indent: 2, name: 'f_mmc_fs_type', type: 'select', options: [['ext2','ext2'],['ext3','ext3'],['vfat','vfat']], value: nvram.mmc_fs_type },
		{ title: '挂载后执行', indent: 2, name: 'f_mmc_exec_mount', type: 'text', maxlen: 64, size: 34, value: nvram.mmc_exec_mount },
		{ title: '在卸载之前执行', indent: 2, name: 'f_mmc_exec_umount', type: 'text', maxlen: 64, size: 34, value: nvram.mmc_exec_umount },
		{ title: '总容量/可用容量', indent: 2, text: (scaleSize(mmc.size) + ' / ' + scaleSize(mmc.free) + ' <small>(' + (mmc.free/mmc.size*100).toFixed(2) + '%)<\/small>'), hidden: !mmc.size },
		null,
	{ title: '卡信息', name: 'f_show_info', type: 'checkbox', value: 0, hidden: !mmcid.type },
		{ title: '卡类型', indent: 2, rid: 'i1', text: mmcid.type },
		{ title: '规格版本', indent: 2, rid: 'i2', text: mmcid.spec },
		{ title: '卡大小', indent: 2, rid: 'i3', text: (scaleSize(mmcid.size)) },
		{ title: '电压范围', indent: 2, rid: 'i4', text: mmcid.volt },
		{ title: '制造 ID', indent: 2, rid: 'i5', text: mmcid.manuf },
		{ title: '应用 ID', indent: 2, rid: 'i6', text: mmcid.appl },
		{ title: '产品名称', indent: 2, rid: 'i7', text: mmcid.prod },
		{ title: '修订', indent: 2, rid: 'i8', text: mmcid.rev },
		{ title: '序列号', indent: 2, rid: 'i9', text: mmcid.serial },
		{ title: '生产日期', indent: 2, rid: 'i10', text: mmcid.date }
]);
</script>
</div>

<script type="text/javascript">show_notice1('<% notice("mmc"); %>');</script>

<!-- / / / -->

</td></tr>
<tr><td id="footer" colspan="2">
	<span id="footer-msg"></span>
	<input type="button" value="保存设置" id="save-button" onclick="save()">
	<input type="button" value="取消设置" id="cancel-button" onclick="reloadPage();">
</td></tr>
</table>
</form>
<script type="text/javascript">verifyFields(null, 1);</script>
</body>
</html>