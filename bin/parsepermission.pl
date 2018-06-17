#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;

$xml = new XML::Simple;
$data = $xml->XMLin($ARGV[0]);

@normal;
@dangerous;
@signature;
@signatureOrSystem;

foreach (@{$data->{"permission"}}) {
	#print $_->{"android:protectionLevel"}." ".$_->{"android:name"}."\n";
	if ($_->{"android:protectionLevel"} eq "normal") {
		push (@normal, $_->{"android:name"});
	} elsif ($_->{"android:protectionLevel"} eq "dangerous") {
		push (@dangerous, $_->{"android:name"});
	} elsif ($_->{"android:protectionLevel"} eq "signature") {
		push (@signature, $_->{"android:name"});
	} elsif ($_->{"android:protectionLevel"} eq "signatureOrSystem") {
		push (@signatureOrSystem, $_->{"android:name"});
	} elsif ($_->{"android:protectionLevel"} =~ m/system/i) {
		push (@signatureOrSystem, $_->{"android:name"});
	} else {
		print "?????\n";
	}
}

$numNorm = scalar(@normal);
$numDang = scalar(@dangerous);
$numSig = scalar(@signature);
$numSigOrSys = scalar(@signatureOrSystem);
$total = $numNorm + $numDang + $numSig + $numSigOrSys;

#print "$numNorm normal permissions:\n";
foreach (@normal) {
	print $_."\n";
}
#print "\n$numDang dangerous permissions:\n";
foreach (@dangerous) {
	print $_."\n";
}

open SYS, ">systempermission" or die $!;
#only include 3rd party permissions
#print "\n$numSig signature permissions:\n";
foreach (@signature) {
	print SYS $_."\n";
}
#print "\n$numSigOrSys signatureOrSystem permissions:\n";
foreach (@signatureOrSystem) {
	print SYS $_."\n";
}
#print "\nTotal $total permissions defined\n";
close SYS;
