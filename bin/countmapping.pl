#!/usr/bin/perl

#Permission:android.permission.CHANGE_WIFI_STATE
#643 Callers:

%mapcount = ();
$currentperm = "";
open FILE, "<pcm" or die $!;
while (<FILE>) {
	chomp($_);
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^([^\s]*) Callers:/) {
		$mapcount{$currentperm} = $1;
	}
}
close FILE;

foreach $k (keys %mapcount) {
	$l = $k;
	$l =~ s/=/\t/;
	print "$l\t".$mapcount{$k}."\n";
}
