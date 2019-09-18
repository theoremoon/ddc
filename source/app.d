import std.stdio;
import std.getopt;
import std.format;
import core.stdc.stdlib : exit;

const string DDC_VERSION = "0.0.1";

const string HELPMESSAGE = `Usage: ddc [OPTION] [file ...]
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
    try
    {
        getopt(args, "version|V", &versionHandler, "help|h", &help);
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
}
