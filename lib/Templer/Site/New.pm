
=head1 NAME

Templer::Site::New - Create a new templer site

=cut

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Templer::Site::New;

    my $site = Templer::Site::New->new();
    $site->create( "/tmp/foo" );

=cut

=head1 DESCRIPTION

This class allows a new C<templer> site to be created on-disk.  This
involves creating a new input tree, stub configuration file, etc.

The content of the new site, and the directory names, are taken from
the DATA section of this class.

=cut

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version,
or

b) the Perl "Artistic License".

=cut

=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut

=head1 METHODS

=cut



use strict;
use warnings;


package Templer::Site::New;

use File::Path qw(mkpath);


=head2 new

The constructor.  No arguments are required/recognized.

=cut

sub new
{
    my $class = shift;
    bless {}, $class;
}


=head2 create

Create a new site in the given directory.

This method parses and processes the DATA section of this very module,
to know which files/directories to create.

=cut

sub create
{
    my ( $self, $base, $force ) = (@_);

    #
    #  Forced defaults to false, if not specified.
    #
    $force = 0 if ( !defined($force) );


    #
    #  Files we created
    #
    my $created = 0;

    my $name   = undef;
    my $marker = undef;
    my $tmp    = undef;

    #
    # Process our data-section.
    #
    while ( my $line = <DATA> )
    {
        chomp($line);

        #
        #  Making a directory?
        #
        if ( $line =~ /^mkdir(.*)/ )
        {
            my $dir = $1;
            $dir =~ s/^\s+|\s+$//g;
            $dir = $base . "/" . $dir;

            if ( !-d $dir )
            {
                File::Path::mkpath( $dir, { verbose => 0 } );
            }

        }
        elsif ( !$name &&
                !$marker &&
                ( $line =~ /file\s+([^\s]+)\s+([^\s]+)/ ) )
        {

            #
            #  Writing to a file?
            #
            $name   = $1;
            $marker = $2;
            $tmp    = undef;

        }
        else
        {

            #
            #  If we have a filename to write to, then append to the temporary
            # contents - unless we've found the EOF marker.
            #
            if ( $name && $marker )
            {
                if ( $line eq $marker )
                {
                    my $create = 1;
                    if ( -e $base . "/" . $name )
                    {
                        $create = 0 unless ($force);
                    }

                    if ($create)
                    {
                        my $dst = $base . "/" . $name;

                        open my $handle, ">:utf8", $dst or
                          die "Failed to write to '$dst' - $!";
                        print $handle $tmp;
                        close($handle);

                        $created += 1;
                    }
                    else
                    {
                        print "WARNING: Refusing to over-write $base/$name\n";
                    }

                    $name   = undef;
                    $marker = undef;
                    $tmp    = undef;
                }
                else
                {
                    $tmp .= $line . "\n";
                }
            }
        }

    }
    $created;
}


1;


__DATA__
mkdir input

mkdir output

mkdir layouts

mkdir includes

file input/robots.txt EOF
User-agent: *
Crawl-delay: 10
Disallow: /cgi-bin
Disallow: /stats
EOF

file input/index.wgn EOF
title: Welcome!
----
<p>Welcome to my site.</p>
EOF

file input/about.wgn EOF
title: About my site
----
<p>This is my site, it was generated by <a href="https://github.com/skx/templer">templer</a>.</p>
EOF

file layouts/default.layout EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
  "http://www.w3.org/TR/html4/loose.dtd">
<html>
 <head>
  <!-- tmpl_if name='title' -->
   <title><!-- tmpl_var name='title' escape='html' --></title>
  <!-- tmpl_else -->
   <title>Untitled Page</title>
  <!-- /tmpl_if -->
 </head>
 <body>
  <!-- tmpl_var name='content' -->
  <p>This is site was generated by <a href="https://github.com/skx/templer">templer</a> on <!-- tmpl_var name='date' -->.</p>
 </body>
</html>
EOF

file templer.cfg EOF
##
#
# The first section of the configuration file refers to the
# input and output paths.
#
# Templer will process all files matching "*.skx" beneath a
# particular directory.  That directory is the input directory.
#
input = ./input/
#
##



##
#
# Within the input directory we'll process files that match
# a given suffix.
#
# By default this is ".skx", so we'll template-expand files
# named "index.skx", "about.skx", etc.
#
suffix = .wgn
#
##



##
#
# If we're working in-place then files will be expanded where
# they are found.
#
# This means that the following files will be created:
#
#   ./input/index.skx       -> input/index.html
#   ./input/foo/index.skx   -> input/foo/index.html
#   ..
#
#
# in-place = 1
#
##



##
#
# The more common way of working is to produce the output in a separate
# directory.
#
# NOTE:  If you specify both "in-place=1" and an output directory the former
#        will take precedence.
#
#
output = ./output/
#
##



##
#
# When pages are processed a layout-template will be used to expand the content
# into.
#
# Each page may specify its own layout if it so wishes, but generally we'd
# expect only one layout to exist.
#
# Here we specify both the path to the layout directory and the layout to use
# if none is specified:
#
#
layout-path = ./layouts/
layout      = default.layout
#
##


##
#
# When pages are processed a layout-template will be used to expand the content
# into.
#
# Each page may specify its own layout if it so wishes, but generally we'd
# expect only one layout to exist.
#
# Here we specify both the path to the layout directory and the layout to use
# if none is specified:
#
#
# layout-path = ./layouts/
#
# layout      = default.layout
#
##




##
#
# Templer supports plugins for expanding variable definitions
# inside the input files, or for formating with text systems
# like Textile, Markdown, etc.
#
# There are several plugins included with the system and you
# can write your own in perl.  Specify the path to load plugins
# from here.
#
plugin-path = ./plugins/
#
##


##
#
# Templer supports including files via the 'read_file' function, along
# with the built-in support that HTML::Template has for file inclusion
# via:
#
#   <!-- tmpl_include name='file.inc' -->
#
# In both cases you may specify a search-path for file inclusion
# via the include-path setting:
#
# include-path = include/:include/local/
#
# Given the choice you should prefer the templer-provided file-inclusion
# method over the HTML::Template facility, because this will force pages to
# be rebuilt when the included-files are changed.
#
# Using a HTML::Template include-file you'll need to explicitly force a
# rebuild if you modify an included file, but not the parent.
#
#
include-path = ./includes
#
##




#
#  Anything below this is a global variable, accessible by name in your
# templates.
#
#  For example this:
#
#    copyright = &copy; Steve Kemp 2012
#
#  Can be used in your template, or you page text via:
#
#    <!-- tmpl_var name='copyright' -->
#
#  Similarly you might wish to include a last-modified date in the layout
# and this could be achieved by wruting this:
#
#   <p>Page last rebuilt at <!-- tmpl_var name='date' --></p>
#
#  Providing you uncomment this line:
#
date = run_command( date '+%A %e %B %Y' )
#
#
#
##
EOF

