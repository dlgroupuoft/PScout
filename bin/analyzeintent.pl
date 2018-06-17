#!/usr/bin/perl

$intentfile = "intent";

%methodactionhash = (
	"<com.android.settings.bluetooth.BluetoothPermissionRequest: void sendIntentToReceiver(java.lang.String,boolean,java.lang.String,boolean)>", 
	"android.bluetooth.device.action.CONNECTION_ACCESS_REPLY",
	"<com.android.settings.bluetooth.BluetoothPermissionActivity: void sendIntentToReceiver(java.lang.String,boolean,java.lang.String,boolean)>",
	"android.bluetooth.device.action.CONNECTION_ACCESS_REPLY",
);
%methodmodehash = (
	"<com.android.settings.bluetooth.BluetoothPermissionRequest: void sendIntentToReceiver(java.lang.String,boolean,java.lang.String,boolean)>", 
	"R",
	"<com.android.settings.bluetooth.BluetoothPermissionActivity: void sendIntentToReceiver(java.lang.String,boolean,java.lang.String,boolean)>",
	"R",
);

open FILE, "<$intentfile" or die $!;
while (<FILE>) {
	chomp($_);
	if ($_ =~ m/!!!/) {
		$line = $_;
		$line =~ s/!!!//;
		@tok = split(/ /, $line);
		$action = $tok[0];
		$perm = $tok[1];
		$method = $tok[4];
		
		next if ($action eq "undefined");
		
		if (length($action) < 5) {
			$line =~ m/<(.*)>/;
			$method = "<$1>";
						
			if (defined $methodactionhash{$method}) {
				print $methodactionhash{$method}." $perm ".$methodmodehash{$method}."\n";
			} else {
				print "???$line\n";			
			}
		} else {
			$action = substr($action, 1, length($action)-2);
			if ($method =~ m/dispatch/i || $method =~ m/broadcast/i || $method =~ m/send/i) {
				print "$action $perm R\n";
			} elsif ($method =~ m/receive/i) {
				print "$action $perm $method\n";
			} else {
				#send of receive ????
				print "???$line\n";
			}
		}
	} else {
		print "$_\n" if ($_ !~ m/---/);
	}
}
close FILE;
