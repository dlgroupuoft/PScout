#!/usr/bin/perl

my $proxy;
my $stub;
my $tgt;
my %rpcmethods;

#Replace a string without using RegExp.
sub str_replace {
	my $replace_this = shift;
	my $with_this  = shift; 
	my $string   = shift;
	
	my $length = length($string);
	my $target = length($replace_this);
	
	for(my $i=0; $i<$length - $target + 1; $i++) {
		if(substr($string,$i,$target) eq $replace_this) {
			$string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
			return $string; #Comment this if you what a global replace
		}
	}
	return $string;
}

open METHOD, "<rpcmethod" or die $!;
while (<METHOD>) {
	if ($_ =~ m/^----- /) {
		$proxy = $_;
		$proxy =~ s/^----- //;
		$proxy =~ s/\n$//;
	} else {
		$method = $_;
		$method =~ s/\n$//;
		push (@{$rpcmethods{$proxy}}, $method);
	}
}
close(METHOD);

open CLASS, "<classhierarchy" or die $!;
%rpcclass = ();
while (<CLASS>) {
	chomp($_);
	if ($_ =~ m/^(.*),.*,SUPER:([^,]*),/) {
		$class = $1;
		$super = $2;
		if ($super =~ m/\$Stub$/) {
			$stubproxy = "$super\$Proxy";
			foreach (@{$rpcmethods{$stubproxy}}) {
				$tgtmethod = str_replace($stubproxy, $class, $_);
				#print "SRC:".$_."STMT:=RPC=>TGT:".$tgtmethod."\n";
				print "SRC:".$_."TGT:".$tgtmethod."\n";
			}
		}
	}
}
close CLASS;



