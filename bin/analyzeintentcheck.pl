#!/usr/bin/perl

$intentfile = "intentpermission";
$intent2file = "intentwithdynamicpermission";
$intentcheckfile = "intentcheck";

%intentperm = ();

open FILE, "<$intentfile" or die $!;
while (<FILE>) {
	chomp($_);
	@tok = split(/ /, $_);
	$action = $tok[0];
	$perm = $tok[1];
	$mode = $tok[2];
	if (defined $intentperm{$action}) {
		$intentperm{$action}[0]++;
	} else {
		push(@{$intentperm{$action}}, 1);
	}
	push(@{$intentperm{$action}}, $perm);
	push(@{$intentperm{$action}}, $mode);
}
close FILE;
open FILE, "<$intent2file" or die $!;
while (<FILE>) {
	chomp($_);
	@tok = split(/ /, $_);
	$action = $tok[0];
	$perm = $tok[1];
	$mode = $tok[2];
	if (defined $intentperm{$action}) {
		$intentperm{$action}[0]++;
	} else {
		push(@{$intentperm{$action}}, 1);
	}
	push(@{$intentperm{$action}}, $perm);
	push(@{$intentperm{$action}}, $mode);
}
close FILE;

#<android.bluetooth.BluetoothDeviceProfileState: void sendConnectionAccessIntent()>;"android.bluetooth.device.action.CONNECTION_ACCESS_REQUEST";<android.content.Context: void sendBroadcast(android.content.Intent,java.lang.String)>

%permission = ();
open FILE, "<$intentcheckfile" or die $!;
while (<FILE>) {
	chomp($_);
	@tok = split(/;/, $_);
	$method = $tok[0];
	$actions = $tok[1];
	
	$invoke = $tok[2];
	@invokemethod = split(/ /, $invoke);
	
	$actions =~ s/\"//g;
	@action = split(/,/, $actions);
	
	foreach $a (@action) {
		$num = $intentperm{$a}[0];
		$i = 0;		
		while ($i < $num) {			
			$perm = $intentperm{$a}[2*$i+1];
			$mode = $intentperm{$a}[2*$i+2];
	
			if ($mode eq "S" && ($invokemethod[2] =~ m/dispatch/i || $invokemethod[2] =~ m/broadcast/i || $invokemethod[2] =~ m/send/i
				|| $invokemethod[2] =~ m/startActivity/ || $invokemethod[2] =~ m/bindService/)) {
				#print "$mode $a\n$perm\n$method\n".$invokemethod[2]."\n\n";
				$permission{$perm}{$method} = 1;
			} elsif ($mode eq "R" && $invokemethod[2] =~ m/receive/i) {
				#print "$mode $a\n$perm\n$method\n".$invokemethod[2]."\n\n";
				$permission{$perm}{$method} = 1;
			}
			$i++;
		}
	}
}
close FILE;

foreach $p (keys %permission) {
	print "PERMISSION:$p\n";
	print "$_\n" foreach (keys %{$permission{$p}});
}
