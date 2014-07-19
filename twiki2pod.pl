#!/usr/bin/env perl

use strict;
use warnings;

print "=encoding utf-8\n\n";

my $level = 0;
while (<>) {
    my $new_level;
    if (s/^(\*{1,})\s+//) {
        $new_level = length $1;

        if ($new_level > $level) {
            while ($new_level > $level) {
                print "\n\n=over\n\n";
                $level++;
            }

        } elsif ($new_level == $level) {
            # do nothing

        } else {
            # $new_level < $level
            while ($new_level < $level) {
                print "\n\n=back\n\n";
                $level--;
            }
        }

        print "\n\n=item *\n\n";

    } else {
        $new_level = 0;

        if ($new_level == $level) {
            # do nothing

        } else {
            # $new_level < $level
            while ($new_level < $level) {
                print "\n\n=back\n\n";
                $level--;
            }
        }
    }

    s/\[\[([^]]+)\|[^]]+\]\]/$1/g;
    s/ ~(\w+)/ $1/g;
    s{http://\S+}{L<$&>}g;
    s/\{\{\{(.+?)\}\}\}/C<<< $1 >>>/g;
    s{//(.*?)//}{I<< $1 >>}g;

    print;
}

while ($level > 0) {
    print "\n\n=back\n\n";
    $level--;
}

