import dcnum;

import std.stdio;
import std.utf;
import std.file;
import std.ascii : isWhite, isDigit;
import std.range;
import std.getopt;
import std.format;
import core.stdc.stdlib : exit;

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

DCNum getnum(R)(R input) if (isInputRange!(R))
{
    const base = 10;

    while (input.front.isWhite)
    {
        input.popFront();
    }

    char uniop = 0;
    if (input.front == '_' || input.front == '-')
    {
        uniop = input.front;
        input.popFront();
    }
    else if (input.front == '+')
    {
        input.popFront();
    }

    while (input.front.isWhite)
    {
        input.popFront();
    }

    int digit = 0;
    auto v = DCNum(0);
    while (!input.empty)
    {
        if (input.front.isDigit)
        {
            digit = input.front - '0';
        }
        else if ('A' <= input.front && input.front <= 'F')
        {
            digit = 10 + input.front - 'A';
        }
        else
        {
            break;
        }
        v = v * DCNum(base) + DCNum(digit);
        input.popFront();
    }
    if (input.front == '.')
    {
        input.popFront();
        auto scale = 0;
        while (!input.empty)
        {
            if (input.front.isDigit)
            {
                digit = input.front - '0';
            }
            else if ('A' <= input.front && input.front <= 'F')
            {
                digit = 10 + input.front - 'A';
            }
            else
            {
                break;
            }

            v = v * DCNum(base) + DCNum(digit);
            scale++;
            input.popFront();
        }
        auto divisor = DCNum(1);
        foreach (_; 0 .. scale)
        {
            divisor = divisor * DCNum(base);
        }
        v.div_scale = scale;
        v = v / divisor;
    }

    if (uniop)
    {
        v = DCNum(0) - v;
    }
    return v;
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

    foreach (f; files)
    {
        writeln(getnum(readText(f).byChar));
    }
    foreach (f; args[1 .. $])
    {
        writeln(getnum(readText(f).byChar));
    }
}
