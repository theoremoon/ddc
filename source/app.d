import dcnum;

import std.stdio;
import std.utf;
import std.file;
import std.ascii : isWhite, isDigit;
import std.range;
import std.getopt;
import std.format;
import core.stdc.stdlib : exit;
import dcvm;

const string DDC_VERSION = "0.0.1";

const string HELPMESSAGE = `Usage: ddc [OPTION] [file ...]
    -f, --file=FILE     evaluate contents of file
    -h, --help          display this message and exit
    -V, --version       output version information and exit`;

void versionHandler(string _)
{
    writefln("ddc %s", DDC_VERSION);
    writeln("Copyright (C) 2019- by theoremoon.");
    exit(0);
}

void main(string[] args)
{
    bool help;
    string[] files;
    try
    {
        getopt(args, "version|V", &versionHandler, "help|h", &help, "file|f", &files);
        if (help)
        {
            writeln(HELPMESSAGE);
            exit(0);
        }
    }
    catch (GetOptException)
    {
        stderr.writeln(HELPMESSAGE);
        exit(1);
    }
    auto vm = newVM();
    foreach (f; files ~ args[1 .. $])
    {
        try
        {
            foreach (line; File(f).byLine)
            {
                vm.evalLine(line.dup);
            }
        }
        catch (FileException)
        {
            stderr.writeln("Could not open file %s".format(f));
        }

    }
    if (!(files ~ args[1 .. $]))
    {
        foreach (line; stdin.byLine)
        {
            vm.evalLine(line.dup);
        }
    }
}
