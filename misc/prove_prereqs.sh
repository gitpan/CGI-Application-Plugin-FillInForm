#!/bin/sh

if [ ! -e t/prereq_scenarios/old_html_fif/HTML/FillInForm.pm ]; then
lwp-mirror \
    http://search.cpan.org/src/TJMATHER/HTML-FillInForm-1.00/lib/HTML/FillInForm.pm \
    t/prereq_scenarios/old_html_fif/HTML/FillInForm.pm
fi

for lib in t/prereq_scenarios/*; do prove -Ilib -I$lib t/; done


