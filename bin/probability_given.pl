#!/usr/bin/perl

#Permission:android.permission.CHANGE_WIFI_STATE
#15 Callers:

%pmapping = ();

open FILE, "<honeycomb/API" or die $!;
$currentperm = "";
while (<FILE>) {
	chomp($_);
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/ Callers:$/) {
	} elsif ($_ =~ m/^</) {
		$pmapping{$currentperm}{$_} = 1;
	}
}
close FILE;

@perm = sort keys %pmapping;

foreach $i (@perm) {
	foreach $j (@perm) {
		next if ($i eq $j);
		
		$totali = 0;
		$counti = 0;
		foreach $k (keys %{$pmapping{$i}}) {
			$totali++;
			$counti++ if (exists $pmapping{$j}{$k} && $pmapping{$j}{$k} == 1);
		}
		
		$totalj = 0;
		$countj = 0; 
		foreach $k (keys %{$pmapping{$j}}) {
			$totalj++;
			$countj++ if (exists $pmapping{$i}{$k} && $pmapping{$i}{$k} == 1);
		}
		
		$i =~ /^.*\.([^\.]*)$/;
		$smalli = $1;
		
		$j =~ /^.*\.([^\.]*)$/;
		$smallj = $1;
		
		print "$smalli\t$smallj\t$counti\t$totali\t$countj\t$totalj\n";
	}
}

#print scalar(@perm)."\n";
