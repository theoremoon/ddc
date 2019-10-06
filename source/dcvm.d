module dcvm;

import std.stdio;
import std.typecons;
import std.ascii;
import dcnum;

Tuple!(long, DCNum) parseNumber(string s, long p)
{
    string number_s = "";
    if (s[p] == '_')
    {
        number_s ~= "-";
        p++;
    }

    long save = p;
    while (s[p].isDigit)
    {
        p++;
    }
    if (s[p] == '.')
    {
        p++;
    }
    while (s[p].isDigit)
    {
        p++;
    }
    number_s ~= s[save .. p];
    return tuple(p, DCNum(number_s));
}

class DCException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) pure
    {
        super(msg, file, line);
    }
}

abstract class DCValue
{
    override string toString();
}

class DCNumber : DCValue
{
private:
    DCNum v;
public:
    this(in DCNum v)
    {
        this.v = DCNum(v);
    }

    override string toString()
    {
        return this.v.toString;
    }
}

class DCStack
{
private:
    DCValue[] stack;
    long p;
public:
    this()
    {
        this.stack = new DCValue[](128);
        this.p = 0;
    }

    void push(DCValue v)
    {
        while (p >= this.stack.length)
        {
            this.stack.length = this.stack.length * 2;
        }
        this.stack[this.p++] = v;
    }

    DCValue pop()
    {
        if (this.p == 0)
        {
            throw new DCException("stack is empty");
        }
        return this.stack[--this.p];
    }

    DCValue top()
    {
        if (this.p == 0)
        {
            throw new DCException("stack is empty");
        }
        return this.stack[this.p - 1];
    }
}

class DCVM
{
private:
    DCStack stack;
public:
    this()
    {
        this.stack = new DCStack();
    }

    void evalLine(string line)
    {
        long p = 0;

        try
        {
            while (p < line.length)
            {
                switch (line[p])
                {
                case '_':
                case '.':
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    auto r = parseNumber(line, p);
                    p = r[0];
                    this.stack.push(new DCNumber(r[1]));
                    break;

                case 'p':
                    p++;
                    writeln(this.stack.top);
                    break;
                case ' ':
                case '\t':
                case '\r':
                    p++;
                    break;
                default:
                    writefln("[%c](%x) is unimplemented", p, p);
                    p++;
                    break;
                }
            }
        }
        catch (DCException e)
        {
            writeln(e);
        }
    }

}
