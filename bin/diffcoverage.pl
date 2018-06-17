#!/usr/bin/perl

$currentperm = "";
$results = ();

open FILE, "<froyo/coverage" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^</) {
		$results{$currentperm}{"froyo"}{$_} = 1;
	}
}
close FILE;
open FILE, "<gingerbread/coverage" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Permission:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^</) {
		$results{$currentperm}{"gingerbread"}{$_} = 1;
	}
}
close FILE;

print "Only in froyo:\n";
$count = 0;
foreach $m (keys %{$results{"android.permission.ACCESS_COARSE_LOCATION"}{"froyo"}}) {
	if (! defined $results{"android.permission.ACCESS_COARSE_LOCATION"}{"gingerbread"}{$m}) {
		print "$m\n";
		$count++;
	}
}
print "$count\n";
print "Only in gingerbread:\n";
$count = 0;
foreach $m (keys %{$results{"android.permission.ACCESS_COARSE_LOCATION"}{"gingerbread"}}) {
	if (! defined $results{"android.permission.ACCESS_COARSE_LOCATION"}{"froyo"}{$m}) {
		print "$m\n";
		$count++;
	}
}
print "$count\n";
