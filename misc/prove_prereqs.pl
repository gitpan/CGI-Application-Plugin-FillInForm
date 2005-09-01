#!/usr/bin/perl

=pod

To use this script, create the following directory
structure under t/:

      prereq_scenarios/
         old_html_fif/
              HTML/
                  FillInForm.pm


...where FillInForm.pm is version 1.00 of HTML::FillInForm


=cut

=pod

This script allows you to run the test suite while simulating a
different set of installed Perl modules.

For instance, you can simulate a situation where an older version of one
module is installed, and where a second module is absent.

This works even if you have the latest version of both modules installed
on your system.

You can create multiple test scenarios to simulate different
combinations of modules.

For each module scenario you want to simulate, create a directory in
your test folder, under prereq_scenarios:

    $ mkdir -p t/prereq_scenarios/html_fif_1.00

Place any modules under this directory.

To simulate the absense of a module, create an empty file.  For instance
if you wanted to create a scenario called 'skip_tt+ttt' which simulates
the absense of Text::Template and Text::TagTemplate, you would do the
following:

    $ mkdir t/skip_lib/skip_tt+ttt
    $ mkdir t/skip_lib/skip_tt+ttt/Text
    $ touch t/skip_lib/skip_tt+ttt/Text/Template.pm
    $ touch t/skip_lib/skip_tt+ttt/Text/TagTemplate.pm

To run the test suite multiple times in a row (each with a different
selection of absent modules), run:

    $ perl misc/prove_prereqs.pl t/*.t

Note that this technique only works when your modules and test scripts play nice.

Instaed of:

    use Petal;
    ok(...some Petal related test...);

you should do:

    SKIP: {
        eval { require Petal };
        if ($@) {
            skip "Petal not installed", 1;
        }
        ok(...some Petal related test...);
    }



=cut

my $Default_Scenarios_Dir = 't/prereq_scenarios';

###################################################################
use strict;
use File::Find;
use Path::Class;
use File::Spec;

unless (@ARGV) {
    die "Usage: $0 [-d /path/to/scenarios] [args to prove]\n";
}

my $scenarios_parent = $Default_Scenarios_Dir;

if (@ARGV) {
    if ($ARGV[0] eq '-d') {
        shift;
        $scenarios_parent = shift;
        $Default_Scenarios_Dir;
    }
}

-d $scenarios_parent or die "Scenario dir does not exist: $scenarios_parent\n";
opendir my $dh, $scenarios_parent or die "Can't read scnarios dir: $scenarios_parent\n";

my @scenarios = grep { !/^\./ } readdir $dh;

closedir $dh;

my %scenario_modules;
foreach my $scenario (@scenarios) {
    my $scenario_path = dir($scenarios_parent, $scenario);

    my @modules;
    find(sub {
        return unless -f;
        return unless /\.pm$/; # skip non-modules
        my $path = dir($File::Find::dir, $_);
        push @modules, $path;

    }, $scenario_path);
    $scenario_modules{$scenario} = \@modules;
}

foreach my $scenario (@scenarios) {

    my $module_info = '';
    my $scenario_path = dir($scenarios_parent, $scenario);

    my $module_paths = $scenario_modules{$scenario};

    foreach my $path (@$module_paths) {
        my $rel_path = $path->relative($scenario_path);
        my ($package, $version, $loads_okay) = module_package_and_version($scenario_path, $rel_path);
        if ($loads_okay) {
            $module_info .= "    $package\t$version\n";
        }
        else {
            $module_info .= "    $package\t[fake skip]\n";
        }
    }

    $module_info ||= 'none';

    print "\n##############################################################\n";
    print "Running tests.  Scenario: $scenario\n";
    my @prove_command = ('prove', '-Ilib', "-I$scenario_path", @ARGV);
    print STDERR "prove: @prove_command\n";
    # do { print <<EOF;
    system(@prove_command) && do {
        die <<EOF;
##############################################################
One or more tests failed in this scenario:
    $scenario

The modules and versions were:
$module_info

The command was:
    @prove_command

Terminating.
##############################################################
EOF
    };
}

sub module_package_and_version
{
    my ($root, $file) = @_;

    my $path = file($root, $file);

    $file =~ m/(.+)\.pm\z/ or die "File $file is not a module\n";
    -e $path or die "File $path does not exist\n";

    my $package = $1;
    $package =~ s/\//::/g;

    my $loads_ok_cmd = qq{$^X -I$root -le"eval { require '$file'}; print(\\\$@ ? 0 : 1);"};
    my $loads_ok     = `$loads_ok_cmd`;
    chomp $loads_ok;

    my $version;

    if ($loads_ok) {
        my $version_cmd = qq{$^X -I$root -le"require '$file'; print \\\$} . qq{$package} . qq{::VERSION"};
        $version        = `$version_cmd`;
        chomp $version;
    }

    return ($package, $version, $loads_ok);
}
