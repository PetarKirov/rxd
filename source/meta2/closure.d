///
module rxd.closure;

struct Closure(Args...)
{
    enum gennedCode = genArgsAliases!Args("Args");
    mixin (gennedCode);

    alias use = typeof(this);
    private alias __my__args__ = Args;
}

private string genArgsAliases(Args...)(string prefix = "Args")
{
    import std.conv : to;
    import std.format : format;
    import std.typecons : staticIota;
    string res;

    string genAliasFunc(string name, string start, size_t idx)
    {
        return ("    auto ref __get__%1$s() { return %2$s[%3$s]; }\n" ~
                "    alias %1$s = __get__%1$s;\n")
            .format(name, start, idx);
    }

    foreach (idx; staticIota!(0, Args.length))
        static if (is(Args[idx] : Closure!U, U...))
            foreach (idx2; staticIota!(0, Args[idx].__my__args__.length))
                res ~= genAliasFunc(Args[idx].__my__args__[idx2].stringof,
                        "Args[" ~ idx.to!string ~"].__my__args__", idx);
        else
            res ~= genAliasFunc(Args[idx].stringof, prefix, idx);

    return res;
}

unittest
{
    struct Point { float x, y; }

    int a = 34;
    Point b = { 3, 4 };
    int c = 32;

    auto inner = Closure!(c)();
    auto outer = Closure!(inner.use, a, b)();

    static assert (inner.sizeof >= (void*).sizeof);
    static assert (outer.sizeof >= (void*).sizeof);

    assert (inner.c == 32);
    assert (outer.a == 34);
    assert (outer.b == Point(3, 4));
    assert (outer.c == 32);

    outer.a++;
    assert (a == 35);
    assert (outer.a == 35);

    outer.c++;
    assert (c == 33);
    assert (inner.c == 33);
    assert (outer.c == 33);
}
