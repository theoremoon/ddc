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
    while (p < s.length && s[p].isDigit)
    {
        p++;
    }
    if (p < s.length && s[p] == '.')
    {
        p++;
    }
    while (p < s.length && s[p].isDigit)
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

    DCValue[] opSlice()(int start, int end)
    {
        return this.stack[start .. end];
    }

    int opDollar()
    {
        return cast(int) this.p;
    }
}

auto newVM(R = typeof(&write!char))(uint scale = 0, uint default_stack_size = 128)
{
    return new DCVM!(R)(&write!char, scale, default_stack_size);
}

auto newVM(R)(R o, uint scale = 0, uint default_stack_size = 128)
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
                case '%':
                    p++;
                    auto x = cast(DCNumber) this.stack.top(1);
                    auto y = cast(DCNumber) this.stack.top(0);
                    if (x is null || y is null)
                    {
                        throw new DCException("non-numeric value");
                    }
                    this.stack.pop();
                    this.stack.pop();
                    this.stack.push(new DCNumber(x.mod(y, this.scale)));
                    break;
                case 'v':
                    p++;
                    auto xx = cast(DCNumber) this.stack.top(0);
                    auto x = xx.sqrt(this.scale);
                    this.stack.pop();
                    this.stack.push(new DCNumber(x));
                    break;

                case 'f':
                    p++;
                    foreach_reverse (t; this.stack[0 .. $])
                    {
                        put(this.o, t.to!string ~ "\n");
                    }
                    break;
                case 'k':
                    p++;
                    auto k = cast(DCNumber) this.stack.pop();
                    if (k is null || k < DCNum(0))
                    {
                        throw new DCException("scale must be a nonnegative number");
                    }
                    this.scale = k.to!uint;
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
            put(this.o, e.message ~ "\n");
        }
    }
}

unittest
{
    import std.outbuffer;

    alias TestCase = Tuple!(string, "testcase", string, "expect");
    auto testcases = [
        TestCase("10000 p", "10000\n"), TestCase("_100.0 p", "-100.0\n"),
        TestCase("1 1 + p", "2\n"), TestCase("1.0 1 + p", "2.0\n"),
        TestCase("1 2 -  p", "-1\n"), TestCase("2 1 -  p", "1\n"),
        TestCase("3 2 *  p", "6\n"), TestCase("_2 1.60 *  p", "-3.20\n"),
        TestCase("3 2 /  p", "1\n"), TestCase("_2 1.60 /  p", "-1\n"),
        TestCase("3 2 %  p", "1\n"), TestCase("_2 1.60 %  p", "-0.40\n"),
        TestCase("1 2 3f", "3\n2\n1\n"), TestCase("1 2 3+f", "5\n1\n"),
        TestCase("4 vp", "2\n"), TestCase("2 vp", "1\n"),
        TestCase("2k1 2.0*p", "2.0\n"), TestCase("5k10.0 1.25/p", "8.00000\n"),
        TestCase("_2k", "scale must be a nonnegative number\n"),
    ];
    foreach (t; testcases)
    {
        auto buf = new OutBuffer();
        auto vm = newVM!(typeof(buf))(buf);
        vm.evalLine(t.testcase);
        auto got = buf.toString();
        assert(got == t.expect,
                "Case %s: expected [%s], got [%s]".format(t.testcase, t.expect, got));
    }
}
