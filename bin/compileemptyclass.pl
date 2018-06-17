#!/usr/bin/perl

#$missingclass = "com.android.internal.telephony.gsm.GSMPhone\$1";
$missingclass = $ARGV[0];

if ($#ARGV != 0) {
	print "Usage: compileemptyclass.pl <package.class>\n";
	exit(0);
}

$missingclass =~ m/(.*)\.([^.]*)$/;
$pkg = $1;
$class = $2;

open FILE, ">$class.java" or die $!;
print FILE "package $pkg;\n";
print FILE "public class $class {\n";
print FILE "public static void main(String[] args) {\n";
print FILE "}\n";
print FILE "}\n";
close FILE;

system("javac '$class.java'");

$pkg =~ s/\./\//g;

if (-e "./$pkg/$class.class") {
	print "Replace existing $class.class? <Y/N> ";
	$decision = <stdin>;
	if ($decision eq "Y\n" || $decision eq "y\n") {
		system("mv '$class.class' ./$pkg/");		
	} else {
		system("rm -f '$class.class'");
	}
} else {
	system("mv '$class.class' ./$pkg/");
}

system("rm -f '$class.java'");
