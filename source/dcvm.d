module dcvm;

import std.conv;
import std.stdio;
import std.format;
import std.typecons;
import std.ascii;
import std.range;
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

    alias v this;
}

class DCStack
{
private:
    DCValue[] stack;
    long p;
public:
    this(uint stack_size)
    in
    {
        assert(stack_size > 0);
    }
    do
    {
        this.stack = new DCValue[](stack_size);
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

    DCValue top(uint n = 0)
    {
        if (this.p - n <= 0)
        {
            throw new DCException("stack is empty");
        }
        return this.stack[this.p - n - 1];
    }
}

auto newVM(R)(R o = &write!char, uint scale = 0, uint default_stack_size = 128)
{
    return new DCVM!(R)(o, scale, default_stack_size);
}

class DCVM(R) if (isOutputRange!(R, char))
{
private:
    DCStack stack;
    uint scale;
    R o;
public:
    this(R o, uint scale = 0, uint default_stack_size = 128)
    in
    {
        assert(default_stack_size > 0);
    }

    do
    {
        this.stack = new DCStack(default_stack_size);
        this.scale = scale;
        this.o = o;
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
                    put(this.o, this.stack.top.to!string ~ "\n");
                    break;

                case '+':
                    p++;
                    auto x = cast(DCNumber) this.stack.top(1);
                    auto y = cast(DCNumber) this.stack.top(0);
                    if (x is null || y is null)
                    {
                        throw new DCException("non-numeric value");
                    }
                    this.stack.pop();
                    this.stack.pop();
                    this.stack.push(new DCNumber(x + y));
                    break;

                case '-':
                    p++;
                    auto x = cast(DCNumber) this.stack.top(1);
                    auto y = cast(DCNumber) this.stack.top(0);
                    if (x is null || y is null)
                    {
                        throw new DCException("non-numeric value");
                    }
                    this.stack.pop();
                    this.stack.pop();
                    this.stack.push(new DCNumber(x - y));
                    break;

                case '*':
                    p++;
                    auto x = cast(DCNumber) this.stack.top(1);
                    auto y = cast(DCNumber) this.stack.top(0);
                    if (x is null || y is null)
                    {
                        throw new DCException("non-numeric value");
                    }
                    this.stack.pop();
                    this.stack.pop();
                    this.stack.push(new DCNumber(x * y));
                    break;

                case '/':
                    p++;
                    auto x = cast(DCNumber) this.stack.top(1);
                    auto y = cast(DCNumber) this.stack.top(0);
                    if (x is null || y is null)
                    {
                        throw new DCException("non-numeric value");
                    }
                    this.stack.pop();
                    this.stack.pop();
                    this.stack.push(new DCNumber(x.div(y, this.scale)));
                    break;
                case ' ':
                case '\t':
                case '\r':
                    p++;
                    break;
                default:
                    put(this.o, "[%c](%x) is unimplemented\n".format(p, p));
                    p++;
                    break;
                }
            }
        }
        catch (DCException e)
        {
            put(this.o, e.to!string ~ "\n");
        }
    }
}

unittest
{

}
