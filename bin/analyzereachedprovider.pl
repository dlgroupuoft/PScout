#!/usr/bin/perl

$providerauthfile = "providerauth";
$reachedfile = "permissionreachedprovider";

#PROVIDER:com.android.cts.verifier.TestResultsProvider;AUTH:com.android.cts.verifier.testresultsprovider

%providerauth = ();
open FILE, "<$providerauthfile" or die $!;
while (<FILE>) {
	chomp($_);
	if ($_ =~ m/^PROVIDER:(.*);AUTH:(.*)/) {
		$providerauth{$1}{$2} = 1;
	}
}
close FILE;

#com.android.providers.telephony.MmsSmsProvider;android.permission.READ_SMS;<com.android.providers.telephony.MmsSmsProvider: android.database.Cursor query(android.net.Uri,java.lang.String[],java.lang.String,java.lang.String[],java.lang.String)>

#content://mms-sms R android.permission.READ_SMS

%results = ();

open FILE, "<$reachedfile" or die $!;
while (<FILE>) {
	chomp($_);
	@tok = split(/;/, $_);
	$class = $tok[0];
	$perm = $tok[1];
	$method = $tok[2];
	@parts = split(/ /, $method);
	
	foreach $a (keys %{$providerauth{$class}}) {
		$mode = "?";
		if ($parts[2] =~ m/insert/i || $parts[2] =~ m/delete/i || $parts[2] =~ m/update/i || $parts[2] =~ m/bulkInsert/i) {
			$mode = "W";
		} elsif ($parts[2] =~ m/query/i) {
			$mode = "R";
		}
		if ($mode eq "?") {
			#what are these??
			#$results{"content://$a $mode $perm\n$method\n"} = 1;
		} else {
			$results{"content://$a $mode $perm"} = 1;
		}
	}
}
close FILE;

print $_."\n" foreach (keys %results);
