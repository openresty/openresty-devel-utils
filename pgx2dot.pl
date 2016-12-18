#!/usr/bin/env perl

use v5.10.1;
use strict;
use warnings;
use Getopt::Std qw( getopts );

my %opts;
getopts("t", \%opts)
    or die "usage: $0 [-t] <infile>\n";

my $trim = $opts{t};

my $infile = shift or die "no input file specified.\n";

open my $in, $infile
    or die "cannot open $infile for reading: $!\n";

my $lang;
my $ver;
my $rule_name;
my $rule_def;
my @rules;
while (<$in>) {
    next if /^\s*\#/ || /^\s*$/;

    if (/^ \s* \%grammar \s+ (\S+)/xsm) {
        $lang = $1;
        next;
    }

    if (/^ \s* \%version \s+ (\S+)/xsm) {
        $ver = $1;
        next;
    }

    if (/^ \s* ([a-z][-\w]* \s*) :/xsmi) {
        s/ \s+ \# \s+ .* //x;
        if ($rule_name) {
            #$rule_def =~ s/\n+\z//s;
            push @rules, [$rule_name, $rule_def];
            undef $rule_def;
            undef $rule_name;
        }

        $rule_name = $1;
        $rule_def = $_;
        next;
    }

    if (defined $rule_name) {
        s/ \s+ \# \s+ .* //x;
        $rule_def .= $_;
        next;
    }

    die "unexpected line: $_";
}

close $in;

my $title;
if (!defined $lang) {
    ($lang = $infile) =~ s/\.\w+$//;
}

$title = "Grammar for <b>$lang</b>";
if (defined $ver) {
    $title .= "&nbsp; v$ver";
}

my $node_shape;
if ($trim) {
    $node_shape = "ellipse";
} else {
    $node_shape = "box";
}

print <<_EOC_;
digraph grammar_spec {
    graph [fontname="helvetica"];
    labelloc="t";
    label=<$title>;
    node [shape=$node_shape, fontname="helvetica"];
    edge [color=red, fontname="helvetica"];

_EOC_

my %rule_ids;

for my $rule (@rules) {
    my ($name, $def) = @$rule;

    my $id = gen_id($name);
    $rule_ids{$id} = 1;

    my $label;
    if ($trim) {
        $label = "<b>$name</b>";

    } else {

        $label = $def;
        if ($label !~ /\n.*?\n/s) {
            $label =~ s/\s* : \s*/:\n  /xgs;
        }

        $label =~ s/\&/\&amp;/g;
        $label =~ s/  /\&nbsp; /g;
        $label =~ s/</\&lt;/g;
        $label =~ s/>/\&gt;/g;
        $label =~ s/"/\&quot;/g;
        $label =~ s/\A \s+ //;
        $label =~ s{^ ([a-z][-\w]*) :}{<b>$1</b>&nbsp;:}x;
        $label =~ s{\n}{<br align="left"/>}g;
    }

    say "    $id [label=<$label>];"
}

say "";

for my $rule (@rules) {
    my ($name, $def) = @$rule;

    my $id = gen_id($name);
    my %edges;
    while ($def =~ /\b <? ([a-z][-\w]*) >? \b/gxsm) {
        my $dep_id = gen_id($1);
        if ($rule_ids{$dep_id} && $dep_id ne $id) {
            my $key = "$id,$dep_id";
            if (!$edges{$key}) {
                say "    $id -> $dep_id";
                $edges{$key} = 1;
            }
        }
    }
}

sub gen_id {
    my $s = shift;
    $s =~ s/\W/_/g;
    $s;
}

say "}";
